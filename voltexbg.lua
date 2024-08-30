local background = {}

local voltexImages = {
    love.graphics.newImage("voltex_red.png"),
    love.graphics.newImage("voltex_green.png"),
    love.graphics.newImage("voltex_blue.png")
}
local voltexLayers = {
    love.graphics.newCanvas(640,480),
    love.graphics.newCanvas(640,480),
    love.graphics.newCanvas(640,480)
}
local voltex = love.graphics.newShader("voltex.frag")
local voltexColors = {
    {1,0,0},
    {0,1,0},
    {0,0,1}
}
voltex:send("colors", unpack(TerminalColors))
voltex:send("dither",
    0/15,8/15,2/15,10/15,
    12/15,4/15,14/15,6/15,
    3/15,11/15,1/15,9/15,
    15/15,7/15,13/15,5/15
)
voltex:send("ditherSize", 2)

function background.init(init)
    background.time = init.time or 0
    background.speed = init.speed or 1
    background.opacity = init.opacity or 0
    background.pulseSpeed = init.pulseSpeed or 0
    background.pulseOpacity = init.pulseOpacity or 0
    background.pulseDuration = init.pulseDuration or 1
end

function background.update(dt)
    if background.pulseOpacity > 0 then
        background.pulseOpacity = math.max(0, background.pulseOpacity - dt*1/background.pulseDuration)
    end
    if background.pulseOpacity < 0 then
        background.pulseOpacity = math.min(0, background.pulseOpacity + dt*1/background.pulseDuration)
    end
    if background.pulseSpeed > 0 then
        background.pulseSpeed = math.max(0, background.pulseSpeed - dt*1/background.pulseDuration)
    end
    if background.pulseSpeed < 0 then
        background.pulseSpeed = math.min(0, background.pulseSpeed + dt*1/background.pulseDuration)
    end
    background.time = background.time + dt*(background.speed+background.pulseSpeed)
end

function background.draw()
    local c = love.graphics.getCanvas()
    for i,layer in ipairs(voltexLayers) do
        love.graphics.setCanvas(layer)
        love.graphics.clear()
        love.graphics.setColor(voltexColors[i])
        love.graphics.draw(voltexImages[i], 320, 240, (background.time*math.pi/2)*i, 1, 1, voltexImages[i]:getWidth()/2, voltexImages[i]:getHeight()/2)
    end
    love.graphics.setCanvas(c)
    love.graphics.setColor(1,1,1,(background.opacity+background.pulseOpacity))
    love.graphics.setShader(voltex)
    voltex:send("layers", unpack(voltexLayers))
    love.graphics.draw(voltexImages[1], 320, 240, 0, 1, 1, voltexImages[1]:getWidth()/2, voltexImages[1]:getHeight()/2)
    love.graphics.setShader()
    -- love.graphics.draw(voltexImages[1], 320, 240, 0, 1, 1, voltexImages[1]:getWidth()/2, voltexImages[1]:getHeight()/2)
end

return background