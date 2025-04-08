local utf8 = require "utf8"

function utf8.sub(txt, i, j)
    local o1 = (utf8.offset(txt,i) or (#txt))
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
    },
    mine = {
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

            if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
                love.graphics.setColor(TerminalColors[ColorID.RED])
                local R,G,B,A = love.graphics.getColor()
                love.graphics.setColor(r*R,g*G,b*B,a*A)
                love.graphics.print("☓", (chartX+visualLane*4)*8+4, math.floor(drawPos*16-8-(isEditor and 0 or 4)), 0, 1, 1, NoteFont:getWidth("○")/2)
            end
            
            love.graphics.setColor(r,g,b,a)
        end,
        hit = function(self,time,lane)
            local pos = self.time-time
            if math.abs(pos) <= TimingWindow and lane == self.lane and not self.destroyed and not self.holding then
                self.destroyed = true
                Hits = Hits + 1
                MissTime = 1
                Combo = 0
                ComboBreaks = ComboBreaks + 1
                LastRating = #NoteRatings
                RatingCounts[LastRating] = RatingCounts[LastRating] + 1
                FullOvercharge = false
                local x = (80-(SceneManager.ActiveScene.chart.lanes*4-1))/2 - 1+(self.lane)*4 + 1
                for _=1, 4 do
                    local drawPos = (5)+(15)+(ViewOffset+ViewOffsetFreeze)*(ScrollSpeed*ScrollSpeedMod)
                    table.insert(Particles, {id = "badhit", x = x*8+12, y = drawPos*16-16, vx = (love.math.random()*2-1)*64, vy = -(love.math.random()*2)*32, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                end
                return false
            end
            return false
        end,
        miss = function(self)
            self.destroyed = true
            Charge = Charge + 1
            Hits = Hits + 1
            LastOffset = 0
            HitOffset = HitOffset + LastOffset
            RealHits = RealHits + 1
            Accuracy = Accuracy + 1
            local c = math.floor(Charge/SceneManager.ActiveScene.chart.totalCharge*100/2-1)
            local x = (16+c)*8
            RemoveParticlesByID("chargeup")
            for _=1,8 do
                table.insert(Particles, {id = "chargeup", x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
            end
            Combo = Combo + 1
            LastRating = 1
            RatingCounts[LastRating] = RatingCounts[LastRating] + 1
            return true
        end,
        getDifficulty = function(self)
            return 0.75
        end,
        calculateCharge = function(self)
            return 1
        end,
        missImmediately = true,
        autoplayIgnores = true
    }
}

EffectTypes = {
    modify_curve = {
        readable = "CURVATURE",
        apply = function(self)
            CurveModifierTarget = self.data.strength
            CurveModifierSmoothing = self.data.smoothing or 0
            if (self.data.smoothing or 0) == 0 then
                CurveModifier = CurveModifierTarget
            end
        end,
        editor = function(self,container)
            local strengthIn = DialogInput:new(0,0,container.width,16,"STRENGTH",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            strengthIn.content = tostring(self.data.strength or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.strength = tonumber(strengthIn.content) or effect.data.strength
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    chromatic = {
        readable = "ABERRATION",
        apply = function(self)
            ChromaticModifierTarget = self.data.strength
            ChromaticModifierSmoothing = self.data.smoothing or 0
            if (self.data.smoothing or 0) == 0 then
                ChromaticModifier = ChromaticModifierTarget
            end
        end,
        editor = function(self,container)
            local strengthIn = DialogInput:new(0,0,container.width,16,"STRENGTH",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            strengthIn.content = tostring(self.data.strength or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.strength = tonumber(strengthIn.content) or effect.data.strength
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    tear = {
        readable = "TEARING",
        apply = function(self)
            TearingModifierTarget = self.data.strength
            TearingModifierSmoothing = self.data.smoothing or 0
            if (self.data.smoothing or 0) == 0 then
                TearingModifier = TearingModifierTarget
            end
        end,
        editor = function(self,container)
            local strengthIn = DialogInput:new(0,0,container.width,16,"STRENGTH",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            strengthIn.content = tostring(self.data.strength or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.strength = tonumber(strengthIn.content) or effect.data.strength
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    board_brightness = {
        readable = "BOARD BRIGHTNESS",
        apply = function(self)
            BoardBrightnessTarget = self.data.brightness or BoardBrightnessTarget
            BoardBrightnessSmoothing = self.data.smoothing or 0
            if (self.data.smoothing or 0) == 0 then
                BoardBrightness = BoardBrightnessTarget
            end
        end,
        editor = function(self,container)
            local strengthIn = DialogInput:new(0,0,container.width,16,"BRIGHTNESS",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            strengthIn.content = tostring(self.data.brightness or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.brightness = tonumber(strengthIn.content) or effect.data.brightness
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    note_brightness = {
        readable = "NOTE BRIGHTNESS",
        apply = function(self)
            NoteBrightnessTarget = self.data.brightness or NoteBrightnessTarget
            NoteBrightnessSmoothing = self.data.smoothing or 0
            if (self.data.smoothing or 0) == 0 then
                NoteBrightness = NoteBrightnessTarget
            end
        end,
        editor = function(self,container)
            local strengthIn = DialogInput:new(0,0,container.width,16,"BRIGHTNESS",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            strengthIn.content = tostring(self.data.brightness or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.brightness = tonumber(strengthIn.content) or effect.data.brightness
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    bloom = {
        readable = "BLOOM",
        apply = function(self)
            BloomStrengthModifierTarget = self.data.strength
            BloomStrengthModifierSmoothing = self.data.smoothing or 0
            if (self.data.smoothing or 0) == 0 then
                BloomStrengthModifier = BloomStrengthModifierTarget
            end
        end,
        editor = function(self,container)
            local strengthIn = DialogInput:new(0,0,container.width,16,"STRENGTH",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            strengthIn.content = tostring(self.data.strength or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.strength = tonumber(strengthIn.content) or effect.data.strength
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    wave = {
        readable = "NOTE WAVINESS",
        apply = function(self)
            WavinessTarget = self.data.strength
            WavinessSmoothing = self.data.smoothing or 0
        end,
        editor = function(self,container)
            local strengthIn = DialogInput:new(0,0,container.width,16,"STRENGTH",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            strengthIn.content = tostring(self.data.strength or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.strength = tonumber(strengthIn.content) or effect.data.strength
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    scroll_speed = {
        readable = "SCROLL SPEED",
        apply = function(self)
            ScrollSpeedModTarget = self.data.speed
            ScrollSpeedModSmoothing = self.data.smoothing or 0
        end,
        editor = function(self,container)
            local strengthIn = DialogInput:new(0,0,container.width,16,"SPEED MULT",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            strengthIn.content = tostring(self.data.speed or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.speed = tonumber(strengthIn.content) or effect.data.speed
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    note_speed = {
        readable = "LANE SPEED",
        apply = function(self)
            if NoteSpeedMods[self.data.lane+1] then
                NoteSpeedMods[self.data.lane+1][2] = self.data.speed
                NoteSpeedMods[self.data.lane+1][3] = self.data.smoothing or 0
            end
        end,
        editor = function(self,container)
            local laneIn = DialogInput:new(0,0,container.width,16,"AFFECTED LANE (0-3)",5)
            local strengthIn = DialogInput:new(0,32,container.width,16,"SPEED MULT",5)
            local smoothingIn = DialogInput:new(0,64,container.width,16,"SMOOTHING",5)
            laneIn.content = tostring(self.data.lane or "")
            strengthIn.content = tostring(self.data.speed or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, strengthIn)
            table.insert(container.contents, laneIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.lane = tonumber(laneIn.content) or effect.data.lane
                effect.data.speed = tonumber(strengthIn.content) or effect.data.speed
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    offset = {
        readable = "VIEW OFFSET",
        apply = function(self)
            ViewOffsetTarget = self.data.offset
            ViewOffsetSmoothing = self.data.smoothing or 0
            ViewOffsetMoveLine = not self.data.keep_line
        end,
        editor = function(self,container)
            local offsetIn = DialogInput:new(0,0,container.width,16,"OFFSET",5)
            local smoothingIn = DialogInput:new(0,32,container.width,16,"SMOOTHING",5)
            local keepIn = DialogToggle:new(0,80,container.width,16,"KEEP LINE")
            offsetIn.content = tostring(self.data.offset or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            keepIn.active = self.data.keep_line
            table.insert(container.contents, keepIn)
            table.insert(container.contents, offsetIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.offset = tonumber(offsetIn.content) or effect.data.offset
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
                effect.data.keep_line = keepIn.active or effect.data.keep_line
            end
        end
    },
    freeze_view = {
        readable = "FREEZE VIEW",
        apply = function(self)
            ViewOffsetFreeze = not ViewOffsetFreeze
        end
    },
    edit_note = {
        readable = "[ADV] EDIT NOTE",
        apply = function(self,chart)
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
        editor = function(self,container)
            local groupIn = DialogInput:new(0,0,container.width,16,"NOTE GROUP",5)
            local timeIn = DialogInput:new(0,32,container.width,16,"TYPE",5)
            local laneIn = DialogInput:new(0,64,container.width,16,"LANE",5)
            local typeIn = DialogInput:new(0,96,container.width,16,"TYPE",5)
            local smoothingIn = DialogInput:new(0,128,container.width,16,"SMOOTHING",5)
            groupIn.content = tostring(self.data.group or "")
            timeIn.content = tostring(self.data.time or "")
            laneIn.content = tostring(self.data.lane or "")
            typeIn.content = tostring(self.data.type or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, groupIn)
            table.insert(container.contents, timeIn)
            table.insert(container.contents, laneIn)
            table.insert(container.contents, typeIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                effect.data.group = groupIn.content or effect.data.group
                effect.data.time = tonumber(timeIn.content) or effect.data.time
                effect.data.lane = tonumber(laneIn.content) or effect.data.lane
                effect.data.type = typeIn.content or effect.data.type
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    transform = {
        readable = "TRANSFORMATIONS",
        apply = function(self)
            if self.data.shift then
                DisplayShiftTarget[1] = (self.data.shift or DisplayShiftTarget)[1]
                DisplayShiftTarget[2] = (self.data.shift or DisplayShiftTarget)[2]
                DisplayShiftSmoothing = self.data.smoothing or 0
            end
            if self.data.scale then
                DisplayScaleTarget[1] = (self.data.scale or DisplayScaleTarget)[1]
                DisplayScaleTarget[2] = (self.data.scale or DisplayScaleTarget)[2]
                DisplayScaleSmoothing = self.data.smoothing or 0
            end
            if self.data.rotation then
                DisplayRotationTarget = self.data.rotation or DisplayRotationTarget
                DisplayRotationSmoothing = self.data.smoothing or 0
            end
            if self.data.shear then
                DisplayShearTarget[1] = (self.data.shear or DisplayShearTarget)[1]
                DisplayShearTarget[2] = (self.data.shear or DisplayShearTarget)[2]
                DisplayShearSmoothing = self.data.smoothing or 0
            end
            if (self.data.smoothing or 0) == 0 then
                DisplayShift[1] = DisplayShiftTarget[1]
                DisplayShift[2] = DisplayShiftTarget[2]
                DisplayScale[1] = DisplayScaleTarget[1]
                DisplayScale[2] = DisplayScaleTarget[2]
                DisplayRotation = DisplayRotationTarget
                DisplayShear[1] = DisplayShearTarget[1]
                DisplayShear[2] = DisplayShearTarget[2]
            end
        end,
        editor = function(self,container)
            local shiftXIn = DialogInput:new(0,0,container.width/2-8,16,"SHIFT X",5)
            local shiftYIn = DialogInput:new(container.width/2+8,0,container.width/2-8,16,"SHIFT Y",5)
            local scaleXIn = DialogInput:new(0,32,container.width/2-8,16,"SCALE X",5)
            local scaleYIn = DialogInput:new(container.width/2+8,32,container.width/2-8,16,"SCALE Y",5)
            local shearXIn = DialogInput:new(0,64,container.width/2-8,16,"SHEAR X",5)
            local shearYIn = DialogInput:new(container.width/2+8,64,container.width/2-8,16,"SHEAR Y",5)
            local rotationIn = DialogInput:new(0,96,container.width,16,"ROTATION",5)
            local smoothingIn = DialogInput:new(0,128,container.width,16,"SMOOTHING",5)
            shiftXIn.content = tostring((self.data.shift or {})[1] or "")
            shiftYIn.content = tostring((self.data.shift or {})[2] or "")
            scaleXIn.content = tostring((self.data.scale or {})[1] or "")
            scaleYIn.content = tostring((self.data.scale or {})[2] or "")
            shearXIn.content = tostring((self.data.shear or {})[1] or "")
            shearYIn.content = tostring((self.data.shear or {})[2] or "")
            rotationIn.content = tostring(self.data.rotation or "")
            smoothingIn.content = tostring(self.data.smoothing or "")
            table.insert(container.contents, shiftXIn)
            table.insert(container.contents, shiftYIn)
            table.insert(container.contents, scaleXIn)
            table.insert(container.contents, scaleYIn)
            table.insert(container.contents, shearXIn)
            table.insert(container.contents, shearYIn)
            table.insert(container.contents, rotationIn)
            table.insert(container.contents, smoothingIn)
            return function(effect)
                local shiftX = tonumber(shiftXIn.content)
                local shiftY = tonumber(shiftYIn.content)
                local scaleX = tonumber(scaleXIn.content)
                local scaleY = tonumber(scaleYIn.content)
                local shearX = tonumber(shearXIn.content)
                local shearY = tonumber(shearYIn.content)
                if shiftX or shiftY then
                    effect.data.shift = {shiftX or (effect.data.shift or {})[1] or 0, shiftY or (effect.data.shift or {})[2] or 0}
                end
                if scaleX or scaleY then
                    effect.data.scale = {scaleX or (effect.data.scale or {})[1] or 1, scaleY or (effect.data.scale or {})[2] or 1}
                end
                if shearX or shearY then
                    effect.data.shear = {shearX or (effect.data.shear or {})[1] or 0, shearY or (effect.data.shear or {})[2] or 0}
                end
                effect.data.rotation = tonumber(rotationIn.content) or effect.data.rotation
                effect.data.smoothing = tonumber(smoothingIn.content) or effect.data.smoothing
            end
        end
    },
    modify_bg = {
        readable = "[ADV] MODIFY BG",
        apply = function(self,chart)
            local background = Assets.Background(chart.background)
            if background then
                for k,v in pairs(self.data) do
                    background[k] = v
                end
            end
        end
    }
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
            love.graphics.print(utf8.sub(SongDifficulty[difficulty].name, i, i), currentX, y)
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
---@field lyrics {easy: Lyrics?, medium: Lyrics?, hard: Lyrics?, extreme: Lyrics?, overvolt: Lyrics?, main: Lyrics?}
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
    songData.lyrics = {}
    local S,mainlyrics = pcall(json.decode, love.filesystem.read(path.."/lyrics.json"))
    if S then
        songData.lyrics.main = Lyrics:new(mainlyrics)
    end
    for name,chart in pairs(songData.charts or {}) do
        songData.levels[name] = chart.level
        local s,lyrics = pcall(json.decode, love.filesystem.read(path.."/"..name.."-lyrics.json"))
        if s then
            songData.lyrics[name] = Lyrics:new(lyrics)
        end
    end

    return songData
end

function SongData:new(name,author,bpm,song,songPreview,charts,levels,lyrics)
    local songData = setmetatable({}, self)
    songData.name = name or "Song"
    songData.author = author or "Composer"
    songData.bpm = bpm or 120
    songData.song = song
    songData.songPreview = songPreview or {0,math.huge}
    songData.charts = charts or {}
    songData.levels = levels or {}
    songData.lyrics = lyrics or {}
    for chartname,chart in pairs(charts or {}) do
        songData.levels[chartname] = songData.levels[chartname] or chart.level
    end
    return songData
end

function SongData:newChart(difficulty, level)
    if self.charts[difficulty] then return self.charts[difficulty] end
    local chart = Chart:new({
        song = self.songPath,
        bpm = self.bpm,
        notes = {},
        effects = {},
        bpmChanges = {},
        name = self.name,
        lanes = 4,
        charter = "?"
    })
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
---@field hideDifficulty boolean
Chart = {}
Chart.__index = Chart

---@param data table
---@return Chart
function Chart:new(data)
    local chart = setmetatable({}, self)

    chart.song = data.song
    chart.bpm = data.bpm

    chart.video = data.video
    chart.background = data.background
    chart.backgroundInit = data.backgroundInit or {}

    chart.notes = data.notes or {}
    table.sort(chart.notes or {}, function (a, b)
        return a.time < b.time
    end)
    chart.effects = data.effects or {}
    table.sort(chart.effects or {}, function (a, b)
        return a.time < b.time
    end)
    chart.bpmChanges = data.bpmChanges or {}
    table.sort(chart.bpmChanges or {}, function (a, b)
        return a.time < b.time
    end)
    chart.time = 0
    chart.totalCharge = 0
    for _,note in ipairs(chart.notes) do
        chart.totalCharge = chart.totalCharge + 1 + (note.length or 0)
    end

    chart.name = data.name or "Chart"
    chart.lanes = data.lanes or 4

    chart.charter = data.charter or "Charter"

    chart.hideDifficulty = data.hideDifficulty

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
    return Chart:new(data)
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
        charter = self.charter,
        hideDifficulty = self.hideDifficulty
    }))
end

function Chart:getDensity()
    if not self.song then return 0 end
    local song = Assets.Source(self.song)
    if not song then return 0 end
    return #self.notes / song:getDuration("seconds")
end

-- TODO: This is still not great. Work on this later
function Chart:getDifficulty()
    if not self.song then return 0 end
    local song = Assets.Source(self.song)
    if not song then return 0 end

    -- Difficulty Rating Constants
    local segmentSize = 1
    local constant = 1.5

    local segmentDensities = {}
    local numSegments = math.ceil(song:getDuration("seconds")/segmentSize)
    local lastNote = 1
    for i = 1, numSegments do
        local amount = 0
        for j = lastNote, #self.notes do
            local note = self.notes[j]
            if note.time > segmentSize*i or note.time + (note.length or 0) > segmentSize*i then
                lastNote = math.max(1,j-1)
                break
            end
            if note.time >= segmentSize*(i-1) then
                local t = NoteTypes[note.type]
                if t then
                    amount = amount + t.getDifficulty(note)
                end
            end
        end
        if amount ~= 0 then
            local added = false
            local value = amount/segmentSize
            for j = 1, #segmentDensities do
                if segmentDensities[j] < amount then
                    table.insert(segmentDensities, j, value)
                    added = true
                    break
                end
            end
            if not added then
                table.insert(segmentDensities, value)
            end
        end
    end
    if #segmentDensities == 0 then
        return 0
    end
    local sumOfWeights = 0
    local result = 0
    for i = 1, #segmentDensities do
        local weight = (1-((i-1)/(#segmentDensities)))
        sumOfWeights = sumOfWeights + weight
        result = result + segmentDensities[i]*weight
    end
    result = result / sumOfWeights
    return result * constant
end

function Chart:getBalance()
    local balance = 0
    for _,note in ipairs(self.notes) do
        balance = balance + (note.lane - (self.lanes-1)/2)
    end
    return balance / #self.notes
end

---@alias LyricComponent {type: "text"|"image"|"key", text?: string, key?: 0|1|2|3, path?: string, x?: number, y?: number, width?: number, height?: number}
---@alias Transformation {shift?: {[1]: number, [2]: number}, scale?: {[1]: number, [2]: number}, shear?: {[1]: number, [2]: number}, rotation?: number}
---@alias Lyric {startTime: number, endTime: number, components: LyricComponent[], transformation?: Transformation, followChart?: boolean, hideBox?: boolean, boxWidth?: number, boxHeight?: number}

---@class Lyrics
---@field script Lyric[]
Lyrics = {}
Lyrics.__index = Lyrics

function Lyrics:new(script)
    local lyrics = setmetatable({}, self)

    lyrics.script = script or {}
    for _,lyric in ipairs(lyrics.script) do
        local boundingBox = {math.huge,math.huge,-math.huge,-math.huge}
        for _,component in ipairs(lyric.components) do
            if component.type == "text" then
                local w,wrap = Font:getWrap(component.text, Font:getWidth(component.text))
                local x1,y1,x2,y2 = component.x, component.y, component.x+w, component.y+(#wrap * Font:getHeight())
                boundingBox[1] = math.min(boundingBox[1], x1, x2)
                boundingBox[2] = math.min(boundingBox[2], y1, y2)
                boundingBox[3] = math.max(boundingBox[3], x1, x2)
                boundingBox[4] = math.max(boundingBox[4], y1, y2)
            end
            if component.type == "key" then
                local text = Keybinds[4][component.key+1] or "?"
                local w,wrap = Font:getWrap(text, Font:getWidth(text))
                local x1,y1,x2,y2 = component.x, component.y, component.x+w, component.y+(#wrap * Font:getHeight())
                boundingBox[1] = math.min(boundingBox[1], x1, x2)
                boundingBox[2] = math.min(boundingBox[2], y1, y2)
                boundingBox[3] = math.max(boundingBox[3], x1, x2)
                boundingBox[4] = math.max(boundingBox[4], y1, y2)
            end
        end
        if not lyric.boxWidth then
            lyric.boxWidth = (boundingBox[3]-boundingBox[1])/8+2
        end
        if not lyric.boxHeight then
            lyric.boxHeight = (boundingBox[4]-boundingBox[2])/16
        end
    end

    return lyrics
end

function Lyrics:draw(time)
    for _,lyric in ipairs(self.script) do
        if time < lyric.startTime or time > lyric.endTime then
            goto continue
        end

        love.graphics.push()

        if lyric.followChart then
            love.graphics.translate(DisplayShift[1], DisplayShift[2])
            love.graphics.translate(320,240)
            love.graphics.scale(DisplayScale[1], DisplayScale[2])
            love.graphics.rotate(DisplayRotation)
            love.graphics.shear(DisplayShear[1], DisplayShear[2])
            love.graphics.translate(-320,-240)
        end

        local transformation = lyric.transformation or {}
        local shift = (transformation.shift or {0,0})
        local scale = (transformation.scale or {1,1})
        local shear = (transformation.shear or {0,0})
        local rotation = (transformation.rotation or 0)
        love.graphics.translate(320,240)
        love.graphics.translate(shift[1], shift[2])
        love.graphics.scale(scale[1], scale[2])
        love.graphics.rotate(rotation)
        love.graphics.shear(shear[1], shear[2])
        love.graphics.translate(-(lyric.boxWidth+2)/2*8, -(lyric.boxHeight+2)/2*16)

        if not lyric.hideBox then
            DrawBoxHalfWidth(0, 0, lyric.boxWidth, lyric.boxHeight)
        end
        for _,component in ipairs(lyric.components) do
            if component.type == "text" then
                local w = Font:getWidth(component.text)
                love.graphics.printf(component.text, 16+component.x, 16+component.y, w, "center")
            end
            if component.type == "key" then
                local text = (Keybinds[4][component.key+1] or "?"):upper()
                local w = Font:getWidth(text)
                love.graphics.printf(text, 16+component.x, 16+component.y, w, "center")
            end
        end
        love.graphics.pop()

        ::continue::
    end
end