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
    scene.zoom = 1
    scene.paused = true
    scene.speed = 25
end

function scene.mousepressed(x,y,b)
    local lane = math.floor((x/8-34)/4+0.5)
    if lane >= 0 and lane < 4 then
        local time = -((y+8)/16-chartPos-chartHeight)/(scene.speed*scene.zoom)+scene.chart.time
        local bpmTime = TimeBPM(1,scene.chart.bpm)
        time = math.floor(time/bpmTime*scene.zoom + 0.5)*bpmTime/scene.zoom
        if b == 1 then
            local found = false
            for i,note in ipairs(scene.chart.notes) do
                if math.abs(note.time-time) <= 0.0625 and note.lane == lane then
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
                if math.abs(note.time-time) <= 0.0625 and note.lane == lane then
                    table.remove(scene.chart.notes, i)
                    for _=1,8 do
                        table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                    end
                    break
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
            if math.abs(note.time-time) <= 0.0625 and note.lane == lane then
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
        scene.zoom = scene.zoom - 1
    end
    if k == "s" and love.keyboard.isDown("lctrl") then
        scene.chart:save("editor_chart.json")
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
        EditorTime = scene.chart.time
        if scene.chart.song then
            scene.chart.song:stop()
            scene.chart.time = 0
        end
        if love.keyboard.isDown("lshift") then
            Autoplay = true
        else
            Autoplay = false
        end
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
                if math.abs(note.time-time) <= 0.0625 and note.lane == lane then
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
                if math.abs(note.time-time) <= 0.0625 and note.lane == lane then
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
            T.draw(note,scene.chart.time,(scene.speed*scene.zoom),chartPos,chartHeight,true)
        end
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
            NoteTypes.normal.draw({time=time,lane=lane,length=0,type="normal",extra={}}, scene.chart.time, (scene.speed*scene.zoom),chartPos,chartHeight)
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

    -- Mouse pointer
    love.graphics.setColor(TerminalColors[16])
    love.graphics.print("○", MouseX-4, MouseY-8)
end

return scene