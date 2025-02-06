local utf8 = require "utf8"

function utf8.sub(txt, i, j)
    local o1 = (utf8.offset(txt,i) or (#txt))-1
    local o2 = (utf8.offset(txt,j+1) or (#txt+1))-1
    return txt:sub(o1,o2)
end

local useSteps = false

Waviness = 0
WavinessTarget = 0
WavinessSmoothing = 0

NoteTypes = {
    normal = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?, visualLane?: number}
        draw = function (self,time,speed,chartPos,chartHeight,chartX,isEditor)
            chartX = chartX + AnaglyphSide/8*0.5
            local mainpos = self.time-time
            local pos = mainpos
            chartHeight = chartHeight or 15
            chartPos = chartPos or 5
            if not isEditor then pos = pos+math.sin(pos*8)*Waviness/speed end
            local drawPos = chartPos+chartHeight-pos*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local visualLane = self.visualLane or self.lane
            if useSteps then drawPos = math.floor(drawPos) end

            local r,g,b,a = love.graphics.getColor()
            
            local cells = self.length * math.abs(speed)
            for i = 0.5, cells do
            -- for i = 1, cells do
                local barPos = mainpos+i/speed
                if not isEditor then barPos = barPos+math.sin(barPos*8)*Waviness/speed end
                local extPos = chartPos+chartHeight-barPos*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
                if extPos >= chartPos and extPos-((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1) < chartPos+(chartHeight-1) then
                    love.graphics.setColor(TerminalColors[NoteColors[((self.lane)%(#NoteColors))+1][3]])
                    local R,G,B,A = love.graphics.getColor()
                    love.graphics.setColor(r*R,g*G,b*B,a*A)
                    love.graphics.print("║", (chartX+visualLane*4)*8+4, math.floor(extPos*16-8-0), 0, 1, 1, NoteFont:getWidth("║")/2)
                    -- love.graphics.setColor(TerminalColors[NoteColors[((self.lane)%(#NoteColors))+1][2]])
                    -- love.graphics.print("▥▥▥", (chartX+self.lane*4-1)*8, math.floor(extPos*16-8))
                end
            end

            if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
                love.graphics.setColor(TerminalColors[NoteColors[((self.lane)%(#NoteColors))+1][3]])
                local R,G,B,A = love.graphics.getColor()
                love.graphics.setColor(r*R,g*G,b*B,a*A)
                love.graphics.print("○", (chartX+visualLane*4)*8+4, math.floor(drawPos*16-8-(isEditor and 0 or 4)), 0, 1, 1, NoteFont:getWidth("○")/2)
                -- love.graphics.print("▥▥▥", (chartX+self.lane*4-1)*8, math.floor(drawPos*16-8))
            end
            
            love.graphics.setColor(r,g,b,a)
        end,
        hit = function(self,time,lane)
            local pos = self.time-time
            if math.abs(pos) <= TimingWindow and lane == self.lane and not self.destroyed and not self.holding then
                local t = OverchargeWindow
                local accuracy = (math.abs(pos)/TimingWindow)
                accuracy = math.max(0,math.min(1,(1/(1-t))*accuracy - ((1/(1-t))-1)))
                return true, accuracy, true
            end
            return false
        end,
        getDifficulty = function(self)
            return 1 + (self.length or 0) * 0.25
        end,
        calculateCharge = function(self)
            return 1 + (self.length or 0)
        end
    },
    swap = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?, visualLane?: number}
        draw = function (self,time,speed,chartPos,chartHeight,chartX,isEditor)
            local mainpos = self.time-time
            local pos = mainpos
            chartHeight = chartHeight or 15
            chartPos = chartPos or 5
            if not isEditor then pos = pos+math.sin(pos*8)*Waviness/speed end
            local drawPos = chartPos+chartHeight-pos*speed
            local laneOffset = isEditor and 1 or math.max(0,math.min(1, ((pos*speed)-7)/4))
            local visualLane = (self.visualLane or self.lane) - self.extra.dir*laneOffset
            local symbol = isEditor and ((self.extra.dir == 1 and "▷") or (self.extra.dir == -1 and "◁") or "◇") or ((math.abs(visualLane-self.lane) <= 1/4 and "○") or (math.abs(visualLane-(self.lane-self.extra.dir)) <= 1/4 and (self.extra.dir == 1 and "▷" or "◁")) or "◇")
            if useSteps then drawPos = math.floor(drawPos) end

            local r,g,b,a = love.graphics.getColor()

            local cells = self.length * speed
            for i = 0.5, cells do
                local barPos = mainpos+i/speed
                if not isEditor then barPos = barPos+math.sin(barPos*8)*Waviness end
                local extPos = chartPos+chartHeight-barPos*speed
                if extPos >= chartPos and extPos < chartPos+(chartHeight-1) then
                    love.graphics.setColor(TerminalColors[NoteColors[((self.lane)%(#NoteColors))+1][3]])
                    local R,G,B,A = love.graphics.getColor()
                    love.graphics.setColor(r*R,g*G,b*B,a*A)
                    love.graphics.print("║", (chartX+visualLane*4)*8+4, math.floor(extPos*16-8-(isEditor and 0 or 4)), 0, 1, 1, NoteFont:getWidth("║")/2)
                end
            end

            if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
                love.graphics.setColor(TerminalColors[NoteColors[((self.lane)%(#NoteColors))+1][3]])
                local R,G,B,A = love.graphics.getColor()
                love.graphics.setColor(r*R,g*G,b*B,a*A)
                love.graphics.setFont(Font)
                if self.extra.dir ~= 0 then love.graphics.print("¤", (chartX+self.lane*4)*8, math.floor(drawPos*16-8-(isEditor and 0 or 4))) end
                love.graphics.setFont(NoteFont)
                love.graphics.print(symbol, (chartX+visualLane*4)*8+4, math.floor(drawPos*16-8-(isEditor and 0 or 4)), 0, 1, 1, NoteFont:getWidth(symbol)/2)
            end
            
            love.graphics.setColor(r,g,b,a)
        end,
        hit = function(self,time,lane)
            local pos = self.time-time
            if math.abs(pos) <= TimingWindow and lane == self.lane and not self.destroyed and not self.holding then
                local t = OverchargeWindow
                local accuracy = (math.abs(pos)/TimingWindow)
                accuracy = math.max(0,math.min(1,(1/(1-t))*accuracy - ((1/(1-t))-1)))
                return true, accuracy, true
            end
            return false
        end,
        getDifficulty = function(self)
            return 1.5 + (self.length or 0) * 0.25
        end,
        calculateCharge = function(self)
            return 1 + (self.length or 0)
        end
    },
    merge = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?, visualLane?: number}
        draw = function (self,time,speed,chartPos,chartHeight,chartX,isEditor)
            -- ▧▥▨ ◐◑
            local mainpos = self.time-time
            local pos = mainpos
            chartHeight = chartHeight or 15
            chartPos = chartPos or 5
            if not isEditor then pos = pos+math.sin(pos*8)*Waviness/speed end
            local drawPos = chartPos+chartHeight-pos*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            if useSteps then drawPos = math.floor(drawPos) end

            local r,g,b,a = love.graphics.getColor()

            local visualLane = self.visualLane or self.lane
            if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
                local min,max = math.min(visualLane+self.extra.dir, visualLane), math.max(visualLane+self.extra.dir, visualLane)
                for i = min,max do
                    love.graphics.setColor(TerminalColors[NoteColors[((i)%(#NoteColors))+1][3]])
                    local R,G,B,A = love.graphics.getColor()
                    love.graphics.setColor(r*R,g*G,b*B,a*A)
                    love.graphics.print(((i == min and i == max) and "◻○◼") or (i == min and "◻◐▥▨") or (i == max and "▧▥◑◼") or "▧▥▥▥▨", (chartX+(i)*4-2)*8, math.floor(drawPos*16-8-(isEditor and 0 or 4)))
                    -- love.graphics.print(((i == min and i == max) and "◻▥▥▥◻") or (i == min and "◻▥▥▥▨") or (i == max and "▧▥▥▥◻") or "▧▥▥▥▨", (chartX+(i)*4-2)*8, math.floor(drawPos*16-8))
                end
            end
            
            love.graphics.setColor(r,g,b,a)
        end,
        hit = function(self,time,lane)
            local pos = self.time-time
            local min,max = math.min(self.lane+self.extra.dir, self.lane), math.max(self.lane+self.extra.dir, self.lane)
            if math.abs(pos) <= TimingWindow and (lane >= min and lane <= max) and not self.destroyed and not self.holding then
                local t = OverchargeWindow
                local accuracy = (math.abs(pos)/TimingWindow)
                accuracy = math.max(0,math.min(1,(1/(1-t))*accuracy - ((1/(1-t))-1)))
                if not self.laneAccuracies then
                    self.laneAccuracies = {}
                end
                if not self.laneAccuracies[lane] then
                    self.laneAccuracies[lane] = accuracy
                end
                local avgAccuracy = 0
                local amount = 0
                for i = min,max do
                    if not self.laneAccuracies[i] then
                        return false, nil, true
                    end
                    avgAccuracy = avgAccuracy + self.laneAccuracies[i]
                    amount = amount + 1
                end
                local rating = GetRating(1 - (avgAccuracy/amount))
                for i = min,max do
                    if i ~= self.lane then
                        if rating == 1 then
                            local x = (80-(SceneManager.ActiveScene.chart.lanes*4-1))/2 - 1+(i)*4 + 1
                            for _=1, 4 do
                                local drawPos = (5)+(15)+(ViewOffset+ViewOffsetFreeze)*(ScrollSpeed*ScrollSpeedMod)
                                table.insert(Particles, {id = "powerhit", x = x*8+12, y = drawPos*16-16, vx = (love.math.random()*2-1)*64, vy = -(love.math.random()*2)*32, life = (love.math.random()*0.5+0.5)*0.25, color = OverchargeColors[love.math.random(1,#OverchargeColors)], char = "¤"})
                            end
                        end
                        Charge = Charge + 1
                        RatingCounts[rating] = RatingCounts[rating] + 1
                        Combo = Combo + 1
                    end
                end
                return true, avgAccuracy/amount, true
            end
            return false, nil, false
        end,
        getDifficulty = function(self)
            return math.abs(self.extra.dir)*1.5+1
        end,
        miss = function(self)
            RatingCounts[#RatingCounts] = RatingCounts[#RatingCounts] + math.abs(self.extra.dir)
            ComboBreaks = ComboBreaks + math.abs(self.extra.dir)
        end,
        reset = function(self)
            self.laneAccuracies = nil
        end,
        calculateCharge = function(self)
            return math.abs(self.extra.dir) + 1
        end
    }
}

EffectTypes = {
    modify_curve = function(self)
        CurveModifierTarget = self.data.strength
        CurveModifierSmoothing = self.data.smoothing or 0
        if (self.data.smoothing or 0) == 0 then
            CurveModifier = CurveModifierTarget
        end
    end,
    chromatic = function(self)
        ChromaticModifierTarget = self.data.strength
        ChromaticModifierSmoothing = self.data.smoothing or 0
        if (self.data.smoothing or 0) == 0 then
            ChromaticModifier = ChromaticModifierTarget
        end
    end,
    tear = function(self)
        TearingModifierTarget = self.data.strength
        TearingModifierSmoothing = self.data.smoothing or 0
        if (self.data.smoothing or 0) == 0 then
            TearingModifier = TearingModifierTarget
        end
    end,
    board_brightness = function(self)
        BoardBrightnessTarget = self.data.brightness or BoardBrightnessTarget
        BoardBrightnessSmoothing = self.data.smoothing or 0
        if (self.data.smoothing or 0) == 0 then
            BoardBrightness = BoardBrightnessTarget
        end
    end,
    note_brightness = function(self)
        NoteBrightnessTarget = self.data.brightness or NoteBrightnessTarget
        NoteBrightnessSmoothing = self.data.smoothing or 0
        if (self.data.smoothing or 0) == 0 then
            NoteBrightness = NoteBrightnessTarget
        end
    end,
    bloom = function(self)
        BloomStrengthModifierTarget = self.data.strength
        BloomStrengthModifierSmoothing = self.data.smoothing or 0
        if (self.data.smoothing or 0) == 0 then
            BloomStrengthModifier = BloomStrengthModifierTarget
        end
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
        ViewOffsetMoveLine = not self.data.keep_line
    end,
    freeze_view = function(self)
        ViewOffsetFreeze = not ViewOffsetFreeze
    end,
    edit_note = function(self,chart)
        for _,note in ipairs(chart.notes) do
            if note.extra.id == self.data.id or note.extra.group == self.data.group then
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
                    if note.timeTarget then note.time = note.timeTarget end
                    if note.laneTarget then note.lane = note.laneTarget ; note.visualLane = note.laneTarget end
                end
                if self.data.id then return end
            end
        end
    end,
    transform = function(self)
        if self.data.shift then
            DisplayShiftTarget = self.data.shift or DisplayShiftTarget
            DisplayShiftSmoothing = self.data.smoothing or 0
        end
        if self.data.scale then
            DisplayScaleTarget = self.data.scale or DisplayScaleTarget
            DisplayScaleSmoothing = self.data.smoothing or 0
        end
        if self.data.rotation then
            DisplayRotationTarget = self.data.rotation or DisplayRotationTarget
            DisplayRotationSmoothing = self.data.smoothing or 0
        end
        if self.data.shear then
            DisplayShearTarget = self.data.shear or DisplayShearTarget
            DisplayShearSmoothing = self.data.smoothing or 0
        end
        if (self.data.smoothing or 0) == 0 then
            DisplayShift = DisplayShiftTarget
            DisplayScale = DisplayScaleTarget
            DisplayRotation = DisplayRotationTarget
            DisplayShear = DisplayShearTarget
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

SongDifficulty = {
    hidden = {
        name = "???",
        color = TerminalColors[ColorID.DARK_GRAY],
        range = {0,math.huge}
    },
    easy = {
        name = "EASY",
        color = TerminalColors[ColorID.LIGHT_GREEN],
        range = {1,5}
    },
    medium = {
        name = "MEDIUM",
        color = TerminalColors[ColorID.YELLOW],
        range = {6,10}
    },
    hard = {
        name = "HARD",
        color = TerminalColors[ColorID.LIGHT_RED],
        range = {11,15}
    },
    extreme = {
        name = "EXTREME",
        color = TerminalColors[ColorID.MAGENTA],
        range = {16,20}
    },
    overvolt = {
        name = "OVERVOLT",
        color = {
            TerminalColors[OverchargeColors[1]],
            TerminalColors[OverchargeColors[2]],
            TerminalColors[OverchargeColors[3]],
            TerminalColors[OverchargeColors[4]],
            TerminalColors[OverchargeColors[5]],
            TerminalColors[OverchargeColors[6]]
        },
        range = {21,30},
        animate = true
    }
}

function PrintDifficulty(x,y,difficulty,level,align)
    local currentX = x
    local length = utf8.len(SongDifficulty[difficulty].name .. (level ~= nil and (" " .. level) or ""))
    local nameLength = utf8.len(SongDifficulty[difficulty].name)
    if align == "right" then
        currentX = x - length*8
    end
    if align == "center" then
        currentX = x - length*4
    end
    local color = SongDifficulty[difficulty].color or TerminalColors[ColorID.WHITE]
    local r,g,b,a = love.graphics.getColor()
    if type(color[1]) == "table" then
        for i = 1, nameLength do
            local colorIndex = (i-1 - (SongDifficulty[difficulty].animate and math.floor(love.timer.getTime()*(SongDifficulty[difficulty].animateSpeed or #color)) or 0))%#color+1
            ---@diagnostic disable-next-line: param-type-mismatch
            love.graphics.setColor(color[colorIndex])
            local R,G,B,A = love.graphics.getColor()
            love.graphics.setColor(r*R,g*G,b*B,a*A)
            love.graphics.print(utf8.sub(SongDifficulty[difficulty].name, i+1, i+1), currentX, y)
            currentX = currentX + 8
        end
    else
        love.graphics.setColor(color)
        local R,G,B,A = love.graphics.getColor()
        love.graphics.setColor(r*R,g*G,b*B,a*A)
        love.graphics.print(SongDifficulty[difficulty].name, currentX, y)
        currentX = currentX + nameLength*8
    end
    if level ~= nil then
        currentX = currentX + 8
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        local R,G,B,A = love.graphics.getColor()
        love.graphics.setColor(r*R,g*G,b*B,a*A)
        love.graphics.print(tostring(level), currentX, y)
    end
    love.graphics.setColor(r,g,b,a)
end

---@class SongData
---@field path string
---@field name string
---@field author string
---@field coverArtist string
---@field song string
---@field songPath string
---@field bpm number
---@field charts {easy: chartdata|Chart?, medium: chartdata|Chart?, hard: chartdata|Chart?, extreme: chartdata|Chart?, overvolt: chartdata|Chart?}
---@field levels {easy: number, medium: number, hard: number, extreme: number, overvolt: number}
---@field songPreview {[1]: number, [2]: number}
SongData = {}
SongData.__index = SongData

---@alias chartdata {path: string, level: number, charter: string}

function LoadSongData(path)
    local infoPath = path.."/info.json"
    if not love.filesystem.getInfo(infoPath) then return nil end
    ---@type boolean, {name: string, author: string, bpm: number, song: string, songPreview: {[1]: number, [2]: number}, charts: {easy: chartdata?, medium: chartdata?, hard: chartdata?, extreme: chartdata?, overvolt: chartdata?}, coverArtist: string}
    local loadedInfo,songInfo = pcall(json.decode, love.filesystem.read(infoPath))
    if not loadedInfo then return nil end

    local songData = setmetatable({}, SongData)
    songData.path = path

    songData.name = songInfo.name
    songData.author = songInfo.author
    songData.coverArtist = songInfo.coverArtist
    songData.bpm = songInfo.bpm
    songData.songPreview = songInfo.songPreview

    songData.song = songInfo.song
    songData.songPath = path.."/"..songInfo.song

    songData.charts = songInfo.charts
    songData.levels = {}
    for name,chart in pairs(songData.charts or {}) do
        songData.levels[name] = chart.level
    end

    return songData
end

function SongData:new(name,author,bpm,song,songPreview,charts,levels)
    local songData = setmetatable({}, self)
    songData.name = name or "Song"
    songData.author = author or "Composer"
    songData.bpm = bpm or 120
    songData.song = song
    songData.songPreview = songPreview or {0,math.huge}
    songData.charts = charts or {}
    songData.levels = levels or {}
    for chartname,chart in pairs(charts or {}) do
        songData.levels[chartname] = songData.levels[chartname] or chart.level
    end
    return songData
end

function SongData:newChart(difficulty, level)
    if self.charts[difficulty] then return self.charts[difficulty] end
    local chart = Chart:new(
        self.songPath,
        self.bpm,
        {}, {}, {},
        self.name, 4,
        nil, nil, {}, "?"
    )
    self.charts[difficulty] = chart
    self.levels[difficulty] = level or 1
    return chart
end

function SongData:removeChart(difficulty)
    if not self.charts[difficulty] then return end
    self.charts[difficulty] = nil
    self.levels[difficulty] = nil
end

function SongData:loadChart(difficulty)
    if not self.charts[difficulty] then return nil end
    if getmetatable(self.charts[difficulty]) == Chart then return self.charts[difficulty] end
    local chart = Chart.fromFile(self.path.."/"..self.charts[difficulty].path)
    self.charts[difficulty] = chart
    return chart
end

function SongData:save(path)
    if not love.filesystem.getInfo(path) then
        love.filesystem.createDirectory(path)
    end
    local charts = {}
    for name,chart in pairs(self.charts) do
        if getmetatable(chart) == Chart then
            charts[name] = {
                path = name..".json",
                charter = chart.charter or "Charter",
                level = self:getLevel(name)
            }
            chart:save(path.."/"..name..".json")
        else
            charts[name] = chart
        end
    end
    love.filesystem.write(path.."/info.json", json.encode({
        name = self.name,
        author = self.author,
        coverArtist = self.coverArtist,
        bpm = self.bpm,
        song = self.song,
        songPreview = self.songPreview,
        charts = charts,
    }))
    self.path = path
end

function SongData:hasLevel(difficulty)
    return self.levels[difficulty] ~= nil
end

function SongData:getLevel(difficulty)
    return self.levels[difficulty]
end

function SongData:getCharter(difficulty)
    if not self.charts[difficulty] then return "Charter" end
    return self.charts[difficulty].charter or "Charter"
end

---@class Chart
---@field song string
---@field video string
---@field background string
---@field backgroundInit table
---@field bpm number
---@field notes table
---@field effects table
---@field bpmChanges table
---@field time number
---@field lanes integer
---@field name string
---@field charter string
Chart = {}
Chart.__index = Chart

function Chart:new(song, bpm, notes, effects, bpmChanges, name, lanes, video, background, backgroundInit, charter)
    local chart = setmetatable({}, self)

    chart.song = song
    chart.bpm = bpm

    chart.video = video
    chart.background = background
    chart.backgroundInit = backgroundInit or {}

    chart.notes = notes or {}
    table.sort(chart.notes or {}, function (a, b)
        return a.time < b.time
    end)
    chart.effects = effects or {}
    table.sort(chart.effects or {}, function (a, b)
        return a.time < b.time
    end)
    chart.bpmChanges = bpmChanges or {}
    table.sort(chart.bpmChanges or {}, function (a, b)
        return a.time < b.time
    end)
    chart.time = 0
    chart.totalCharge = 0
    for _,note in ipairs(chart.notes) do
        chart.totalCharge = chart.totalCharge + 1 + (note.length or 0)
    end

    chart.name = name or "Chart"
    chart.lanes = lanes or 4

    chart.charter = charter or "Charter"

    return chart
end

function Chart:sort()
    table.sort(self.notes or {}, function (a, b)
        return a.time < b.time
    end)
    table.sort(self.effects or {}, function (a, b)
        return a.time < b.time
    end)
    table.sort(self.bpmChanges or {}, function (a, b)
        return a.time < b.time
    end)
end

function Chart:recalculateCharge()
    self.totalCharge = 0
    for _,note in ipairs(self.notes) do
        if (NoteTypes[note.type] or {}).calculateCharge then
            self.totalCharge = self.totalCharge + NoteTypes[note.type].calculateCharge(note)
        else
            self.totalCharge = self.totalCharge + 1 + (note.length or 0)
        end
    end
end

function Chart:resetAllNotes()
    for _,note in ipairs(self.notes) do
        note.destroyed = false
        note.heldFor = nil
        note.holding = nil
        if NoteTypes[note.type].reset then
            NoteTypes[note.type].reset(note)
        end
    end
    for _,effect in ipairs(self.effects) do
        effect.destroyed = false
    end
end

function Chart.fromFile(path,b)
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
    return Chart:new(data.song,data.bpm,data.notes,data.effects,data.bpmChanges,data.name,data.lanes,data.video,data.background,data.backgroundInit,data.charter)
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
        song = self.song:sub(#getPathOf(self.song)+2, -1),
        video = self.video,
        background = self.background,
        backgroundInit = self.backgroundInit,
        bpm = self.bpm,
        notes = notes,
        effects = effects,
        bpmChanges = self.bpmChanges,
        charter = self.charter
    }))
end

function Chart:getDensity()
    if not self.song then return 0 end
    local song = Assets.Source(self.song)
    if not song then return 0 end
    return #self.notes / song:getDuration("seconds")
end

function Chart:getDifficulty()
    if not self.song then return 0 end
    local song = Assets.Source(self.song)
    if not song then return 0 end
    local startTime = math.huge
    local endTime = -math.huge
    local amount = 0
    for _,note in ipairs(self.notes) do
        amount = amount + NoteTypes[note.type].getDifficulty(note)
        startTime = math.min(startTime, note.time, note.time+note.length)
        endTime = math.max(endTime, note.time, note.time+note.length)
    end
    local duration = (endTime-startTime)
    if duration == 0 then return 0 end
    return amount / (endTime-startTime) * 1.5
end

function Chart:getBalance()
    local balance = 0
    for _,note in ipairs(self.notes) do
        balance = balance + (note.lane - (self.lanes-1)/2)
    end
    return balance / #self.notes
end