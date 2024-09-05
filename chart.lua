local useSteps = false

Waviness = 0
WavinessTarget = 0
WavinessSmoothing = 0

NoteTypes = {
    normal = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?}
        draw = function (self,time,speed,chartPos,chartHeight,chartX,isEditor)
            local mainpos = self.time-time
            local pos = mainpos
            chartHeight = chartHeight or 15
            chartPos = chartPos or 5
            if not isEditor then pos = pos+math.sin(pos*8)*Waviness/speed end
            local drawPos = chartPos+chartHeight-pos*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            if useSteps then drawPos = math.floor(drawPos) end
            if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
                love.graphics.setColor(TerminalColors[NoteColors[((self.lane)%(#NoteColors))+1][3]])
                love.graphics.print("○", (chartX+self.lane*4)*8, math.floor(drawPos*16-8))
            end
            local cells = self.length * speed
            for i = 1, cells do
                local barPos = mainpos+i/speed
                if not isEditor then barPos = barPos+math.sin(barPos*8)*Waviness/speed end
                local extPos = chartPos+chartHeight-barPos*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
                if extPos >= chartPos and extPos-((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1) < chartPos+(chartHeight-1) then
                    love.graphics.setColor(TerminalColors[NoteColors[((self.lane)%(#NoteColors))+1][3]])
                    love.graphics.print("║", (chartX+self.lane*4)*8, math.floor(extPos*16-8))
                end
            end
        end
    },
    swap = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?}
        draw = function (self,time,speed,chartPos,chartHeight,chartX,isEditor)
            local mainpos = self.time-time
            local pos = mainpos
            chartHeight = chartHeight or 15
            chartPos = chartPos or 5
            if not isEditor then pos = pos+math.sin(pos*8)*Waviness/speed end
            local drawPos = chartPos+chartHeight-pos*speed
            local laneOffset = math.max(0,math.min(1, ((pos*speed)-7)/4))
            local visualLane = self.lane - self.extra.dir*laneOffset
            local symbol = (math.abs(visualLane-self.lane) <= 1/4 and "○") or (math.abs(visualLane-(self.lane-self.extra.dir)) <= 1/4 and (self.extra.dir == 1 and "▷" or "◁")) or "◇"
            if useSteps then drawPos = math.floor(drawPos) end
            if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
                love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                love.graphics.print("¤", (chartX+self.lane*4)*8, math.floor(drawPos*16-8))
                love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                love.graphics.print(symbol, (chartX+visualLane*4)*8, math.floor(drawPos*16-8))
            end
            local cells = self.length * speed
            for i = 1, cells do
                local barPos = mainpos+i/speed
                if not isEditor then barPos = barPos+math.sin(barPos*8)*Waviness end
                local extPos = chartPos+chartHeight-barPos*speed
                if extPos >= chartPos and extPos < chartPos+(chartHeight-1) then
                    love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                    love.graphics.print("║", (chartX+visualLane*4)*8, math.floor(extPos*16-8))
                end
            end
        end
    }
}

EffectTypes = {
    modify_curve = function(self)
        CurveModifier = self.data.strength
    end,
    chromatic = function(self)
        Chromatic = self.data.strength
    end,
    tear = function(self)
        MissTime = self.data.strength
    end,
    wave = function(self)
        WavinessTarget = self.data.strength
        WavinessSmoothing = self.data.smoothing or 0
    end,
    scroll_speed = function(self)
        ScrollSpeedModTarget = self.data.speed
        ScrollSpeedModSmoothing = self.data.smoothing or 0
    end,
    note_speed = function(self)
        if NoteSpeedMods[self.data.lane+1] then
            NoteSpeedMods[self.data.lane+1][2] = self.data.speed
            NoteSpeedMods[self.data.lane+1][3] = self.data.smoothing or 0
        end
    end,
    offset = function(self)
        ViewOffsetTarget = self.data.offset
        ViewOffsetSmoothing = self.data.smoothing or 0
    end,
    edit_note = function(self,chart)
        for _,note in ipairs(chart) do
            if note.extra.id == self.data.id then
                if self.data.time then
                    note.timeTarget = self.data.time
                end
                if self.data.lane then
                    note.laneTarget = self.data.lane
                end
                if self.data.type then
                    note.type = self.data.type
                end
                if self.data.extra then
                    for k,v in pairs(self.data.extra) do
                        note.extra[k] = v
                    end
                end
                if self.data.smoothing then
                    note.smoothing = self.data.smoothing
                else
                    note.lane = note.laneTarget
                    note.time = note.timeTarget
                end
            end
        end
    end,
    modify_bg = function(self,chart)
        if chart.background then
            chart.background[self.data.key] = self.data.value
        end
    end,
}

Note = {}
Note.__index = Note

function Note:new(time,lane,length,noteType,extra)
    local note = setmetatable({}, self)

    note.time = time
    note.lane = lane
    note.length = length
    note.type = noteType
    note.extra = extra

    return note
end

Effect = {}
Effect.__index = Effect

function Effect:new(time,effectType,data)
    local note = setmetatable({}, self)

    note.time = time
    note.type = effectType
    note.data = data

    return note
end

Chart = {}
Chart.__index = Chart

function Chart:new(song, bpm, notes, effects, name, lanes, video, background, backgroundInit)
    local chart = setmetatable({}, self)

    if love.filesystem.getInfo(song) then
        chart.song = love.audio.newSource(song, "stream")
    end
    chart.songPath = song
    chart.bpm = bpm

    if video and love.filesystem.getInfo(video) then
        chart.video = love.graphics.newVideo(video)
    end
    chart.videoPath = video

    if background and love.filesystem.getInfo(background) then
        local s,r = pcall(require, background:sub(1,-5))
        if s then
            chart.background = r
            chart.backgroundPath = background
        else
            chart.background = require "boxesbg"
            chart.backgroundPath = "boxesbg.lua"
        end
    else
        chart.background = require "boxesbg"
        chart.backgroundPath = "boxesbg.lua"
    end

    if chart.background then
        chart.background.init(backgroundInit or {})
    end
    self.backgroundInit = backgroundInit or {}

    chart.notes = notes or {}
    table.sort(chart.notes or {}, function (a, b)
        return a.time < b.time
    end)
    chart.effects = effects or {}
    table.sort(chart.effects or {}, function (a, b)
        return a.time < b.time
    end)
    chart.time = 0
    chart.totalCharge = 0
    for _,note in ipairs(chart.notes) do
        chart.totalCharge = chart.totalCharge + 1 + (note.length or 0)
    end

    chart.name = name or "Chart"
    chart.lanes = lanes or 4

    return chart
end

function Chart:sort()
    table.sort(self.notes or {}, function (a, b)
        return a.time < b.time
    end)
    table.sort(self.effects or {}, function (a, b)
        return a.time < b.time
    end)
end

function Chart:recalculateCharge()
    self.totalCharge = 0
    for _,note in ipairs(self.notes) do
        self.totalCharge = self.totalCharge + 1 + (note.length or 0)
    end
end

function Chart:resetAllNotes()
    for _,note in ipairs(self.notes) do
        note.destroyed = false
        note.heldFor = nil
        note.holding = nil
    end
    for _,effect in ipairs(self.effects) do
        effect.destroyed = false
    end
end

function Chart.fromFile(path)
    local s,data = pcall(json.decode, love.filesystem.read(path))
    if not s then return end
    data.song = getPathOf(path).."/"..data.song
    if data.song:sub(1,1) == "/" then data.song = data.song:sub(2,-1) end
    local video = data.video
    if data.video then
        data.video = getPathOf(path).."/"..data.video
        if data.video:sub(1,1) == "/" then data.video = data.video:sub(2,-1) end
        if not love.filesystem.getInfo(data.video) then
            data.video = video
        end
    end
    local background = data.background
    if data.background then
        data.background = getPathOf(path).."/"..data.background
        if data.background:sub(1,1) == "/" then data.background = data.background:sub(2,-1) end
        if not love.filesystem.getInfo(data.background) then
            data.background = background
        end
    end
    for i,note in ipairs(data.notes) do
        data.notes[i] = Note:new(note.time,note.lane,note.length,note.type,note.extra)
    end
    for i,effect in ipairs(data.effects) do
        data.effects[i] = Effect:new(effect.time,effect.type,effect.data)
    end
    return Chart:new(data.song,data.bpm,data.notes,data.effects,data.name,data.lanes,data.video,data.background,data.backgroundInit)
end

function Chart:save(path)
    local notes = {}
    for _,note in ipairs(self.notes) do
        table.insert(notes, {time = note.time, lane = note.lane, length = note.length, type = note.type, extra = note.extra})
    end
    local effects = {}
    for _,effect in ipairs(self.effects) do
        table.insert(effects, {time = effect.time, type = effect.type, data = effect.data})
    end
    love.filesystem.write(path, json.encode({
        name = self.name,
        lanes = self.lanes,
        song = self.songPath,
        video = self.videoPath,
        background = self.backgroundPath,
        backgroundInit = self.backgroundInit,
        bpm = self.bpm,
        notes = notes,
        effects = effects
    }))
end

function Chart:getDensity()
    if not self.song then
        return 0
    end
    return #self.notes / self.song:getDuration("seconds")
end