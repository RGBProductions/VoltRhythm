local scene = {}

SuppressBorder = true

local selected = 0

local options = {
    {"CONTINUE", function()
        SceneManager.Transition("scenes/startup")
        SuppressBorder = false
    end},
    {"CONTINUE (EFFECTS OFF)", function()
        SystemSettings.enable_screen_effects = false
        SystemSettings.enable_chart_effects = false
        SceneManager.Transition("scenes/startup")
    end},
    {"DON'T TELL ME AGAIN", function()
        love.filesystem.write("hidepswarning","")
        SceneManager.Transition("scenes/startup")
    end},
    {"EXIT", function()
        love.event.push("quit")
    end}
}

function scene.keypressed(k)
    if k == "up" then
        selected = (selected - 1) % #options
    end
    if k == "down" then
        selected = (selected + 1) % #options
    end
    if k == "return" then
        options[selected+1][2]()
    end
end

function scene.draw()
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.printf("VoltRhythm contains rapidly-moving patterns and flashing lights that could cause health complications for those with photosensitive conditions.\n\nIf you suffer from any of these conditions, please use extreme caution while playing or avoid playing entirely.", 64, 128, 512, "center")
    for i,option in ipairs(options) do
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if selected == i-1 then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        love.graphics.printf(option[1], 64, 256+32*(i-1), 512, "center")
    end
end

return scene