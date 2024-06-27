require "colors"
require "chart"
texture = require "texture"

function TimeBPM(t,bpm)
    local secPerSixteenth = 15/bpm
    return secPerSixteenth*t
end

function WhichSixteenth(t,bpm)
    local secPerSixteenth = 15/bpm
    return t/secPerSixteenth
end

Font = love.graphics.newImageFont("font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%.┌─┐│└┘├┤┴┬█▓▒░┊┈╬○◇▷◁║¤")

function DrawBox(x,y,w,h)
    love.graphics.print("┌"..("──"):rep(w).."┐\n"..("│"..("  "):rep(w).."│\n"):rep(h).."└"..("──"):rep(w).."┘", x*8, y*16)
end

function DrawFilledBox(x,y,w,h)
    love.graphics.print("█"..("██"):rep(w).."█\n"..("█"..("██"):rep(w).."█\n"):rep(h).."█"..("██"):rep(w).."█", x*8, y*16)
end

function DrawBoxHalfWidth(x,y,w,h)
    love.graphics.print("┌"..("─"):rep(w).."┐\n"..("│"..(" "):rep(w).."│\n"):rep(h).."└"..("─"):rep(w).."┘", x*8, y*16)
end

Keybinds = {
    "d","f","j","k"
}

Display = love.graphics.newCanvas(640,480)
love.graphics.setLineWidth(1)
love.graphics.setLineStyle("rough")
love.graphics.setFont(Font)

Bloom = love.graphics.newCanvas()
Final = love.graphics.newCanvas()
Partial = love.graphics.newCanvas()

CurveStrength = 0.5
CurveModifier = 1

Chromatic = 0

ScreenShader = love.graphics.newShader("screen.frag")
ScreenShader:send("curveStrength", CurveStrength*CurveModifier)
ScreenShader:send("scanlineStrength", 0.5)
ScreenShader:send("textureSize", {Display:getDimensions()})
ScreenShader:send("tearStrength", 0)
ScreenShader:send("chromaticStrength", Chromatic)
ScreenShader:send("horizBlurStrength", 0.5)
ScreenShader:send("tearTime", love.timer.getTime())

BloomShader = love.graphics.newShader("bloom.frag")
BloomShader:send("strength", 1)

UseShaders = true

function love.resize(w,h)
    Bloom = love.graphics.newCanvas(w,h)
    Final = love.graphics.newCanvas(w,h)
    Partial = love.graphics.newCanvas(w,h)
end

-- unraveling stasis for testing, will be removed later
local chart = require "unst" -- TEMPORARY, TO REPLACE WITH JSON LATER
Speed = 25
ChartName = "UNRAVELING STASIS"

love.math.setRandomSeed(0)
BackgroundBoxes = {}
for _=1,32 do
    local color = love.math.random(2,8)
    local x1,y1 = love.math.random(0,79),love.math.random(0,29)
    local x2,y2 = math.min(79,x1+love.math.random(2,4)),math.min(29,y1+love.math.random(2,4))
    local x,y,w,h = math.min(x1,x2),math.min(y1,y2),(math.abs(x2-x1)-2)/2,(math.abs(y2-y1)-2)/2
    table.insert(BackgroundBoxes,{x,y,w,h,color})
end

Particles = {}

Charge = 0
PressAmounts = {0,0,0,0}
HitAmounts = {0,0,0,0}

MissTime = 0

Autoplay = true

function love.keypressed(k)
    if k == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
    if k == "f1" then
        UseShaders = not UseShaders
    end
    if k == "space" then
        love.graphics.captureScreenshot("lol.png")
    end
    if not Autoplay then
        for i,note in ipairs(chart.notes) do
            local pos = note.time-chart.time
            if math.abs(pos) <= 0.2 and k == Keybinds[note.lane+1] then
                Charge = Charge + 1*(1-(math.abs(pos)/0.2))
                local c = math.floor(Charge/chart.totalCharge*100)
                local x = (16+c/2)*8
                Particles = {}
                for _=1,8 do
                    table.insert(Particles, {x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
                end
                if note.length <= 0 then
                    table.remove(chart.notes, i)
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

MouseX = Display:getWidth()/2
MouseY = Display:getHeight()/2

-- love.mouse.setRelativeMode(true)

function love.mousemoved(x,y,dx,dy)
    local s = math.min(love.graphics.getWidth()/Display:getWidth(), love.graphics.getHeight()/Display:getHeight())
    MouseX = math.max(0,math.min(Display:getWidth(), MouseX + dx/s))
    MouseY = math.max(0,math.min(Display:getHeight(), MouseY + dy/s))
end

local lastTime = chart.time
local moveBoxTime = 0

function love.update(dt)
    chart.time = chart.time + dt
    if chart.time > 0 then
        if lastTime <= 0 then
            chart.song:play()
        end
        chart.time = chart.song:tell("seconds")
    end
    lastTime = lastTime + dt

    do
        local i = 1
        local num = #chart.notes
        while i <= num do
            local note = chart.notes[i]
            local pos = note.time-chart.time
            if Autoplay then
                if pos <= 0 then
                    Charge = Charge + 1
                    local c = math.floor(Charge/chart.totalCharge*100)
                    local x = (16+c/2)*8
                    Particles = {}
                    for _=1,8 do
                        table.insert(Particles, {x = x, y = 24*16+8, vx = love.math.random()*32, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = (c < 80 and ColorID.YELLOW) or (OverchargeColors[love.math.random(1,#OverchargeColors)]), char = "¤"})
                    end
                    if note.length <= 0 then
                        table.remove(chart.notes, i)
                        i = i - 1
                    end
                    HitAmounts[note.lane+1] = 1
                    PressAmounts[note.lane+1] = 1
                end
            end
            if pos <= 0 then
                if note.length > 0 then
                    if love.keyboard.isDown(Keybinds[note.lane+1]) then
                        local lastHeldFor = note.heldFor or 0
                        note.heldFor = math.min(note.length, lastHeldFor + dt)
                        Charge = Charge + (note.heldFor-lastHeldFor)
                        HitAmounts[note.lane+1] = 1
                        if note.heldFor >= note.length then
                            table.remove(chart.notes, i)
                            i = i - 1
                        end
                    else
                        MissTime = 1
                    end
                end
            end
            if pos <= -0.5 then
                if note.length <= 0 then
                    table.remove(chart.notes, i)
                    i = i - 1
                else
                    if not love.keyboard.isDown(Keybinds[note.lane+1]) then
                        MissTime = 1
                    end
                end
                MissTime = 1
            end
            i = i + 1
            num = #chart.notes
        end
    end

    do
        local i = 1
        local num = #chart.effects
        while i <= num do
            local effect = chart.effects[i]
            local pos = effect.time-chart.time
            if pos <= 0 then
                local t = EffectTypes[effect.type]
                if type(t) == "function" then
                    t(effect)
                end
                table.remove(chart.effects, i)
                i = i - 1
            end
            i = i + 1
            num = #chart.effects
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

    moveBoxTime = moveBoxTime + dt
    while moveBoxTime >= 1/20 do
        local move = love.math.random(1,#BackgroundBoxes)
        local color = love.math.random(2,8)
        local x1,y1 = love.math.random(0,79),love.math.random(0,29)
        local x2,y2 = math.min(79,x1+love.math.random(2,4)),math.min(29,y1+love.math.random(2,4))
        local x,y,w,h = math.min(x1,x2),math.min(y1,y2),(math.abs(x2-x1)-2)/2,(math.abs(y2-y1)-2)/2
        table.insert(BackgroundBoxes,{x,y,w,h,color})
        table.remove(BackgroundBoxes, move)
        moveBoxTime = moveBoxTime - 1/20
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

function love.draw()
    love.graphics.setCanvas(Display)
    love.graphics.clear(0,0,0)

    for _,box in ipairs(BackgroundBoxes) do
        love.graphics.setColor(TerminalColors[box[5]])
        DrawBox(box[1],box[2],box[3],box[4])
    end
    love.graphics.setColor(TerminalColors[16])
    love.graphics.print("Time " .. chart.time, 50*8, 5*16)
    love.graphics.print("Beat " .. math.floor(WhichSixteenth(chart.time, chart.bpm)/4), 50*8, 6*16)
    love.graphics.print("Sixteenth " .. math.floor(WhichSixteenth(chart.time, chart.bpm)), 50*8, 7*16)
    love.graphics.print("BPM " .. chart.bpm, 50*8, 8*16)
    DrawBoxHalfWidth(32, 4, 15, 16)
    DrawBoxHalfWidth(15, 23, 50, 1)
    love.graphics.print("┌─" .. ("─"):rep(#ChartName) .. "─┐\n│ " .. ChartName .. " │\n└─" .. ("─"):rep(#ChartName) .. "─┘", ((80-(#ChartName+3))/2)*8, 1*16)
    if Autoplay then love.graphics.print("┬──────────┬\n│ AUTOPLAY │\n┴──────────┴", 34*8, 21*16) end
    love.graphics.print("┌──────────┐\n│  CHARGE  │\n├──────────┴", 15*8, 21*16)
    local c = math.floor(Charge/chart.totalCharge*100)
    love.graphics.print(" ", 63*8, 22*16)
    love.graphics.print("┌──────────┐\n│  " .. (" "):rep(5-#tostring(math.floor(Charge))) .. math.floor(Charge) .."¤  │\n┴──────────┤", 55*8, 21*16)
    love.graphics.print("┬\n\n┴", 56*8, 23*16)
    love.graphics.setColor(TerminalColors[(c < 40 and 5) or (c < 80 and 15) or 11])
    love.graphics.print(("█"):rep(math.min(41,c/2)), 16*8, 24*16)
    for i = 1, math.max(0,c/2-41) do
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

    for _,note in ipairs(chart.notes) do
        local t = NoteTypes[note.type]
        if t and type(t.draw) == "function" then
            t.draw(note,chart.time,Speed)
        end
    end

    for _,particle in ipairs(Particles) do
        love.graphics.setColor(TerminalColors[particle.color])
        love.graphics.print(particle.char, particle.x-4, particle.y-8)
    end

    love.graphics.setColor(TerminalColors[16])
    -- love.graphics.print("▒", MouseX-4, MouseY-8)
    
    love.graphics.setCanvas(Final)
    love.graphics.clear(0,0,0)
    love.graphics.setColor(1,1,1)

    local s = math.min(love.graphics.getWidth()/Display:getWidth(), love.graphics.getHeight()/Display:getHeight())
    if UseShaders then love.graphics.setShader(ScreenShader) end
    love.graphics.draw(Display, (love.graphics.getWidth()-Display:getWidth()*s)/2, (love.graphics.getHeight()-Display:getHeight()*s)/2, 0, s, s)
    love.graphics.setShader()
    love.graphics.setCanvas()

    if UseShaders then
        texture.blur(Final, Partial, Bloom, 8, true)
        texture.blur(Final, Partial, Bloom, 8, true)
        love.graphics.setShader(BloomShader)
        BloomShader:send("blurred", Bloom)
    end
    love.graphics.draw(Final)
    love.graphics.setShader()
end