local scene = {}

local utf8 = require "utf8"

function utf8.sub(txt, i, j)
    local o1 = (utf8.offset(txt,i) or (#txt))
    local o2 = (utf8.offset(txt,j+1) or (#txt+1))-1
    return txt:sub(o1,o2)
end

local icons = {}
for _,icon in ipairs(love.filesystem.getDirectoryItems("images/profile")) do
    if icon:sub(1,4) == "icon" then
        table.insert(icons, icon:sub(1,-5))
    end
end

local keyboard = {
    pos = {1,1},
    shift = 0, -- 0 = off, 1 = on, 2 = stay on
    -- type 0 = char
    -- type 1 = space
    -- type 2 = shift
    -- type 3 = delete
    -- type 4 = confirm
    keys = {
        {{0,"`","~"},{0,"1","!"},{0,"2","@"},{0,"3","#"},{0,"4","$"},{0,"5","%"},{0,"6","^"},{0,"7","&"},{0,"8","*"},{0,"9","("},{0,"0",")"},{0,"-","_"},{0,"=","+"},{3," "," "},selectOffset={1,0}},
        {{0,"q","Q"},{0,"w","W"},{0,"e","E"},{0,"r","R"},{0,"t","T"},{0,"y","Y"},{0,"u","U"},{0,"i","I"},{0,"o","O"},{0,"p","P"},{0,"[","{"},{0,"]","}"},{0,"\\","|"}},
        {{0,"a","A"},{0,"s","S"},{0,"d","D"},{0,"f","F"},{0,"g","G"},{0,"h","H"},{0,"j","J"},{0,"k","K"},{0,"l","L"},{0,";",":"},{0,"'",'"'},{4," "," "}},
        {{2," "," "},{0,"z","Z"},{0,"x","X"},{0,"c","C"},{0,"v","V"},{0,"b","B"},{0,"n","N"},{0,"m","M"},{0,",","<"},{0,".",">"},{0,"/","?"},{1," "," "},selectOffset={-1,0}}
    }
}
for _,row in ipairs(keyboard.keys) do
    local w = 0
    for _,key in ipairs(row) do
        if key[1] == 0 then
            w = w + 40
        else
            w = w + 64
        end
    end
    row.width = w
end

function scene.load(args)
    scene.destination = args.destination
    scene.transition = args.transition
    scene.set = args.set
    scene.quitOnFail = args.quitOnFail

    scene.frame = 0
    scene.state = args.minState or 0
    scene.minState = args.minState or 0

    scene.name = args.name or ""
    scene.id = args.id
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
    love.keyboard.setTextInput(scene.state == 0)
end

function scene.gamepadpressed(s, b)
    if scene.state == 0 then
        if b == "dpleft" then
            repeat
                keyboard.pos[1] = ((keyboard.pos[1] - 2) % #keyboard.keys[keyboard.pos[2]]) + 1
            until ((keyboard.keys[keyboard.pos[2]] or {})[keyboard.pos[1]] or {0,"",""})[1] > -1
        end
        if b == "dpright" then
            repeat
                keyboard.pos[1] = (keyboard.pos[1] % #keyboard.keys[keyboard.pos[2]]) + 1
            until ((keyboard.keys[keyboard.pos[2]] or {})[keyboard.pos[1]] or {0,"",""})[1] > -1
        end
        if b == "dpup" then
            if keyboard.keys[keyboard.pos[2]].selectOffset then
                keyboard.pos[1] = math.max(1,math.min(#keyboard.keys[keyboard.pos[2]], keyboard.pos[1] - keyboard.keys[keyboard.pos[2]].selectOffset[1]))
                keyboard.pos[2] = keyboard.pos[2] - keyboard.keys[keyboard.pos[2]].selectOffset[2]
            end
            repeat
                keyboard.pos[2] = ((keyboard.pos[2] - 2) % #keyboard.keys) + 1
                keyboard.pos[1] = math.max(1,math.min(#keyboard.keys[keyboard.pos[2]], keyboard.pos[1]))
            until ((keyboard.keys[keyboard.pos[2]] or {})[keyboard.pos[1]] or {0,"",""})[1] > -1
            if keyboard.keys[keyboard.pos[2]].selectOffset then
                keyboard.pos[1] = math.max(1,math.min(#keyboard.keys[keyboard.pos[2]], keyboard.pos[1] + keyboard.keys[keyboard.pos[2]].selectOffset[1]))
                keyboard.pos[2] = keyboard.pos[2] + keyboard.keys[keyboard.pos[2]].selectOffset[2]
            end
        end
        if b == "dpdown" then
            if keyboard.keys[keyboard.pos[2]].selectOffset then
                keyboard.pos[1] = math.max(1,math.min(#keyboard.keys[keyboard.pos[2]], keyboard.pos[1] - keyboard.keys[keyboard.pos[2]].selectOffset[1]))
                keyboard.pos[2] = keyboard.pos[2] - keyboard.keys[keyboard.pos[2]].selectOffset[2]
            end
            repeat
                keyboard.pos[2] = (keyboard.pos[2] % #keyboard.keys) + 1
                keyboard.pos[1] = math.max(1,math.min(#keyboard.keys[keyboard.pos[2]], keyboard.pos[1]))
            until ((keyboard.keys[keyboard.pos[2]] or {})[keyboard.pos[1]] or {0,"",""})[1] > -1
            if keyboard.keys[keyboard.pos[2]].selectOffset then
                keyboard.pos[1] = math.max(1,math.min(#keyboard.keys[keyboard.pos[2]], keyboard.pos[1] + keyboard.keys[keyboard.pos[2]].selectOffset[1]))
                keyboard.pos[2] = keyboard.pos[2] + keyboard.keys[keyboard.pos[2]].selectOffset[2]
            end
        end
    end
    if b == "dpleft" then
        scene.keypressed("left")
    end
    if b == "dpright" then
        scene.keypressed("right")
    end
    if b == "dpup" then
        scene.keypressed("up")
    end
    if b == "dpdown" then
        scene.keypressed("down")
    end
    if b == "a" then
        if scene.state == 0 then
            local key = (keyboard.keys[keyboard.pos[2]] or {})[keyboard.pos[1]] or {0,"",""}
            if key[1] == 0 then
                scene.textinput(keyboard.shift > 0 and key[3] or key[2])
                keyboard.shift = keyboard.shift <= 1 and 0 or 2
            end
            if key[1] == 1 then
                scene.textinput(" ")
                keyboard.shift = keyboard.shift <= 1 and 0 or 2
            end
            if key[1] == 2 then
                keyboard.shift = (keyboard.shift + 1) % 3
            end
            if key[1] == 3 then
                scene.keypressed("backspace")
            end
            if key[1] == 4 then
                scene.keypressed("return")
            end
        else
            scene.keypressed("return")
        end
    end
    if b == "b" then
        if scene.state == 0 then
            scene.keypressed("backspace")
        else
            scene.keypressed("escape")
        end
    end
    if b == "y" then
        if scene.state == 0 then
            keyboard.shift = (keyboard.shift + 1) % 3
        end
    end
    if b == "x" then
        if scene.state == 0 then
            scene.keypressed("space")
        end
    end
    if b == "start" then
        if scene.state == 0 then
            scene.keypressed("return")
        end
    end
    if b == "back" then
        scene.keypressed("escape")
    end
    return true
end

local leftx = 0
local lefty = 0

function scene.gamepadaxis(s, a, v)
    local lx = leftx
    local ly = lefty
    if a == "leftx" then
        leftx = v
    end
    if a == "lefty" then
        lefty = v
    end
    if leftx >= 0.5 and lx < 0.5 then
        scene.gamepadpressed(s, "dpright")
    end
    if leftx <= -0.5 and lx > -0.5 then
        scene.gamepadpressed(s, "dpleft")
    end
    if lefty >= 0.5 and ly < 0.5 then
        scene.gamepadpressed(s, "dpdown")
    end
    if lefty <= -0.5 and ly > -0.5 then
        scene.gamepadpressed(s, "dpup")
    end
    return true
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
            love.keyboard.setTextInput(scene.state == 0)
        end
        if k == "escape" then
            scene.state = scene.state - 1
            love.keyboard.setTextInput(scene.state == 0)
        end
        if scene.state < scene.minState then
            SceneManager[scene.transition and "Transition" or "LoadScene"]("scenes/"..scene.destination, {profileSetupFailed = true})
            if scene.quitOnFail then
                love.event.push("quit")
            end
            return true
        end
        return true
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
                    Save.SetProfile(scene.id or scene.name)
                    Save.Write("name", scene.name)
                    Save.Write("icon", icons[scene.icon])
                    Save.Write("main_color", scene.mainColor)
                    Save.Write("accent_color", scene.accentColor)
                    if not scene.set then Save.SetProfile(current) end
                    SceneManager[scene.transition and "Transition" or "LoadScene"]("scenes/"..scene.destination, {profileSetupFailed = false})
                    return true
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
                love.keyboard.setTextInput(scene.state == 0)
            end
            if scene.state < scene.minState then
                SceneManager[scene.transition and "Transition" or "LoadScene"]("scenes/"..scene.destination, {profileSetupFailed = true})
                if scene.quitOnFail then
                    love.event.push("quit")
                end
                return true
            end
            return true
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
            return true
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
            return true
        end
    end
    return true
end

function scene.textinput(t)
    if scene.frame == 0 then return end
    if scene.state == 0 then
        scene.name = utf8.sub(scene.name .. t, 1, 20)
    end
end

function scene.update(dt)
    scene.frame = 1
    local blend = math.pow(1/((5/4)^60), dt)
    scene.iconSelectionView = blend*(scene.iconSelectionView-scene.iconSelectionViewTarget)+scene.iconSelectionViewTarget
    if math.abs(scene.iconSelectionViewTarget-scene.iconSelectionView) <= 8/128 then
        scene.iconSelectionView = scene.iconSelectionViewTarget
    end
end

function scene.draw()
    if scene.state == 0 then
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        local showKeyboard = HasGamepad
        local kboffset = (showKeyboard and 64 or 0)
        DrawBoxHalfWidth(26, 12.5-kboffset/16, 26, 3)
        love.graphics.printf("TYPE YOUR PROFILE'S NAME", 0, 216 - kboffset, 640, "center")
        love.graphics.printf(scene.name, 0, 248-kboffset, 640, "center")
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        love.graphics.print("█", 320+(utf8.len(scene.name)*8)/2, 248-kboffset)
        love.graphics.line(320-12*8, 264-kboffset, 320+12*8, 264-kboffset)
        if showKeyboard then
            for i,row in ipairs(keyboard.keys) do
                local x = 320 - row.width / 2
                local y = i*48 + 192
                local ox = -12
                for j,key in ipairs(row) do
                    love.graphics.setColor(TerminalColors[(keyboard.pos[1] == j and keyboard.pos[2] == i) and ColorID.WHITE or ColorID.DARK_GRAY])
                    local w = (key[1] == 0 or key[1] == -1) and 3 or 9
                    if key[1] > -1 then
                        DrawBoxHalfWidth((x+ox)/8, y/16, w, 1)
                        local txt = keyboard.shift == 0 and key[2] or key[3]
                        if key[1] == 1 then
                            txt = KeyLabel({"gbutton","x"}) .. " SPACE"
                        end
                        if key[1] == 2 then
                            txt = KeyLabel({"gbutton","y"}) .. " " .. (keyboard.shift == 0 and "shift" or (keyboard.shift == 1 and "Shift" or "SHIFT"))
                        end
                        if key[1] == 3 then
                            txt = KeyLabel({"gbutton","b"}) .. " BCKSP"
                        end
                        if key[1] == 4 then
                            txt = KeyLabel({"gbutton","start"}) .. " CNFRM"
                        end
                        love.graphics.printf(txt,(x+ox)+8,y+16,w*8,"center")
                    end
                    ox = ox + w * 8 + 16
                end
            end
        end
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