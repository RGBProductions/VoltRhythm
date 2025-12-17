local utf8 = require "utf8"

local scene = {}

---@type love.Source|nil
local preview = nil
local previewTimes = {0,math.huge}
local hiddenAmbience = love.audio.newSource("sounds/ominous_ambience.ogg", "stream")
hiddenAmbience:setLooping(true)
local lockImage = love.graphics.newImage("images/lock.png")
local hiddenCover = love.graphics.newImage("images/cover/hidden.png")
local songselectText = love.graphics.newImage("images/title/songselect.png")

local askToDelete = nil
local askToDeleteDiff = nil

local overvoltWarning = false
local shouldOvervoltWarning = love.filesystem.getInfo("hideovwarning") == nil

function SongSelectSetSelectedSong(song, difficulty)
    local last = scene.selected.identifier
    
    difficulty = difficulty or SongDifficultyOrder[SongSelectDifficulty]
    local set = (difficulty == "overvolt" or difficulty == "hidden") and scene.disk.overvoltSongs or scene.disk.normalSongs
    local item = set[song]
    if not item then
        return
    end
    for i = 1, #set do
        if set[i] == item then
            SongSelectSelectedSong = i
            break
        end
    end
    SongSelectOffsetView:start(item.position * 128, "outExpo", 0.5)

    ---@type SongData
    local data = item.songData

    local j = table.index(SongDifficultyOrder, difficulty)
    if not table.index(item.difficulties, difficulty) then
        if table.index(item.difficulties, SongDifficultyOrder[math.min(j+1, 4)]) then
            j = math.min(j+1, 4)
        elseif table.index(item.difficulties, SongDifficultyOrder[math.max(j-1, 1)]) then
            j = math.max(j-1, 1)
        else
            for i = 1, 4 do
                if table.index(item.difficulties, SongDifficultyOrder[(j+i-1)%4+1]) then
                    j = (j+i-1)%4+1
                    break
                end
                if table.index(item.difficulties, SongDifficultyOrder[(j-i-1)%4+1]) then
                    j = (j-i-1)%4+1
                    break
                end
            end
        end
    end

    ---@type number
    ---@diagnostic disable-next-line: assign-type-mismatch
    SongSelectDifficulty = j
    SongSelectDifficultyView:start(SongSelectDifficulty, "outExpo", 0.3)
    difficulty = SongDifficultyOrder[SongSelectDifficulty]

    local wasOvervolt = SongSelectOvervoltMode
    SongSelectOvervoltMode = difficulty == "overvolt" or difficulty == "hidden"
    if wasOvervolt ~= SongSelectOvervoltMode then
        MissTime = 2
        SongSelectDifficultyView:set(SongSelectDifficultyView.target)
        SongSelectOffsetView:set(SongSelectOffsetView.target)
        if SongSelectOvervoltMode and shouldOvervoltWarning then
            shouldOvervoltWarning = false
            overvoltWarning = true
            love.filesystem.write("hideovwarning", "")
        end
    end
    
    set = SongSelectOvervoltMode and scene.disk.overvoltSongs or scene.disk.normalSongs
    scene.selected = set[SongSelectSelectedSong]

    local hide = (scene.selected.lock or {}).hideUntilUnlocked and not scene.selected.unlocks[difficulty].passed
    local nextPreview = hide and hiddenAmbience or Assets.Preview(data.songPath, data.songPreview)
    if nextPreview and nextPreview ~= preview then
        local times = {previewTimes[1], previewTimes[2]}
        local stopTime = 0
        if preview then
            stopTime = preview:tell("seconds")
            preview:stop()
        end
        previewTimes = data.songPreview
        preview = nextPreview
        preview:setLooping(true)
        preview:setVolume(SystemSettings.song_volume)
        preview:play()
        if data.keepPreview and last == scene.selected.linkedTo then
            local t = math.max(0, math.min(1, stopTime/(times[2]-times[1])))
            local T = t*(previewTimes[2]-previewTimes[1])
            preview:seek(T, "seconds")
        end
    end
end

function scene.load(args)
    ---@type Easer
    SongSelectOffsetView = SongSelectOffsetView or Easer:new(0)
    SongSelectSelectedSong = SongSelectSelectedSong or 1
    SongSelectSelectedSection = SongSelectSelectedSection or 1
    SongSelectDifficulty = SongSelectDifficulty or 3
    SongSelectDifficultyView = SongSelectDifficultyView or Easer:new(SongSelectDifficulty)
    SongSelectOvervoltMode = SongSelectOvervoltMode or false

    if (args.campaign or SongSelectCampaign) ~= SongSelectCampaign then
        SongSelectSelectedSong = 1
        SongSelectSelectedSection = 1
        SongSelectDifficulty = 3
        SongSelectDifficultyView:set(SongSelectDifficulty)
        SongSelectOffsetView:set(0)
        SongSelectOvervoltMode = false
    end

    SongSelectCampaign = args.campaign or SongSelectCampaign or "mainline"

    scene.disk = SongDisk.Disks[SongSelectCampaign]
    scene.chargeMetrics = scene.disk.metrics

    scene.source = args.source or "menu"
    scene.destination = args.destination or "game"

    for _,song in ipairs(scene.disk.allSongs) do
        song.unlocks = {}
        for _,diff in ipairs(SongDifficultyOrder) do
            if not song.lock then
                song.unlocks[diff] = {passed = true}
            else
                song.unlocks[diff] = song.lock:check(scene.disk, diff)
            end
        end
    end

    local set = SongSelectOvervoltMode and scene.disk.overvoltSongs or scene.disk.normalSongs
    scene.selected = set[SongSelectSelectedSong]

    SongSelectHasNormal = #scene.disk.normalSongs > 0
    SongSelectHasOvervolt = #scene.disk.overvoltSongs > 0
    SongSelectOvervoltUnlocked = true

    SongSelectSetSelectedSong(scene.selected.identifier, SongDifficultyOrder[SongSelectDifficulty])
end

function scene.action(a)
    if SceneManager.TransitionState.Transitioning then return end
    
    if a == "back" then
        if overvoltWarning then
            overvoltWarning = false
            return
        end
        if preview then preview:stop() end
        SceneManager.Transition("scenes/" .. scene.source)
    end
    local set = SongSelectOvervoltMode and scene.disk.overvoltSongs or scene.disk.normalSongs
    if a == "right" then
        SongSelectSetSelectedSong(set[(SongSelectSelectedSong % #set) + 1].identifier, SongDifficultyOrder[SongSelectDifficulty])
    end
    if a == "left" then
        SongSelectSetSelectedSong(set[((SongSelectSelectedSong - 2) % #set) + 1].identifier, SongDifficultyOrder[SongSelectDifficulty])
    end
    local selected = set[SongSelectSelectedSong]
    if a == "up" then
        if selected.songData then
            repeat
                if SongSelectOvervoltMode then
                    SongSelectDifficulty = ((SongSelectDifficulty - 4) % 2) + 5
                else
                    SongSelectDifficulty = (SongSelectDifficulty % 4) + 1
                end
            until table.index(selected.difficulties, SongDifficultyOrder[SongSelectDifficulty])
        end
        SongSelectDifficultyView:start(SongSelectDifficulty, "outExpo", 0.3)
    end
    if a == "down" then
        if selected.songData then
            repeat
                if SongSelectOvervoltMode then
                    SongSelectDifficulty = ((SongSelectDifficulty - 6) % 2) + 5
                else
                    SongSelectDifficulty = ((SongSelectDifficulty - 2) % 4) + 1
                end
            until table.index(selected.difficulties, SongDifficultyOrder[SongSelectDifficulty])
        end
        SongSelectDifficultyView:start(SongSelectDifficulty, "outExpo", 0.3)
    end
    if a == "overvolt" then
        local nextSet = set == scene.disk.normalSongs and scene.disk.overvoltSongs or scene.disk.normalSongs
        local choice = nextSet[selected.linkedTo or selected.identifier] or nextSet[1]
        if nextSet == scene.disk.overvoltSongs then
            SongSelectSetSelectedSong(choice.identifier, table.index(choice.difficulties, "overvolt") and "overvolt" or "hidden")
        else
            SongSelectSetSelectedSong(choice.identifier, "extreme")
        end
    end
    if a == "confirm" then
        ---@type SongData
        local data = scene.selected.songData
        local diff = SongDifficultyOrder[SongSelectDifficulty]
        if not data:hasLevel(diff) then return end
        if not scene.selected.unlocks[diff].passed then return end
        
        if preview then preview:stop() end
        SceneManager.Transition("scenes/" .. scene.destination, {songData = data, difficulty = diff})
    end
    if a == "show_more" then
        scene.showMore = not scene.showMore
    end
end

function scene.update(dt)
    SongSelectOffsetView:update(dt)
    SongSelectDifficultyView:update(dt)
end

function scene.draw()
    local binds = {
        back = HasGamepad and Save.Read("keybinds.back")[2] or Save.Read("keybinds.back")[1],
        confirm = HasGamepad and Save.Read("keybinds.confirm")[2] or Save.Read("keybinds.confirm")[1],
        show_more = HasGamepad and Save.Read("keybinds.show_more")[2] or Save.Read("keybinds.show_more")[1],
        overvolt = HasGamepad and Save.Read("keybinds.overvolt")[2] or Save.Read("keybinds.overvolt")[1]
    }

    local set = SongSelectOvervoltMode and scene.disk.overvoltSongs or scene.disk.normalSongs
    local selected = set[SongSelectSelectedSong]

    local function drawSong(song)
        local pos = song.position * 128
        local x = 320 + pos - SongSelectOffsetView:get()
        if x < -64 or x >= 704 then return end

        local offset = math.max(-1, math.min(1, (pos - SongSelectOffsetView:get())/128))
        local s = 1-(math.abs(offset)*0.25)

        local targetDiff = SongDifficultyOrder[SongSelectDifficulty]
        if not table.index(song.difficulties, targetDiff) then
            for i = 1, 4 do
                local i1 = table.index(song.difficulties, SongDifficultyOrder[SongSelectDifficulty+i])
                if i1 then
                    targetDiff = song.difficulties[i1]
                    break
                end
                local i2 = table.index(song.difficulties, SongDifficultyOrder[SongSelectDifficulty-i])
                if i2 then
                    targetDiff = song.difficulties[i2]
                    break
                end
            end
        end
        local savedRating = Save.Read("songs."..(song.scorePrefix or "")..song.identifier.."."..targetDiff)
        if savedRating and savedRating.fullOvercharge then
            -- draw the overcharge outline
            for Y = -0.5, 5.5 do
                for X = -0.5, 5.5 do
                    local color = TerminalColors[OverchargeColors[(math.floor(love.timer.getTime()*6 + (Y-X))%#OverchargeColors)+1]]
                    love.graphics.setColor(color)
                    love.graphics.print("██", x-48*s+X*16*s, 280-48*s+Y*16*s, 0, s, s)
                end
            end
        end

        local b = song.unlocks[targetDiff].passed and 1 or 0.25
        love.graphics.setColor(0.5*b,0.5*b,0.5*b)
        if song == selected then
            love.graphics.setColor(1*b,1*b,1*b)
        end
        song.cover = Assets.GetCover((song.songData or {}).path, (song.songData or {}).coverAnimSpeed)
        love.graphics.draw(((song.lock or {}).hideUntilUnlocked and not song.unlocks[targetDiff].passed) and hiddenCover or song.cover, x, 280, 0, s*96/song.cover:getWidth(), s*96/song.cover:getHeight(), song.cover:getWidth()/2, song.cover:getHeight()/2)
        love.graphics.setColor(1,1,1)

        if not song.unlocks[targetDiff].passed then
            love.graphics.draw(lockImage, x, 280, 0, s, s, 48, 48)
        end
    end

    love.graphics.setColor(1,1,1)

    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(songselectText, 320, 32, 0, 2, 2, songselectText:getWidth()/2, 0)

    DrawBoxHalfWidth(2, 6, 74, 6)
    local difficulty = SongSelectOvervoltMode and (table.index(SongDifficultyOrder, selected.difficulties[#selected.difficulties]) or 5) or SongSelectDifficulty
    local diffname = SongDifficultyOrder[difficulty]
    local savedRating = Save.Read("songs."..(selected.scorePrefix or "")..selected.identifier.."."..SongDifficultyOrder[difficulty])
    local unlocked = selected.unlocks[diffname].passed
    if not unlocked then
        local numReqs = #selected.unlocks[diffname].conditions
        local y = 152-((numReqs-1)*16)/2
        for i,condition in ipairs(selected.unlocks[diffname].conditions) do
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            if condition.passed then
                love.graphics.setColor(TerminalColors[ColorID.LIGHT_GREEN])
            end
            love.graphics.printf(condition.display, 0, y+(i-1)*16, 640, "center")
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    elseif not savedRating then
        love.graphics.printf("- NO DATA -", 0, 152, 640, "center")
    else
        love.graphics.printf("BEST RANK", 0, 112, 640, "center")

        local ratingImage = Ranks[savedRating.rank].image
        love.graphics.draw(ratingImage, 320, 160, 0, 2, 2, ratingImage:getWidth()/2, ratingImage:getHeight()/2)
        if savedRating.plus then love.graphics.draw(Plus, 320, 160, 0, 2, 2, Plus:getWidth()/2, Plus:getHeight()/2) end

        if savedRating.fullOvercharge then
            local foText = "FULL OVERCHARGE"
            for i = 1, #foText do
                local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
                love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
                love.graphics.print(foText:sub(i,i), 320-(8*#foText)/2+(i-1)*8, 192)
            end
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        elseif savedRating.fullCombo then
            local fcText = "FULL COMBO"
            love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
            love.graphics.print(fcText, 320-(8*#fcText)/2, 192)
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end

        if not scene.showMore then
            for i,rating in ipairs(NoteRatings) do
                local x,y = 320+96, 96+(i)*16
                local countString = tostring(savedRating.ratings[i])
                NoteRatings[i].draw(x,y,false)
                love.graphics.setColor(TerminalColors[ColorID.WHITE])
                love.graphics.print(countString, x+8*(20-#(countString)), y)
            end
            -- love.graphics.print("CHARGE: " .. (savedRating.charge or 0) .. " + " .. (savedRating.overcharge or 0) .. "¤", 48, 128)
            love.graphics.print("CHARGE", 64, 128-16)
            love.graphics.print("OVERCHARGE", 64, 144-16)
            love.graphics.print("X-CHARGE", 64, 160-16)
            love.graphics.print("ACCURACY", 64, 176-16)
            
            local c = math.floor((savedRating.charge or 0)*ChargeValues[SongDifficultyOrder[difficulty]].charge)
            local o = math.floor((savedRating.overcharge or 0)*ChargeValues[SongDifficultyOrder[difficulty]].charge)
            local x = math.floor(((savedRating.charge or 0) + (savedRating.overcharge or 0))/ChargeYield*XChargeYield*ChargeValues[SongDifficultyOrder[difficulty]].xcharge)
            love.graphics.print(c .. "¤", 64+8*(19-#tostring(c)), 128-16)
            love.graphics.print("+" .. o .. "¤", 64+8*(19-#("+" .. tostring(o))), 144-16)
            love.graphics.print(x .. "¤", 64+8*(19-#tostring(x)), 160-16)
            love.graphics.print(math.floor((savedRating.accuracy or 0)*100*100)/100 .. "%", 64+8*(19-#tostring(math.floor((savedRating.accuracy or 0)*100*100)/100)), 176-16)

            love.graphics.printf(KeyLabel(binds.show_more) .. " - OVERALL", 64, 192, 160, "center")
        else
            local ratings = {}
            for _,diff in ipairs(selected.difficulties) do
                ratings[diff] = Save.Read("songs."..(selected.scorePrefix or "")..selected.identifier.."."..diff) or {}
            end
            local c,o,x = 0,0,0
            for diff,rating in pairs(ratings) do
                c = c + (rating.charge or 0)*ChargeValues[diff].charge
                o = o + (rating.overcharge or 0)*ChargeValues[diff].charge
                x = x + ((rating.charge or 0) + (rating.overcharge or 0))/ChargeYield*XChargeYield*ChargeValues[diff].xcharge
            end
            c,o,x = math.floor(c),math.floor(o),math.floor(x)

            love.graphics.print("TOTAL CHARGE", 320+88, 128-16)
            love.graphics.print("TOTAL OVERCHARGE", 320+88, 144-16)
            love.graphics.print("TOTAL X-CHARGE", 320+88, 160-16)
            
            love.graphics.print(c .. "¤", 320+80+8*(22-#tostring(c)), 128-16)
            love.graphics.print("+" .. o .. "¤", 320+80+8*(22-#("+" .. tostring(o))), 144-16)
            love.graphics.print(x .. "¤", 320+80+8*(22-#tostring(x)), 160-16)

            local pc = math.floor((savedRating.charge or 0))
            local po = math.floor((savedRating.overcharge or 0))
            local px = math.floor(((savedRating.charge or 0) + (savedRating.overcharge or 0))/ChargeYield*XChargeYield)

            love.graphics.print("PLAY CHARGE", 64-8, 128-16)
            love.graphics.print("PLAY OVERCHARGE", 64-8, 144-16)
            love.graphics.print("PLAY X-CHARGE", 64-8, 160-16)
            love.graphics.print("PLAY ACCURACY", 64-8, 176-16)
            
            love.graphics.print(pc .. "¤", 64+8*(20-#tostring(pc)), 128-16)
            love.graphics.print("+" .. po .. "¤", 64+8*(20-#("+" .. tostring(po))), 144-16)
            love.graphics.print(px .. "¤", 64+8*(20-#tostring(px)), 160-16)
            love.graphics.print(math.floor((savedRating.accuracy or 0)*100*100)/100 .. "%", 64+8*(20-#tostring(math.floor((savedRating.accuracy or 0)*100*100)/100)), 176-16)

            love.graphics.printf(KeyLabel(binds.show_more) .. " - CHART", 64, 192, 160, "center")
        end
    end

    DrawBoxHalfWidth(2, 21, 74, 3)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local hide = (selected.lock or {}).hideUntilUnlocked and not unlocked
    local emblem = Assets.Emblem(selected.songData.emblem)
    local emblemSize = hide and 0 or (emblem and (emblem:getWidth() + 8) or 0)
    local songName = hide and "- NO DATA -" or ((selected.songData or {}).name or "Unrecognized Song")
    love.graphics.print(songName, (640-(utf8.len(songName)*8 + emblemSize))/2 + emblemSize, 360 + (hide and 8 or 0))
    if emblem and not hide then love.graphics.draw(emblem, (640-(utf8.len(songName)*8 + emblemSize))/2, 368, 0, 1, 1, 0, emblem:getHeight()/2) end
    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    if not hide then love.graphics.printf((selected.songData or {}).author or "???", 0, 376, 640, "center") end
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local charter = "???"
    if selected.songData then
        local chart = selected.songData:loadChart(SongDifficultyOrder[difficulty])
        if chart then
            charter = chart.charter or "???"
        end
    end
    if unlocked then
        love.graphics.printf("CHART: " .. charter, 32, 360, 640, "left")
        love.graphics.printf("COVER: " .. ((selected.songData or {}).coverArtist or "???"), 32, 376, 640, "left")
        -- local difficultyName = SongDifficulty[difficulties[SongSelectDifficulty] or "easy"].name or scene.difficulty:upper()
        -- local difficultyColor = SongDifficulty[difficulties[SongSelectDifficulty] or "easy"].color or TerminalColors[ColorID.WHITE]
        -- local diffs = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].difficulties
        -- local difficulty = SongSelectOvervoltMode and (table.index(difficulties, diffs[#diffs]) or 5) or SongSelectDifficulty
        -- love.graphics.setColor(difficultyColor)
        -- love.graphics.print(difficultyName, 608 - (#difficultyName + 1 + #tostring(difficultyLevel) + 2) * 8, 360)
        ---@type SongData?
        local data = selected.songData
        for _,diff in ipairs(selected.difficulties) do
            -- print(diff)
            local index = table.index(SongDifficultyOrder, diff)
            local p = (index - SongSelectDifficultyView:get())
            if p >= -1.5 and p <= 1.5 and ((SongSelectOvervoltMode and diff == "overvolt") or (not SongSelectOvervoltMode and diff ~= "overvolt")) then
                local difficultyLevel = 0
                if selected.songData then
                    difficultyLevel = selected.songData:getLevel(diff)
                end
                love.graphics.setColor(index == (SongSelectOvervoltMode and (table.index(SongDifficultyOrder, selected.difficulties[#selected.difficulties]) or 5) or SongSelectDifficulty) and {1,1,1} or {0.5,0.5,0.5})
                PrintDifficulty(592,368 - p*16,diff,difficultyLevel,"right")
                if data then
                    local hasEffects = #((data:loadChart(diff or "easy") or {}).effects or {}) ~= 0
                    if hasEffects then
                        local x = 592 - 8 * (utf8.len(SongDifficulty[diff].name .. (difficultyLevel ~= nil and (" " .. (difficultyLevel or 0)) or "")) + 3)
                        love.graphics.print("✨", x, 368 - p*16)
                    end
                end
            end
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        -- love.graphics.print(tostring(difficultyLevel), 608 - (#tostring(difficultyLevel) + 2) * 8, 360)
        -- print(#selected.difficulties - (selected.hasOvervolt and 1 or 0))
        if not SongSelectOvervoltMode and (#selected.difficulties - (selected.hasOvervolt and 1 or 0) > 1) then love.graphics.print("🡙", 600, 368) end
    end

    -- love.graphics.printf("Press F8 to create a new song in the editor", 32, 400, 576, "left")
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.printf(KeyLabel(binds.back) .. " - Exit", 32, 416, 576, "left")
    local canPlay = unlocked and (selected.songData and selected.songData:loadChart(SongDifficultyOrder[difficulty]) ~= nil)
    if not canPlay then
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
    end
    love.graphics.printf(KeyLabel(binds.confirm) .. " - Play", 32, 416, 576, "right")
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    if SongSelectHasOvervolt and SongSelectHasNormal and SongSelectOvervoltUnlocked then
        if SongSelectOvervoltMode then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            love.graphics.printf("GO BACK", 32, 416, 576, "center")
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.printf("PRESS " .. KeyLabel(binds.overvolt), 32, 432, 576, "center")
        else
            PrintDifficulty(320, 416, "overvolt", nil, "center")
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.printf("PRESS " .. KeyLabel(binds.overvolt), 32, 432, 576, "center")
        end
    end
    -- love.graphics.printf("Total Charge: " .. math.floor(scene.totalCharge) .. "¤ (" .. math.floor(scene.totalCharge / scene.potentialCharge * 100) .. "%)", 32, 400, 576, "left")
    -- love.graphics.printf("Total Overcharge: " .. math.floor(scene.totalOvercharge) .. "¤ (" .. math.floor(scene.totalOvercharge / scene.potentialOvercharge * 100) .. "%)", 32, 400, 576, "right")
    -- love.graphics.printf("Total X-Charge: " .. math.floor(scene.totalXCharge) .. "¤ (" .. math.floor(scene.totalXCharge / scene.potentialXCharge * 100) .. "%)", 32, 416, 576, "center")

    for i,song in ipairs(set) do
        drawSong(song)
    end

    if askToDelete then
        local w = math.max(32, utf8.len(songName)+2)
        local x = 40-w/2-1
        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1,1,1)
        DrawBoxHalfWidth(x, 10, w, 8)
        love.graphics.printf("DELETING SCORE FOR SONG:\n" .. songName, 0, 176, 640, "center")
        love.graphics.printf("ARE YOU SURE?", 0, 240, 640, "center")
        love.graphics.printf("ESC - No", x*8+16, 288, w*8-16, "left")
        love.graphics.printf("ENTER - Yes", x*8+16, 288, w*8-16, "right")
    end

    if overvoltWarning then
        local w = math.max(32, utf8.len(songName)+2)
        local x = 40-w/2-1
        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1,1,1)
        DrawBoxHalfWidth(x, 8.5, w, 11)
        love.graphics.printf("FOR YOUR SAFETY...", 0, 152, 640, "center")
        love.graphics.printf("OVERVOLT charts are SEVERELY overcharted by design. Please be careful playing these charts.\n\nIf at any point you feel excessive pain in your hands, discontinue play immediately.", x*8+16, 184, w*8-16, "center")
        love.graphics.printf(KeyLabel(binds.back) .. " - Dismiss", x*8+16, 312, w*8-16, "center")
    end
end

return scene