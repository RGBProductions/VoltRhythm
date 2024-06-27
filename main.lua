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

require "scenes.editor"
require "scenes.game"

Scene = GameScene

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
    if Scene and type(Scene.keypressed) == "function" then
        Scene.keypressed(k)
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

function love.update(dt)
    if Scene and type(Scene.update) == "function" then
        Scene.update(dt)
    end
end

function love.draw()
    love.graphics.setCanvas(Display)
    love.graphics.clear(0,0,0)

    if Scene and type(Scene.draw) == "function" then
        Scene.draw()
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