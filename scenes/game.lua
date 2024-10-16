local utf8 = require "utf8"

local scene = {}

local defaultBg = Assets.Background("boxesbg.lua")
if defaultBg then defaultBg.init() end

PausedText = love.graphics.newImage("images/paused.png")
Counter = {
    love.graphics.newImage("images/counter1.png"),
    love.graphics.newImage("images/counter2.png"),
    love.graphics.newImage("images/counter3.png")
}

NoteRatings = {
    {
        draw = function(ox,oy,center)
            local txt = "OVERCHARGE"
            for x = 1, #txt do
                local c = txt:sub(x,x)
                love.graphics.setColor(TerminalColors[OverchargeColors[(x-1)%#OverchargeColors+1]])
                love.graphics.print(c, ox+((center and (-(#txt)/2) or 0) + x-1)*8, oy)
            end
        end,
        min = 0.9,
        max = math.huge
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.GOLD])
            local txt = "SURGE"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        min = 0.8,
        max = 0.9
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.YELLOW])
            local txt = "AMP"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        min = 0.6,
        max = 0.8
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.GREEN])
            local txt = "FLUX"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        min = 0.4,
        max = 0.6
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            local txt = "NULL"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        min = 0.15,
        max = 0.4
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.RED])
            local txt = "BREAK"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        min = 0,
        max = 0.15
    }
}

---@param args {songData: SongData, difficulty: string, modifiers: table}
function scene.load(args)
    if args.songData then
        scene.songData = args.songData
        scene.difficulty = args.difficulty
        scene.chart = scene.songData:loadChart(args.difficulty or "easy")
        if scene.chart then
            scene.chart.time = TimeBPM(-16,scene.chart.bpm)
        end
    end
    if scene.chart then
        scene.song = Assets.Source(scene.chart.song)
        scene.video = Assets.Video(scene.chart.video)
        scene.background = Assets.Background(scene.chart.background) or defaultBg
        if scene.background and type(scene.background.init) == "function" then
            scene.background.init(scene.chart.backgroundInit or {})
        end
    end
    scene.modifiers = args.modifiers or {}
    scene.chartName = "UNRAVELING STASIS"
    AudioOffset = 0/1000
    HitOffset = 0
    RealHits = 0
    Charge = 0
    Hits = 0
    Accuracy = 0
    Combo = 0
    ComboBreaks = 0
    FullOvercharge = true
    ScrollSpeed = 25
    ScrollSpeedMod = 1
    ScrollSpeedModTarget = 1
    ScrollSpeedModSmoothing = 0
    NoteSpeedMods = {
        {1,1,0},
        {1,1,0},
        {1,1,0},
        {1,1,0}
    }
    ViewOffset = 0
    ViewOffsetTarget = 0
    ViewOffsetSmoothing = 16
    ViewOffsetFreeze = 0
    ChartFrozen = false
    LastRating = 0
    scene.lastTime = scene.chart.time
    if scene.video then
        scene.video:pause()
        scene.video:rewind()
        scene.video:getSource():setVolume(0)
    end

    RatingCounts = {}
    for i,_ in ipairs(NoteRatings) do
        RatingCounts[i] = 0
    end

    PressAmounts = {}
    HitAmounts = {}
    for i = 1, scene.chart.lanes do
        PressAmounts[i] = 0
        HitAmounts[i] = 0
    end

    DisplayShift = {0,0}
    DisplayShiftTarget = {0,0}
    DisplayShiftSmoothing = 0
    DisplayScale = {1,1}
    DisplayScaleTarget = {1,1}
    DisplayScaleSmoothing = 0
    DisplayRotation = 0
    DisplayRotationTarget = 0
    DisplayRotationSmoothing = 0

    PauseTimer = 0
    Paused = false
    SongStarted = false
end

function scene.keypressed(k)
    if k == "escape" then
        if Paused then
            Paused = false
        elseif PauseTimer <= 0 then
            if scene.song then scene.song:pause() end
            if scene.video then scene.video:pause() end
            Paused = true
            PauseTimer = 1.5
        end
    end
    if k == "f8" then
        if scene.song then scene.song:stop() end
        scene.chart.time = 0
        scene.chart:resetAllNotes()
        Charge = 0
        SceneManager.Transition("scenes/editor", {songData = scene.songData, difficulty = scene.difficulty})
    end
    if PauseTimer > 0 then return end
    if k == "]" then
        scene.chart.time = math.huge
    end
    if not Autoplay then
        for i,note in ipairs(scene.chart.notes) do
            local pos = note.time-scene.chart.time
            if math.abs(pos) <= 0.2 and k == (Keybinds[scene.chart.lanes] or Keybinds[8])[note.lane+1] and not note.destroyed and not note.holding then
                local t = 0.125
                local accuracy = (math.abs(pos)/0.2)
                accuracy = math.max(0,math.min(1,(1/(1-t))*accuracy - ((1/(1-t))-1)))
                local accValue = (1-accuracy)
                for R,rating in ipairs(NoteRatings) do
                    if accValue >= rating.min and accValue < rating.max then
                        LastRating = R
                        break
                    end
                end
                RatingCounts[LastRating] = RatingCounts[LastRating] + 1
                if LastRating ~= 1 then FullOvercharge = false end
                if LastRating == 1 then
                    accuracy = 0 -- 100%
                    local x = (80-(scene.chart.lanes*4-1))/2 - 1+(note.lane)*4 + 1
                    for _=1, 4 do
                        local drawPos = (5)+(15)+(ViewOffset+ViewOffsetFreeze)*(ScrollSpeed*ScrollSpeedMod)
                        table.insert(Particles, {id = "powerhit", x = x*8+12, y = drawPos*16-16, vx = (love.math.random()*2-1)*64, vy = -(love.math.random()*2)*32, life = (love.math.random()*0.5+0.5)*0.25, color = OverchargeColors[love.math.random(1,#OverchargeColors)], char = "¤"})
                    end
                end
                Charge = Charge + (1-accuracy)
                Hits = Hits + 1
                HitOffset = HitOffset + pos
                RealHits = RealHits + 1
                Accuracy = Accuracy + (1-accuracy)
                local c = math.floor(Charge/scene.chart.totalCharge*100/2-1)
                local x = (16+c)*8
                RemoveParticlesByID("chargeup")
                for _=1,8 do
                    table.insert(Particles, {id = "chargeup", x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
                end
                if note.length <= 0 then
                    note.destroyed = true
                else
                    note.holding = true
                    note.heldFor = 0
                end
                HitAmounts[note.lane+1] = 1
                Combo = Combo + 1
                if LastRating >= #NoteRatings-1 then
                    Combo = 0
                    ComboBreaks = ComboBreaks + 1
                end
                break
            end
        end
    end
end

function scene.update(dt)
    if Paused or SceneManager.TransitioningIn() then return end
    if PauseTimer > 0 then
        PauseTimer = PauseTimer - dt
        if PauseTimer <= 0 then
            if SongStarted then
                if scene.song then scene.song:play() end
                if scene.video and scene.chart.time < scene.video:getSource():getDuration("seconds") then scene.video:play() end
            end
        end
        return
    end
    -- Update chart time and scroll chart
    local lastTime = scene.chart.time
    scene.chart.time = scene.chart.time + dt*(scene.modifiers.speed or 1)
    if scene.chart.time > -AudioOffset then
        if scene.lastTime <= -AudioOffset then
            SongStarted = true
            if scene.song then scene.song:setPitch(scene.modifiers.speed or 1); scene.song:play() end
            if scene.video then scene.video:getSource():setPitch(scene.modifiers.speed or 1); scene.video:play() end
        end
        if scene.song then
            if scene.song:isPlaying() then
                local st = scene.song:tell("seconds")-AudioOffset
                local drift = st-scene.chart.time
                -- Only fix drift if we're NOT at the end of song AND we are too much offset
                if math.abs(drift) >= 0.05 and drift > -scene.song:getDuration("seconds") then
                    scene.chart.time = scene.song:tell("seconds")
                end
            end
        end
    end

    -- Freeze notes in place and move judgement line instead
    local diff = scene.chart.time - lastTime
    if ChartFrozen then
        ViewOffsetFreeze = ViewOffsetFreeze - diff
    else
        ViewOffsetFreeze = 0
    end

    scene.lastTime = scene.lastTime + dt*(scene.modifiers.speed or 1)

    do
        local i = 1
        local num = #scene.chart.notes
        while i <= num do
            local note = scene.chart.notes[i]
            if note.destroyed then
                goto continue
            end
            do
                local pos = note.time-scene.chart.time
                if Autoplay then
                    if pos <= 0 then
                        if (note.heldFor or 0) <= 0 then
                            Charge = Charge + 1
                            Combo = Combo + 1
                            LastRating = 1
                            RatingCounts[LastRating] = RatingCounts[LastRating] + 1
                            local x = (80-(scene.chart.lanes*4-1))/2 - 1+(note.lane)*4 + 1
                            for _=1, 4 do
                                local drawPos = (5)+(15)+(ViewOffset+ViewOffsetFreeze)*(ScrollSpeed*ScrollSpeedMod)
                                table.insert(Particles, {id = "powerhit", x = x*8+12, y = drawPos*16-16, vx = (love.math.random()*2-1)*64, vy = -(love.math.random()*2)*32, life = (love.math.random()*0.5+0.5)*0.25, color = OverchargeColors[love.math.random(1,#OverchargeColors)], char = "¤"})
                            end
                            Accuracy = Accuracy + 1
                            Hits = Hits + 1
                            HitOffset = HitOffset + 0
                            RealHits = RealHits + 1
                            local c = math.floor(Charge/scene.chart.totalCharge*100/2-1)
                            local x = (16+c)*8
                            RemoveParticlesByID("chargeup")
                            for _=1,8 do
                                table.insert(Particles, {id = "chargeup", x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
                            end
                            PressAmounts[note.lane+1] = 32
                        end
                        if note.length <= 0 then
                            note.destroyed = true
                            i = i - 1
                        else
                            note.holding = true
                        end
                        HitAmounts[note.lane+1] = 1
                        if not Autoplay then PressAmounts[note.lane+1] = 1 end
                    end
                end
                if note.holding and pos <= 0 then
                    if note.length > 0 then
                        if love.keyboard.isDown((Keybinds[scene.chart.lanes] or Keybinds[8])[note.lane+1]) or Autoplay then
                            local lastHeldFor = note.heldFor or 0
                            note.heldFor = math.min(note.length, lastHeldFor + dt)
                            Charge = Charge + (note.heldFor-lastHeldFor)
                            HitAmounts[note.lane+1] = 1
                            if note.heldFor >= note.length then
                                note.destroyed = true
                                i = i - 1
                            end
                        end
                        if Autoplay then
                            PressAmounts[note.lane+1] = 32
                        end
                    end
                end
                if pos <= -0.25 then
                    if note.length <= 0 then
                        note.destroyed = true
                        i = i - 1
                        Hits = Hits + 1
                        MissTime = 1
                        Combo = 0
                        ComboBreaks = ComboBreaks + 1
                        LastRating = #NoteRatings
                        RatingCounts[LastRating] = RatingCounts[LastRating] + 1
                        FullOvercharge = false
                    else
                        if pos <= -0.25-note.length then
                            if not note.holding then
                                MissTime = 1
                                Combo = 0
                                ComboBreaks = ComboBreaks + 1
                                LastRating = #NoteRatings
                                RatingCounts[LastRating] = RatingCounts[LastRating] + 1
                                FullOvercharge = false
                            end
                            note.destroyed = true
                            i = i - 1
                        else
                            if not love.keyboard.isDown((Keybinds[scene.chart.lanes] or Keybinds[8])[note.lane+1]) and not Autoplay then
                                if pos <= -0.25-(note.length-0.4) then
                                    if note.heldFor == 0 or not note.heldFor then
                                        MissTime = 1
                                        Combo = 0
                                        ComboBreaks = ComboBreaks + 1
                                        LastRating = #NoteRatings
                                        RatingCounts[LastRating] = RatingCounts[LastRating] + 1
                                        FullOvercharge = false
                                    end
                                    note.destroyed = true
                                    i = i - 1
                                else
                                    MissTime = 1
                                    Combo = 0
                                    ComboBreaks = ComboBreaks + 1
                                    LastRating = #NoteRatings
                                    RatingCounts[LastRating] = RatingCounts[LastRating] + 1
                                    FullOvercharge = false
                                end
                            end
                        end
                    end
                end
            end
            ::continue::
            i = i + 1
            num = #scene.chart.notes
        end
    end

    do
        local i = 1
        local num = #scene.chart.effects
        while i <= num do
            local effect = scene.chart.effects[i]
            local pos = effect.time-scene.chart.time
            if effect.destroyed then
                goto continue
            end
            if pos <= 0 then
                local t = EffectTypes[effect.type]
                if type(t) == "function" then
                    t(effect,scene.chart)
                end
                effect.destroyed = true
                i = i - 1
            end
            ::continue::
            i = i + 1
            num = #scene.chart.effects
        end
    end

    if scene.song then
        if scene.chart.time >= scene.song:getDuration("seconds")-AudioOffset then
            if not SceneManager.TransitionState.Transitioning then
                SceneManager.Transition("scenes/rating", {chart = scene.chart, songData = scene.songData, difficulty = scene.difficulty, offset = HitOffset/RealHits, ratings = RatingCounts, accuracy = Accuracy/math.max(Hits,1), charge = Charge/scene.chart.totalCharge, fullCombo = ComboBreaks == 0, fullOvercharge = FullOvercharge})
            end
        end
    end

    do
        local i = 1
        local num = #Particles
        while i <= num do
            local particle = Particles[i]
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.life = particle.life - dt
            if particle.life <= 0 then
                table.remove(Particles, i)
                i = i - 1
            end
            i = i + 1
            num = #Particles
        end
    end

    do
        local blend = math.pow(0.01,dt)
        CurveModifier = blend*(CurveModifier-1)+1
        ScreenShader:send("curveStrength", CurveStrength*CurveModifier)
    end
    do
        local blend = math.pow(0.05,dt)
        Chromatic = blend*Chromatic
        ScreenShader:send("chromaticStrength", Chromatic)
    end
    do
        if DisplayShiftSmoothing == 0 then
            DisplayShift[1] = DisplayShiftTarget[1]
            DisplayShift[2] = DisplayShiftTarget[2]
        else
            local blend = math.pow(1/DisplayShiftSmoothing,dt)
            DisplayShift[1] = blend*(DisplayShift[1]-DisplayShiftTarget[1])+DisplayShiftTarget[1]
            DisplayShift[2] = blend*(DisplayShift[2]-DisplayShiftTarget[2])+DisplayShiftTarget[2]
        end
    end
    do
        if DisplayScaleSmoothing == 0 then
            DisplayScale[1] = DisplayScaleTarget[1]
            DisplayScale[2] = DisplayScaleTarget[2]
        else
            local blend = math.pow(1/DisplayScaleSmoothing,dt)
            DisplayScale[1] = blend*(DisplayScale[1]-DisplayScaleTarget[1])+DisplayScaleTarget[1]
            DisplayScale[2] = blend*(DisplayScale[2]-DisplayScaleTarget[2])+DisplayScaleTarget[2]
        end
    end
    do
        if DisplayRotationSmoothing == 0 then
            DisplayRotation = DisplayRotationTarget
        else
            local blend = math.pow(1/DisplayRotationSmoothing,dt)
            DisplayRotation = blend*(DisplayRotation-DisplayRotationTarget)+DisplayRotationTarget
        end
    end
    do
        if ViewOffsetSmoothing == 0 then
            ViewOffset = ViewOffsetTarget
        else
            local blend = math.pow(1/ViewOffsetSmoothing,dt)
            ViewOffset = blend*(ViewOffset-ViewOffsetTarget)+ViewOffsetTarget
        end
    end
    do
        if ScrollSpeedModSmoothing == 0 then
            ScrollSpeedMod = ScrollSpeedModTarget
        else
            local blend = math.pow(1/ScrollSpeedModSmoothing,dt)
            ScrollSpeedMod = blend*(ScrollSpeedMod-ScrollSpeedModTarget)+ScrollSpeedModTarget
        end

        for _,mod in ipairs(NoteSpeedMods) do
            if mod[3] == 0 then
                mod[1] = mod[2]
            else
                local blend = math.pow(1/mod[3],dt)
                mod[1] = blend*(mod[1]-mod[2])+mod[2]
            end
        end
    end
    do
        if WavinessSmoothing == 0 then
            Waviness = WavinessTarget
        else
            local blend = math.pow(1/WavinessSmoothing,dt)
            Waviness = blend*(Waviness-WavinessTarget)+WavinessTarget
        end
    end

    MissTime = math.max(0,MissTime - dt * 8)
    ScreenShader:send("tearStrength", MissTime*8/Display:getWidth())
    
    ScreenShader:send("tearTime", love.timer.getTime())

    for i = 1, scene.chart.lanes do
        PressAmounts[i] = math.max(0, math.min(Autoplay and math.huge or 1, PressAmounts[i] + dt*8*((love.keyboard.isDown((Keybinds[scene.chart.lanes] or Keybinds[8])[i]) and not Autoplay) and 1/dt or -1/dt)))
        HitAmounts[i] = math.max(0, math.min(1, HitAmounts[i] - dt*8))
    end
    if scene.background and scene.background.update then
        scene.background.update(dt)
    end
end

function scene.draw()
    -- Backgrounds
    if scene.background and scene.background.draw then
        scene.background.draw()
    end
    if scene.video then
        if SongStarted then
            love.graphics.setColor(1,1,1)
            local s = math.max(640/scene.video:getWidth(), 480/scene.video:getHeight())
            love.graphics.draw(scene.video, (640-scene.video:getWidth()*s)/2, (480-scene.video:getHeight()*s)/2, 0, s, s)
        end
    end

    love.graphics.push()
    love.graphics.translate(DisplayShift[1], DisplayShift[2])
    love.graphics.translate(320,240)
    love.graphics.scale(DisplayScale[1], DisplayScale[2])
    love.graphics.rotate(DisplayRotation)
    love.graphics.translate(-320,-240)

    -- Debug info
    love.graphics.setColor(TerminalColors[16])
    love.graphics.print("Full Combo: " .. tostring(ComboBreaks == 0), 50*8, 5*16)
    love.graphics.print("Full Overcharge: " .. tostring(FullOvercharge), 50*8, 6*16)

    -- Chart and bar outlines
    DrawBoxHalfWidth((80-(scene.chart.lanes*4-1))/2 - 1, 4, scene.chart.lanes*4-1, 16)
    DrawBoxHalfWidth(14, 23, 50, 1)

    -- Text Displays
    local difficultyName = SongDifficulty[scene.difficulty or "easy"].name or scene.difficulty:upper()
    local difficultyColor = SongDifficulty[scene.difficulty or "easy"].color or TerminalColors[ColorID.WHITE]
    local level = scene.songData:getLevel(scene.difficulty)
    local fullText = scene.songData.name .. " - " .. difficultyName .. " " .. level
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.print("┌─" .. ("─"):rep(utf8.len(fullText)) .. "─┐\n│ " .. (" "):rep(utf8.len(fullText)) .. " │\n└─" .. ("─"):rep(utf8.len(fullText)) .. "─┘", ((80-(utf8.len(fullText)+4))/2)*8, 1*16)
    love.graphics.print(scene.songData.name .. " - ", ((80-(utf8.len(fullText)+4))/2 + 2)*8, 2*16)
    love.graphics.setColor(difficultyColor)
    love.graphics.print(difficultyName, ((80-(utf8.len(fullText)+4))/2 + 2 + utf8.len(scene.songData.name .. " - "))*8, 2*16)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.print(tostring(level), ((80-(utf8.len(fullText)+4))/2 + 2 + utf8.len(scene.songData.name .. " - " .. difficultyName .. " "))*8, 2*16)

    if Autoplay then love.graphics.print("┬──────────┬\n│ ".. (Showcase and "SHOWCASE" or "AUTOPLAY") .. " │\n┴──────────┴", 34*8, 21*16) end
    local acc = math.floor(Accuracy/math.max(Hits,1)*100)

    love.graphics.print("┬──────────┬\n│ ACC " .. (" "):rep(3-#tostring(acc))..acc.. "% │\n└──────────┘", 34*8, 25*16)
    love.graphics.print("┌──────────┐\n│  CHARGE  │\n├──────────┴", 14*8, 21*16)
    local c = Charge/scene.chart.totalCharge*100
    local chargeAmount = math.floor(c/100*ChargeYield)
    if c ~= c then chargeAmount = 0 end
    love.graphics.print(" ", 62*8, 22*16) -- Empty space
    love.graphics.print("┌──────────┐\n│  " .. (" "):rep(5-#tostring(chargeAmount)) .. chargeAmount .."¤  │\n┴──────────┤", 54*8, 21*16)

    -- Bar fill
    c = math.floor(Charge/scene.chart.totalCharge*100)
    love.graphics.print("┬\n\n┴", 55*8, 23*16)
    love.graphics.setColor(TerminalColors[(c < 40 and 5) or (c < 80 and 15) or 11])
    love.graphics.print(("█"):rep(math.min(41,c/2)), 15*8, 24*16)
    -- OVERCHARGE
    if c == c then
        local ocChunks = math.min(10,math.max(0,c/2-41))
        for i = 1, ocChunks do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print("█", (55+i)*8, 24*16)
        end
    end

    -- Lanes and judgement line
    for i = 1, scene.chart.lanes-1 do
        love.graphics.setColor(TerminalColors[9])
        local x = (80-(scene.chart.lanes*4-1))/2 - 1+(i-1)*4 + 1
        love.graphics.print(("   ┊\n"):rep(16), x*8, 5*16)
    end
    do
        local drawPos = (5)+(15)+(ViewOffset+ViewOffsetFreeze)*(ScrollSpeed*ScrollSpeedMod)
        if drawPos >= 5 and drawPos <= 20 then
            love.graphics.print("┈┈┈"..("╬┈┈┈"):rep(scene.chart.lanes-1), ((80-(scene.chart.lanes*4-1))/2 - 1+(1-1)*4 + 1)*8, drawPos*16-16)
        end
    end

    -- Hit areas
    for i = 1, scene.chart.lanes do
        local x = (80-(scene.chart.lanes*4-1))/2 - 1+(i-1)*4 + 1
        local v = math.ceil(math.min(1,PressAmounts[i])+HitAmounts[i]*2)
        if v > 0 then
            local drawPos = (5)+(15)+(ViewOffset+ViewOffsetFreeze)*(ScrollSpeed*ScrollSpeedMod)
            love.graphics.setColor(TerminalColors[NoteColors[((i-1)%(#NoteColors))+1][v+1]])
            love.graphics.print("███", x*8, drawPos*16-16)
        end
    end

    -- Notes
    for _,note in ipairs(scene.chart.notes) do
        if not note.destroyed then
            local t = NoteTypes[note.type]
            if t and type(t.draw) == "function" then
                t.draw(note,scene.chart.time,(ScrollSpeed*ScrollSpeedMod)*NoteSpeedMods[note.lane+1][1],nil,nil,((80-(scene.chart.lanes*4-1))/2)+1)
            end
        end
    end

    -- Last rating and combo
    if NoteRatings[LastRating] then
        local x,y = 40*8, 6*16
        NoteRatings[LastRating].draw(x,y,true)
    end
    local comboString = tostring(Combo)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.print(comboString, ((80-(#comboString))/2)*8, 7*16)

    -- Rating counts
    -- for i,rating in ipairs(NoteRatings) do
    --     local x,y = 32, (i+4)*16
    --     NoteRatings[i].draw(x,y,false)
    --     love.graphics.setColor(TerminalColors[ColorID.WHITE])
    --     love.graphics.print(RatingCounts[i], x+12*8, y)
    -- end

    -- Particles
    for _,particle in ipairs(Particles) do
        love.graphics.setColor(TerminalColors[particle.color])
        love.graphics.print(particle.char, particle.x-4, particle.y-8)
    end

    love.graphics.pop()

    if Paused or PauseTimer > 0 then
        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if Paused then
            love.graphics.draw(PausedText, 320, 240, 0, 1, 1, PausedText:getWidth()/2, PausedText:getHeight()/2)
        else
            local counterText = Counter[math.ceil(PauseTimer*2)]
            if counterText then
                love.graphics.draw(counterText, 320, 344, 0, 1, 1, counterText:getWidth()/2, 0)
            end
        end
    end
end

return scene