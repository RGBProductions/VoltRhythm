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
    scene.paused = true
    scene.speed = 25
end

function scene.mousepressed(x,y,b)
    local lane = math.floor((x/8-34)/4+0.5)
    if lane >= 0 and lane < 4 then
        local time = -((y+8)/16-chartPos-chartHeight)/scene.speed+scene.chart.time
        local bpmTime = TimeBPM(1,scene.chart.bpm)
        time = math.floor(time/bpmTime + 0.5)*bpmTime
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
                local drawPos = chartPos+chartHeight-(note.time-scene.chart.time)*scene.speed
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
        scene.chart.time = scene.chart.time + dt*(love.keyboard.isDown("lshift") and 2 or 1)
        if scene.chart.song then
            scene.chart.song:stop()
        end
    end

    if love.keyboard.isDown("down") then
        scene.chart.time = math.max(0,scene.chart.time - dt*(love.keyboard.isDown("lshift") and 2 or 1))
        if scene.chart.song then
            scene.chart.song:stop()
        end
    end
end

function scene.keypressed(k)
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
        scene.chart = Chart:new(songPath,songBpm,{},{})
        scene.chart:save("editor_chart.json")
    end
    if k == "f9" then
        if love.keyboard.isDown("lshift") then
            Autoplay = true
        else
            Autoplay = false
        end
        scene.chart:recalculateCharge()
        scene.chart.time = TimeBPM(-16,scene.chart.bpm)
        SceneManager.LoadScene("scenes/game", {chart = scene.chart})
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
        drawLine(TimeBPM(i*4+0-0.5+math.floor(scene.chart.time/t/4)*4,scene.chart.bpm),scene.chart.time,scene.speed,8)
        drawLine(TimeBPM(i*4+1-0.5+math.floor(scene.chart.time/t/4)*4,scene.chart.bpm),scene.chart.time,scene.speed,9)
        drawLine(TimeBPM(i*4+2-0.5+math.floor(scene.chart.time/t/4)*4,scene.chart.bpm),scene.chart.time,scene.speed,9)
        drawLine(TimeBPM(i*4+3-0.5+math.floor(scene.chart.time/t/4)*4,scene.chart.bpm),scene.chart.time,scene.speed,9)
    end

    for _,note in ipairs(scene.chart.notes) do
        local t = NoteTypes[note.type]
        if t and type(t.draw) == "function" then
            t.draw(note,scene.chart.time,scene.speed,chartPos,chartHeight)
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
            local time = -((y+8)/16-chartPos-chartHeight)/scene.speed+scene.chart.time
            local bpmTime = TimeBPM(1,scene.chart.bpm)
            time = math.floor(time/bpmTime + 0.5)*bpmTime
            NoteTypes.normal.draw({time=time,lane=lane,length=0,type="normal",extra={}}, scene.chart.time, scene.speed,chartPos,chartHeight)
        end
    end

    -- Mouse pointer
    love.graphics.setColor(TerminalColors[16])
    love.graphics.print("○", MouseX-4, MouseY-8)
end

return scene