local scene = {}

local utf8 = require "utf8"

function utf8.sub(txt, i, j)
    local o1 = (utf8.offset(txt,i) or (#txt))-1
    local o2 = (utf8.offset(txt,j+1) or (#txt+1))-1
    return txt:sub(o1,o2)
end

local icons = {}
for _,icon in ipairs(love.filesystem.getDirectoryItems("images/profile")) do
    if icon:sub(1,4) == "icon" then
        table.insert(icons, icon:sub(1,-5))
    end
end

function scene.load(args)
    scene.destination = args.destination
    scene.transition = args.transition
    scene.set = args.set
    scene.quitOnFail = args.quitOnFail

    scene.state = args.minState or 0
    scene.minState = args.minState or 0

    scene.name = args.name or ""
    scene.icon = args.icon or 1
    if type(scene.icon) == "string" then
        scene.icon = table.index(icons, scene.icon) or 1
    end
    scene.mainColor = args.mainColor or ColorID.LIGHT_RED
    scene.accentColor = args.accentColor or ColorID.BLUE

    scene.iconSetupPointer = 0
    scene.iconSelectingType = 0
    scene.iconSelection = 0
    scene.iconSelectionView = 0
    scene.iconSelectionViewTarget = 0
    scene.colorSelectionX = 0
    scene.colorSelectionY = 0

    love.keyboard.setKeyRepeat(true)
end

function scene.keypressed(k)
    if scene.state == 0 then
        if k == "backspace" then
            local offset = utf8.offset(scene.name, -1)
            if offset then
                scene.name = scene.name:sub(1, offset-1)
            end
        end
        if k == "return" then
            scene.state = scene.state + 1
        end
        if k == "escape" then
            scene.state = scene.state - 1
        end
        if scene.state < scene.minState then
            SceneManager[scene.transition and "Transition" or "LoadScene"]("scenes/"..scene.destination, {profileSetupFailed = true})
            if scene.quitOnFail then
                love.event.push("quit")
            end
            return
        end
        return
    end
    if scene.state == 1 then
        if scene.iconSelectingType == 0 then
            if k == "right" then
                scene.iconSetupPointer = (scene.iconSetupPointer + 1) % 4
            end
            if k == "left" then
                scene.iconSetupPointer = (scene.iconSetupPointer - 1) % 4
            end
            if k == "return" then
                if scene.iconSetupPointer == 3 then
                    local current = Save.Profile
                    Save.SetProfile(scene.name)
                    Save.Write("icon", icons[scene.icon])
                    Save.Write("main_color", scene.mainColor)
                    Save.Write("accent_color", scene.accentColor)
                    if not scene.set then Save.SetProfile(current) end
                    SceneManager[scene.transition and "Transition" or "LoadScene"]("scenes/"..scene.destination, {profileSetupFailed = false})
                    return
                end
                scene.iconSelectingType = scene.iconSetupPointer + 1
                if scene.iconSelectingType == 1 then
                    scene.iconSelection = scene.icon - 1
                    scene.iconSelectionView = scene.iconSelection
                    scene.iconSelectionViewTarget = scene.iconSelection
                else
                    local col = scene.mainColor
                    if scene.iconSelectingType == 3 then
                        col = scene.accentColor
                    end
                    col = col - 1
                    scene.colorSelectionX = col % 4
                    scene.colorSelectionY = math.floor(col / 4)
                end
            end
            if k == "escape" then
                scene.state = scene.state - 1
            end
            if scene.state < scene.minState then
                SceneManager[scene.transition and "Transition" or "LoadScene"]("scenes/"..scene.destination, {profileSetupFailed = true})
                if scene.quitOnFail then
                    love.event.push("quit")
                end
                return
            end
            return
        end
        if scene.iconSelectingType == 1 then
            if k == "up" then
                scene.iconSelection = (scene.iconSelection-1) % #icons
                scene.iconSelectionViewTarget = scene.iconSelection
            end
            if k == "down" then
                scene.iconSelection = (scene.iconSelection+1) % #icons
                scene.iconSelectionViewTarget = scene.iconSelection
            end
            if k == "return" then
                scene.icon = scene.iconSelection+1
                scene.iconSelectingType = 0
            end
            if k == "escape" then
                scene.iconSelectingType = 0
            end
            return
        end
        if scene.iconSelectingType > 1 then
            if k == "right" then
                scene.colorSelectionX = (scene.colorSelectionX + 1) % 4
            end
            if k == "left" then
                scene.colorSelectionX = (scene.colorSelectionX - 1) % 4
            end
            if k == "down" then
                scene.colorSelectionY = (scene.colorSelectionY + 1) % 4
            end
            if k == "up" then
                scene.colorSelectionY = (scene.colorSelectionY - 1) % 4
            end
            if k == "return" then
                if scene.iconSelectingType == 2 then
                    scene.mainColor = scene.colorSelectionX+scene.colorSelectionY*4+1
                else
                    scene.accentColor = scene.colorSelectionX+scene.colorSelectionY*4+1
                end
                scene.iconSelectingType = 0
            end
            if k == "escape" then
                scene.iconSelectingType = 0
            end
            return
        end
    end
end

function scene.textinput(t)
    if scene.state == 0 then
        scene.name = utf8.sub(scene.name .. t, 1, 20)
    end
end

function scene.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    scene.iconSelectionView = blend*(scene.iconSelectionView-scene.iconSelectionViewTarget)+scene.iconSelectionViewTarget
    if math.abs(scene.iconSelectionViewTarget-scene.iconSelectionView) <= 8/128 then
        scene.iconSelectionView = scene.iconSelectionViewTarget
    end
end

function scene.draw()
    if scene.state == 0 then
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        DrawBoxHalfWidth(26, 12.5, 26, 3)
        love.graphics.printf("TYPE YOUR PROFILE'S NAME", 0, 216, 640, "center")
        love.graphics.printf(scene.name, 0, 248, 640, "center")
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        love.graphics.print("█", 320+(utf8.len(scene.name)*8)/2, 248)
        love.graphics.line(320-12*8, 264, 320+12*8, 264)
    end
    if scene.state == 1 then
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        DrawBoxHalfWidth(21, 11, 36, 8)
        love.graphics.printf("PROFILE ICON", 0, 192, 640, "center")
        love.graphics.setColor(TerminalColors[scene.iconSetupPointer == 0 and ColorID.WHITE or ColorID.DARK_GRAY])
        DrawBoxHalfWidth(28-5, 14, 8, 4)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        do
            local icon = Assets.ProfileIcon(icons[scene.icon])
            if icon then
                ProfileIconShader:send("color1", TerminalColors[scene.mainColor or ColorID.LIGHT_RED])
                ProfileIconShader:send("color2", TerminalColors[scene.accentColor or ColorID.LIGHT_BLUE])
                love.graphics.setShader(ProfileIconShader)
                love.graphics.draw(icon, 320-32-8-16-5*8, 240+32, 0, 2, 2, 16, 16)
                love.graphics.setShader()
            end
        end
        love.graphics.setColor(TerminalColors[scene.iconSetupPointer == 1 and ColorID.WHITE or ColorID.DARK_GRAY])
        DrawBoxHalfWidth(39-5, 15.5, 3, 1)
        love.graphics.setColor(TerminalColors[scene.mainColor or ColorID.LIGHT_RED])
        love.graphics.rectangle("fill", 336+4-16-5*8, 264, 16, 16)
        love.graphics.setColor(TerminalColors[scene.iconSetupPointer == 2 and ColorID.WHITE or ColorID.DARK_GRAY])
        DrawBoxHalfWidth(39-5+6, 15.5, 3, 1)
        love.graphics.setColor(TerminalColors[scene.accentColor or ColorID.BLUE])
        love.graphics.rectangle("fill", 336+4+48-16-5*8, 264, 16, 16)
        love.graphics.setColor(TerminalColors[scene.iconSetupPointer == 3 and ColorID.WHITE or ColorID.DARK_GRAY])
        DrawBoxHalfWidth(51-5, 15.5, 9, 1)
        love.graphics.print("CONFIRM", 424-5*8, 264)

        if scene.iconSelectingType == 1 then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            DrawBoxHalfWidth(28-5, 0, 8, 40)
            for i,name in ipairs(icons) do
                local icon = Assets.ProfileIcon(name)
                if icon then
                    ProfileIconShader:send("color1", TerminalColors[scene.mainColor or ColorID.LIGHT_RED])
                    ProfileIconShader:send("color2", TerminalColors[scene.accentColor or ColorID.LIGHT_BLUE])
                    love.graphics.setShader(ProfileIconShader)
                    love.graphics.draw(icon, 320-32-8-16-5*8, 240+32+(i-(scene.iconSelectionView+1))*96, 0, 2, 2, 16, 16)
                    love.graphics.setShader()
                end
            end
            love.graphics.print("├────────┤", 224-5*8, 224)
            love.graphics.print("├────────┤", 224-5*8, 304)
        end
        if scene.iconSelectingType > 1 then
            local ox = scene.iconSelectingType == 2 and 0 or 6
            
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            DrawBoxHalfWidth(39-5-10+ox, 10, 23, 12)
            for y = 0, 3 do
                for x = 0, 3 do
                    local bx,by = (39-5-10+ox+(x*6)+2.5)*8, (10+(y*3)+2)*16
                    love.graphics.setColor(TerminalColors[(scene.colorSelectionX == x and scene.colorSelectionY == y) and ColorID.WHITE or ColorID.DARK_GRAY])
                    DrawBoxHalfWidth(39-5-10+ox+(x*6)+1, 10+(y*3)+1, 3, 1)
                    love.graphics.setColor(TerminalColors[x+y*4+1])
                    love.graphics.rectangle("fill", bx, by, 16, 16)
                end
            end
        end
        -- love.graphics.rectangle("fill", 336+32, 264, 16, 16)
    end
end

function scene.unload()
    love.keyboard.setKeyRepeat(false)
end

return scene