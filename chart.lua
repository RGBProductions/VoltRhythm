local useSteps = false

NoteTypes = {
    normal = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?}
        draw = function (self,time,speed)
            local pos = self.time-time
            local chartHeight = 15
            local chartPos = 5
            local drawPos = chartPos+chartHeight-pos*speed
            if useSteps then drawPos = math.floor(drawPos) end
            if drawPos >= chartPos and drawPos < chartPos+16 then
                love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                love.graphics.print("○", (34+self.lane*4)*8, drawPos*16-8)
            end
            local cells = self.length * speed
            for i = 1, cells do
                local extPos = drawPos-i
                if extPos >= chartPos and extPos < chartPos+14 then
                    love.graphics.setColor(TerminalColors[NoteColors[self.lane+1][3]])
                    love.graphics.print("║", (34+self.lane*4)*8, extPos*16-8)
                end
            end
        end
    },
    swap = {
        ---@param self {time: number, lane: number, length: number, type: string, extra: table, heldFor: number?}
        draw = function (self,time,speed)
            local pos = self.time-time
            local chartHeight = 15
            local chartPos = 5
            local drawPos = chartPos+chartHeight-pos*speed
            local laneOffset = math.max(0,math.min(1, ((pos*speed)-7)/4))
            local visualLane = self.lane - self.extra.dir*laneOffset
            local symbol = (math.abs(visualLane-self.lane) <= 1/4 and "○") or (math.abs(visualLane-(self.lane-self.extra.dir)) <= 1/4 and (self.extra.dir == 1 and "▷" or "◁")) or "◇"
            if useSteps then drawPos = math.floor(drawPos) end
            if drawPos >= chartPos and drawPos < chartPos+16 then
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

    chart.song = song
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

function Chart.fromFile(path)
    
end