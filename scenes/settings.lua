local scene = {}

local rebind = {false,0}
local selected = 0

function scene.keypressed(k)
    if rebind[1] then
        Keybinds[4][rebind[2]] = k
        rebind[1] = false
    end
    if k == "escape" then
        SceneManager.Transition("scenes/menu")
    end
    if k == "return" then
        rebind[1] = true
        rebind[2] = selected+1
    end
    if k == "up" then
        selected = (selected - 1) % 4
    end
    if k == "down" then
        selected = (selected + 1) % 4
    end
end

function scene.load()
end

function scene.draw()
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.print("KEYBINDS", 64, 64)
    for i,k in ipairs(Keybinds[4]) do
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if selected == i-1 then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        love.graphics.print(k, 64, 64 + 32*i)
    end
end

return scene