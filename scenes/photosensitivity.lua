local scene = {}

SuppressBorder = true

local selected = 0

local options = {
    {"photosensitivty_continue", function()
        SceneManager.Transition("scenes/startup")
        SuppressBorder = false
    end},
    {"photosensitivty_no_fx", function()
        SystemSettings.enable_screen_effects = false
        SystemSettings.enable_chart_effects = false
        SystemSettings.enable_background = false
        SceneManager.Transition("scenes/startup")
    end},
    {"photosensitivity_disable_warning", function()
        love.filesystem.write("hidepswarning","")
        SceneManager.Transition("scenes/startup")
    end},
    {"photosensitivity_exit", function()
        love.event.push("quit")
    end}
}

function scene.action(a)
    if a == "up" then
        selected = (selected - 1) % #options
    end
    if a == "down" then
        selected = (selected + 1) % #options
    end
    if a == "confirm" then
        options[selected+1][2]()
    end
end

function scene.draw()
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawText(Localize("photosensitivity_text"), 64, 128, 512, "center")
    for i,option in ipairs(options) do
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if selected == i-1 then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        DrawText(Localize(option[1]), 64, 256+32*(i-1), 512, "center")
    end
end

return scene