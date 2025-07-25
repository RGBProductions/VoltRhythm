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

local function action(a)
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

function scene.keypressed(k)
    if k == "up" then
        action("up")
    end
    if k == "down" then
        action("down")
    end
    if k == "return" then
        action("confirm")
    end
end

function scene.gamepadaxis(stick,axis,value)
    if math.abs(GamepadLastAxes[axis] or 0) < 0.5 and math.abs(value) >= 0.5 then
        if axis == "lefty" then
            if value > 0 then
                action("down")
            else
                action("up")
            end
        end
    end
end

function scene.gamepadpressed(stick,button)
    if button == "dpup" then
        action("up")
    end
    if button == "dpdown" then
        action("down")
    end
    if button == "a" or button == "start" then
        action("confirm")
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