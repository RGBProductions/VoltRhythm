local utf8 = require "utf8"

function utf8.sub(txt, i, j)
    local o1 = (utf8.offset(txt,i) or (#txt))
    local o2 = (utf8.offset(txt,j+1) or (#txt+1))-1
    return txt:sub(o1,o2)
end

local scene = {}

local resultsText = love.graphics.newImage("images/title/results.png")

function scene.load(args)
    scene.showMore = false
    scene.rank,scene.plus = GetRank(args.accuracy or 0)
    scene.charge = math.floor((math.min(args.charge, 80)*ChargeYield)/100)
    scene.overcharge = math.floor((math.max((args.charge)-80, 0)*ChargeYield)/100)
    scene.chargeGate = args.chargeGate or 0.8
    scene.accuracy = args.accuracy
    scene.fullCombo = args.fullCombo
    scene.fullOvercharge = args.fullOvercharge
    scene.offset = args.offset*1000
    scene.songData = args.songData
    scene.difficulty = args.difficulty
    scene.chart = args.chart
    scene.ratings = args.ratings
    scene.cover = Assets.GetCover((args.songData or {}).path or "")
    scene.textScroll = 0
    scene.textScrollTimer = 2
    scene.textScrollDirection = -1
    -- TODO: Build a more flexible condition-checking system for complex flow between scenes
    scene.next = args.next or {path = "songselect", args = {}}
    if Assets.Source(scene.chart.song) then
        Assets.Source(scene.chart.song):stop()
    end
    MissTime = 0
    ScreenShader:send("tearStrength", MissTime*8/Display:getWidth())

    local spl = scene.songData.path:split("/")
    local id = spl[#spl]

    local savedRating = Save.Read("songs."..(args.scorePrefix or "")..id.."."..scene.difficulty)
    local shouldSave = not Autoplay and not Showcase
    if savedRating then
        scene.newBest = not ((savedRating.accuracy or 0) > scene.accuracy or (savedRating.charge or 0) > scene.charge or (savedRating.overcharge or 0) > scene.overcharge)
        if not scene.newBest then
            shouldSave = false
        end
    end
    if shouldSave then
        Save.Write("songs."..(args.scorePrefix or "")..id.."."..scene.difficulty,{
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
    SongDisk.RecalculateScores()

    if SystemSettings.discord_rpc_level == RPCLevels.FULL then
        Discord.setActivity("Finished " .. scene.songData.name, SongDifficulty[scene.difficulty].name .. " " .. scene.songData:getLevel(scene.difficulty) .. " - " .. scene.charge+scene.overcharge .. " ¤")
        Discord.updatePresence()
    end
end

function scene.update(dt)
    if scene.songData.coverAnimSpeed then
        scene.cover = Assets.GetAnimatedCover(scene.songData.path, scene.songData.coverAnimSpeed)
    end
    local songName = scene.songData.name
    if #songName > 20 then
        if scene.textScrollTimer <= 0 then
            local min,max = 0, utf8.len(songName)-20
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

function scene.action(a)
    if a == "restart" then
        scene.chart:resetAllNotes()
        scene.chart:sort()
        scene.chart:recalculateCharge()
        scene.chart.time = TimeBPM(-16,scene.chart.bpm)
        SceneManager.Transition("scenes/game", {songData = scene.songData, difficulty = scene.difficulty, next = scene.next})
    end
    if a == "back" then
        SceneManager.Transition("scenes/songselect")
    end
    if a == "confirm" then
        SceneManager.Transition("scenes/" .. (scene.next.path or "songselect"), scene.next.args)
    end
    if a == "show_more" then
        scene.showMore = not scene.showMore
    end
end

function scene.draw()
    local binds = {
        back = HasGamepad and Save.Read("keybinds.back")[2] or Save.Read("keybinds.back")[1],
        confirm = HasGamepad and Save.Read("keybinds.confirm")[2] or Save.Read("keybinds.confirm")[1],
        show_more = HasGamepad and Save.Read("keybinds.show_more")[2] or Save.Read("keybinds.show_more")[1],
        restart = HasGamepad and Save.Read("keybinds.restart")[2] or Save.Read("keybinds.restart")[1]
    }

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBox(4,9,11,11)
    DrawBox(28,9,11,11)
    DrawBox(52,9,11,11)

    if scene.showMore then
        local chargeString = scene.charge.."¤"
        local overchargeString = "+"..scene.overcharge.."¤"
        local totalChargeString = (scene.charge+scene.overcharge).."¤"
        local xchargeString = math.floor((scene.charge+scene.overcharge)*ChargeValues[scene.difficulty].xcharge).."¤"
        local offsetString = math.floor(scene.offset*100)/100 .. " ms"
        local comboString = tostring(MaxCombo)

        love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
        love.graphics.printf("PLAY SCORE", 48, 160 + 16*0, 160, "center")

        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        love.graphics.print("CHARGE", 48, 160 + 16*1)
        love.graphics.print("OVERCHARGE", 48, 160 + 16*2)
        love.graphics.print("TOTAL CHARGE", 48, 160 + 16*3)
        love.graphics.print(chargeString, 48+8*(20-utf8.len(chargeString)), 160 + 16*1)
        love.graphics.print(overchargeString, 48+8*(20-utf8.len(overchargeString)), 160 + 16*2)
        love.graphics.print(totalChargeString, 48+8*(20-utf8.len(totalChargeString)), 160 + 16*3)

        love.graphics.print("X-CHARGE", 48, 160 + 16*5)
        love.graphics.print(xchargeString, 48+8*(20-utf8.len(xchargeString)), 160 + 16*5)

        love.graphics.print("AVG OFFSET", 48, 160 + 16*7)
        love.graphics.print("MAX COMBO", 48, 160 + 16*8)
        love.graphics.print(offsetString, 48+8*(20-utf8.len(offsetString)), 160 + 16*7)
        love.graphics.print(comboString, 48+8*(20-utf8.len(comboString)), 160 + 16*8)
    else
        local chargeString = math.floor(scene.charge*ChargeValues[scene.difficulty].charge).."¤"
        local overchargeString = "+"..math.floor(scene.overcharge*ChargeValues[scene.difficulty].charge).."¤"
        local totalChargeString = math.floor((scene.charge+scene.overcharge)*ChargeValues[scene.difficulty].charge).."¤"
        local accuracyString = math.floor(Accuracy/math.max(Hits,1)*100*100)/100 .. "%"

        love.graphics.print("CHARGE", 48, 160 + 16*0)
        love.graphics.print("OVERCHARGE", 48, 160 + 16*1)
        love.graphics.print("TOTAL CHARGE", 48, 160 + 16*2)
        love.graphics.print("ACCURACY", 48, 160 + 16*3)
        love.graphics.print(chargeString, 48+8*(20-utf8.len(chargeString)), 160 + 16*0)
        love.graphics.print(overchargeString, 48+8*(20-utf8.len(overchargeString)), 160 + 16*1)
        love.graphics.print(totalChargeString, 48+8*(20-utf8.len(totalChargeString)), 160 + 16*2)
        love.graphics.print(accuracyString, 48+8*(20-utf8.len(accuracyString)), 160 + 16*3)
        
        for i,rating in ipairs(NoteRatings) do
            local x,y = 48, 160+(i+4)*16
            local countString = tostring(scene.ratings[i])
            NoteRatings[i].draw(x,y,false)
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.print(countString, 48+8*(20-utf8.len(countString)), y)
        end
    end
    love.graphics.printf(KeyLabel(binds.show_more) .. " - " .. (scene.showMore and "Back" or "More"), 48, 352, 160, "center")

    local songName = scene.songData.name
    local artistName = scene.songData.author
    local difficulty = SongDifficulty[scene.difficulty or "easy"].name or scene.difficulty:upper()
    local difficultyColor = SongDifficulty[scene.difficulty or "easy"].color or TerminalColors[ColorID.WHITE]
    local level = scene.songData:getLevel(scene.difficulty or "easy")
    -- local combinedDifficultyString = difficulty .. " " .. level
    love.graphics.setColor(1,1,1)
    love.graphics.draw(scene.cover, 272, 192, 0, 96/scene.cover:getWidth(), 96/scene.cover:getHeight())
    -- love.graphics.setColor(difficultyColor)
    -- love.graphics.print(difficulty, 232+8*(22-#combinedDifficultyString)/2, 192)
    PrintDifficulty(232+88, 160, scene.difficulty or "easy", level, "center")
    -- love.graphics.setColor(TerminalColors[ColorID.WHITE])
    -- love.graphics.print(tostring(level), 232+8*((22-#combinedDifficultyString)/2 + #difficulty+1), 192)

    local startText = 1+math.floor(scene.textScroll)
    local endText = math.min(utf8.len(songName), 20)+math.floor(scene.textScroll)
    local displaySongName = utf8.sub(songName, startText, endText)
    love.graphics.print(displaySongName, 232+8*(22-utf8.len(displaySongName))/2, 288 + 16*1)

    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    love.graphics.print(artistName, 232+8*(22-#artistName)/2, 288 + 16*2)

    love.graphics.setColor(1,1,1)
    love.graphics.draw(Ranks[scene.rank].image, 448, 184, 0, 4)
    if scene.plus then love.graphics.draw(Plus, 448, 184, 0, 4) end
    local rankText = "RANK"
    love.graphics.print(rankText, 424+8*(22-#rankText)/2, 160)
    if scene.fullOvercharge then
        local foText = "FULL OVERCHARGE"
        for i = 1, #foText do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print(foText:sub(i,i), 424+8*(22-#foText)/2+(i-1)*8, 320)
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    elseif scene.fullCombo then
        local fcText = "FULL COMBO"
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        love.graphics.print(fcText, 424+8*(22-#fcText)/2, 320)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    elseif scene.charge < scene.chargeGate*ChargeYield then
        local uvText = "UNDERVOLTED..."
        love.graphics.setColor(TerminalColors[ColorID.RED])
        love.graphics.print(uvText, 424+8*(22-#uvText)/2, 320)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    end

    if Autoplay then
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        DrawBoxHalfWidth(32,22,14,1)
        local autoText = Showcase and "SHOWCASE" or "AUTOPLAY"
        love.graphics.print(autoText, 232+8*(22-#autoText)/2, 368)
    elseif scene.newBest then
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        DrawBoxHalfWidth(32,22,14,1)
        local nrText = "NEW RECORD!!"
        for i = 1, #nrText do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print(nrText:sub(i,i), 232+8*(22-#nrText)/2+(i-1)*8, 368)
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    end

    DrawBoxHalfWidth(14, 6, 50, 1)
    -- Bar fill
    local c = math.floor(Charge/scene.chart.totalCharge*100)
    if scene.chargeGate > 0 and scene.chargeGate < 1 then
        local gateX = (15+math.floor(50*scene.chargeGate))
        love.graphics.print("┬\n\n┴", gateX*8, 6*16)
    end
    love.graphics.print("┬\n\n┴", 55*8, 6*16)
    love.graphics.setColor(TerminalColors[(c < 40 and 5) or (c < 80 and 15) or 11])
    love.graphics.print(("█"):rep(math.min(41,c/2)), 15*8, 7*16)
    -- OVERCHARGE
    if c == c then
        local ocChunks = math.min(10,math.max(0,c/2-41))
        for i = 1, ocChunks do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print("█", (55+i)*8, 7*16)
        end
    end
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.printf(KeyLabel(binds.back) .. " - Exit", 32, 400, 576, "left")
    love.graphics.printf(KeyLabel(binds.restart) .. " - Retry", 32, 400, 576, "center")
    love.graphics.printf(KeyLabel(binds.confirm) .. " - Continue", 32, 400, 576, "right")

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(resultsText, 320, 32, 0, 2, 2, resultsText:getWidth()/2, 0)
end

function scene.unload()
    if SystemSettings.discord_rpc_level > RPCLevels.PLAYING then
        Discord.setActivity("Not playing")
        Discord.updatePresence()
    end
end

return scene