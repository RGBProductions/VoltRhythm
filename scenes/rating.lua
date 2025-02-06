local utf8 = require "utf8"

local scene = {}

local resultsText = love.graphics.newImage("images/results.png")

function scene.load(args)
    scene.rank,scene.plus = GetRank(args.accuracy or 0)
    scene.charge = math.floor(math.min(args.charge / 100, 0.8)*ChargeYield)
    scene.overcharge = math.floor(math.max((args.charge / 100)-0.8, 0)*ChargeYield)
    scene.accuracy = args.accuracy
    scene.fullCombo = args.fullCombo
    scene.fullOvercharge = args.fullOvercharge
    scene.offset = math.floor(args.offset*1000)
    scene.songData = args.songData
    scene.difficulty = args.difficulty
    scene.chart = args.chart
    scene.ratings = args.ratings
    scene.cover = Assets.GetCover((args.songData or {}).path or "")
    scene.textScroll = 0
    scene.textScrollTimer = 2
    scene.textScrollDirection = -1
    if Assets.Source(scene.chart.song) then
        Assets.Source(scene.chart.song):stop()
    end
    MissTime = 0
    ScreenShader:send("tearStrength", MissTime*8/Display:getWidth())

    local spl = scene.songData.path:split("/")
    local id = spl[#spl]

    local savedRating = Save.Read("songs."..id.."."..scene.difficulty)
    local shouldSave = not Autoplay and not Showcase
    if savedRating then
        if (savedRating.accuracy or 0) > scene.accuracy or (savedRating.charge or 0) > scene.charge or (savedRating.overcharge or 0) > scene.overcharge then
            shouldSave = false
        end
    end
    if shouldSave then
        Save.Write("songs."..id.."."..scene.difficulty,{
            ratings = scene.ratings,
            charge = scene.charge,
            overcharge = scene.overcharge,
            accuracy = scene.accuracy,
            rank = scene.rank,
            plus = scene.plus,
            fullCombo = scene.fullCombo,
            fullOvercharge = scene.fullOvercharge
        })
    end
end

function scene.update(dt)
    local songName = scene.songData.name
    if #songName > 20 then
        if scene.textScrollTimer <= 0 then
            local min,max = 0,#songName-20
            scene.textScroll = math.max(min,math.min(max,scene.textScroll + scene.textScrollDirection*dt*3))
            if scene.textScroll >= max or scene.textScroll <= min then
                scene.textScrollTimer = 2
            end
        else
            scene.textScrollTimer = scene.textScrollTimer - dt
            if scene.textScrollTimer <= 0 then
                scene.textScrollDirection = -scene.textScrollDirection
            end
        end
    end
end

function scene.keypressed(k)
    if k == "r" then
        scene.chart:resetAllNotes()
        scene.chart:sort()
        scene.chart:recalculateCharge()
        scene.chart.time = TimeBPM(-16,scene.chart.bpm)
        SceneManager.Transition("scenes/game", {songData = scene.songData, difficulty = scene.difficulty})
    end
    if k == "escape" then
        SceneManager.Transition("scenes/songselect")
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

    local songName = scene.songData.name
    local artistName = scene.songData.author
    local difficulty = SongDifficulty[scene.difficulty or "easy"].name or scene.difficulty:upper()
    local difficultyColor = SongDifficulty[scene.difficulty or "easy"].color or TerminalColors[ColorID.WHITE]
    local level = scene.songData:getLevel(scene.difficulty or "easy")
    -- local combinedDifficultyString = difficulty .. " " .. level
    love.graphics.setColor(1,1,1)
    love.graphics.draw(scene.cover, 272, 224)
    -- love.graphics.setColor(difficultyColor)
    -- love.graphics.print(difficulty, 232+8*(22-#combinedDifficultyString)/2, 192)
    PrintDifficulty(232+88, 192, scene.difficulty or "easy", level, "center")
    -- love.graphics.setColor(TerminalColors[ColorID.WHITE])
    -- love.graphics.print(tostring(level), 232+8*((22-#combinedDifficultyString)/2 + #difficulty+1), 192)

    local startText = 1+math.floor(scene.textScroll)
    local endText = math.min(#songName, 20)+math.floor(scene.textScroll)
    local displaySongName = songName:sub(startText, endText)
    love.graphics.print(displaySongName, 232+8*(22-#displaySongName)/2, 320 + 16*1)

    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    love.graphics.print(artistName, 232+8*(22-#artistName)/2, 320 + 16*2)

    love.graphics.setColor(1,1,1)
    love.graphics.draw(Ranks[scene.rank].image, 448, 216, 0, 4)
    if scene.plus then love.graphics.draw(Plus, 448, 216, 0, 4) end
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