local border = {}

border.time = 0

local images = ...

local imgs = {
    images.f1,
    images.f1,
    images.f1,
    images.f1,
    images.f2,
    images.f3,
    images.f3,
    images.f3,
    images.f3,
    images.f2
}

function border.update(dt)
    border.time = border.time + dt*6
end

function border.draw()
    love.graphics.draw(imgs[(math.floor(border.time) % #imgs) + 1])
end

return border