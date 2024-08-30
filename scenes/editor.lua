local scene = {}

local chartPos = 5
local chartHeight = 20

local songPath = "unst.ogg"
local songBpm = 223

local function drawLine(time,chartTime,speed,col)
    local pos = time-chartTime
    chartHeight = chartHeight or 15
    chartPos = chartPos or 5
    local drawPos = chartPos+chartHeight-pos*speed
    if drawPos > chartPos and drawPos < chartPos+(chartHeight) then
        love.graphics.setColor(TerminalColors[col or 9])
        love.graphics.print("┈┈┈╬┈┈┈╬┈┈┈╬┈┈┈", 33*8, drawPos*16-8)
    end
end

function scene.load(args)
    if args.chart then
        scene.chart = args.chart
    elseif love.filesystem.getInfo("editor_chart.json") then
        scene.chart = Chart.fromFile("editor_chart.json")
    else
        scene.chart = Chart:new(songPath,songBpm,{},{})
    end
    if EditorTime then
        scene.chart.time = EditorTime
    else
        EditorTime = 0
    end
    MissTime = 0
    Chromatic = 0
    if ScreenShader then
        ScreenShader:send("tearStrength", MissTime*8/Display:getWidth())
        ScreenShader:send("chromaticStrength", Chromatic)
    end
    scene.targetEffect = 0
    scene.zoom = 1
    scene.paused = true
    scene.speed = 25
end

function scene.mousepressed(x,y,b)
    local hadTarget = scene.targetEffect ~= 0
    scene.targetEffect = 0
    local lane = math.floor((x/8-34)/4+0.5)
    if lane >= 0 and lane < 4 and not hadTarget then
        local time = -((y+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
        local bpmTime = TimeBPM(1,scene.chart.bpm)
        time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom
        if b == 1 then
            local found = false
            for i,note in ipairs(scene.chart.notes) do
                if math.abs(note.time-time) <= 0.0625/scene.zoom and note.lane == lane then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(scene.chart.notes, Note:new(time, lane, 0, "normal", {}))
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = love.math.random(1,16), char = "¤"})
                end
            end
        elseif b == 2 then
            for i,note in ipairs(scene.chart.notes) do
                local drawPos = chartPos+chartHeight-(note.time-scene.chart.time)*(scene.speed*scene.zoom)
                drawPos = drawPos*16-8
                if math.abs(note.time-time) <= 0.0625/scene.zoom and note.lane == lane then
                    table.remove(scene.chart.notes, i)
                    for _=1,8 do
                        table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                    end
                    break
                end
            end
        end
    end
    if lane >= 4 then
        local effects = {}
        for i,effect in ipairs(scene.chart.effects) do
            effects[math.floor(effect.time*10*scene.zoom)] = effects[math.floor(effect.time*10*scene.zoom)] or {}
            table.insert(effects[math.floor(effect.time*10*scene.zoom)], {effect = effect, index = i})
        end

        if b == 1 then
            local time = -((y+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
            local bpmTime = TimeBPM(1,scene.chart.bpm)
            time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom
            if (effects[math.floor(time*10*scene.zoom)] or {})[lane-3] then
                scene.targetEffect = (effects[math.floor(time*10*scene.zoom)] or {})[lane-3].index
                -- print(effects[math.floor(time*10*scene.zoom)][lane-3].effect.type)
                -- for k,v in pairs(effects[math.floor(time*10*scene.zoom)][lane-3].effect.data) do
                --     print(k,v)
                -- end
            elseif not hadTarget then
                table.insert(scene.chart.effects, {time = time, type = "none", data = {}})
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = love.math.random(1,16), char = "¤"})
                end
            end
        elseif b == 2 then
            local time = -((y+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
            local bpmTime = TimeBPM(1,scene.chart.bpm)
            time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom
            if (effects[math.floor(time*10*scene.zoom)] or {})[lane-3] and not hadTarget then
                table.remove(scene.chart.effects, (effects[math.floor(time*10*scene.zoom)] or {})[lane-3].index)
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                end
            end
        end
    end
end

function scene.wheelmoved(x,y)
    local lane = math.floor((MouseX/8-34)/4+0.5)
    if lane >= 0 and lane < 4 then
        local time = -((MouseY+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
        local bpmTime = TimeBPM(1,scene.chart.bpm)
        time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom

        for i,note in ipairs(scene.chart.notes) do
            local drawPos = chartPos+chartHeight-(note.time-scene.chart.time)*(scene.speed*scene.zoom)
            drawPos = drawPos*16-8
            if math.abs(note.time-time) <= 0.0625/scene.zoom and note.lane == lane then
                note.length = math.max(0,note.length+TimeBPM(y,scene.chart.bpm)/scene.zoom)
                break
            end
        end
    end
end

function scene.update(dt)
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

    if scene.chart.song then
        if scene.chart.song:isPlaying() then
            scene.chart.time = scene.chart.song:tell("seconds")
        end
    end

    if love.keyboard.isDown("up") then
        scene.chart.time = scene.chart.time + dt*(love.keyboard.isDown("lshift") and 2 or 1)/scene.zoom
        if scene.chart.song then
            scene.chart.song:stop()
        end
    end

    if love.keyboard.isDown("down") then
        scene.chart.time = math.max(0,scene.chart.time - dt*(love.keyboard.isDown("lshift") and 2 or 1)/scene.zoom)
        if scene.chart.song then
            scene.chart.song:stop()
        end
    end
end

function scene.keypressed(k)
    if k == "]" then
        scene.zoom = scene.zoom + 1
    end
    if k == "[" then
        scene.zoom = math.max(1,scene.zoom - 1)
    end
    if k == "pageup" then
        local a = TimeBPM(1,scene.chart.bpm)/scene.zoom
        for _,note in ipairs(scene.chart.notes) do
            note.time = note.time + a
        end
    end
    if k == "pagedown" then
        local a = TimeBPM(1,scene.chart.bpm)/scene.zoom
        for _,note in ipairs(scene.chart.notes) do
            note.time = note.time - a
        end
    end
    if k == "home" then
        scene.chart.time = 0
        if scene.chart.song then
            scene.chart.song:stop()
        end
    end
    if k == "end" then
        scene.chart:sort()
        scene.chart.time = scene.chart.notes[#scene.chart.notes].time
        if scene.chart.song then
            scene.chart.song:stop()
        end
    end
    if k == "s" and love.keyboard.isDown("lctrl") then
        scene.chart:save("editor_chart.json")
    end
    if k == "o" and love.keyboard.isDown("lctrl") then
        if love.filesystem.getInfo("editor_chart.json") then
            scene.chart = Chart.fromFile("editor_chart.json")
        end
    end
    if k == "space" then
        if scene.chart.song then
            scene.chart.song:seek(scene.chart.time, "seconds")
            if scene.chart.song:isPlaying() then
                scene.chart.song:pause()
            else
                scene.chart.song:play()
            end
        end
    end
    if k == "n" and love.keyboard.isDown("lctrl") then
        if scene.chart.song then
            scene.chart.song:stop()
            scene.chart.time = 0
        end
        scene.chart = Chart:new(songPath,songBpm,{},{})
    end
    if k == "f9" then
        print(scene.chart:getDensity())
        EditorTime = scene.chart.time
        if scene.chart.song then
            scene.chart.song:stop()
            scene.chart.time = 0
        end
        if love.keyboard.isDown("lshift") then
            if love.keyboard.isDown("lctrl") then
                Showcase = true
            else
                Showcase = false
            end
            Autoplay = true
        else
            Autoplay = false
            Showcase = false
        end
        scene.chart:sort()
        scene.chart:recalculateCharge()
        scene.chart.time = TimeBPM(-16,scene.chart.bpm)
        SceneManager.LoadScene("scenes/game", {chart = scene.chart})
    end
    if k == "left" then
        local lane = math.floor((MouseX/8-34)/4+0.5)
        if lane >= 0 and lane < 4 then
            local time = -((MouseY+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
            local bpmTime = TimeBPM(1,scene.chart.bpm)
            time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom
    
            for i,note in ipairs(scene.chart.notes) do
                local drawPos = chartPos+chartHeight-(note.time-scene.chart.time)*(scene.speed*scene.zoom)
                drawPos = drawPos*16-8
                if math.abs(note.time-time) <= 0.0625/scene.zoom and note.lane == lane then
                    if note.lane+1 < 4 then
                        if note.type == "normal" then
                            note.type = "swap"
                            note.extra.dir = -1
                        else
                            note.type = "normal"
                            note.extra.dir = nil
                        end
                    end
                    break
                end
            end
        end
    end
    if k == "right" then
        local lane = math.floor((MouseX/8-34)/4+0.5)
        if lane >= 0 and lane < 4 then
            local time = -((MouseY+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
            local bpmTime = TimeBPM(1,scene.chart.bpm)
            time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom
    
            for i,note in ipairs(scene.chart.notes) do
                local drawPos = chartPos+chartHeight-(note.time-scene.chart.time)*(scene.speed*scene.zoom)
                drawPos = drawPos*16-8
                if math.abs(note.time-time) <= 0.0625/scene.zoom and note.lane == lane then
                    if note.lane-1 >= 0 then
                        if note.type == "normal" then
                            note.type = "swap"
                            note.extra.dir = 1
                        else
                            note.type = "normal"
                            note.extra.dir = nil
                        end
                    end
                    break
                end
            end
        end
    end
end

function scene.draw()
    DrawBoxHalfWidth(32, chartPos-1, 15, chartHeight)
    love.graphics.setColor(TerminalColors[9])
    love.graphics.print(("┊\n"):rep(20), 36*8, 5*16)
    love.graphics.print(("┊\n"):rep(20), 40*8, 5*16)
    love.graphics.print(("┊\n"):rep(20), 44*8, 5*16)

    local t = 15/scene.chart.bpm
    for i = 0, 3 do
        local steps = scene.zoom*4
        for j = 0, steps-1 do
            drawLine(TimeBPM(i*4+j/(steps/4)-0.5/scene.zoom+math.floor(scene.chart.time/t/4)*4,scene.chart.bpm),scene.chart.time,(scene.speed*scene.zoom),j==0 and 8 or 9)
        end
    end

    for _,note in ipairs(scene.chart.notes) do
        local T = NoteTypes[note.type]
        if T and type(T.draw) == "function" then
            T.draw(note,scene.chart.time,(scene.speed*scene.zoom),chartPos,chartHeight,34,true)
        end
    end

    local function drawEffect(self,time,speed,chartX,isEditor)
        local mainpos = self.time-time
        local pos = mainpos
        local drawPos = chartPos+chartHeight-pos*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
        if drawPos >= chartPos and drawPos < chartPos+(chartHeight+1) and (self.heldFor or 0) <= 0 then
            love.graphics.setColor(TerminalColors[self.selected and ColorID.GREEN or ColorID.WHITE])
            love.graphics.print("◇", (chartX+self.lane*4)*8, math.floor(drawPos*16-8))
        end
    end

    local effectAmounts = {}
    for i,effect in ipairs(scene.chart.effects) do
        effectAmounts[math.floor(effect.time*10*scene.zoom)] = (effectAmounts[math.floor(effect.time*10*scene.zoom)] or 0) + 1
        drawEffect({time = effect.time, lane = 3+effectAmounts[math.floor(effect.time*10*scene.zoom)], selected = i == scene.targetEffect},scene.chart.time,(scene.speed*scene.zoom),34,true)
    end

    for _,particle in ipairs(Particles) do
        love.graphics.setColor(TerminalColors[particle.color])
        love.graphics.print(particle.char, particle.x-4, particle.y-8)
    end

    do
        local x,y = MouseX, MouseY
        local lane = math.floor((x/8-34)/4+0.5)
        if lane >= 0 and lane < 4 then
            local time = -((y+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
            local bpmTime = TimeBPM(1,scene.chart.bpm)
            time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom
            NoteTypes.normal.draw({time=time,lane=lane,length=0,type="normal",extra={}}, scene.chart.time, (scene.speed*scene.zoom),chartPos,chartHeight,34,true)
        end
        if lane >= 4 then
            local time = -((y+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
            local bpmTime = TimeBPM(1,scene.chart.bpm)
            time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom
            if (effectAmounts[math.floor(time*10*scene.zoom)] or 0) <= lane-4 then
                drawEffect({time=time,lane=math.min(lane, 3+(effectAmounts[math.floor(time*10*scene.zoom)] or 0)+1)}, scene.chart.time, (scene.speed*scene.zoom),34,true)
            end
        end
    end

    love.graphics.setColor(TerminalColors[16])
    love.graphics.print("F9 to playtest", 0, 48)
    love.graphics.print("F8 to return here", 0, 64)
    love.graphics.print("CTRL S to save chart", 0, 80)
    love.graphics.print("CTRL N to make a new chart", 0, 96)
    love.graphics.print("Up and Down to scroll chart", 0, 112)
    love.graphics.print("Space to toggle audio playback", 0, 128)
    love.graphics.print("Left click to place note", 0, 160)
    love.graphics.print("Right click to remove note", 0, 176)
    love.graphics.print("Scroll to change note length", 0, 192)

    if scene.chart.effects[scene.targetEffect] then
        local effect = scene.chart.effects[scene.targetEffect]
        love.graphics.print(effect.type, 50*8, 8*16)
        local pos = 9
        for k,v in pairs(effect.data) do
            love.graphics.print(tostring(k) .. ": " .. tostring(v), 50*8, pos*16)
            pos = pos + 1
        end
    end

    -- Mouse pointer
    love.graphics.setColor(TerminalColors[16])
    love.graphics.print("○", MouseX-4, MouseY-8)
end

return scene