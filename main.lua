require "colors"
require "chart"
require "save"
json = require "json"
texture = require "texture"

Save.Load()

ChargeYield = 200

function TimeBPM(t,bpm)
    local secPerSixteenth = 15/bpm
    return secPerSixteenth*t
end

function WhichSixteenth(t,bpm)
    local secPerSixteenth = 15/bpm
    return t/secPerSixteenth
end

Font = love.graphics.newImageFont("font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%.+-┌─┐│└┘├┤┴┬█▓▒░┊┈╬○◇▷◁║¤")

function DrawBox(x,y,w,h)
    love.graphics.print("┌"..("──"):rep(w).."┐\n"..("│"..("  "):rep(w).."│\n"):rep(h).."└"..("──"):rep(w).."┘", x*8, y*16)
end

function DrawFilledBox(x,y,w,h)
    love.graphics.print("█"..("██"):rep(w).."█\n"..("█"..("██"):rep(w).."█\n"):rep(h).."█"..("██"):rep(w).."█", x*8, y*16)
end

function DrawBoxHalfWidth(x,y,w,h)
    love.graphics.print("┌"..("─"):rep(w).."┐\n"..("│"..(" "):rep(w).."│\n"):rep(h).."└"..("─"):rep(w).."┘", x*8, y*16)
end

require "scenemanager"

SceneManager.LoadScene("scenes/editor")

Keybinds = {
    [4] = {"d","f","j","k"},
    [8] = {"s","d","f","b","n","j","k","l"}
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

love.mouse.setRelativeMode(true)

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

function RemoveParticlesByID(id)
    local i,n = 1,#Particles
    while i <= n do
        if Particles[i].id == id then
            table.remove(Particles, i)
            i = i - 1
        end
        i = i + 1
        n = #Particles
    end
end

Charge = 0
Accuracy = 0
Hits = 0
PressAmounts = {0,0,0,0,0,0,0,0}
HitAmounts = {0,0,0,0,0,0,0,0}

MissTime = 0

Autoplay = false

function love.keypressed(k)
    if k == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
    if k == "f1" then
        UseShaders = not UseShaders
    end
    if k == "f5" then
        love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
    end

    SceneManager.KeyPressed(k)
end

MouseX = Display:getWidth()/2
MouseY = Display:getHeight()/2

function love.mousemoved(x,y,dx,dy)
    local s = math.min(love.graphics.getWidth()/Display:getWidth(), love.graphics.getHeight()/Display:getHeight())
    local omx,omy = MouseX,MouseY
    MouseX = math.max(0,math.min(Display:getWidth(), MouseX + dx))
    MouseY = math.max(0,math.min(Display:getHeight(), MouseY + dy))
    SceneManager.MouseMoved(MouseX,MouseY,MouseX-omx,MouseY-omy)
end

function love.mousepressed(x,y,b)
    SceneManager.MousePressed(MouseX,MouseY,b)
end

function love.wheelmoved(x,y)
    SceneManager.WheelMoved(x,y)
end

function love.update(dt)
    SceneManager.Update(dt)
end

function love.draw()
    love.graphics.setCanvas(Display)
    love.graphics.clear(0,0,0)

    SceneManager.Draw()

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

function love.quit()
    Save.Flush()
end