love.graphics.setDefaultFilter("nearest", "nearest")
require "assets"
require "util"
require "colors"
require "chart"
require "save"
json = require "json"
texture = require "texture"

love.audio.setVolume(0.5)

Version = (require "version")()

ChargeYield = 200
XChargeYield = 50
TimingWindow = 0.2
OverchargeWindow = 0.125

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
        sampleColor = function() return OverchargeColors[love.math.random(1,#OverchargeColors)] end,
        min = 0.9,
        max = math.huge
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.GOLD])
            local txt = "SURGE"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        sampleColor = function() return ColorID.GOLD end,
        min = 0.8,
        max = 0.9
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.YELLOW])
            local txt = "AMP"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        sampleColor = function() return ColorID.YELLOW end,
        min = 0.6,
        max = 0.8
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.GREEN])
            local txt = "FLUX"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        sampleColor = function() return ColorID.GREEN end,
        min = 0.4,
        max = 0.6
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            local txt = "NULL"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        sampleColor = function() return ColorID.LIGHT_GRAY end,
        min = 0.15,
        max = 0.4
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.RED])
            local txt = "BREAK"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        sampleColor = function() return ColorID.RED end,
        min = 0,
        max = 0.15
    }
}

Plus = love.graphics.newImage("images/rank/plus.png")

Ranks = {
    {
        image = love.graphics.newImage("images/rank/F.png"),
        charge = 0.3,
        plus = math.huge
    },
    {
        image = love.graphics.newImage("images/rank/D.png"),
        charge = 0.6,
        plus = 0.55
    },
    {
        image = love.graphics.newImage("images/rank/C.png"),
        charge = 0.7,
        plus = 0.65
    },
    {
        image = love.graphics.newImage("images/rank/B.png"),
        charge = 0.8,
        plus = 0.75
    },
    {
        image = love.graphics.newImage("images/rank/A.png"),
        charge = 0.9,
        plus = 0.85
    },
    {
        image = love.graphics.newImage("images/rank/S.png"),
        charge = 0.95,
        plus = 0.925
    },
    {
        image = love.graphics.newImage("images/rank/O.png"),
        charge = math.huge,
        plus = 0.99
    }
}

function GetRank(charge)
    for i,rank in ipairs(Ranks) do
        if charge < rank.charge then
            return i, charge >= rank.plus
        end
    end
    return #Ranks, charge >= Ranks[#Ranks].plus
end

ChargeValues = {
    easy = {
        charge = 0.15,
        xcharge = 0
    },
    medium = {
        charge = 0.3,
        xcharge = 0.1
    },
    hard = {
        charge = 0.5,
        xcharge = 0.1
    },
    extreme = {
        charge = 0.05,
        xcharge = 0.8
    },
    overvolt = {
        charge = 0,
        xcharge = 0
    },
    hidden = {
        charge = 0,
        xcharge = 0
    }
}

function TimeBPM(t,bpm)
    local secPerSixteenth = 15/bpm
    return secPerSixteenth*t
end

function WhichSixteenth(t,bpm)
    local secPerSixteenth = 15/bpm
    return t/secPerSixteenth
end

-- ーあいうえおかきくけこさしすせそたちつてとなにぬねの

-- ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρσςτυφχψω

Cursor = nil
CursorX = 0
CursorY = 0

function SetCursor(cursor,x,y)
    if not Cursor and cursor then
        MouseX = 320
        MouseY = 240
    end
    Cursor = cursor
    CursorX = x or 0
    CursorY = y or 0
end

Font = love.graphics.newImageFont("font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%().,'\"!?/:+-_=┌─┐│└┘├┤┴┬█▓▒░┊┈╬○◇▷◁║¤👑▧▥▨◐◑◻🡙ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρσςτυφχψω🮰✨")
NoteFont = love.graphics.newImageFont("images/notes/default.png", "○◇▷◁║▧▥▨◐◑◻◼☓")

function DrawBox(x,y,w,h)
    love.graphics.print("┌"..("──"):rep(w).."┐\n"..("│"..("  "):rep(w).."│\n"):rep(h).."└"..("──"):rep(w).."┘", x*8, y*16)
end

function DrawFilledBox(x,y,w,h)
    love.graphics.print("█"..("██"):rep(w).."█\n"..("█"..("██"):rep(w).."█\n"):rep(h).."█"..("██"):rep(w).."█", x*8, y*16)
end

function DrawBoxHalfWidth(x,y,w,h)
    love.graphics.print("┌"..("─"):rep(w).."┐\n"..("│"..(" "):rep(w).."│\n"):rep(h).."└"..("─"):rep(w).."┘", x*8, y*16)
end

function table.index(t,v)
    for k,n in pairs(t) do
        if n == v then
            return k
        end
    end
    return nil
end

require "transition"
require "scenemanager"

local loadedProfile = Save.Load()
if not loadedProfile then
    Save.SetProfile("RGB")
end

function EnterMainGame(transition)
    SceneManager[transition and "Transition" or "LoadScene"]("scenes/menu")
end

if love.filesystem.getInfo("hidepswarning") then
    EnterMainGame()
else
    SceneManager.LoadScene("scenes/photosensitivity")
end

-- if loadedProfile then
--     SceneManager.LoadScene("scenes/photosensitivity")
--     -- SceneManager.LoadScene("scenes/profile")
-- else
--     -- SceneManager.LoadScene("scenes/photosensitivity")
--     -- local songData = LoadSongData("songs/cute")
--     -- SceneManager.LoadScene("scenes/game", {songData = songData, difficulty = "hard"})
--     SceneManager.LoadScene("scenes/photosensitivity")
-- end

-- SceneManager.LoadScene("scenes/game", {chart = "songs/cute/hard.json"})

border = require "borders.overcharged"

Keybinds = {
    [4] = {"d","f","j","k"},
    [8] = {"s","d","f","b","n","j","k","l"},
    [12] = {"a","s","d","f","g","h","j","k","l",";","'","return"}
}

Display = love.graphics.newCanvas(640,480)
Display:setFilter("linear", "linear")
Display2 = love.graphics.newCanvas(640,480)
Display2:setFilter("linear", "linear")
love.graphics.setLineWidth(1)
love.graphics.setLineStyle("rough")
love.graphics.setFont(Font)

AnaglyphMerge = love.graphics.newCanvas(640,480)
Bloom = love.graphics.newCanvas()
Final = love.graphics.newCanvas()
Partial = love.graphics.newCanvas()

CurveStrength = 0.5

CurveModifier = 1
CurveModifierTarget = 1
CurveModifierSmoothing = 0

Chromatic = 1
ChromaticModifier = 0
ChromaticModifierTarget = 0
ChromaticModifierSmoothing = 0

TearingStrength = 1
TearingModifier = 0
TearingModifierTarget = 0
TearingModifierSmoothing = 0

BloomStrength = 1
BloomStrengthModifier = 1
BloomStrengthModifierTarget = 1
BloomStrengthModifierSmoothing = 0

ScreenShader = love.graphics.newShader("screen.frag")
ScreenShader:send("curveStrength", CurveStrength*CurveModifier)
ScreenShader:send("scanlineStrength", 0.5)
ScreenShader:send("textureSize", {Display:getDimensions()})
ScreenShader:send("tearStrength", 0)
ScreenShader:send("chromaticStrength", Chromatic*ChromaticModifier)
ScreenShader:send("horizBlurStrength", 0.5)
ScreenShader:send("tearTime", love.timer.getTime())

BloomShader = love.graphics.newShader("bloom.frag")
BloomShader:send("strength", 2)

UseShaders = true

function love.resize(w,h)
    Bloom = love.graphics.newCanvas(w,h)
    Final = love.graphics.newCanvas(w,h)
    Partial = love.graphics.newCanvas(w,h)
end

love.mouse.setRelativeMode(true)

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
Showcase = false

function love.filedropped(file)
    SceneManager.FileDropped(file)
end

function love.directorydropped(file)
    SceneManager.DirectoryDropped(file)
end

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
    if k == "f2" then
        love.graphics.captureScreenshot("screenshot" .. love.math.random(0,999999999) .. ".png")
    end

    SceneManager.KeyPressed(k)
end

function love.textinput(t)
    SceneManager.TextInput(t)
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

function love.mousereleased(x,y,b)
    SceneManager.MouseReleased(MouseX,MouseY,b)
end

function love.wheelmoved(x,y)
    SceneManager.WheelMoved(x,y)
end

AnaglyphL = -4
AnaglyphR = 4
Anaglyph = love.graphics.newShader("anaglyph.frag")
Anaglyph:send("left", Display2)
AnaglyphSide = 0
AnaglyphOn = false

function love.update(dt)
    if border then border.update(dt) end

    do
        if CurveModifierSmoothing == 0 then
            CurveModifier = CurveModifierTarget
        else
            local blend = math.pow(1/CurveModifierSmoothing,dt)
            CurveModifier = blend*(CurveModifier-CurveModifierTarget)+CurveModifierTarget
        end
    end
    do
        if ChromaticModifierSmoothing == 0 then
            ChromaticModifier = ChromaticModifierTarget
        else
            local blend = math.pow(1/ChromaticModifierSmoothing,dt)
            ChromaticModifier = blend*(ChromaticModifier-ChromaticModifierTarget)+ChromaticModifierTarget
        end
    end
    do
        if TearingModifierSmoothing == 0 then
            TearingModifier = TearingModifierTarget
        else
            local blend = math.pow(1/TearingModifierSmoothing,dt)
            TearingModifier = blend*(TearingModifier-TearingModifierTarget)+TearingModifierTarget
        end
    end
    do
        if BloomStrengthModifierSmoothing == 0 then
            BloomStrengthModifier = BloomStrengthModifierTarget
        else
            local blend = math.pow(1/BloomStrengthModifierSmoothing,dt)
            BloomStrengthModifier = blend*(BloomStrengthModifier-BloomStrengthModifierTarget)+BloomStrengthModifierTarget
        end
    end
    
    MissTime = math.max(0,MissTime - dt * 8)
    
    ScreenShader:send("curveStrength", CurveStrength*CurveModifier)
    ScreenShader:send("tearStrength", TearingStrength*(MissTime*2/Display:getWidth() + TearingModifier))
    ScreenShader:send("chromaticStrength", Chromatic * ChromaticModifier)
    ScreenShader:send("horizBlurStrength", 0.5)
    ScreenShader:send("tearTime", love.timer.getTime())

    BloomShader:send("strength", BloomStrength*BloomStrengthModifier)

    SceneManager.Update(dt)
    SceneManager.UpdateTransition(dt)
end

function love.draw()
    AnaglyphSide = 0
    if AnaglyphOn then
        AnaglyphSide = AnaglyphR
    end
    love.graphics.setCanvas(Display)
    love.graphics.clear(0,0,0)

    love.graphics.setColor(1,1,1)
    SceneManager.Draw()
    love.graphics.setColor(1,1,1)
    SceneManager.DrawTransition()
    love.graphics.setColor(1,1,1)
    if border and not SuppressBorder then border.draw() end
    love.graphics.setColor(1,1,1)
    love.graphics.print(Version.name .. " v" .. Version.version, 16, 480-16-16)
    if Cursor then
        love.graphics.print(Cursor, MouseX-CursorX, MouseY-CursorY)
    end

    love.graphics.setColor(TerminalColors[16])
    -- love.graphics.print("▒", MouseX-4, MouseY-8)

    if AnaglyphOn then
        AnaglyphSide = AnaglyphL
        love.graphics.setCanvas(Display2)
        love.graphics.clear(0,0,0)
    
        love.graphics.setColor(1,1,1)
        SceneManager.Draw()
        love.graphics.setColor(1,1,1)
        SceneManager.DrawTransition()
        love.graphics.setColor(1,1,1)
        if border and not SuppressBorder then border.draw() end
        love.graphics.setColor(1,1,1)
        love.graphics.print(Version.name .. " v" .. Version.version, 16, 480-16-16)
    
        love.graphics.setColor(TerminalColors[16])
        love.graphics.setCanvas(AnaglyphMerge)
        love.graphics.setShader(Anaglyph)
        Anaglyph:send("left", Display2)
        love.graphics.draw(Display)
        love.graphics.setCanvas(Display)
        love.graphics.clear(0,0,0)
        love.graphics.draw(AnaglyphMerge)
    end
    
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

function love.focus(f)
    SceneManager.Focus(f)
end

function love.quit()
    Save.Flush()
end

love.errorhandler = require "errorhandler"