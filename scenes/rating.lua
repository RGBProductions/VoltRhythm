local utf8 = require "utf8"

local scene = {}

local defaultSongCover = love.graphics.newImage("test_cover.png")

local resultsText = love.graphics.newImage("images/results.png")

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
        image = love.graphics.newImage("images/rank/C.png"),
        charge = 0.7
    },
    {
        image = love.graphics.newImage("images/rank/B.png"),
        charge = 0.8
    },
    {
        image = love.graphics.newImage("images/rank/A.png"),
        charge = 0.9
    },
    {
        image = love.graphics.newImage("images/rank/S.png"),
        charge = 0.95
    },
    {
        image = love.graphics.newImage("images/rank/O.png"),
        charge = math.huge
    }
}

local function getRank(charge)
    for i,rank in ipairs(ranks) do
        if charge < rank.charge then
            return i
        end
    end
    return #ranks
end

function scene.load(args)
    scene.rank = getRank(args.charge or 0)
    scene.charge = math.floor(math.min(args.charge, 0.8)*ChargeYield)
    scene.overcharge = math.floor(math.max(args.charge-0.8, 0)*ChargeYield)
    scene.accuracy = args.accuracy
    scene.fullCombo = args.fullCombo
    scene.fullOvercharge = args.fullOvercharge
    scene.offset = math.floor(args.offset*1000)
    scene.chart = args.chart
    scene.ratings = args.ratings
end

function scene.keypressed(k)
    if k == "r" then
        scene.chart:resetAllNotes()
        scene.chart:sort()
        scene.chart:recalculateCharge()
        scene.chart.time = TimeBPM(-16,scene.chart.bpm)
        SceneManager.LoadScene("scenes/game", {chart = scene.chart})
    end
end

function scene.draw()
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local chargeString = scene.charge.."¤"
    local overchargeString = "+"..scene.overcharge.."¤"
    local totalChargeString = (scene.charge+scene.overcharge).."¤"
    local accuracyString = math.floor(Accuracy/math.max(Hits,1)*100).."%"
    DrawBox(4,11,11,11)
    DrawBox(28,11,11,11)
    DrawBox(52,11,11,11)
    love.graphics.print("CHARGE", 48, 192 + 16*0)
    love.graphics.print("OVERCHARGE", 48, 192 + 16*1)
    love.graphics.print("TOTAL CHARGE", 48, 192 + 16*2)
    love.graphics.print("ACCURACY", 48, 192 + 16*3)

    -- ACCURACY       ???
    -- ACCURACY        ??
    -- ACCURACY         ?

    love.graphics.print(chargeString, 48+8*(20-utf8.len(chargeString)), 192 + 16*0)
    love.graphics.print(overchargeString, 48+8*(20-utf8.len(overchargeString)), 192 + 16*1)
    love.graphics.print(totalChargeString, 48+8*(20-utf8.len(totalChargeString)), 192 + 16*2)
    love.graphics.print(accuracyString, 48+8*(20-utf8.len(accuracyString)), 192 + 16*3)

    for i,rating in ipairs(NoteRatings) do
        local x,y = 48, 192+(i+4)*16
        local countString = tostring(scene.ratings[i])
        NoteRatings[i].draw(x,y,false)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        love.graphics.print(countString, 48+8*(20-utf8.len(countString)), y)
    end

    local songName = "song"
    local artistName = "composer"
    local difficulty = "EASY"
    local difficultyColor = TerminalColors[ColorID.RED]
    local level = 0
    local combinedDifficultyString = difficulty .. " " .. level
    love.graphics.setColor(1,1,1)
    love.graphics.draw(defaultSongCover, 272, 224)
    love.graphics.setColor(difficultyColor)
    love.graphics.print(difficulty, 232+8*(22-#combinedDifficultyString)/2, 192)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.print(tostring(level), 232+8*((22-#combinedDifficultyString)/2 + #difficulty+1), 192)
    love.graphics.print(songName, 232+8*(22-#songName)/2, 320 + 16*1)
    love.graphics.print(artistName, 232+8*(22-#artistName)/2, 320 + 16*2)

    love.graphics.setColor(1,1,1)
    love.graphics.draw(ranks[scene.rank].image, 448, 216, 0, 4)
    local rankText = "RANK"
    love.graphics.print(rankText, 424+8*(22-#rankText)/2, 192)
    if scene.fullOvercharge then
        local foText = "FULL OVERCHARGE"
        for i = 1, #foText do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print(foText:sub(i,i), 424+8*(22-#foText)/2+(i-1)*8, 352)
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    elseif scene.fullCombo then
        local fcText = "FULL COMBO"
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        love.graphics.print(fcText, 424+8*(22-#fcText)/2, 352)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    end

    DrawBoxHalfWidth(14, 8, 50, 1)
    -- Bar fill
    local c = math.floor(Charge/scene.chart.totalCharge*100)
    love.graphics.print("┬\n\n┴", 55*8, 8*16)
    love.graphics.setColor(TerminalColors[(c < 40 and 5) or (c < 80 and 15) or 11])
    love.graphics.print(("█"):rep(math.min(41,c/2)), 15*8, 9*16)
    -- OVERCHARGE
    if c == c then
        local ocChunks = math.min(10,math.max(0,c/2-41))
        for i = 1, ocChunks do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print("█", (55+i)*8, 9*16)
        end
    end

    love.graphics.setColor(1,1,1)
    DrawBoxHalfWidth(2, 1, 74, 5)
    love.graphics.draw(resultsText, 320, 36, 0, 3, 3, resultsText:getWidth()/2, 0)
end

return scene