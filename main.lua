love.graphics.setDefaultFilter("nearest", "nearest")

function table.index(t,v)
    for k,n in pairs(t) do
        if n == v then
            return k
        end
    end
    return nil
end

require "assets"
defaultCovers = {
    love.graphics.newImage("images/cover/default0.png"),
    love.graphics.newImage("images/cover/default1.png"),
    love.graphics.newImage("images/cover/default2.png"),
    love.graphics.newImage("images/cover/default3.png"),
    love.graphics.newImage("images/cover/default4.png"),
    love.graphics.newImage("images/cover/default5.png")
}
require "util"
require "colors"
require "chart"
require "songdisk"
require "input"
require "save"
json = require "json"
texture = require "texture"

SongDisk.Retrieve()

Version = (require "version")()

ChargeYield = 200
XChargeYield = 50
TimingWindow = 0.2
OverchargeWindow = 0.125

EffectTimescale = 1
WindowFocused = true

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
            love.graphics.setColor(TerminalColors[ColorID.YELLOW])
            local txt = "SURGE"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        sampleColor = function() return ColorID.YELLOW end,
        min = 0.8,
        max = 0.9
    },
    {
        draw = function(ox,oy,center)
            love.graphics.setColor(TerminalColors[ColorID.GOLD])
            local txt = "AMP"
            love.graphics.print(txt, ox+(center and (-(#txt)/2) or 0)*8, oy)
        end,
        sampleColor = function() return ColorID.GOLD end,
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
        plus = 0.92
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

Font = love.graphics.newImageFont("images/font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%()[].,'\"!?/:+-_=┌─┐│└┘├┤┴┬┼█▓▒░┊┈╬○◇▷◁║¤👑▧▥▨◐◑◻☓⚠🡙ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρσςτυφχψω🮰✨�Ħ🔗ⒶⒷⓍⓎⓛⓡⓁⓇⓑⓢ⮜⮞⮝⮟⒧⒭ⓧⓄⓈⓉⓞⓗⓥⓕⓜⓟ➀➁")

NoteFontOptions = {"dots"}

NoteFonts = {
    dots = love.graphics.newImageFont("images/notes/default.png", "○◇▷◁║▧▥▨◐◑◻◼☓⚠┊")
}

NoteFont = NoteFonts.dots

function DrawBox(x,y,w,h)
    love.graphics.print("┌"..("──"):rep(w).."┐\n"..("│"..("  "):rep(w).."│\n"):rep(h).."└"..("──"):rep(w).."┘", x*8, y*16)
end

function DrawFilledBox(x,y,w,h)
    love.graphics.print("█"..("██"):rep(w).."█\n"..("█"..("██"):rep(w).."█\n"):rep(h).."█"..("██"):rep(w).."█", x*8, y*16)
end

function DrawBoxHalfWidth(x,y,w,h)
    love.graphics.print("┌"..("─"):rep(w).."┐\n"..("│"..(" "):rep(w).."│\n"):rep(h).."└"..("─"):rep(w).."┘", x*8, y*16)
end

require "transition"
require "scenemanager"

function EnterMainGame(transition)
    SceneManager[transition and "Transition" or "LoadScene"]("scenes/startup")
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

BorderOptions = {"none", "overcharged"}

Borders = {
    none = nil,
    overcharged = require("borders.overcharged")
}

-- border = nil

SystemSettings = {
    master_volume = 0.5,
    song_volume = 0.75,
    sound_volume = 1,
    audio_offset = 0,
    enable_chart_effects = true,
    enable_screen_effects = true,
    pause_on_lost_focus = true,
    show_fps = false,
    screen_effects = {
        screen_curvature = 0.5,
        scanlines = 0.5,
        chromatic_aberration = 1,
        bloom = 1,
        saturation = 1
    }
}

if love.filesystem.getInfo("settings.json") then
    local s,r = pcall(json.decode, love.filesystem.read("settings.json"))
    if s then
        table.merge(SystemSettings, r)
    end
end

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

GameDisplay = love.graphics.newCanvas(640,480)

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

ScreenShader = love.graphics.newShader("shaders/screen.frag")
ScreenShader:send("curveStrength", SystemSettings.screen_effects.screen_curvature*CurveModifier)
ScreenShader:send("scanlineStrength", 1-SystemSettings.screen_effects.scanlines)
ScreenShader:send("texSize", {Display:getDimensions()})
ScreenShader:send("tearStrength", 0)
ScreenShader:send("chromaticStrength", SystemSettings.screen_effects.chromatic_aberration*ChromaticModifier)
ScreenShader:send("horizBlurStrength", 0.5)
ScreenShader:send("tearTime", love.timer.getTime())
ScreenShader:send("saturation", SystemSettings.screen_effects.saturation)

BloomShader = love.graphics.newShader("shaders/bloom.frag")
BloomShader:send("strength", 2)

ProfileIconShader = love.graphics.newShader("shaders/profile_icon.frag")

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

GamepadLastAxes = {}
GamepadAxes = {}

local gamepads = 0
HasGamepad = false

KeyMap = {
    key = {
        escape = "ESC",
        ["return"] = "ENTER",
        ralt = "R.ALT",
        lalt = "L.ALT",
        rshift = "R.SHIFT",
        lshift = "L.SHIFT",
        rctrl = "R.CONTROL",
        lctrl = "L.CONTROL"
    },
    gbutton = {
        a = {[0x054CFFFF] = "ⓧ", [0xFFFFFFFF] = "Ⓐ"},
        b = {[0x054CFFFF] = "Ⓞ", [0xFFFFFFFF] = "Ⓑ"},
        x = {[0x057E0306] = "➀", [0x054CFFFF] = "Ⓢ", [0xFFFFFFFF] = "Ⓧ"},
        y = {[0x057E0306] = "➁", [0x054CFFFF] = "Ⓣ", [0xFFFFFFFF] = "Ⓨ"},
        leftshoulder = "ⓛ",
        rightshoulder = "ⓡ",
        leftstick = "Ⓛ",
        rightstick = "Ⓡ",
        back  = {[0x057EFFFF] = "ⓜ", [0x054CFFFF] = "ⓗ", [0x045E028E] = "ⓑ", [0x045E0291] = "ⓑ", [0x045E02A0] = "ⓑ", [0x045E02A1] = "ⓑ", [0x045E0719] = "ⓑ", [0x045EFFFF] = "ⓥ", [0xFFFFFFFF] = "ⓑ"},
        start = {[0x057EFFFF] = "ⓟ", [0x054CFFFF] = "ⓞ", [0x045E028E] = "ⓕ", [0x045E0291] = "ⓕ", [0x045E02A0] = "ⓕ", [0x045E02A1] = "ⓕ", [0x045E0719] = "ⓕ", [0xFFFFFFFF] = "ⓢ"},
        dpleft = "⮜",
        dpright = "⮞",
        dpup = "⮝",
        dpdown = "⮟"
    },
    gtrigger = {
        triggerleft = "⒧",
        triggerright = "⒭",
        leftx = "LEFT STICK HORIZ.",
        lefty = "LEFT STICK VERT"
    }
}

function KeyLabel(v)
    ---@type love.Joystick
    local stick = love.joystick.getJoysticks()[1]
    local vid,pid = 0xFFFF,0xFFFF
    if stick then
        vid,pid = stick:getDeviceInfo()
    end
    local mapped = KeyMap[v[1]][v[2]] or v[2]
    if type(mapped) == "table" then
        mapped = mapped[vid*65536+pid] or mapped[vid*65536+0xFFFF] or mapped[0xFFFFFFFF] or v[2]
    end
    return mapped:upper()
end

function love.gamepadaxis(stick,axis,value)
    GamepadAxes[axis] = value
    Input.GamepadAxis(stick,axis,value)
    if not SceneManager.GamepadAxis(stick,axis,value) then
        if math.abs(GamepadLastAxes[axis] or 0) < 0.5 and math.abs(value) >= 0.5 then
            if BindContains(Save.Read("keybinds.pause"), "gtrigger", axis) then
                SceneManager.Action("pause")
            end
            if BindContains(Save.Read("keybinds.back"), "gtrigger", axis) then
                SceneManager.Action("back")
            end
            if BindContains(Save.Read("keybinds.confirm"), "gtrigger", axis) then
                SceneManager.Action("confirm")
            end
            if BindContains(Save.Read("keybinds.restart"), "gtrigger", axis) then
                SceneManager.Action("restart")
            end
            if BindContains(Save.Read("keybinds.overvolt"), "gtrigger", axis) then
                SceneManager.Action("overvolt")
            end
            if BindContains(Save.Read("keybinds.show_more"), "gtrigger", axis) then
                SceneManager.Action("show_more")
            end
            if BindContains(Save.Read("keybinds.menu_left"), "gtrigger", axis) then
                SceneManager.Action("left")
            end
            if BindContains(Save.Read("keybinds.menu_right"), "gtrigger", axis) then
                SceneManager.Action("right")
            end
            if BindContains(Save.Read("keybinds.menu_up"), "gtrigger", axis) then
                SceneManager.Action("up")
            end
            if BindContains(Save.Read("keybinds.menu_down"), "gtrigger", axis) then
                SceneManager.Action("down")
            end
            SceneManager.Action("*")
            
            if axis == "leftx" then
                if value > 0 then
                    SceneManager.Action("right")
                else
                    SceneManager.Action("left")
                end
            end
            if axis == "lefty" then
                if value > 0 then
                    SceneManager.Action("down")
                else
                    SceneManager.Action("up")
                end
            end
        end
    end

    GamepadLastAxes[axis] = value
end

function love.gamepadpressed(stick,button)
    Input.GamepadPressed(stick,button)
    if SceneManager.GamepadPressed(stick,button) then return end

    if BindContains(Save.Read("keybinds.pause"), "gbutton", button) then
        SceneManager.Action("pause")
    end
    if BindContains(Save.Read("keybinds.back"), "gbutton", button) then
        SceneManager.Action("back")
    end
    if BindContains(Save.Read("keybinds.confirm"), "gbutton", button) then
        SceneManager.Action("confirm")
    end
    if BindContains(Save.Read("keybinds.restart"), "gbutton", button) then
        SceneManager.Action("restart")
    end
    if BindContains(Save.Read("keybinds.overvolt"), "gbutton", button) then
        SceneManager.Action("overvolt")
    end
    if BindContains(Save.Read("keybinds.show_more"), "gbutton", button) then
        SceneManager.Action("show_more")
    end
    if BindContains(Save.Read("keybinds.menu_left"), "gbutton", button) then
        SceneManager.Action("left")
    end
    if BindContains(Save.Read("keybinds.menu_right"), "gbutton", button) then
        SceneManager.Action("right")
    end
    if BindContains(Save.Read("keybinds.menu_up"), "gbutton", button) then
        SceneManager.Action("up")
    end
    if BindContains(Save.Read("keybinds.menu_down"), "gbutton", button) then
        SceneManager.Action("down")
    end
    SceneManager.Action("*")
end

function love.gamepadreleased(stick,button)
    Input.GamepadReleased(stick,button)
    SceneManager.GamepadReleased(stick,button)
end

function love.filedropped(file)
    SceneManager.FileDropped(file)
end

function love.directorydropped(file)
    SceneManager.DirectoryDropped(file)
end

function love.keypressed(k)
    if k == "f1" then
        SystemSettings.enable_screen_effects = not SystemSettings.enable_screen_effects
    end
    if k == "f2" then
        local date = os.date("*t")
        local yr = date.year
        local mo = ("0"):rep(2-#tostring(date.month))..date.month
        local dy = ("0"):rep(2-#tostring(date.day))..date.day
        local hr = ("0"):rep(2-#tostring(date.hour))..date.hour
        local mn = ("0"):rep(2-#tostring(date.min))..date.min
        local sc = ("0"):rep(2-#tostring(date.sec))..date.sec
        local name = "screenshot-" .. yr..mo..dy.."-"..hr..mn..sc
        local num
        while love.filesystem.getInfo(name..(num or "")..".png") do
            num = (num or 0) + 1
        end
        love.graphics.captureScreenshot(name..(num or "")..".png")
    end
    if k == "f5" then
        love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
    end
    if k == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end

    Input.KeyPressed(k)
    if SceneManager.KeyPressed(k) then return end

    if BindContains(Save.Read("keybinds.pause"), "key", k) then
        SceneManager.Action("pause")
    end
    if BindContains(Save.Read("keybinds.back"), "key", k) then
        SceneManager.Action("back")
    end
    if BindContains(Save.Read("keybinds.confirm"), "key", k) then
        SceneManager.Action("confirm")
    end
    if BindContains(Save.Read("keybinds.restart"), "key", k) then
        SceneManager.Action("restart")
    end
    if BindContains(Save.Read("keybinds.overvolt"), "key", k) then
        SceneManager.Action("overvolt")
    end
    if BindContains(Save.Read("keybinds.show_more"), "key", k) then
        SceneManager.Action("show_more")
    end
    if BindContains(Save.Read("keybinds.menu_left"), "key", k) then
        SceneManager.Action("left")
    end
    if BindContains(Save.Read("keybinds.menu_right"), "key", k) then
        SceneManager.Action("right")
    end
    if BindContains(Save.Read("keybinds.menu_up"), "key", k) then
        SceneManager.Action("up")
    end
    if BindContains(Save.Read("keybinds.menu_down"), "key", k) then
        SceneManager.Action("down")
    end
    SceneManager.Action("*")
end

function love.keyreleased(k)
    Input.KeyReleased(k)
    SceneManager.KeyReleased(k)
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
Anaglyph = love.graphics.newShader("shaders/anaglyph.frag")
Anaglyph:send("left", Display2)
AnaglyphSide = 0
AnaglyphOn = false

function love.update(dt)
    HasGamepad = false
    for _,joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            HasGamepad = true
        end
    end
    love.audio.setVolume(SystemSettings.master_volume)
    
    local border = Borders[Save.Read("border")]
    if border and border.update then border.update(dt) end

    do
        if CurveModifierSmoothing == 0 then
            CurveModifier = CurveModifierTarget
        else
            local blend = math.pow(1/CurveModifierSmoothing,dt*EffectTimescale)
            CurveModifier = blend*(CurveModifier-CurveModifierTarget)+CurveModifierTarget
        end
    end
    do
        if ChromaticModifierSmoothing == 0 then
            ChromaticModifier = ChromaticModifierTarget
        else
            local blend = math.pow(1/ChromaticModifierSmoothing,dt*EffectTimescale)
            ChromaticModifier = blend*(ChromaticModifier-ChromaticModifierTarget)+ChromaticModifierTarget
        end
    end
    do
        if TearingModifierSmoothing == 0 then
            TearingModifier = TearingModifierTarget
        else
            local blend = math.pow(1/TearingModifierSmoothing,dt*EffectTimescale)
            TearingModifier = blend*(TearingModifier-TearingModifierTarget)+TearingModifierTarget
        end
    end
    do
        if BloomStrengthModifierSmoothing == 0 then
            BloomStrengthModifier = BloomStrengthModifierTarget
        else
            local blend = math.pow(1/BloomStrengthModifierSmoothing,dt*EffectTimescale)
            BloomStrengthModifier = blend*(BloomStrengthModifier-BloomStrengthModifierTarget)+BloomStrengthModifierTarget
        end
    end
    
    MissTime = math.max(0,MissTime - dt * 8 * EffectTimescale)
    
    ScreenShader:send("curveStrength", SystemSettings.screen_effects.screen_curvature*CurveModifier)
    ScreenShader:send("scanlineStrength", 1-SystemSettings.screen_effects.scanlines)
    ScreenShader:send("tearStrength", TearingStrength*(MissTime*2/Display:getWidth() + TearingModifier))
    ScreenShader:send("chromaticStrength", SystemSettings.screen_effects.chromatic_aberration * ChromaticModifier)
    ScreenShader:send("horizBlurStrength", 0.5)
    ScreenShader:send("tearTime", love.timer.getTime())
    ScreenShader:send("saturation", SystemSettings.screen_effects.saturation)

    BloomShader:send("strength", SystemSettings.screen_effects.bloom*BloomStrengthModifier)

    SceneManager.Update(dt)
    SceneManager.UpdateTransition(dt)

    for axis,value in pairs(GamepadAxes) do
        GamepadLastAxes[axis] = value
    end
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
    local border = Borders[Save.Read("border")]
    if border and not SuppressBorder and border.draw then border.draw() end
    love.graphics.setColor(1,1,1)
    love.graphics.print(Version.name .. " v" .. Version.version .. (SystemSettings.show_fps and (" - " .. love.timer.getFPS() .. " FPS") or ""), 16, 480-16-16)
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
        if border and not SuppressBorder and border.draw then border.draw() end
        love.graphics.setColor(1,1,1)
        love.graphics.print(Version.name .. " v" .. Version.version .. (SystemSettings.show_fps and (" - " .. love.timer.getFPS() .. " FPS") or ""), 16, 480-16-16)
    
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
    if SystemSettings.enable_screen_effects then love.graphics.setShader(ScreenShader) end
    love.graphics.draw(Display, (love.graphics.getWidth()-Display:getWidth()*s)/2, (love.graphics.getHeight()-Display:getHeight()*s)/2, 0, s, s)
    love.graphics.setShader()
    love.graphics.setCanvas()

    if SystemSettings.enable_screen_effects then
        texture.blur(Final, Partial, Bloom, 8, true)
        texture.blur(Final, Partial, Bloom, 8, true)
        love.graphics.setShader(BloomShader)
        BloomShader:send("blurred", Bloom)
    end
    love.graphics.draw(Final)
    love.graphics.setShader()
end

function love.focus(f)
    WindowFocused = f
    SceneManager.Focus(f)
end

function love.quit()
    Save.Flush()
    love.filesystem.write("settings.json", json.encode(SystemSettings))
end

love.errorhandler = require "errorhandler"