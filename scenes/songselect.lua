local utf8 = require "utf8"

local scene = {}

---@type love.Source|nil
local preview = nil
local previewTimes = {0,math.huge}
local hiddenAmbience = love.audio.newSource("sounds/ominous_ambience.ogg", "stream")
hiddenAmbience:setLooping(true)

local askToDelete = nil
local askToDeleteDiff = nil

local function playSong(songInfo)
    local nextPreview
    local p = songInfo.hide and hiddenAmbience or songInfo.preview
    if p then
        nextPreview = p
    end
    if preview == nextPreview then return end
    if preview then preview:stop() end
    if (not songInfo) or (not songInfo.songData) then
        preview = nil
        previewTimes = {0,math.huge}
        return
    end
    preview = nextPreview
    if preview then
        preview:setVolume(SystemSettings.song_volume)
        preview:setLooping(true)
        preview:play()
    end
end

function scene.update(dt)
    local blendAmt = 1/((5/4) ^ 60)
    local blend = blendAmt^dt
    SongSelectOffsetView = blend*(SongSelectOffsetView - SongSelectOffsetViewTarget) + SongSelectOffsetViewTarget
end

local difficulties = {
    "easy", "medium", "hard", "extreme", "overvolt", "hidden"
}

local lockImage = love.graphics.newImage("images/lock.png")
local hiddenCover = love.graphics.newImage("images/cover/hidden.png")

local function testLock(lock)
    local global = lock.global or {}
    local songs = lock.songs or {}
    local requirements = {}
    if global.charge then table.insert(requirements, {type = "Get " .. global.charge .. " total Charge", value = global.charge, passed = scene.totalCharge >= global.charge}) end
    if global.overcharge then table.insert(requirements, {type = "Get " .. global.overcharge .. " total Overcharge", value = global.overcharge, passed = scene.totalOvercharge >= global.overcharge}) end
    if global.xcharge then table.insert(requirements, {type = "Get " .. global.xcharge .. " total X-Charge", value = global.xcharge, passed = scene.totalXCharge >= global.xcharge}) end
    local namesSorted = {}
    for name,_ in pairs(songs) do
        table.insert(namesSorted, name)
    end
    table.sort(namesSorted, function (a, b)
        return (SongDisk.AllSongNames[a] or "ZZZZZZZZZZZZZZ") < (SongDisk.AllSongNames[b] or "ZZZZZZZZZZZZZZ")
    end)
    for _,name in pairs(namesSorted) do
        local song = songs[name]
        local savedRating = Save.Read("songs."..name) or {}
        local savedRatingExists = Save.Read("songs."..name) ~= nil
        local c,o,x = 0,0,0
        for diff,save in pairs(savedRating) do
            c = c + (save.charge or 0) * ChargeValues[diff].charge
            o = o + (save.overcharge or 0) * ChargeValues[diff].charge
            x = x + (c + o)/ChargeYield*XChargeYield
        end
        if song.completed ~= nil then table.insert(requirements, {type = "Complete \"" .. scene.songNames[name] .. "\" on any difficulty", song = name, value = song.completed, passed = savedRatingExists}) end
        if song.charge then table.insert(requirements, {type = "Get " .. song.charge .. " Charge in \"" .. scene.songNames[name] .. '"', song = name, value = song.charge, passed = c >= song.charge}) end
        if song.overcharge then table.insert(requirements, {type = "Get " .. song.overcharge .. " Overcharge in \"" .. scene.songNames[name] .. '"', song = name, value = song.overcharge, passed = o >= song.overcharge}) end
        if song.xcharge then table.insert(requirements, {type = "Get " .. song.xcharge .. " X-Charge in \"" .. scene.songNames[name] .. '"', song = name, value = song.xcharge, passed = x >= song.xcharge}) end
    end
    local meets = true
    for _,requirement in ipairs(requirements) do
        if not requirement.passed then
            meets = false
            break
        end
    end
    return requirements,meets,lock.hide and not meets
end

local function finishSelection()
    local selected = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
    if selected.songData then
        if not table.index(selected.difficulties, difficulties[SongSelectDifficulty]) then
            for i = 1, 5 do
                if table.index(selected.difficulties, difficulties[SongSelectDifficulty-i]) then
                    if (not SongSelectOvervoltMode) and difficulties[SongSelectDifficulty-i] ~= "overvolt" and difficulties[SongSelectDifficulty-i] ~= "hidden" then
                        SongSelectDifficulty = SongSelectDifficulty-i
                        break
                    end
                end
                if table.index(selected.difficulties, difficulties[SongSelectDifficulty+i]) then
                    if (not SongSelectOvervoltMode) and difficulties[SongSelectDifficulty+i] ~= "overvolt" and difficulties[SongSelectDifficulty+i] ~= "hidden" then
                        SongSelectDifficulty = SongSelectDifficulty+i
                        break
                    end
                end
            end
        end
    end
    playSong(selected)
end

function scene.load(args)
    scene.source = args.source or "songdiskselect"
    scene.destination = args.destination or "game"

    -- scene.campaigns = json.decode(love.filesystem.read("campaign/campaigns.json"))
    if (args.campaign or SongSelectCampaign) ~= SongSelectCampaign then
        SongSelectSelectedSong = 1
        SongSelectSelectedSection = 1
        SongSelectOffsetView = 0
        SongSelectOffsetViewTarget = 0
        SongSelectOvervoltMode = false
    end
    SongSelectCampaign = args.campaign or SongSelectCampaign or "mainline"
    SongSelectSelectedSong = SongSelectSelectedSong or 1
    SongSelectSelectedSection = SongSelectSelectedSection or 1
    SongSelectOffsetView = SongSelectOffsetView or 0
    SongSelectOffsetViewTarget = SongSelectOffsetViewTarget or 0
    SongSelectDifficulty = SongSelectDifficulty or 3
    SongSelectOvervoltMode = SongSelectOvervoltMode or false
    scene.campaign = SongDisk.Get(SongSelectCampaign)
    local metrics = SongDisk.Load(SongSelectCampaign)
    local chargeMetrics = SongDisk.GetChargeMetrics(SongSelectCampaign)
    scene.showMore = false
    scene.totalCharge = chargeMetrics.totalCharge
    scene.totalOvercharge = chargeMetrics.totalOvercharge
    scene.totalXCharge = chargeMetrics.totalXCharge
    scene.potentialCharge = chargeMetrics.potentialCharge
    scene.potentialOvercharge = chargeMetrics.potentialOvercharge
    scene.potentialXCharge = chargeMetrics.potentialXCharge
    scene.positions = metrics.positions
    scene.overvoltPositions = metrics.overvoltPositions
    scene.positionsByName = metrics.positionsByName
    scene.overvoltPositionsByName = metrics.overvoltPositionsByName
    scene.songNames = SongDisk.AllSongNames
    scene.songCount = metrics.songCount
    -- local lastPosition = 0
    -- local lastOVPosition = 0
    -- for c,campaign in ipairs(scene.campaigns) do
    --     for s,section in ipairs(campaign.sections) do
    --         for S,song in ipairs(section.songs) do
    --             scene.songCount = scene.songCount + 1
    --             section.songs[S] = {
    --                 name = song.song,
    --                 difficulties = song.difficulties,
    --                 lock = song.lock or {},
    --                 songData = LoadSongData("songs/" .. song.song),
    --                 cover = Assets.GetCover("songs/" .. song.song),
    --             }
    --             if section.songs[S].songData then
    --                 section.songs[S].preview = Assets.Preview(section.songs[S].songData.songPath, section.songs[S].songData.songPreview)
    --             end
    --             scene.songNames[song.song] = (section.songs[S].songData or {}).name or song.song
    --             for _,name in ipairs(song.difficulties) do
    --                 if name == "overvolt" or name == "hidden" then
    --                     scene.overvoltPositions[section.songs[S]] = lastOVPosition
    --                     scene.overvoltPositionsByName[song.song] = lastOVPosition
    --                     lastOVPosition = lastOVPosition + 1
    --                 elseif not scene.positions[section.songs[S]] then
    --                     scene.positions[section.songs[S]] = lastPosition
    --                     scene.positionsByName[song.song] = lastPosition
    --                     lastPosition = lastPosition + 1
    --                 end
    --                 scene.potentialCharge = scene.potentialCharge + 160*ChargeValues[name].charge
    --                 scene.potentialOvercharge = scene.potentialOvercharge + 40*ChargeValues[name].charge
    --                 scene.potentialXCharge = scene.potentialXCharge + 50*ChargeValues[name].xcharge
    --                 local savedRating = Save.Read("songs."..song.song.."."..name)
    --                 if savedRating then
    --                     scene.totalCharge = scene.totalCharge + savedRating.charge*ChargeValues[name].charge
    --                     scene.totalOvercharge = scene.totalOvercharge + savedRating.overcharge*ChargeValues[name].charge
    --                     scene.totalXCharge = scene.totalXCharge + (savedRating.charge+savedRating.overcharge)/ChargeYield*XChargeYield*ChargeValues[name].xcharge
    --                     local reRank, rePlus = GetRank(savedRating.accuracy)
    --                     Save.Write("songs."..song.song.."."..name..".rank", reRank)
    --                     Save.Write("songs."..song.song.."."..name..".plus", rePlus)
    --                 end
    --             end
    --         end
    --     end
    -- end
    SongSelectHasOvervolt = false
    for s,section in ipairs(scene.campaign.sections) do
        for S,song in ipairs(section.songs) do
            song.unlockConditions, song.isUnlocked, song.hide = testLock(song.lock or {})
            if song.isUnlocked and (table.index(song.difficulties, "overvolt") or table.index(song.difficulties, "hidden")) then
                SongSelectHasOvervolt = true
            end
        end
    end
    -- playSong(scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong])
    finishSelection()
    SceneManager.TransitionState.Pause = 1
end

function scene.keypressed(k)
    if SceneManager.TransitioningIn() or SceneManager.TransitioningOut() then return end
    if askToDelete then
        if k == "return" then
            Save.Write("songs." .. askToDelete .. "." .. askToDeleteDiff, nil)
            askToDelete = nil
            askToDeleteDiff = nil
        end
        if k == "escape" then
            askToDelete = nil
            askToDeleteDiff = nil
        end
        return
    end
    if k == "backspace" then
        local selected = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
        local difficulty = SongSelectOvervoltMode and (table.index(difficulties, selected.difficulties[1]) or 5) or SongSelectDifficulty
        local savedRating = Save.Read("songs."..(selected.scorePrefix or "")..selected.name.."."..difficulties[difficulty])
        if savedRating and selected.isUnlocked then
            askToDelete = (selected.scorePrefix or "")..selected.name
            askToDeleteDiff = difficulties[difficulty]
        end
    end
    if k == "tab" then
        local selected = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
        local difficulty = SongSelectOvervoltMode and (table.index(difficulties, selected.difficulties[1]) or 5) or SongSelectDifficulty
        local savedRating = Save.Read("songs."..(selected.scorePrefix or "")..selected.name.."."..difficulties[difficulty])
        if savedRating and selected.isUnlocked then
            scene.showMore = not scene.showMore
        end
    end
    if k == "o" and scene.campaign.hasOvervolt then
        MissTime = 2
        SongSelectOvervoltMode = not SongSelectOvervoltMode
        local prev = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
        local foundSame = nil
        for i,song in ipairs(scene.campaign.sections[SongSelectSelectedSection].songs) do
            if (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[song] and song.name == prev.name then
                foundSame = i
            end
        end
        if foundSame then
            SongSelectSelectedSong = foundSame
        else
            SongSelectSelectedSong = 1
            while not (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]] do
                SongSelectSelectedSong = SongSelectSelectedSong + 1
                if SongSelectSelectedSong > #scene.campaign.sections[SongSelectSelectedSection].songs then
                    SongSelectSelectedSection = (SongSelectSelectedSection % #scene.campaign.sections) + 1
                    SongSelectSelectedSong = 1
                end
            end
        end
        SongSelectOffsetViewTarget = (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]] * 128
        finishSelection()
    end
    if k == "f8" then
        if preview then
            preview:stop()
            preview:setLooping(false)
        end
        SceneManager.Transition("scenes/neditor")
    end
    if k == "right" then
        local found = false
        while not found do
            SongSelectSelectedSong = SongSelectSelectedSong + 1
            if SongSelectSelectedSong > #scene.campaign.sections[SongSelectSelectedSection].songs then
                SongSelectSelectedSection = (SongSelectSelectedSection % #scene.campaign.sections) + 1
                SongSelectSelectedSong = 1
            end
            if (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]] then
                found = true
            end
        end
        SongSelectOffsetViewTarget = (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]] * 128
        finishSelection()
    end
    if k == "left" then
        local found = false
        while not found do
            SongSelectSelectedSong = SongSelectSelectedSong - 1
            if SongSelectSelectedSong <= 0 then
                SongSelectSelectedSection = ((SongSelectSelectedSection - 2) % #scene.campaign.sections) + 1
                SongSelectSelectedSong = #scene.campaign.sections[1].songs
            end
            if (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]] then
                found = true
            end
        end
        SongSelectOffsetViewTarget = (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]] * 128
        finishSelection()
    end
    if not SongSelectOvervoltMode then
        if k == "up" then
            local selected = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
            if selected.songData and selected.isUnlocked then
                -- SongSelectDifficulty = (SongSelectDifficulty % 4) + 1
                repeat
                    SongSelectDifficulty = (SongSelectDifficulty % 4) + 1
                until table.index(selected.difficulties, difficulties[SongSelectDifficulty])
            end
        end
        if k == "down" then
            local selected = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
            if selected.songData and selected.isUnlocked then
                -- SongSelectDifficulty = ((SongSelectDifficulty - 2) % 4) + 1
                repeat
                    SongSelectDifficulty = ((SongSelectDifficulty - 2) % 4) + 1
                until table.index(selected.difficulties, difficulties[SongSelectDifficulty])
            end
        end
    end

    if k == "return" then
        if scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].isUnlocked then
            local diffs = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].difficulties
            local difficulty = SongSelectOvervoltMode and (table.index(difficulties, diffs[#diffs]) or 5) or SongSelectDifficulty
            ---@type SongData?
            local songData = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].songData
            local scorePrefix = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].scorePrefix
            if songData and songData:loadChart(difficulties[difficulty]) ~= nil then
                if preview then
                    preview:stop()
                    preview:setLooping(false)
                end
                Autoplay = love.keyboard.isDown("lshift")
                Showcase = love.keyboard.isDown("lctrl") and Autoplay
                SceneManager.Transition("scenes/" .. scene.destination, {songData = songData, scorePrefix = scorePrefix, difficulty = difficulties[difficulty]})
            end
        end
    end

    if k == "escape" then
        if preview then
            preview:stop()
            preview:setLooping(false)
        end
        SceneManager.Transition("scenes/" .. scene.source)
    end
end

local songselectText = love.graphics.newImage("images/title/songselect.png")

function scene.draw()
    local selected = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]

    local function drawSong(song)
        if not (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[song] then return end
        local pos = (SongSelectOvervoltMode and scene.overvoltPositions or scene.positions)[song] * 128
        local x = 320 + pos - SongSelectOffsetView
        if x < -64 or x >= 704 then return end

        local offset = math.max(-1, math.min(1, (pos - SongSelectOffsetView)/128))
        local s = 1-(math.abs(offset)*0.25)

        local targetDiff = difficulties[SongSelectDifficulty]
        if not table.index(song.difficulties, targetDiff) then
            for i = 1, 4 do
                local i1 = table.index(song.difficulties, difficulties[SongSelectDifficulty+i])
                if i1 then
                    targetDiff = song.difficulties[i1]
                    break
                end
                local i2 = table.index(song.difficulties, difficulties[SongSelectDifficulty-i])
                if i2 then
                    targetDiff = song.difficulties[i2]
                    break
                end
            end
        end
        local savedRating = Save.Read("songs."..(song.scorePrefix or "")..song.name.."."..targetDiff)
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

        local b = song.isUnlocked and 1 or 0.25
        love.graphics.setColor(0.5*b,0.5*b,0.5*b)
        if song == selected then
            love.graphics.setColor(1*b,1*b,1*b)
        end
        if (song.songData or {}).coverAnimSpeed then
            song.cover = Assets.GetAnimatedCover(song.songData.path, song.songData.coverAnimSpeed)
        end
        love.graphics.draw(song.hide and hiddenCover or song.cover, x, 280, 0, s*96/song.cover:getWidth(), s*96/song.cover:getHeight(), song.cover:getWidth()/2, song.cover:getHeight()/2)
        love.graphics.setColor(1,1,1)

        if not song.isUnlocked then
            love.graphics.draw(lockImage, x, 280, 0, s, s, 48, 48)
        end
    end

    love.graphics.setColor(1,1,1)

    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(songselectText, 320, 32, 0, 2, 2, songselectText:getWidth()/2, 0)

    DrawBoxHalfWidth(2, 6, 74, 6)
    local difficulty = SongSelectOvervoltMode and (table.index(difficulties, selected.difficulties[#selected.difficulties]) or 5) or SongSelectDifficulty
    local savedRating = Save.Read("songs."..(selected.scorePrefix or "")..selected.name.."."..difficulties[difficulty])
    if not selected.isUnlocked then
        local numReqs = #selected.unlockConditions
        local y = 152-((numReqs-1)*16)/2
        for i,condition in ipairs(selected.unlockConditions) do
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            if condition.passed then
                love.graphics.setColor(TerminalColors[ColorID.LIGHT_GREEN])
            end
            love.graphics.printf(condition.type, 0, y+(i-1)*16, 640, "center")
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
            
            local c = math.floor((savedRating.charge or 0)*ChargeValues[difficulties[difficulty]].charge)
            local o = math.floor((savedRating.overcharge or 0)*ChargeValues[difficulties[difficulty]].charge)
            local x = math.floor(((savedRating.charge or 0) + (savedRating.overcharge or 0))/ChargeYield*XChargeYield*ChargeValues[difficulties[difficulty]].xcharge)
            love.graphics.print(c .. "¤", 64+8*(19-#tostring(c)), 128-16)
            love.graphics.print("+" .. o .. "¤", 64+8*(19-#("+" .. tostring(o))), 144-16)
            love.graphics.print(x .. "¤", 64+8*(19-#tostring(x)), 160-16)
            love.graphics.print(math.floor((savedRating.accuracy or 0)*100)  .. "%", 64+8*(19-#tostring(math.floor((savedRating.accuracy or 0)*100))), 176-16)

            love.graphics.printf("TAB - OVERALL", 64, 192, 160, "center")
        else
            local ratings = {}
            for _,diff in ipairs(selected.difficulties) do
                ratings[diff] = Save.Read("songs."..(selected.scorePrefix or "")..selected.name.."."..diff) or {}
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
            love.graphics.print(math.floor((savedRating.accuracy or 0)*100)  .. "%", 64+8*(20-#tostring(math.floor((savedRating.accuracy or 0)*100))), 176-16)

            love.graphics.printf("TAB - CHART", 64, 192, 160, "center")
        end
    end

    DrawBoxHalfWidth(2, 21, 74, 2)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local emblem = Assets.Emblem(selected.songData.emblem)
    local emblemSize = selected.hide and 0 or (emblem and (emblem:getWidth() + 8) or 0)
    local songName = selected.hide and "- NO DATA -" or ((selected.songData or {}).name or "Unrecognized Song")
    love.graphics.print(songName, (640-(utf8.len(songName)*8 + emblemSize))/2 + emblemSize, 352 + (selected.hide and 8 or 0))
    if emblem and not selected.hide then love.graphics.draw(emblem, (640-(utf8.len(songName)*8 + emblemSize))/2, 360, 0, 1, 1, 0, emblem:getHeight()/2) end
    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    if not selected.hide then love.graphics.printf((selected.songData or {}).author or "???", 0, 368, 640, "center") end
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local charter = "???"
    if selected.songData then
        local chart = selected.songData:loadChart(difficulties[difficulty])
        if chart then
            charter = chart.charter or "???"
        end
    end
    if selected.isUnlocked then
        love.graphics.printf("CHARTER: " .. charter, 32, 352, 640, "left")
        love.graphics.printf("COVER ARTIST: " .. ((selected.songData or {}).coverArtist or "???"), 32, 368, 640, "left")
        -- local difficultyName = SongDifficulty[difficulties[SongSelectDifficulty] or "easy"].name or scene.difficulty:upper()
        -- local difficultyColor = SongDifficulty[difficulties[SongSelectDifficulty] or "easy"].color or TerminalColors[ColorID.WHITE]
        -- local diffs = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].difficulties
        -- local difficulty = SongSelectOvervoltMode and (table.index(difficulties, diffs[#diffs]) or 5) or SongSelectDifficulty
        local difficultyLevel = 0
        if selected.songData then
            difficultyLevel = selected.songData:getLevel(difficulties[difficulty])
        end
        -- love.graphics.setColor(difficultyColor)
        -- love.graphics.print(difficultyName, 608 - (#difficultyName + 1 + #tostring(difficultyLevel) + 2) * 8, 360)
        PrintDifficulty(592,360,difficulties[difficulty],difficultyLevel,"right")
        ---@type SongData?
        local data = scene.campaign.sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].songData
        if data then
            local hasEffects = #((data:loadChart(difficulties[difficulty] or "easy") or {}).effects or {}) ~= 0
            if hasEffects then
                local x = 592 - 8 * (utf8.len(SongDifficulty[difficulties[difficulty] or "easy"].name .. (difficultyLevel ~= nil and (" " .. (difficultyLevel or 0)) or "")) + 3)
                love.graphics.print("✨", x, 360)
            end
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        -- love.graphics.print(tostring(difficultyLevel), 608 - (#tostring(difficultyLevel) + 2) * 8, 360)
        if not SongSelectOvervoltMode then love.graphics.print("🡙", 600, 360) end
    end

    -- love.graphics.printf("Press F8 to create a new song in the editor", 32, 400, 576, "left")
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.printf("ESC - Exit", 32, 400, 576, "left")
    local canPlay = selected.isUnlocked and (selected.songData and selected.songData:loadChart(difficulties[difficulty]) ~= nil)
    if not canPlay then
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
    end
    love.graphics.printf("ENTER - Play", 32, 400, 576, "right")
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    if SongSelectHasOvervolt then
        if SongSelectOvervoltMode then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            love.graphics.printf("GO BACK", 32, 400, 576, "center")
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.printf("PRESS O", 32, 416, 576, "center")
        else
            PrintDifficulty(320, 400, "overvolt", nil, "center")
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.printf("PRESS O", 32, 416, 576, "center")
        end
    end
    -- love.graphics.printf("Total Charge: " .. math.floor(scene.totalCharge) .. "¤ (" .. math.floor(scene.totalCharge / scene.potentialCharge * 100) .. "%)", 32, 400, 576, "left")
    -- love.graphics.printf("Total Overcharge: " .. math.floor(scene.totalOvercharge) .. "¤ (" .. math.floor(scene.totalOvercharge / scene.potentialOvercharge * 100) .. "%)", 32, 400, 576, "right")
    -- love.graphics.printf("Total X-Charge: " .. math.floor(scene.totalXCharge) .. "¤ (" .. math.floor(scene.totalXCharge / scene.potentialXCharge * 100) .. "%)", 32, 416, 576, "center")

    for _,section in ipairs(scene.campaign.sections) do
        for i,song in ipairs(section.songs) do
            drawSong(song)
        end
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
end

return scene