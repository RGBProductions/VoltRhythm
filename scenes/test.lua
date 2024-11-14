local scene = {}

local images = {
    [0] = love.graphics.newImage("images/default0.png"),
    [1] = love.graphics.newImage("images/default1.png"),
    [2] = love.graphics.newImage("images/default2.png"),
    [3] = love.graphics.newImage("images/default3.png"),
    [4] = love.graphics.newImage("images/default4.png"),
    [5] = love.graphics.newImage("images/default5.png"),
    [6] = love.graphics.newImage("test_cover.png")
}

local sample = love.graphics.newImage("sample.png")

local i = 0

function scene.keypressed(k)
    if k == "space" then
        i = (i + 1) % 8
    end
end

function scene.draw()
    love.graphics.draw(sample)
    -- love.graphics.draw(images[i], 128, 128, 0, 2, 2)
end

return scene