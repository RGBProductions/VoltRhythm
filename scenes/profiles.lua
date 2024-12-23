local scene = {}

local selected = 0

function scene.keypressed(k)
    if k == "escape" then
        SceneManager.Transition("scenes/menu")
    end
    if k == "return" then
        if selected < #scene.profiles then
            Save.SetProfile(scene.profiles[selected+1].name)
            SceneManager.Transition("scenes/menu")
        else
            SceneManager.LoadScene("scenes/setup", {source = "profiles", destination = "profiles", set = false})
        end
    end
    if k == "up" then
        selected = (selected - 1) % (#scene.profiles + 1)
    end
    if k == "down" then
        selected = (selected + 1) % (#scene.profiles + 1)
    end
end

function scene.load()
    scene.profiles = Save.GetProfileList()
end

function scene.draw()
    for i,profile in ipairs(scene.profiles) do
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if selected == i-1 then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        love.graphics.print(profile.name, 64, 64 + 32*(i-1))
    end
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    if selected == #scene.profiles then
        love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
    end
    love.graphics.print("CREATE NEW", 64, 64 + 32*#scene.profiles)
end

return scene