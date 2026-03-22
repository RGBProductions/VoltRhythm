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

local sortDisplayTime = 0

local versionWarning = nil

local overvoltWarning = false
local shouldOvervoltWarning = love.filesystem.getInfo("hideovwarning") == nil

local sortMethods = {
    {"default", function(a,b)
        return (table.index(scene.disk.normalSongs, a) or table.index(scene.disk.overvoltSongs, a)) < (table.index(scene.disk.normalSongs, b) or table.index(scene.disk.overvoltSongs, b))
    end, false},
    {"title", function(a,b)
        return ((a.songData or {}).name or "") < ((b.songData or {}).name or "")
    end, false},
    {"difficulty", function(a,b)
        local diff1 = SongDifficultyOrder[SongSelectDifficulty]
        local diff2 = SongDifficultyOrder[SongSelectDifficulty]
        do
            if not table.index(a.difficulties, diff1) then
                for i = 1, 6 do
                    local i1 = table.index(a.difficulties, SongDifficultyOrder[SongSelectDifficulty+i])
                    if i1 then
                        diff1 = a.difficulties[i1]
                        break
                    end
                    local i2 = table.index(a.difficulties, SongDifficultyOrder[SongSelectDifficulty-i])
                    if i2 then
                        diff1 = a.difficulties[i2]
                        break
                    end
                end
            end
        end
        do
            if not table.index(b.difficulties, diff2) then
                for i = 1, 6 do
                    local i1 = table.index(b.difficulties, SongDifficultyOrder[SongSelectDifficulty+i])
                    if i1 then
                        diff2 = b.difficulties[i1]
                        break
                    end
                    local i2 = table.index(b.difficulties, SongDifficultyOrder[SongSelectDifficulty-i])
                    if i2 then
                        diff2 = b.difficulties[i2]
                        break
                    end
                end
            end
        end
        return a.songData:getLevel(diff1) < b.songData:getLevel(diff2)
    end, true}
}

function SongSelectSetSelectedSong(song, difficulty)
    local last = scene.selected.identifier
    
    difficulty = difficulty or SongDifficultyOrder[SongSelectDifficulty]
    local set = (difficulty == "overvolt" or difficulty == "hidden") and scene.sortedOvervolt or scene.sortedNormal
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
        if SongSelectOvervoltMode and (difficulty == "overvolt" or difficulty == "hidden") then
            j = 11-j
        else
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
    
    set = SongSelectOvervoltMode and scene.sortedOvervolt or scene.sortedNormal
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
        previewTimes = data.songPreview or {0,math.huge}
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

function SongSelectSortSongs(method)
    table.sort(scene.sortedNormal, method[2])
    table.sort(scene.sortedOvervolt, method[2])
    for i,itm in ipairs(scene.sortedNormal) do
        itm.position = i-1
    end
    for i,itm in ipairs(scene.sortedOvervolt) do
        itm.position = i-1
    end
    local set = SongSelectOvervoltMode and scene.sortedOvervolt or scene.sortedNormal
    for i = 1, #set do
        if set[i] == scene.selected then
            SongSelectSelectedSong = i
            SongSelectOffsetView:start(scene.selected.position * 128, "outExpo", 0.5)
            break
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

    scene.source = args.source or "songdiskselect"
    scene.destination = args.destination or "game"

    scene.sortedNormal = {}
    scene.sortedOvervolt = {}

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

    for i,song in pairs(scene.disk.normalSongs) do scene.sortedNormal[i] = song end
    for i,song in pairs(scene.disk.overvoltSongs) do scene.sortedOvervolt[i] = song end

    SongSelectSortMethod = SongSelectSortMethod or 1

    local set = SongSelectOvervoltMode and scene.sortedOvervolt or scene.sortedNormal
    if #scene.disk.normalSongs < 1 then
        set = scene.sortedOvervolt
        SongSelectOvervoltMode = true
        SongSelectDifficulty = 5
    end

    SongSelectSortSongs(sortMethods[SongSelectSortMethod])
    scene.selected = set[SongSelectSelectedSong]

    SongSelectHasNormal = #scene.disk.normalSongs > 0
    SongSelectHasOvervolt = #scene.disk.overvoltSongs > 0

    SongSelectOvervoltUnlocked = false
    for _,song in ipairs(scene.disk.overvoltSongs) do
        for _,diff in ipairs(song.difficulties) do
            if song.lock and song.lock:check(scene.disk, diff).passed then
                SongSelectOvervoltUnlocked = true
                break
            end
        end
        if SongSelectOvervoltUnlocked then break end
    end

    SongSelectSetSelectedSong(scene.selected.identifier, SongDifficultyOrder[SongSelectDifficulty])

    if SystemSettings.discord_rpc_level > RPCLevels.PLAYING then
        if SystemSettings.discord_rpc_level == RPCLevels.FULL then
            Discord.setActivity("Selecting a song", "Viewing disk " .. scene.disk.name)
        elseif SystemSettings.discord_rpc_level == RPCLevels.PARTIAL then
            Discord.setActivity("Selecting a song")
        end
        Discord.updatePresence()
    end
end

function scene.action(a)
    if SceneManager.TransitionState.Transitioning then return end
    
    if a == "sort" then
        SongSelectSortMethod = (SongSelectSortMethod % #sortMethods) + 1
        SongSelectSortSongs(sortMethods[SongSelectSortMethod])
        sortDisplayTime = 1
    end
    if a == "back" then
        if overvoltWarning then
            overvoltWarning = false
            return
        end
        if versionWarning then
            versionWarning = nil
            return
        end
        if preview then preview:stop() end
        SceneManager.Transition("scenes/" .. scene.source)
    end
    local set = SongSelectOvervoltMode and scene.sortedOvervolt or scene.sortedNormal
    if a == "right" then
        local lastDiff = SongSelectDifficulty
        SongSelectSetSelectedSong(set[(SongSelectSelectedSong % #set) + 1].identifier, SongDifficultyOrder[SongSelectDifficulty])
        if SongSelectDifficulty ~= lastDiff and sortMethods[SongSelectSortMethod][3] then SongSelectSortSongs(sortMethods[SongSelectSortMethod]) end
    end
    if a == "left" then
        local lastDiff = SongSelectDifficulty
        SongSelectSetSelectedSong(set[((SongSelectSelectedSong - 2) % #set) + 1].identifier, SongDifficultyOrder[SongSelectDifficulty])
        if SongSelectDifficulty ~= lastDiff and sortMethods[SongSelectSortMethod][3] then SongSelectSortSongs(sortMethods[SongSelectSortMethod]) end
    end
    -- local selected = set[SongSelectSelectedSong]
    if a == "up" then
        if scene.selected.songData then
            local diff = table.index(scene.selected.difficulties, SongDifficultyOrder[SongSelectDifficulty])
            diff = diff % #scene.selected.difficulties + 1
            SongSelectDifficulty = table.index(SongDifficultyOrder, scene.selected.difficulties[diff])
        end
        SongSelectDifficultyView:start(SongSelectDifficulty, "outExpo", 0.3)
        if sortMethods[SongSelectSortMethod][3] then SongSelectSortSongs(sortMethods[SongSelectSortMethod]) end
    end
    if a == "down" then
        if scene.selected.songData then
            local diff = table.index(scene.selected.difficulties, SongDifficultyOrder[SongSelectDifficulty])
            diff = (diff - 2) % #scene.selected.difficulties +1
            SongSelectDifficulty = table.index(SongDifficultyOrder, scene.selected.difficulties[diff])
        end
        SongSelectDifficultyView:start(SongSelectDifficulty, "outExpo", 0.3)
        if sortMethods[SongSelectSortMethod][3] then SongSelectSortSongs(sortMethods[SongSelectSortMethod]) end
    end
    if a == "overvolt" and #scene.sortedOvervolt > 0 then
        local nextSet = set == scene.sortedNormal and scene.sortedOvervolt or scene.sortedNormal
        local choice = nextSet[scene.selected.linkedTo or scene.selected.identifier] or nextSet[1]
        if nextSet == scene.sortedOvervolt then
            SongSelectSetSelectedSong(choice.identifier, table.index(choice.difficulties, "overvolt") and "overvolt" or "hidden")
        elseif #nextSet > 0 then
            SongSelectSetSelectedSong(choice.identifier, "extreme")
        end
    end
    if a == "confirm" then
        ---@type SongData
        local data = scene.selected.songData
        local diff = SongDifficultyOrder[SongSelectDifficulty]
        if not data:hasLevel(diff) then return end
        if not scene.selected.unlocks[diff].passed then return end
        local chart = data:loadChart(diff)
        if chart ~= nil and (chart.isOld or chart.isNew or chart.version.name ~= Version.name) and not versionWarning then
            versionWarning = {old = chart.isOld, new = chart.isNew, client = chart.version.name ~= Version.name, version = chart.version}
        else
            versionWarning = nil
            if preview then preview:stop() end
            Autoplay = love.keyboard.isDown("lshift")
            Showcase = Autoplay and love.keyboard.isDown("lctrl")
            SceneManager.Transition("scenes/" .. scene.destination, {songData = data, difficulty = diff, scorePrefix = scene.selected.scorePrefix})
        end
    end
    if a == "show_more" then
        scene.showMore = not scene.showMore
    end
end

function scene.update(dt)
    SongSelectOffsetView:update(dt)
    SongSelectDifficultyView:update(dt)
    sortDisplayTime = sortDisplayTime - dt
end

function scene.draw()
    local binds = {
        back = BindDisplayMode == 1 and Save.Keybind("back")[2] or Save.Keybind("back")[1],
        confirm = BindDisplayMode == 1 and Save.Keybind("confirm")[2] or Save.Keybind("confirm")[1],
        show_more = BindDisplayMode == 1 and Save.Keybind("show_more")[2] or Save.Keybind("show_more")[1],
        overvolt = BindDisplayMode == 1 and Save.Keybind("overvolt")[2] or Save.Keybind("overvolt")[1]
    }

    local set = SongSelectOvervoltMode and scene.sortedOvervolt or scene.sortedNormal
    -- local selected = set[SongSelectSelectedSong]

    local function drawSong(song)
        local pos = song.position * 128
        local x = 320 + pos - SongSelectOffsetView:get()
        if x < -64 or x >= 704 then return end

        local offset = math.max(-1, math.min(1, (pos - SongSelectOffsetView:get())/128))
        local s = 1-(math.abs(offset)*0.25)

        local targetDiff = SongDifficultyOrder[SongSelectDifficulty]
        if not table.index(song.difficulties, targetDiff) then
            for i = 1, 6 do
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
                    DrawText("██", x-48*s+X*16*s, 280-48*s+Y*16*s, nil, nil, nil, 0, s, s)
                end
            end
        end

        local b = song.unlocks[targetDiff].passed and 1 or 0.25
        love.graphics.setColor(0.5*b,0.5*b,0.5*b)
        if song == scene.selected then
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
    local difficulty = SongSelectOvervoltMode and (table.index(SongDifficultyOrder, scene.selected.difficulties[#scene.selected.difficulties]) or 5) or SongSelectDifficulty
    local diffname = SongDifficultyOrder[difficulty]
    local savedRating = Save.Read("songs."..(scene.selected.scorePrefix or "")..scene.selected.identifier.."."..SongDifficultyOrder[difficulty])
    local unlocked = scene.selected.unlocks[diffname].passed
    if not unlocked then
        local numReqs = #scene.selected.unlocks[diffname].conditions
        local y = 152-((numReqs-1)*16)/2
        for i,condition in ipairs(scene.selected.unlocks[diffname].conditions) do
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            if condition.passed then
                love.graphics.setColor(TerminalColors[ColorID.LIGHT_GREEN])
            end
            DrawText(condition.display, 0, y+(i-1)*16, 640, "center")
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
    elseif not savedRating then
        DrawText(Localize("songselect_nodata"), 0, 152, 640, "center")
    else
        DrawText(Localize("score_bestrank"), 0, 112, 640, "center")

        local ratingImage = Ranks[savedRating.rank].image
        love.graphics.draw(ratingImage, 320, 160, 0, 2, 2, ratingImage:getWidth()/2, ratingImage:getHeight()/2)
        if savedRating.plus then love.graphics.draw(Plus, 320, 160, 0, 2, 2, Plus:getWidth()/2, Plus:getHeight()/2) end

        if savedRating.fullOvercharge then
            local foText = Localize("score_max")
            for i = 1, utf8.len(foText) do
                local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
                love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
                DrawText(utf8.sub(foText,i,i), 320-Font:getWidth(foText)/2+Font:getWidth(utf8.sub(foText,1,i-1)), 192)
            end
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        elseif savedRating.fullCombo then
            -- local fcText = "FULL COMBO"
            local fcText = Localize("score_fc")
            love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
            DrawText(fcText, 0, 192, 640, "center")
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end

        if not scene.showMore then
            for i,rating in ipairs(NoteRatings) do
                local x,y = 320+96, 96+(i)*16
                local countString = tostring(savedRating.ratings[i])
                NoteRatings[i].draw(x,y,false)
                love.graphics.setColor(TerminalColors[ColorID.WHITE])
                DrawText(countString, x+8*(20-#(countString)), y)
            end
            -- DrawText("CHARGE: " .. (savedRating.charge or 0) .. " + " .. (savedRating.overcharge or 0) .. "¤", 48, 128)
            DrawText(Localize("score_charge"), 64, 128-16)
            DrawText(Localize("score_overcharge"), 64, 144-16)
            DrawText(Localize("score_xcharge"), 64, 160-16)
            DrawText(Localize("score_acc"), 64, 176-16)
            
            local c = math.floor((savedRating.charge or 0)*ChargeValues[SongDifficultyOrder[difficulty]].charge)
            local o = math.floor((savedRating.overcharge or 0)*ChargeValues[SongDifficultyOrder[difficulty]].charge)
            local x = math.floor(((savedRating.charge or 0) + (savedRating.overcharge or 0))/ChargeYield*XChargeYield*ChargeValues[SongDifficultyOrder[difficulty]].xcharge)
            DrawText(c .. "¤", 64+8*(19-#tostring(c)), 128-16)
            DrawText("+" .. o .. "¤", 64+8*(19-#("+" .. tostring(o))), 144-16)
            DrawText(x .. "¤", 64+8*(19-#tostring(x)), 160-16)
            DrawText(math.floor((savedRating.accuracy or 0)*100*100)/100 .. "%", 64+8*(19-#tostring(math.floor((savedRating.accuracy or 0)*100*100)/100)), 176-16)
        else
            local ratings = {}
            for _,diff in ipairs(scene.selected.difficulties) do
                ratings[diff] = Save.Read("songs."..(scene.selected.scorePrefix or "")..scene.selected.identifier.."."..diff) or {}
            end
            local c,o,x = 0,0,0
            for diff,rating in pairs(ratings) do
                c = c + (rating.charge or 0)*ChargeValues[diff].charge
                o = o + (rating.overcharge or 0)*ChargeValues[diff].charge
                x = x + ((rating.charge or 0) + (rating.overcharge or 0))/ChargeYield*XChargeYield*ChargeValues[diff].xcharge
            end
            c,o,x = math.floor(c),math.floor(o),math.floor(x)

            DrawText(Localize("score_charge_total"), 320+88, 128-16)
            DrawText(Localize("score_overcharge_total"), 320+88, 144-16)
            DrawText(Localize("score_xcharge_total"), 320+88, 160-16)
            
            DrawText(c .. "¤", 320+80+8*(22-#tostring(c)), 128-16)
            DrawText("+" .. o .. "¤", 320+80+8*(22-#("+" .. tostring(o))), 144-16)
            DrawText(x .. "¤", 320+80+8*(22-#tostring(x)), 160-16)

            local pc = math.floor((savedRating.charge or 0))
            local po = math.floor((savedRating.overcharge or 0))
            local px = math.floor(((savedRating.charge or 0) + (savedRating.overcharge or 0))/ChargeYield*XChargeYield)

            DrawText(Localize("score_charge_raw"), 64-8, 128-16)
            DrawText(Localize("score_overcharge_raw"), 64-8, 144-16)
            DrawText(Localize("score_xcharge_raw"), 64-8, 160-16)
            DrawText(Localize("score_acc_raw"), 64-8, 176-16)
            
            DrawText(pc .. "¤", 64+8*(20-#tostring(pc)), 128-16)
            DrawText("+" .. po .. "¤", 64+8*(20-#("+" .. tostring(po))), 144-16)
            DrawText(px .. "¤", 64+8*(20-#tostring(px)), 160-16)
            DrawText(math.floor((savedRating.accuracy or 0)*100*100)/100 .. "%", 64+8*(20-#tostring(math.floor((savedRating.accuracy or 0)*100*100)/100)), 176-16)
        end

        DrawText(Localize(scene.showMore and "nav_chart" or "nav_overall", KeyLabel(binds.show_more)), 64, 192, 160, "center")
    end

    DrawBoxHalfWidth(2, 21, 74, 3)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local hide = (scene.selected.lock or {}).hideUntilUnlocked and not unlocked
    local emblem = Assets.Emblem(scene.selected.songData.emblem)
    local emblemSize = hide and 0 or (emblem and (emblem:getWidth() + 8) or 0)
    local songName = hide and Localize("songselect_nodata") or ((scene.selected.songData or {}).name or "Unrecognized Song")
    DrawText(songName, (640-(utf8.len(songName)*8 + emblemSize))/2 + emblemSize, 352 + (hide and 16 or 0))
    if emblem and not hide then love.graphics.draw(emblem, (640-(utf8.len(songName)*8 + emblemSize))/2, 360, 0, 1, 1, 0, emblem:getHeight()/2) end
    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    if not hide then
        DrawText((scene.selected.songData or {}).author or "???", 0, 368, 640, "center")
        local source = Assets.Source((scene.selected.songData or {}).songPath)
        if source then
            local time = ReadableTime(source:getDuration("seconds"))
            DrawText(((scene.selected.songData or {}).bpm or "?") .. " BPM - " .. time, 0, 384, 640, "center")
        end
    end
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local charter = "???"
    if scene.selected.songData then
        local chart = scene.selected.songData:loadChart(SongDifficultyOrder[difficulty])
        if chart then
            charter = chart.charter or "???"
        end
    end
    if unlocked then
        DrawText(Localize("songselect_charter", charter), 32, 360, 640, "left")
        DrawText(Localize("songselect_cover", ((scene.selected.songData or {}).coverArtist or "???")), 32, 376, 640, "left")

        ---@type SongData?
        local data = scene.selected.songData
        for _,diff in ipairs(scene.selected.difficulties) do
            local index = table.index(SongDifficultyOrder, diff)
            local p = (index - SongSelectDifficultyView:get())
            if p >= -1.5 and p <= 1.5 and ((SongSelectOvervoltMode and (diff == "overvolt" or diff == "hidden")) or (not SongSelectOvervoltMode and not (diff == "overvolt" or diff == "hidden"))) then
                local difficultyLevel = 0
                if scene.selected.songData then
                    difficultyLevel = scene.selected.songData:getLevel(diff)
                end
                love.graphics.setColor(index == SongSelectDifficulty and {1,1,1} or {0.5,0.5,0.5})
                PrintDifficulty(592,368 - p*16,diff,difficultyLevel,"right")
                if data then
                    local hasEffects = #((data:loadChart(diff or "easy") or {}).effects or {}) ~= 0
                    if hasEffects then
                        local x = 592 - (Font:getWidth(Localize("difficulty_"..diff) .. (difficultyLevel ~= nil and (" " .. (difficultyLevel or 0)) or "")) + 24)
                        DrawText("✨", x, 368 - p*16)
                    end
                end
            end
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if #scene.selected.difficulties > 1 then DrawText("🡙", 600, 368) end
    end

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawText(Localize("nav_exit", KeyLabel(binds.back)), 32, 416, 576, "left")
    local canPlay = unlocked and (scene.selected.songData and scene.selected.songData:loadChart(SongDifficultyOrder[difficulty]) ~= nil)
    if not canPlay then
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
    end
    DrawText(Localize("nav_play", KeyLabel(binds.confirm)), 32, 416, 576, "right")
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    if SongSelectHasOvervolt and SongSelectHasNormal then
        if SongSelectOvervoltMode then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            DrawText(Localize("songselect_goback"), 32, 416, 576, "center")
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        elseif SongSelectOvervoltUnlocked then
            PrintDifficulty(320, 416, "overvolt", nil, "center")
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end
        if SongSelectOvervoltMode or SongSelectOvervoltUnlocked then
            DrawText(Localize("songselect_overvolt", KeyLabel(binds.overvolt)), 32, 432, 576, "center")
        end
    end

    for i,song in ipairs(set) do
        drawSong(song)
    end

    if sortDisplayTime > 0 then
        local text = Localize("sorted", Localize("sort_" .. sortMethods[SongSelectSortMethod][1]))
        local w = Font:getWidth(text)
        DrawBoxHalfWidth(40-w/16-2, 15.5, w/8+2, 1)
        DrawText(text, 0, 264, 640, "center")
    end

    if askToDelete then
        local w = math.max(32, utf8.len(songName)+2)
        local x = 40-w/2-1
        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1,1,1)
        DrawBoxHalfWidth(x, 10, w, 8)
        DrawText(Localize("warning_delete_score_title", songName), 0, 176, 640, "center")
        DrawText(Localize("warning_delete_score"), 0, 240, 640, "center")
        DrawText(Localize("nav_no", KeyLabel(binds.back)), x*8+16, 288, w*8-16, "left")
        DrawText(Localize("nav_yes", KeyLabel(binds.confirm)), x*8+16, 288, w*8-16, "right")
    end

    if overvoltWarning then
        local w = math.max(32, utf8.len(songName)+2)
        local x = 40-w/2-1
        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1,1,1)
        DrawBoxHalfWidth(x, 8.5, w, 11)
        DrawText(Localize("warning_overvolt_title"), 0, 152, 640, "center")
        DrawText(Localize("warning_overvolt"), x*8+16, 184, w*8-16, "center")
        DrawText(Localize("nav_dismiss", KeyLabel(binds.back)), x*8+16, 312, w*8-16, "center")
    end

    if versionWarning then
        local w = 48
        local x = 40-w/2-1
        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1,1,1)
        DrawBoxHalfWidth(x, 8.5, w, 11)
        DrawText(Localize("warning_version_title"), 0, 152, 640, "center")
        DrawText(Localize("warning_version", Localize(versionWarning.old and "warning_version_old" or (versionWarning.new and "warning_version_new" or "warning_version_client")), ((versionWarning.version.name ~= nil and versionWarning.version.version ~= nil) and (versionWarning.version.name .. " v" .. versionWarning.version.version) or "Unknown"), Version.name .. " v" .. Version.version), x*8+16, 184, w*8-16, "center")
        DrawText(Localize("nav_back", KeyLabel(binds.back)), x*8+16, 312, w*8-16, "left")
        DrawText(Localize("nav_play_anyway", KeyLabel(binds.confirm)), x*8+16, 312, w*8-16, "right")
    end
end

return scene