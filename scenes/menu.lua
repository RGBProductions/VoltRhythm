local scene = {}

local logo = love.graphics.newImage("images/logo.png")

local options = {
    {"SINGLEPLAYER", "MAIN GAME", love.graphics.newImage("images/menu/sp.png"), function()
        if SongSelectOvervoltMode then
            SongSelectOvervoltMode = false
            SongSelectSelectedSong = 1
            SongSelectSelectedSection = 1
        end
        SceneManager.Transition("scenes/songdiskselect")
    end},
    {"MULTIPLAYER", "PLAY WITH FRIENDS", love.graphics.newImage("images/menu/mp.png"), function()
        SceneManager.Transition("scenes/mpmenu")
    end},
    {"EDITOR", "CREATE CHARTS", love.graphics.newImage("images/menu/edit.png"), function()
        SceneManager.Transition("scenes/neditor")
    end},
    {"PROFILES", "MANAGE USERS", love.graphics.newImage("images/menu/prof.png"), function()
        SceneManager.Transition("scenes/profiles")
    end},
    {"SETTINGS", "CONFIGURE SYSTEM", love.graphics.newImage("images/menu/cfg.png"), function()
        SceneManager.Transition("scenes/settings")
    end},
    {"CALIBRATE", "TEMPORARY SOLUTION", love.graphics.newImage("images/menu/cfg.png"), function()
        SceneManager.Transition("scenes/calibration")
    end},
    {"EXIT", "SHUTDOWN SYSTEM", love.graphics.newImage("images/menu/exit.png"), function()
        love.event.push("quit")
    end}
}

MenuView = MenuView or 0
MenuViewTarget = MenuViewTarget or 0

MenuSelection = MenuSelection or 0

local bg = Assets.Background("boxesbg.lua") or {}

function scene.load()
    bg.init()

    local colorIndexes = Save.Read("note_colors") or {ColorID.LIGHT_RED, ColorID.YELLOW, ColorID.LIGHT_GREEN, ColorID.LIGHT_BLUE}
    NoteColors = {
        ColorTransitionTable[colorIndexes[1]],
        ColorTransitionTable[colorIndexes[2]],
        ColorTransitionTable[colorIndexes[3]],
        ColorTransitionTable[colorIndexes[4]]
    }
end

function scene.update(dt)
    bg.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    MenuView = blend*(MenuView-MenuViewTarget)+MenuViewTarget
    if math.abs(MenuViewTarget-MenuView) <= 8/128 then
        MenuView = MenuViewTarget
    end
    if MenuView < 0 then
        MenuView = MenuView+#options
        MenuViewTarget = MenuViewTarget + #options
    end
    if MenuView > #options then
        MenuView = MenuView-#options
        MenuViewTarget = MenuViewTarget - #options
    end
end

function scene.keypressed(k)
    if SceneManager.TransitioningIn() then return end
    if k == "right" then
        MenuSelection = (MenuSelection + 1) % #options
        MenuViewTarget = MenuViewTarget + 1
    end
    if k == "left" then
        MenuSelection = (MenuSelection - 1) % #options
        MenuViewTarget = MenuViewTarget - 1
    end
    if k == "return" then
        options[MenuSelection+1][4]()
    end
end

local function lerp(a,b,t)
    return t*(b-a)+a
end

function scene.draw()
    bg.draw()
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.draw(logo, 320, 64, 0, 2, 2, logo:getWidth()/2, 0)
    for i = MenuViewTarget-2, MenuViewTarget+2 do
        local option = options[i%#options+1]

        local x = 320+(i-MenuView)*192
        local y = 272

        local I = math.abs(MenuViewTarget-i)
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        if I == 0 then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end

        local width = math.floor(lerp(24, 7, math.abs(MenuView-i)))
        DrawBoxHalfWidth(math.floor(x/8-width/2), y/16-1, width, 3)
        if width > 8 then
            love.graphics.print("┬\n│\n│\n│\n┴", math.floor(x/8-width/2 + 8)*8, y-16)
        end
        if I < 2 then
            love.graphics.draw(option[3], math.floor(x/8-width/2)*8+12, y, 0, math.min(48,math.floor(width)*8)/48, 1)
        end

        if I < 1 then
            local label1 = option[1]
            local _,label2 = Font:getWrap(option[2], 112)
            local _,label1Wrapped = Font:getWrap(label1, (width-10)*8)
            local _,label2Wrapped = Font:getWrap(label2[1], (width-10)*8)
            local _,label3Wrapped = Font:getWrap(label2[2] or "", (width-10)*8)
            love.graphics.printf(label1Wrapped[1], math.floor((x-16)/8)*8, y, 112, "center")
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            love.graphics.printf(label2Wrapped[1], math.floor((x-16)/8)*8, y+16, 112, "center")
            love.graphics.printf(label3Wrapped[1], math.floor((x-16)/8)*8, y+32, 112, "center")
        end
    end

    local x = 320-4-(#options-1)/2*16
    love.graphics.print((" "):rep(#options*2+1), x-8, 352)
    for i = 1, #options do
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        if i == MenuSelection+1 then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end
        love.graphics.print("○", x+(i-1)*16, 352)
    end
    
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    ProfileIconShader:send("color1", TerminalColors[Save.Read("main_color") or ColorID.LIGHT_RED])
    ProfileIconShader:send("color2", TerminalColors[Save.Read("accent_color") or ColorID.BLUE])
    love.graphics.setShader(ProfileIconShader)
    local loginText = "LOGGED IN AS " .. Save.Read("name")
    local icon = Assets.ProfileIcon(Save.Read("icon") or "icon1")
    if icon then
        love.graphics.draw(icon, 320-Font:getWidth(loginText)/2-32+32, 400+8, 0, 1, 1, 16, 16)
    end
    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    love.graphics.printf(loginText, 32, 400, 640, "center")
end

return scene