local scene = {}

local logo = love.graphics.newImage("images/temp_logo.png")

local options = {
    {"SINGLEPLAYER", "PLAY ALONE", love.graphics.newImage("images/menu/sp.png"), function()
        if SongSelectOvervoltMode then
            SongSelectOvervoltMode = false
            SongSelectSelectedSong = 1
            SongSelectSelectedSection = 1
        end
        SceneManager.Transition("scenes/songselect")
    end},
    {"MULTIPLAYER", "PLAY WITH FRIENDS", love.graphics.newImage("images/menu/mp.png"), function()
        SceneManager.Transition("scenes/mpmenu")
    end},
    {"EDITOR", "CREATE CHARTS", love.graphics.newImage("images/menu/edit.png"), function()
        SceneManager.Transition("scenes/neditor", {songData = LoadSongData("songs/worstnightmare"), difficulty = "overvolt"})
    end},
    {"PROFILES", "MANAGE USERS", love.graphics.newImage("images/menu/prof.png"), function()
        SceneManager.Transition("scenes/profiles")
    end},
    {"SETTINGS", "CONFIGURE SYSTEM", love.graphics.newImage("images/menu/cfg.png"), function()
        SceneManager.Transition("scenes/settings")
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
end

function scene.update(dt)
    bg.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    -- local closer = view+math.min(math.abs(selected-view),math.abs((selected+#options)-view),math.abs((selected-#options)-view))
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
    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    love.graphics.printf("LOGGED IN AS " .. Save.Read("name"), 0, 400, 640, "center")
end

return scene