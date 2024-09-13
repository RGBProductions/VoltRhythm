local background = {}

function background.init(init)
    background.moveBoxTime = 0
    background.boxes = {}
    for _=1,32 do
        local color = love.math.random(2,8)
        local x1,y1 = love.math.random(0,79),love.math.random(0,29)
        local x2,y2 = math.min(79,x1+love.math.random(2,4)),math.min(29,y1+love.math.random(2,4))
        local x,y,w,h = math.min(x1,x2),math.min(y1,y2),(math.abs(x2-x1)-2)/2,(math.abs(y2-y1)-2)/2
        table.insert(background.boxes,{x,y,w,h,color})
    end
end

function background.update(dt)
    background.moveBoxTime = background.moveBoxTime + dt
    while background.moveBoxTime >= 1/20 do
        local move = love.math.random(1,#background.boxes)
        local color = love.math.random(2,8)
        local x1,y1 = love.math.random(0,79),love.math.random(0,29)
        local x2,y2 = math.min(79,x1+love.math.random(2,4)),math.min(29,y1+love.math.random(2,4))
        local x,y,w,h = math.min(x1,x2),math.min(y1,y2),(math.abs(x2-x1)-2)/2,(math.abs(y2-y1)-2)/2
        table.insert(background.boxes,{x,y,w,h,color})
        table.remove(background.boxes, move)
        background.moveBoxTime = background.moveBoxTime - 1/20
    end
end

function background.draw()
    for _,box in ipairs(background.boxes) do
        love.graphics.setColor(TerminalColors[box[5]])
        DrawBox(DisplayShift[1]/8/4 + box[1], DisplayShift[2]/8/4 + box[2], box[3], box[4])
    end
end

return background