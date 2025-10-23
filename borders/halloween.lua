local border = {}

border.time = 0

local imgs = {
    love.graphics.newImage("borders/halloween1.png"),
    love.graphics.newImage("borders/halloween1.png"),
    love.graphics.newImage("borders/halloween1.png"),
    love.graphics.newImage("borders/halloween1.png"),
    love.graphics.newImage("borders/halloween2.png"),
    love.graphics.newImage("borders/halloween3.png"),
    love.graphics.newImage("borders/halloween3.png"),
    love.graphics.newImage("borders/halloween3.png"),
    love.graphics.newImage("borders/halloween3.png"),
    love.graphics.newImage("borders/halloween2.png")
}

function border.update(dt)
    border.time = border.time + dt*6
end

function border.draw()
    love.graphics.draw(imgs[(math.floor(border.time) % #imgs) + 1])
end

return border