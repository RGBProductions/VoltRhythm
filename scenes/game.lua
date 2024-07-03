local scene = {}

function scene.load(args)
    if args.chart then
        scene.chart = args.chart
    else
        scene.chart = require "unst" -- TEMPORARY, TO REPLACE WITH JSON LATER
    end
    scene.speed = 25
    scene.chartName = "UNRAVELING STASIS"
    Charge = 0
    Hits = 0
    Accuracy = 0
    scene.lastTime = scene.chart.time
    scene.moveBoxTime = 0
end

function scene.keypressed(k)
    if k == "f8" then
        if scene.chart.song then scene.chart.song:stop() end
        scene.chart.time = 0
        scene.chart:resetAllNotes()
        Charge = 0
        SceneManager.LoadScene("scenes/editor", {chart = scene.chart})
    end
    if not Autoplay then
        for i,note in ipairs(scene.chart.notes) do
            local pos = note.time-scene.chart.time
            if math.abs(pos) <= 0.2 and k == Keybinds[note.lane+1] and not note.destroyed then
                local t = 0.125
                local accuracy = (math.abs(pos)/0.2)
                accuracy = math.max(0,math.min(1,(1/(1-t))*accuracy - ((1/(1-t))-1)))
                Charge = Charge + (1-accuracy)
                Hits = Hits + 1
                Accuracy = Accuracy + (1-accuracy)
                local c = math.floor(Charge/scene.chart.totalCharge*100)
                local x = (16+c/2)*8
                Particles = {}
                for _=1,8 do
                    table.insert(Particles, {x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
                end
                if note.length <= 0 then
                    note.destroyed = true
                else
                    note.holding = true
                    note.heldFor = 0
                end
                HitAmounts[note.lane+1] = 1
                break
            end
        end
    end
end

function scene.update(dt)
    scene.chart.time = scene.chart.time + dt
    if scene.chart.time > 0 then
        if scene.lastTime <= 0 then
            if scene.chart.song then scene.chart.song:play() end
        end
        scene.chart.time = (scene.chart.song ~= nil and scene.chart.song:tell("seconds")) or (scene.chart.time+dt)
    end
    scene.lastTime = scene.lastTime + dt

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
                        if (note.heldFor or 0) <= 0 then Charge = Charge + 1 end
                        local c = math.floor(Charge/scene.chart.totalCharge*100)
                        local x = (16+c/2)*8
                        Particles = {}
                        for _=1,8 do
                            table.insert(Particles, {x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
                        end
                        if note.length <= 0 then
                            note.destroyed = true
                            i = i - 1
                        end
                        HitAmounts[note.lane+1] = 1
                        PressAmounts[note.lane+1] = 1
                    end
                end
                if pos <= 0 then
                    if note.length > 0 then
                        if love.keyboard.isDown(Keybinds[note.lane+1]) or Autoplay then
                            local lastHeldFor = note.heldFor or 0
                            note.heldFor = math.min(note.length, lastHeldFor + dt)
                            Charge = Charge + (note.heldFor-lastHeldFor)
                            HitAmounts[note.lane+1] = 1
                            if note.heldFor >= note.length then
                                note.destroyed = true
                                i = i - 1
                            end
                        end
                    end
                end
                if pos <= -0.5 then
                    if note.length <= 0 then
                        note.destroyed = true
                        i = i - 1
                        Hits = Hits + 1
                        MissTime = 1
                    else
                        if not love.keyboard.isDown(Keybinds[note.lane+1]) then
                            MissTime = 1
                        end
                        if pos <= -0.5-note.length then
                            note.destroyed = true
                            i = i - 1
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
            if pos <= 0 then
                local t = EffectTypes[effect.type]
                if type(t) == "function" then
                    t(effect)
                end
                table.remove(scene.chart.effects, i)
                i = i - 1
            end
            i = i + 1
            num = #scene.chart.effects
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

    MissTime = math.max(0,MissTime - dt * 8)
    ScreenShader:send("tearStrength", MissTime*8/Display:getWidth())
    
    ScreenShader:send("tearTime", love.timer.getTime())

    scene.moveBoxTime = scene.moveBoxTime + dt
    while scene.moveBoxTime >= 1/20 do
        local move = love.math.random(1,#BackgroundBoxes)
        local color = love.math.random(2,8)
        local x1,y1 = love.math.random(0,79),love.math.random(0,29)
        local x2,y2 = math.min(79,x1+love.math.random(2,4)),math.min(29,y1+love.math.random(2,4))
        local x,y,w,h = math.min(x1,x2),math.min(y1,y2),(math.abs(x2-x1)-2)/2,(math.abs(y2-y1)-2)/2
        table.insert(BackgroundBoxes,{x,y,w,h,color})
        table.remove(BackgroundBoxes, move)
        scene.moveBoxTime = scene.moveBoxTime - 1/20
    end

    PressAmounts[1] = math.max(0, math.min(1, PressAmounts[1] + dt*8*((love.keyboard.isDown("d") and not Autoplay) and 1/dt or -1/dt)))
    PressAmounts[2] = math.max(0, math.min(1, PressAmounts[2] + dt*8*((love.keyboard.isDown("f") and not Autoplay) and 1/dt or -1/dt)))
    PressAmounts[3] = math.max(0, math.min(1, PressAmounts[3] + dt*8*((love.keyboard.isDown("j") and not Autoplay) and 1/dt or -1/dt)))
    PressAmounts[4] = math.max(0, math.min(1, PressAmounts[4] + dt*8*((love.keyboard.isDown("k") and not Autoplay) and 1/dt or -1/dt)))
    HitAmounts[1] = math.max(0, math.min(1, HitAmounts[1] - dt*8))
    HitAmounts[2] = math.max(0, math.min(1, HitAmounts[2] - dt*8))
    HitAmounts[3] = math.max(0, math.min(1, HitAmounts[3] - dt*8))
    HitAmounts[4] = math.max(0, math.min(1, HitAmounts[4] - dt*8))
end

function scene.draw()
    for _,box in ipairs(BackgroundBoxes) do
        love.graphics.setColor(TerminalColors[box[5]])
        DrawBox(box[1],box[2],box[3],box[4])
    end
    love.graphics.setColor(TerminalColors[16])
    love.graphics.print("Time " .. scene.chart.time, 50*8, 5*16)
    love.graphics.print("Beat " .. math.floor(WhichSixteenth(scene.chart.time, scene.chart.bpm)/4), 50*8, 6*16)
    love.graphics.print("Sixteenth " .. math.floor(WhichSixteenth(scene.chart.time, scene.chart.bpm)), 50*8, 7*16)
    love.graphics.print("BPM " .. scene.chart.bpm, 50*8, 8*16)
    DrawBoxHalfWidth(32, 4, 15, 16)
    DrawBoxHalfWidth(15, 23, 50, 1)
    love.graphics.print("┌─" .. ("─"):rep(#scene.chartName) .. "─┐\n│ " .. scene.chartName .. " │\n└─" .. ("─"):rep(#scene.chartName) .. "─┘", ((80-(#scene.chartName+3))/2)*8, 1*16)
    if Autoplay then love.graphics.print("┬──────────┬\n│ AUTOPLAY │\n┴──────────┴", 34*8, 21*16) end
    local acc = math.floor(Accuracy/math.max(Hits,1)*100)
    love.graphics.print("┬──────────┬\n│ ACC " .. (" "):rep(3-#tostring(acc))..acc.. "% │\n└──────────┘", 34*8, 25*16)
    love.graphics.print("┌──────────┐\n│  CHARGE  │\n├──────────┴", 15*8, 21*16)
    local c = math.floor(Charge/scene.chart.totalCharge*100)
    love.graphics.print(" ", 63*8, 22*16)
    love.graphics.print("┌──────────┐\n│  " .. (" "):rep(5-#tostring(math.floor(c/100*ChargeYield))) .. math.floor(c/100*ChargeYield) .."¤  │\n┴──────────┤", 55*8, 21*16)
    love.graphics.print("┬\n\n┴", 56*8, 23*16)
    love.graphics.setColor(TerminalColors[(c < 40 and 5) or (c < 80 and 15) or 11])
    love.graphics.print(("█"):rep(math.min(41,c/2)), 16*8, 24*16)
    for i = 1, math.min(10,math.max(0,c/2-41)) do
        local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
        love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
        love.graphics.print("█", (56+i)*8, 24*16)
    end
    love.graphics.setColor(TerminalColors[9])
    love.graphics.print(("   ┊\n"):rep(13).."┈┈┈╬┈┈┈\n"..("   ┊\n"):rep(2), 33*8, 5*16)
    love.graphics.print(("   ┊\n"):rep(13).."┈┈┈╬┈┈┈\n"..("   ┊\n"):rep(2), 37*8, 5*16)
    love.graphics.print(("   ┊\n"):rep(13).."┈┈┈╬┈┈┈\n"..("   ┊\n"):rep(2), 41*8, 5*16)
    love.graphics.setColor(TerminalColors[NoteColors[1][math.ceil(PressAmounts[1]+HitAmounts[1]*2)+1]])
    love.graphics.print("███", 33*8, 19*16)
    love.graphics.setColor(TerminalColors[NoteColors[2][math.ceil(PressAmounts[2]+HitAmounts[2]*2)+1]])
    love.graphics.print("███", 37*8, 19*16)
    love.graphics.setColor(TerminalColors[NoteColors[3][math.ceil(PressAmounts[3]+HitAmounts[3]*2)+1]])
    love.graphics.print("███", 41*8, 19*16)
    love.graphics.setColor(TerminalColors[NoteColors[4][math.ceil(PressAmounts[4]+HitAmounts[4]*2)+1]])
    love.graphics.print("███", 45*8, 19*16)

    for _,note in ipairs(scene.chart.notes) do
        if not note.destroyed then
            local t = NoteTypes[note.type]
            if t and type(t.draw) == "function" then
                t.draw(note,scene.chart.time,scene.speed)
            end
        end
    end

    for _,particle in ipairs(Particles) do
        love.graphics.setColor(TerminalColors[particle.color])
        love.graphics.print(particle.char, particle.x-4, particle.y-8)
    end
end

return scene