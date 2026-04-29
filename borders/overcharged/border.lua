local border = {}

border.time = 0
border.speed = 16

local w,h = 40,30

local function xpos(t)
    local rw,rh = w-1,h-1
    return math.max(0,math.min(rw, rw+rh/2-math.abs((t % (2*(rw+rh))) - (rw+rh/2))))
end

local function ypos(t)
    local rw,rh = w-1,h-1
    return math.max(0,math.min(rh, rh+rw/2-math.abs(((t-rw) % (2*(rh+rw))) - (rh+rw/2))))
end

function border.update(dt)
    border.time = border.time + dt*border.speed
end

function border.draw()
    for i = 0, 34*4 do
        local t = math.floor(border.time)+i
        local x,y = xpos(t),ypos(t)
        local chr = x == 0 and "│ " or " │"
        if (x == 0 and y == 0) then
            chr = "┌─"
        end
        if (x == w-1 and y == 0) then
            chr = "─┐"
        end
        if (x == 0 and y == h-1) then
            chr = "└─"
        end
        if (x == w-1 and y == h-1) then
            chr = "─┘"
        end
        if (x ~= 0 and x ~= w-1) then
            chr = "──"
        end
        love.graphics.setColor(TerminalColors[OverchargeColors[(i%#OverchargeColors)+1]])
        love.graphics.print(chr, x*16, y*16)
    end
end

return border