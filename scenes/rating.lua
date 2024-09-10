local scene = {}

local ranks = {
    {
        image = love.graphics.newImage("images/rank/F.png"),
        charge = 0.3
    },
    {
        image = love.graphics.newImage("images/rank/D.png"),
        charge = 0.6
    },
    {
        image = love.graphics.newImage("images/rank/B.png"),
        charge = 0.7
    },
    {
        image = love.graphics.newImage("images/rank/A.png"),
        charge = 0.8
    },
    {
        image = love.graphics.newImage("images/rank/S.png"),
        charge = 0.95
    },
    {
        image = love.graphics.newImage("images/rank/O.png"),
        charge = 1
    }
}

local function getRank(charge)
    for i,rank in ipairs(ranks) do
        if charge <= rank.charge then
            return i
        end
    end
    return #ranks
end

function scene.load(args)
    scene.rank = getRank(args.charge or 0)
    scene.charge = math.floor(math.min(args.charge, 0.8)*ChargeYield)
    scene.overcharge = math.floor(math.max(args.charge-0.8, 0)*ChargeYield)
    scene.fullCombo = args.fullCombo
    scene.fullOvercharge = args.fullOvercharge
    scene.offset = math.floor(args.offset*1000)
end

function scene.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(ranks[scene.rank].image, 128, 64, 0, 4)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local chargeString = tostring(scene.charge)
    local overchargeString = tostring(scene.overcharge)
    love.graphics.print("CHARGE     " .. (" "):rep(3-#chargeString) .. "+" .. scene.charge .. "¤", 272, 64)
    love.graphics.print("OVERCHARGE " .. (" "):rep(3-#overchargeString) .. "+" .. scene.overcharge .. "¤", 272, 80)

    if scene.fullCombo then
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        love.graphics.print("FULL COMBO", 272, 112)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    end
    if scene.fullOvercharge then
        local text = "FULL OVERCHARGE"
        for i = 1, #text do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print(text:sub(i,i), 272+(i-1)*8, 128)
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    end
end

return scene