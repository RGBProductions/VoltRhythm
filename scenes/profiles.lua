local scene = {}

local utf8 = require "utf8"

function utf8.sub(txt, i, j)
    local o1 = (utf8.offset(txt,i) or (#txt))
    local o2 = (utf8.offset(txt,j+1) or (#txt+1))-1
    return txt:sub(o1,o2)
end

local profilesText = love.graphics.newImage("images/profiles.png")

local addIcon = Assets.ProfileIcon("add")

function scene.keypressed(k)
    if SceneManager.TransitioningIn() then
        return
    end
    if k == "escape" then
        SceneManager.Transition("scenes/menu")
    end
    if k == "return" then
        if ProfilesSelection < #scene.profiles then
            Save.SetProfile(scene.profiles[ProfilesSelection+1].name)
            SceneManager.Transition("scenes/menu")
        else
            SceneManager.LoadScene("scenes/setup", {destination = "profiles", set = false, transition = false})
        end
    end
    if k == "e" then
        if ProfilesSelection < #scene.profiles then
            local profile = scene.profiles[ProfilesSelection+1]
            SceneManager.LoadScene("scenes/setup", {destination = "profiles", set = false, minState = 1, name = profile.name, icon = profile.icon, mainColor = profile.main_color, accentColor = profile.accent_color, transition = false})
        end
    end
    if k == "up" then
        ProfilesSelection = (ProfilesSelection - 1) % (#scene.profiles + 1)
        ProfilesViewTarget = (ProfilesViewTarget - 1) % (#scene.profiles + 1)
    end
    if k == "down" then
        ProfilesSelection = (ProfilesSelection + 1) % (#scene.profiles + 1)
        ProfilesViewTarget = (ProfilesViewTarget + 1) % (#scene.profiles + 1)
    end
end

function scene.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    ProfilesView = blend*(ProfilesView-ProfilesViewTarget)+ProfilesViewTarget
    if math.abs(ProfilesViewTarget-ProfilesView) <= 8/128 then
        ProfilesView = ProfilesViewTarget
    end
end

function scene.load(args)
    scene.profiles = Save.GetProfileList()
    if not args.profileSetupFailed then
        ProfilesSelection = 0
        ProfilesView = 0
        ProfilesViewTarget = 0
    else
        ProfilesView = ProfilesViewTarget
    end
end

function scene.draw()
    local pos = 14-ProfilesView*6

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.printf("ENTER - Select", 0, (16)*16, 176, "right")
    if ProfilesSelection >= #scene.profiles then
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
    end
    love.graphics.printf("E - Edit", 480, (16)*16, 176, "left")

    local function drawProfile(i,icon,profile)
        local name = profile.name
        if utf8.len(name) > 12 then
            name = utf8.sub(name, 1, 9) .. "..."
        end
        local progress
        if profile.scores then
            progress = math.floor(profile.scores.percentCompleted*100)
        end
        love.graphics.setColor(TerminalColors[ProfilesSelection == i-1 and ColorID.WHITE or ColorID.DARK_GRAY])
        DrawBoxHalfWidth(40-16, pos, 32, 4)
        love.graphics.print("┬\n│\n│\n│\n│\n┴", 280, (pos)*16)
        if icon then
            ProfileIconShader:send("color1", TerminalColors[profile.main_color or ColorID.LIGHT_RED])
            ProfileIconShader:send("color2", TerminalColors[profile.accent_color or ColorID.BLUE])
            love.graphics.setShader(ProfileIconShader)
            love.graphics.draw(icon, 208, (pos+1)*16, 0, 2, 2)
            love.graphics.setShader()
        end
        love.graphics.printf(name, 296, (pos+2)*16, 152, "left")
        if progress then
            love.graphics.printf(progress .. "%", 296, (pos+2)*16, 152, "right")
        end
        pos = pos + 6
    end

    for i,profile in ipairs(scene.profiles) do
        local icon = Assets.ProfileIcon(profile.icon)
        drawProfile(i,icon,profile)
    end
    drawProfile(#scene.profiles+1,addIcon,{name = "CREATE NEW", main_color = ColorID.WHITE, accent_color = ColorID.WHITE})

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(profilesText, 320, 32, 0, 2, 2, profilesText:getWidth()/2, 0)
end

return scene