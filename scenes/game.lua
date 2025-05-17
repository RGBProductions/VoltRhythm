local utf8 = require "utf8"

local scene = {}

local hitSounds = {
    love.audio.newSource("sounds/hit.ogg", "stream"),
    love.audio.newSource("sounds/hit.ogg", "stream"),
    love.audio.newSource("sounds/hit.ogg", "stream"),
    love.audio.newSource("sounds/hit.ogg", "stream"),
    love.audio.newSource("sounds/hit.ogg", "stream"),
    love.audio.newSource("sounds/hit.ogg", "stream"),
    love.audio.newSource("sounds/hit.ogg", "stream"),
    love.audio.newSource("sounds/hit.ogg", "stream")
}

local lastHitSound = 0

local defaultBg = Assets.Background("boxesbg.lua")
if defaultBg then defaultBg.init() end

PausedText = love.graphics.newImage("images/paused.png")
Counter = {
    love.graphics.newImage("images/counter1.png"),
    love.graphics.newImage("images/counter2.png"),
    love.graphics.newImage("images/counter3.png")
}

function GetRating(accValue)
    for R,rating in ipairs(NoteRatings) do
        if accValue >= rating.min and accValue < rating.max then
            return R
        end
    end
    return #NoteRatings
end

---@param args {songData: SongData, scorePrefix: string?, difficulty: string, modifiers: table, isEditor?: boolean, forced?: boolean, masquerade?: string, chargeGate?: number, next?: {path: string, args?: table}}
function scene.load(args)
    scene.next = args.next
    ResetEffects()
    for _,hitSound in ipairs(hitSounds) do
        hitSound:setVolume(SystemSettings.sound_volume)
    end
    love.keyboard.setKeyRepeat(false)
    ---@type integer
    LastOffset = nil
    scene.isEditor = args.isEditor
    scene.forced = args.forced
    if args.songData then
        scene.songData = args.songData
        scene.scorePrefix = args.scorePrefix
        scene.difficulty = args.difficulty
        scene.chart = scene.songData:loadChart(args.difficulty or "easy")
        if scene.chart then
            scene.chart.time = TimeBPM(-16,scene.chart.bpm)
        end
    end
    scene.masquerade = args.masquerade or scene.difficulty or "hidden"
    if scene.chart then
        scene.song = Assets.Source(scene.chart.song)
        if scene.song then
            scene.song:setVolume(SystemSettings.song_volume)
            scene.song:seek(0, "seconds")
        end
        scene.video = Assets.Video(scene.chart.video)
        scene.background = Assets.Background(scene.chart.background) or defaultBg
        if scene.background and type(scene.background.init) == "function" then
            scene.background.init(scene.chart.backgroundInit or {})
        end
        scene.chart:recalculateCharge()
        scene.chart:resetAllNotes()
    end
    scene.modifiers = args.modifiers or {}
    scene.chartName = "UNRAVELING STASIS"
    scene.chargeGate = args.chargeGate or 0.8
    scene.audioOffset = Showcase and 0 or SystemSettings.audio_offset or 0
    scene.bpmChangeTime = 0
    scene.bpmChangeBeats = 0
    scene.bpm = scene.chart.bpm
    scene.beatCount = WhichSixteenth(scene.chart.time - scene.bpmChangeTime, scene.bpm) / 4 + scene.bpmChangeBeats
    local colorIndexes = Save.Read("note_colors") or {ColorID.LIGHT_RED, ColorID.YELLOW, ColorID.LIGHT_GREEN, ColorID.LIGHT_BLUE}
    NoteColors = {
        ColorTransitionTable[colorIndexes[1]],
        ColorTransitionTable[colorIndexes[2]],
        ColorTransitionTable[colorIndexes[3]],
        ColorTransitionTable[colorIndexes[4]]
    }
    Keybinds[4] = Save.Read("keybinds")
    HitOffset = 0
    RealHits = 0
    Charge = 0
    Potential = 0
    Hits = 0
    Accuracy = 0
    Combo = 0
    MaxCombo = 0
    ComboBreaks = 0
    FullOvercharge = true
    HideTitlebar = false
    ShowReducedInfo = false
    ScrollSpeed = Save.Read("scroll_speed")
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
    ViewOffsetMoveLine = true
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

    NoteBrightness = 1
    NoteBrightnessTarget = 1
    NoteBrightnessSmoothing = 0
    BoardBrightness = 1
    BoardBrightnessTarget = 1
    BoardBrightnessSmoothing = 0

    PauseTimer = 0
    Paused = false
    SongStarted = false
    PauseSelection = 0

    HandleChartEffects()
end

function ResetEffects()
    DisplayShift = {0,0}
    DisplayShiftTarget = {0,0}
    DisplayShiftSmoothing = 0
    DisplayScale = {1,1}
    DisplayScaleTarget = {1,1}
    DisplayScaleSmoothing = 0
    DisplayRotation = 0
    DisplayRotationTarget = 0
    DisplayRotationSmoothing = 0
    DisplayShear = {0,0}
    DisplayShearTarget = {0,0}
    DisplayShearSmoothing = 0

    BloomStrengthModifier = 1
    BloomStrengthModifierTarget = 1
    BloomStrengthModifierSmoothing = 0
    ChromaticModifier = 0
    ChromaticModifierTarget = 0
    ChromaticModifierSmoothing = 0
    TearingModifier = 0
    TearingModifierTarget = 0
    TearingModifierSmoothing = 0
    CurveModifier = 1
    CurveModifierTarget = 1
    CurveModifierSmoothing = 0
end

function PauseGame()
    if scene.song then scene.song:pause() end
    if scene.video then scene.video:pause() end
    Paused = true
    PauseTimer = 1.5
    PauseSelection = 0
end

function Restart()
    if scene.song then scene.song:stop() end
    scene.chart:resetAllNotes()
    SceneManager.Transition("scenes/game", {songData = scene.songData, scorePrefix = scene.scorePrefix, difficulty = scene.difficulty, isEditor = scene.isEditor, forced = scene.forced})
end

function Exit()
    if scene.forced then return end
    if scene.song then scene.song:stop() end
    scene.chart:resetAllNotes()
    if scene.isEditor then
        scene.chart.time = 0
        scene.chart:resetAllNotes()
        Charge = 0
        SceneManager.Transition("scenes/neditor", {songData = scene.songData, scorePrefix = scene.scorePrefix, difficulty = scene.difficulty})
    else
        SceneManager.Transition("scenes/songselect")
    end
end

function scene.keypressed(k)
    if k == "escape" then
        if Paused then
            Paused = false
        elseif PauseTimer <= 0 then
            PauseGame()
        end
    end
    if Paused then
        if k == "backspace" and Paused and not scene.forced then
            Exit()
        end
        if k == "return" then
            if PauseSelection == 0 then
                Paused = false
            end
            if PauseSelection == 1 then
                Restart()
            end
            if PauseSelection == 2 and not scene.forced then
                Exit()
            end
        end
        if k == "left" then
            PauseSelection = (PauseSelection-1)%(scene.forced and 2 or 3)
        end
        if k == "right" then
            PauseSelection = (PauseSelection+1)%(scene.forced and 2 or 3)
        end
    end
    if k == "r" then
        Restart()
    end
    if k == "f8" then
        if scene.forced then return end
        if scene.song then scene.song:stop() end
        scene.chart.time = 0
        scene.chart:resetAllNotes()
        Charge = 0
        SceneManager.Transition("scenes/neditor", {songData = scene.songData, scorePrefix = scene.scorePrefix, difficulty = scene.difficulty})
    end
    if PauseTimer > 0 then return end
    if k == "]" then
        scene.chart.time = math.huge
    end
    if not Autoplay then
        local laneIndex = table.index(Keybinds[scene.chart.lanes] or Keybinds[8], k)
        if laneIndex then
            for i,note in ipairs(scene.chart.notes) do
                local pos = note.time-scene.chart.time
                if pos > TimingWindow then -- too far for us to care
                    break
                end
                local t = NoteTypes[note.type]
                if t then
                    if t.hit then
                        local hit,accuracy,marked = t.hit(note, scene.chart.time, laneIndex-1)
                        if hit then
                            local hitSound = hitSounds[lastHitSound+1]
                            lastHitSound = (lastHitSound + 1) % #hitSounds
                            if hitSound and Save.Read("enable_hit_sounds") then
                                hitSound:stop()
                                hitSound:play()
                            end
                            local accValue = (1-accuracy)
                            LastRating = GetRating(accValue)
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
                            LastOffset = (note.time-scene.chart.time)
                            HitOffset = HitOffset + LastOffset
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
                            MaxCombo = math.max(Combo, MaxCombo)
                            if LastRating >= #NoteRatings-1 then
                                Combo = 0
                                ComboBreaks = ComboBreaks + 1
                            end
                            break
                        end
                        if marked then
                            break
                        end
                    end
                end
                -- local pos = note.time-scene.chart.time
                -- if math.abs(pos) <= TimingWindow and k == (Keybinds[scene.chart.lanes] or Keybinds[8])[note.lane+1] and not note.destroyed and not note.holding then
                --     local t = 0.125
                --     local accuracy = (math.abs(pos)/TimingWindow)
                --     accuracy = math.max(0,math.min(1,(1/(1-t))*accuracy - ((1/(1-t))-1)))
                --     local accValue = (1-accuracy)
                --     for R,rating in ipairs(NoteRatings) do
                --         if accValue >= rating.min and accValue < rating.max then
                --             LastRating = R
                --             break
                --         end
                --     end
                --     RatingCounts[LastRating] = RatingCounts[LastRating] + 1
                --     if LastRating ~= 1 then FullOvercharge = false end
                --     if LastRating == 1 then
                --         accuracy = 0 -- 100%
                --         local x = (80-(scene.chart.lanes*4-1))/2 - 1+(note.lane)*4 + 1
                --         for _=1, 4 do
                --             local drawPos = (5)+(15)+(ViewOffset+ViewOffsetFreeze)*(ScrollSpeed*ScrollSpeedMod)
                --             table.insert(Particles, {id = "powerhit", x = x*8+12, y = drawPos*16-16, vx = (love.math.random()*2-1)*64, vy = -(love.math.random()*2)*32, life = (love.math.random()*0.5+0.5)*0.25, color = OverchargeColors[love.math.random(1,#OverchargeColors)], char = "¤"})
                --         end
                --     end
                --     Charge = Charge + (1-accuracy)
                --     Hits = Hits + 1
                --     HitOffset = HitOffset + pos
                --     RealHits = RealHits + 1
                --     Accuracy = Accuracy + (1-accuracy)
                --     local c = math.floor(Charge/scene.chart.totalCharge*100/2-1)
                --     local x = (16+c)*8
                --     RemoveParticlesByID("chargeup")
                --     for _=1,8 do
                --         table.insert(Particles, {id = "chargeup", x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
                --     end
                --     if note.length <= 0 then
                --         note.destroyed = true
                --     else
                --         note.holding = true
                --         note.heldFor = 0
                --     end
                --     HitAmounts[note.lane+1] = 1
                --     Combo = Combo + 1
                --     if LastRating >= #NoteRatings-1 then
                --         Combo = 0
                --         ComboBreaks = ComboBreaks + 1
                --     end
                --     break
                -- end
            end
        end
    end
end

function HandleChartEffects()
    if not SystemSettings.enable_chart_effects then return end
    local i = 1
    local num = #scene.chart.effects
    while i <= num do
        local effect = scene.chart.effects[i]
        local pos = effect.time-scene.chart.time
        if pos > 0 then -- too far for us to care
            i = num
            return
        end
        if effect.destroyed then
            goto continue
        end
        if pos <= 0 then
            local t = EffectTypes[effect.type] or {}
            if type(t.apply) == "function" then
                t.apply(effect,scene.chart)
            end
            effect.destroyed = true
            i = i - 1
        end
        ::continue::
        i = i + 1
        num = #scene.chart.effects
    end
end

function scene.update(dt)
    if not WindowFocused and PauseTimer <= 0 and SystemSettings.pause_on_lost_focus then
        PauseGame()
    end
    if Paused or SceneManager.TransitioningIn() or SceneManager.TransitioningOut() then return end
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
    scene.modifiers.speed = love.keyboard.isDown("lshift") and 16 or 1
    EffectTimescale = scene.modifiers.speed
    -- Update chart time and scroll chart
    local lastTime = scene.chart.time
    scene.chart.time = scene.chart.time + dt*(scene.modifiers.speed or 1)
    if scene.chart.time > -scene.audioOffset then
        if scene.lastTime <= -scene.audioOffset then
            SongStarted = true
            if scene.song then scene.song:play() end
            if scene.video then scene.video:play() end
        end
        if scene.song then
            if scene.song:isPlaying() then
                local st = scene.song:tell("seconds")-scene.audioOffset
                local drift = st-scene.chart.time
                -- Only fix drift if we're NOT at the end of song AND we are too much offset
                if math.abs(drift) >= 0.05 and drift > -scene.song:getDuration("seconds") then
                    scene.chart.time = scene.song:tell("seconds")
                end
            end
        end
        if scene.song then scene.song:setPitch(scene.modifiers.speed or 1) end
        if scene.video then scene.video:getSource():setPitch(scene.modifiers.speed or 1) end
    end

    -- remember this for later
    -- when you cross a bpm change:
    -- > store the time in the song of the bpm change
    -- > store the current number of beats
    -- then to calculate current beat, take the beat count as:
    -- WhichSixteenth(time - bpmChangeTime) / 4 + bpmChangeBeats

    local lastBeatCount = scene.beatCount
    for _,bpmChange in ipairs(scene.chart.bpmChanges) do
        if scene.chart.time >= bpmChange.time and lastTime < bpmChange.time then
            -- Cross bpm change!
            scene.bpmChangeBeats = WhichSixteenth(bpmChange.time - scene.bpmChangeTime, scene.bpm) / 4 + scene.bpmChangeBeats
            scene.bpmChangeTime = bpmChange.time
            scene.bpm = bpmChange.bpm
        end
    end
    scene.beatCount = WhichSixteenth(scene.chart.time - scene.bpmChangeTime, scene.bpm) / 4 + scene.bpmChangeBeats

    -- Freeze notes in place and move judgement line instead
    local diff = scene.chart.time - lastTime
    if ChartFrozen then
        ViewOffsetFreeze = ViewOffsetFreeze - diff
    else
        ViewOffsetFreeze = 0
    end

    scene.lastTime = scene.lastTime + dt*(scene.modifiers.speed or 1)

    for _,note in ipairs(scene.chart.notes) do
        if note.laneTarget then note.lane = note.laneTarget end
        if (note.smoothing or 0) == 0 then
            if note.timeTarget then note.time = note.timeTarget end
            if note.laneTarget then note.visualLane = note.laneTarget end
        else
            local blend = math.pow(1/note.smoothing,dt)
            if note.timeTarget then note.time = blend*(note.time-note.timeTarget)+note.timeTarget end
            if note.laneTarget then note.visualLane = blend*(note.visualLane-note.laneTarget)+note.laneTarget end
        end
    end

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
                if pos > 0.5 then -- too far for us to care
                    i = num
                    break
                end
                if Autoplay then
                    if pos <= 0 then
                        local t = NoteTypes[note.type]
                        if not t.autoplayIgnores then
                            local hit = true
                            if t.hit then
                                hit = false
                                for l = 0, scene.chart.lanes-1 do
                                    local hitThis,_,marked = t.hit(note, note.time, l)
                                    if marked then
                                        PressAmounts[l+1] = 32
                                        HitAmounts[l+1] = 1
                                    end
                                    hit = hit or hitThis
                                end
                            end
                            if hit then
                                local hitSound = hitSounds[lastHitSound+1]
                                lastHitSound = (lastHitSound + 1) % #hitSounds
                                if hitSound and Save.Read("enable_hit_sounds") then
                                    hitSound:stop()
                                    hitSound:play()
                                end
                                if (note.heldFor or 0) <= 0 then
                                    Charge = Charge + 1
                                    Combo = Combo + 1
                                    MaxCombo = math.max(Combo, MaxCombo)
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
                                    LastOffset = 0
                                    RealHits = RealHits + 1
                                    local c = math.floor(Charge/scene.chart.totalCharge*100/2-1)
                                    local x = (16+c)*8
                                    RemoveParticlesByID("chargeup")
                                    for _=1,8 do
                                        table.insert(Particles, {id = "chargeup", x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
                                    end
                                end
                                if note.length <= 0 then
                                    if not note.destroyed then
                                        note.destroyed = true
                                        i = i - 1
                                    end
                                else
                                    note.holding = true
                                end
                                if not Autoplay then PressAmounts[note.lane+1] = 1 end
                            end
                        end
                    end
                end
                if note.holding and pos <= 0 then
                    if note.length > 0 then
                        if love.keyboard.isDown((Keybinds[scene.chart.lanes] or Keybinds[8])[note.lane+1]) or Autoplay then
                            local lastHeldFor = note.heldFor or 0
                            note.heldFor = math.min(note.length, lastHeldFor + dt)
                            Charge = Charge + (note.heldFor-lastHeldFor)
                            if (lastBeatCount % 0.5) > (scene.beatCount % 0.5) then
                                local x = (80-(scene.chart.lanes*4-1))/2 - 1+(note.lane)*4 + 1
                                for _=1, 4 do
                                    local drawPos = (5)+(15)+(ViewOffset+ViewOffsetFreeze)*(ScrollSpeed*ScrollSpeedMod)
                                    table.insert(Particles, {id = "holdgrind", x = x*8+12, y = drawPos*16-16, vx = (love.math.random()*2-1)*32, vy = -(love.math.random()*2)*64, life = (love.math.random()*0.5+0.5)*0.25, color = NoteColors[note.lane+1][3], char = "¤"})
                                end
                            end
                            HitAmounts[note.lane+1] = 1
                            if note.heldFor >= note.length then
                                if not note.destroyed then
                                    note.destroyed = true
                                    i = i - 1
                                end
                            end
                        end
                        if Autoplay then
                            PressAmounts[note.lane+1] = 32
                        end
                    end
                end
                local t = NoteTypes[note.type]
                if not t then goto continue end
                if pos <= (t.missImmediately and 0 or -0.25) then
                    local permitted = false
                    if t.miss then
                        permitted = t.miss(note) or permitted
                    end
                    if not permitted then
                        if note.length <= 0 then
                            if not note.destroyed then
                                note.destroyed = true
                                i = i - 1
                            end
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
                                if not note.destroyed then
                                    note.destroyed = true
                                    i = i - 1
                                end
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
                                        if not note.destroyed then
                                            note.destroyed = true
                                            i = i - 1
                                        end
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
            end
            ::continue::
            i = i + 1
            num = #scene.chart.notes
        end
    end

    HandleChartEffects()

    if scene.song then
        if scene.chart.time >= scene.song:getDuration("seconds") then
            if not SceneManager.TransitionState.Transitioning then
                if FullOvercharge then
                    Charge = scene.chart.totalCharge
                end
                if scene.isEditor then
                    if scene.song then scene.song:stop() end
                    scene.chart.time = 0
                    scene.chart:resetAllNotes()
                    Charge = 0
                    SceneManager.Transition("scenes/neditor", {songData = scene.songData, scorePrefix = scene.scorePrefix, difficulty = scene.difficulty})
                else
                    SceneManager.Transition("scenes/rating", {chart = scene.chart, songData = scene.songData, scorePrefix = scene.scorePrefix, difficulty = scene.difficulty, offset = HitOffset/RealHits, ratings = RatingCounts, accuracy = Accuracy/math.max(Hits,1), charge = (Charge*100)/scene.chart.totalCharge, chargeGate = scene.chargeGate, fullCombo = ComboBreaks == 0, fullOvercharge = FullOvercharge, next = scene.next})
                end
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

    -- do
    --     local blend = math.pow(0.01,dt)
    --     CurveModifier = blend*(CurveModifier-1)+1
    --     ScreenShader:send("curveStrength", SystemSettings.screen_effects.screen_curvature*CurveModifier)
    -- end
    -- do
    --     local blend = math.pow(0.05,dt)
    --     Chromatic = blend*Chromatic
    --     ScreenShader:send("chromaticStrength", Chromatic)
    -- end
    do
        if DisplayShiftSmoothing == 0 then
            DisplayShift[1] = DisplayShiftTarget[1]
            DisplayShift[2] = DisplayShiftTarget[2]
        else
            local blend = math.pow(1/DisplayShiftSmoothing,dt*EffectTimescale)
            DisplayShift[1] = blend*(DisplayShift[1]-DisplayShiftTarget[1])+DisplayShiftTarget[1]
            DisplayShift[2] = blend*(DisplayShift[2]-DisplayShiftTarget[2])+DisplayShiftTarget[2]
        end
    end
    do
        if DisplayScaleSmoothing == 0 then
            DisplayScale[1] = DisplayScaleTarget[1]
            DisplayScale[2] = DisplayScaleTarget[2]
        else
            local blend = math.pow(1/DisplayScaleSmoothing,dt*EffectTimescale)
            DisplayScale[1] = blend*(DisplayScale[1]-DisplayScaleTarget[1])+DisplayScaleTarget[1]
            DisplayScale[2] = blend*(DisplayScale[2]-DisplayScaleTarget[2])+DisplayScaleTarget[2]
        end
    end
    do
        if DisplayRotationSmoothing == 0 then
            DisplayRotation = DisplayRotationTarget
        else
            local blend = math.pow(1/DisplayRotationSmoothing,dt*EffectTimescale)
            DisplayRotation = blend*(DisplayRotation-DisplayRotationTarget)+DisplayRotationTarget
        end
    end
    do
        if DisplayShearSmoothing == 0 then
            DisplayShear[1] = DisplayShearTarget[1]
            DisplayShear[2] = DisplayShearTarget[2]
        else
            local blend = math.pow(1/DisplayShearSmoothing,dt*EffectTimescale)
            DisplayShear[1] = blend*(DisplayShear[1]-DisplayShearTarget[1])+DisplayShearTarget[1]
            DisplayShear[2] = blend*(DisplayShear[2]-DisplayShearTarget[2])+DisplayShearTarget[2]
        end
    end
    do
        if ViewOffsetSmoothing == 0 then
            ViewOffset = ViewOffsetTarget
        else
            local blend = math.pow(1/ViewOffsetSmoothing,dt*EffectTimescale)
            ViewOffset = blend*(ViewOffset-ViewOffsetTarget)+ViewOffsetTarget
        end
    end
    do
        if ScrollSpeedModSmoothing == 0 then
            ScrollSpeedMod = ScrollSpeedModTarget
        else
            local blend = math.pow(1/ScrollSpeedModSmoothing,dt*EffectTimescale)
            ScrollSpeedMod = blend*(ScrollSpeedMod-ScrollSpeedModTarget)+ScrollSpeedModTarget
        end

        for _,mod in ipairs(NoteSpeedMods) do
            if mod[3] == 0 then
                mod[1] = mod[2]
            else
                local blend = math.pow(1/mod[3],dt*EffectTimescale)
                mod[1] = blend*(mod[1]-mod[2])+mod[2]
            end
        end
    end
    do
        if WavinessSmoothing == 0 then
            Waviness = WavinessTarget
        else
            local blend = math.pow(1/WavinessSmoothing,dt*EffectTimescale)
            Waviness = blend*(Waviness-WavinessTarget)+WavinessTarget
        end
    end
    do
        if NoteBrightnessSmoothing == 0 then
            NoteBrightness = NoteBrightnessTarget
        else
            local blend = math.pow(1/NoteBrightnessSmoothing,dt*EffectTimescale)
            NoteBrightness = blend*(NoteBrightness-NoteBrightnessTarget)+NoteBrightnessTarget
        end
    end
    do
        if BoardBrightnessSmoothing == 0 then
            BoardBrightness = BoardBrightnessTarget
        else
            local blend = math.pow(1/BoardBrightnessSmoothing,dt*EffectTimescale)
            BoardBrightness = blend*(BoardBrightness-BoardBrightnessTarget)+BoardBrightnessTarget
        end
    end

    for i = 1, scene.chart.lanes do
        PressAmounts[i] = math.max(0, math.min(Autoplay and math.huge or 1, (PressAmounts[i] or 0) + dt*8*((love.keyboard.isDown((Keybinds[scene.chart.lanes] or Keybinds[8])[i]) and not Autoplay) and 1/dt or -1/dt)))
        HitAmounts[i] = math.max(0, math.min(1, (HitAmounts[i] or 0) - dt*8))
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
    love.graphics.shear(DisplayShear[1], DisplayShear[2])
    love.graphics.translate(-320,-240)

    love.graphics.translate(AnaglyphSide, 0)

    -- Debug info
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    --love.graphics.print("Full Combo: " .. tostring(ComboBreaks == 0), 50*8 + AnaglyphSide*0.75, 5*16)
    --love.graphics.print("Full Overcharge: " .. tostring(FullOvercharge), 50*8 + AnaglyphSide*0.75, 6*16)

    -- Chart and bar outlines
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local r0,g0,b0,a0 = love.graphics.getColor()
    love.graphics.setColor(r0*BoardBrightness,g0*BoardBrightness,b0*BoardBrightness,a0)
    DrawBoxHalfWidth((80-(scene.chart.lanes*4-1))/2 - 1, 4, scene.chart.lanes*4-1, 16)
    DrawBoxHalfWidth(14, 23, 50, 1)

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local r1,g1,b1,a1 = love.graphics.getColor()
    love.graphics.setColor(r1*BoardBrightness,g1*BoardBrightness,b1*BoardBrightness,a1)
    -- Text Displays
    if not HideTitlebar then
        local difficultyName = SongDifficulty[scene.masquerade or "easy"].name or scene.masquerade:upper()
        local difficultyColor = SongDifficulty[scene.masquerade or "easy"].color or TerminalColors[ColorID.WHITE]
        local level = scene.songData:getLevel(scene.difficulty)
        local fullText = scene.songData.name .. (scene.chart.hideDifficulty and "" or (" - " .. SongDifficulty[scene.masquerade].name .. (level ~= nil and (" " .. level) or "")))
        -- local fullText = scene.songData.name .. " - " .. difficultyName .. " " .. level
        love.graphics.print("┌─" .. ("─"):rep(utf8.len(fullText)) .. "─┐\n│ " .. (" "):rep(utf8.len(fullText)) .. " │\n└─" .. ("─"):rep(utf8.len(fullText)) .. "─┘", ((80-(utf8.len(fullText)+4))/2)*8, 1*16)
        love.graphics.print(scene.songData.name .. (scene.chart.hideDifficulty and "" or " - "), ((80-(utf8.len(fullText)+4))/2 + 2)*8, 2*16)
        -- love.graphics.setColor(difficultyColor)
        -- love.graphics.print(difficultyName, ((80-(utf8.len(fullText)+4))/2 + 2 + utf8.len(scene.songData.name .. " - "))*8, 2*16)
        if not scene.chart.hideDifficulty then PrintDifficulty(((80-(utf8.len(fullText)+4))/2 + 2 + utf8.len(scene.songData.name .. " - "))*8, 2*16, scene.masquerade or "easy", level, "left") end
        love.graphics.setColor(r1*BoardBrightness,g1*BoardBrightness,b1*BoardBrightness,a1)
    end
    -- love.graphics.print(tostring(level), ((80-(utf8.len(fullText)+4))/2 + 2 + utf8.len(scene.songData.name .. " - " .. difficultyName .. " "))*8, 2*16)

    if Autoplay then love.graphics.print("┬──────────┬\n│ ".. (Showcase and "SHOWCASE" or "AUTOPLAY") .. " │\n┴──────────┴", 34*8, 21*16) end

    if not ShowReducedInfo then
        local acc = math.floor(Accuracy/math.max(Hits,1)*100)

        love.graphics.print("┬──────────┬\n│ ACC " .. (" "):rep(3-#tostring(acc))..acc.. "% │\n└──────────┘", 34*8, 25*16)
        love.graphics.print("┌──────────┐\n│  CHARGE  │\n├──────────┴", 14*8, 21*16)
        local c = (Charge*100)/scene.chart.totalCharge
        local chargeAmount = math.floor(c/100*ChargeYield)
        if c ~= c then chargeAmount = 0 end
        love.graphics.print(" ", 62*8, 22*16) -- Empty space
        love.graphics.print("┌──────────┐\n│  " .. (" "):rep(5-#tostring(chargeAmount)) .. chargeAmount .."¤  │\n┴──────────┤", 54*8, 21*16)
    end
    -- Gate
    if scene.chargeGate > 0 and scene.chargeGate < 1 then
        love.graphics.setColor(r1*BoardBrightness,g1*BoardBrightness,b1*BoardBrightness,a1)
        local gateX = (15+math.floor(50*scene.chargeGate))
        local symbol = (gateX == 25 or gateX == 54) and "┼" or "┬"
        love.graphics.print(symbol.."\n\n┴", gateX*8, 23*16)
        love.graphics.setColor(TerminalColors[ColorID.GOLD])
        local r2,g2,b2,a2 = love.graphics.getColor()
        love.graphics.setColor(r2*BoardBrightness,g2*BoardBrightness,b2*BoardBrightness,a2)
        love.graphics.print("┊", gateX*8, 24*16)
    end
    -- Overcharge Threshold
    do
        love.graphics.setColor(r1*BoardBrightness,g1*BoardBrightness,b1*BoardBrightness,a1)
        local thresholdX = (15+math.floor(50*0.8))
        love.graphics.print("┬\n\n┴", thresholdX*8, 23*16)
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        local r2,g2,b2,a2 = love.graphics.getColor()
        love.graphics.setColor(r2*BoardBrightness,g2*BoardBrightness,b2*BoardBrightness,a2)
        love.graphics.print("┊", thresholdX*8, 24*16)
    end

    -- Bar fill
    local c = math.floor((Charge*100)/scene.chart.totalCharge)
    love.graphics.setColor(TerminalColors[(c < (scene.chargeGate/2*100) and 5) or (c < (scene.chargeGate*100) and 15) or 11])
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
    love.graphics.setColor(TerminalColors[9])
    local r3,g3,b3,a3 = love.graphics.getColor()
    love.graphics.setColor(r3*BoardBrightness,g3*BoardBrightness,b3*BoardBrightness,a3)
    for i = 1, scene.chart.lanes-1 do
        local x = (80-(scene.chart.lanes*4-1))/2 - 1+(i-1)*4 + 1
        love.graphics.print(("   ┊\n"):rep(16), x*8, 5*16)
    end
    local jlBrightness = math.max(BoardBrightness,NoteBrightness)
    love.graphics.setColor(r3*jlBrightness,g3*jlBrightness,b3*jlBrightness,a3)
    do
        local drawPos = (5)+(15)+(ViewOffsetMoveLine and (ViewOffset+ViewOffsetFreeze) or 0)*(ScrollSpeed*ScrollSpeedMod)
        if drawPos >= 5 and drawPos <= 20 then
            love.graphics.print("┈┈┈"..("╬┈┈┈"):rep(scene.chart.lanes-1), ((80-(scene.chart.lanes*4-1))/2 - 1+(1-1)*4 + 1)*8, drawPos*16-16)
        end
    end

    -- Hit areas
    for i = 1, scene.chart.lanes do
        local x = (80-(scene.chart.lanes*4-1))/2 - 1+(i-1)*4 + 1
        local v = math.ceil(math.min(1,PressAmounts[i])+HitAmounts[i]*2)
        if v > 0 then
            local drawPos = (5)+(15)+(ViewOffsetMoveLine and (ViewOffset+ViewOffsetFreeze) or 0)*(ScrollSpeed*ScrollSpeedMod)
            love.graphics.setColor(TerminalColors[NoteColors[((i-1)%(#NoteColors))+1][v+1]])
            love.graphics.print("███", x*8 + AnaglyphSide*0.75, drawPos*16-16)
            -- if HitAmounts[i] > 0 then
            --     love.graphics.setColor(TerminalColors[ColorID.BLACK])
            --     love.graphics.print("○", x*8 + 8 + AnaglyphSide*0.75, drawPos*16-16)
            -- end
        end
    end

    -- Notes
    for _,note in ipairs(scene.chart.notes) do
        if not note.destroyed then
            local t = NoteTypes[note.type]
            if t and type(t.draw) == "function" then
                love.graphics.setFont(NoteFont)
                love.graphics.setColor(NoteBrightness,NoteBrightness,NoteBrightness,1)
                t.draw(note,scene.chart.time,(ScrollSpeed*ScrollSpeedMod)*NoteSpeedMods[note.lane+1][1],nil,nil,((80-(scene.chart.lanes*4-1))/2)+1)
                love.graphics.setFont(Font)
            end
        end
    end

    -- Last rating and combo
    if NoteRatings[LastRating] then
        local x,y = 40*8, 6*16
        x = x + AnaglyphSide*0.75
        NoteRatings[LastRating].draw(x,y,true)
    end
    -- if LastOffset then
    --     love.graphics.printf(math.floor(LastOffset*1000*100)/100 .. " ms", 320-128, 9*16, 256, "center")
    --     love.graphics.printf(math.floor((HitOffset/RealHits)*1000*100)/100 .. " ms", 320-128, 10*16, 256, "center")
    -- end
    local comboString = tostring(Combo)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.print(comboString, ((80-(#comboString))/2)*8 + AnaglyphSide*0.75, 7*16)

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

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local lyrics = scene.songData.lyrics[scene.difficulty] or scene.songData.lyrics.main
    if lyrics then
        lyrics:draw(scene.chart.time)
    end

    if Paused or PauseTimer > 0 then
        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if Paused then
            DrawBoxHalfWidth(23, 12, 32, 4)
            love.graphics.draw(PausedText, 320, 240-16, 0, 1, 1, PausedText:getWidth()/2, PausedText:getHeight()/2)
            love.graphics.setColor(TerminalColors[PauseSelection == 0 and ColorID.LIGHT_BLUE or ColorID.WHITE])
            love.graphics.printf("Resume", 320-96, 240+16, 96, "center", 0, 1, 1, 48, 8)
            love.graphics.setColor(TerminalColors[PauseSelection == 1 and ColorID.LIGHT_BLUE or ColorID.WHITE])
            love.graphics.printf("Restart", 320, 240+16, 96, "center", 0, 1, 1, 48, 8)
            love.graphics.setColor(TerminalColors[scene.forced and ColorID.DARK_GRAY or (PauseSelection == 2 and ColorID.LIGHT_BLUE or ColorID.WHITE)])
            love.graphics.printf("Quit", 320+96, 240+16, 96, "center", 0, 1, 1, 48, 8)
        else
            local counterText = Counter[math.ceil(PauseTimer*2)]
            if counterText then
                love.graphics.draw(counterText, 320, 344, 0, 1, 1, counterText:getWidth()/2, 0)
            end
        end
    end

    -- love.graphics.setColor(TerminalColors[ColorID.WHITE])
    -- love.graphics.print(tostring(scene.chart:getDifficulty()), 64, 64)
    -- love.graphics.print(tostring(math.floor(scene.chart:getDifficulty() + 0.5)), 64, 64+16)
    -- love.graphics.print(tostring(math.floor(scene.chart:getDensity()*1.5 + 0.5)), 64, 64+16)
end

function scene.unload()
    EffectTimescale = 1
    Particles = {}
    ResetEffects()
end

return scene
