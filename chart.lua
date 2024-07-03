local useSteps = false

NoteTypes = {
    normal = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?}
        draw = function (self,time,speed,chartPos,chartHeight)
            local pos = self.time-time
            chartHeight = chartHeight or 15
            chartPos = chartPos or 5
            local drawPos = chartPos+chartHeight-pos*speed
            if useSteps then drawPos = math.floor(drawPos) end
            if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
                love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                love.graphics.print("○", (34+self.lane*4)*8, drawPos*16-8)
            end
            local cells = self.length * speed
            for i = 1, cells do
                local extPos = drawPos-i
                if extPos >= chartPos and extPos < chartPos+(chartHeight-1) then
                    love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                    love.graphics.print("║", (34+self.lane*4)*8, extPos*16-8)
                end
            end
        end
    },
    swap = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?}
        draw = function (self,time,speed,chartPos,chartHeight)
            local pos = self.time-time
            chartHeight = chartHeight or 15
            chartPos = chartPos or 5
            local drawPos = chartPos+chartHeight-pos*speed
            local laneOffset = math.max(0,math.min(1, ((pos*speed)-7)/4))
            local visualLane = self.lane - self.extra.dir*laneOffset
            local symbol = (math.abs(visualLane-self.lane) <= 1/4 and "○") or (math.abs(visualLane-(self.lane-self.extra.dir)) <= 1/4 and (self.extra.dir == 1 and "▷" or "◁")) or "◇"
            if useSteps then drawPos = math.floor(drawPos) end
            if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
                love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                love.graphics.print(symbol, (34+visualLane*4)*8, drawPos*16-8)
            end
            local cells = self.length * speed
            for i = 1, cells do
                local extPos = drawPos-i
                if extPos >= chartPos and extPos < chartPos+14 then
                    love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                    love.graphics.print("║", (34+visualLane*4)*8, extPos*16-8)
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
    end
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

function Chart:new(song, bpm, notes, effects)
    local chart = setmetatable({}, self)

    chart.song = love.audio.newSource(song, "stream")
    chart.songPath = song
    chart.bpm = bpm

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

    return chart
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
    end
end

function Chart.fromFile(path)
    local s,data = pcall(json.decode, love.filesystem.read(path))
    if not s then return end
    for i,note in ipairs(data.notes) do
        data.notes[i] = Note:new(note.time,note.lane,note.length,note.type,note.extra)
    end
    for i,effect in ipairs(data.effects) do
        data.effects[i] = Effect:new(effect.time.effect.type,effect.data)
    end
    return Chart:new(data.song,data.bpm,data.notes,data.effects)
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
        song = self.songPath,
        bpm = self.bpm,
        notes = notes,
        effects = effects
    }))
end