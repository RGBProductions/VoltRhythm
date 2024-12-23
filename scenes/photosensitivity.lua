local scene = {}

SuppressBorder = true

local selected = 0

local options = {
    {"CONTINUE", function()
        SceneManager.Transition("scenes/menu")
        SuppressBorder = false
    end},
    {"CONTINUE (EFFECTS OFF)", function()
        UseShaders = false
        SceneManager.Transition("scenes/menu")
    end},
    {"DON'T TELL ME AGAIN", function()
        love.filesystem.write("hidepswarning","")
        SceneManager.Transition("scenes/menu")
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
    love.graphics.printf("VoltRhythm may contain rapidly-moving patterns and flashing lights that could cause health problems for those with photosensitive conditions.\n\nIf you suffer from one of these conditions, please use extreme caution while playing or avoid playing entirely.", 64, 128, 512, "center")
    for i,option in ipairs(options) do
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if selected == i-1 then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        love.graphics.printf(option[1], 64, 256+32*(i-1), 512, "center")
    end
end

return scene