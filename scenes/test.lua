local scene = {}

local img = love.graphics.newImage("menutest.png")

function scene.draw()
    love.graphics.draw(img)
end

return scene