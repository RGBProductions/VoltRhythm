local utf8 = require "utf8"

local scene = {}

local name = "Profile"
local blinkTime = 0

function scene.update(dt)
    blinkTime = (blinkTime + dt) % 0.5
end

function scene.textinput(t)
    name = (name .. t):sub(1,20)
    blinkTime = 0
end

function scene.keypressed(k)
    if k == "backspace" then
        local byteoffset = utf8.offset(name, -1)
        if byteoffset then
            name = name:sub(1, byteoffset-1)
        end
        blinkTime = 0
    end
    if k == "escape" then
        if not scene.source then
            love.event.push("quit")
        end
        SceneManager.Transition("scenes/" .. scene.source)
    end
    if k == "return" then
        local current = Save.Profile
        Save.SetProfile(name)
        if not scene.set then Save.SetProfile(current) end
        SceneManager.Transition("scenes/" .. (scene.destination or "menu"))
    end
end

function scene.load(args)
    scene.source = args.source
    scene.destination = args.destination
    scene.set = args.set
end

function scene.draw()
    DrawBoxHalfWidth(40-11, 12, 22, 2)
    love.graphics.printf("ENTER A USERNAME", 256, 208, 144, "center")
    love.graphics.print(name .. (blinkTime <= 0.25 and "█" or ""), 248, 224)
    love.graphics.line(248, 240, 408, 240)
end

return scene