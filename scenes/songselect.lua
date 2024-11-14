local utf8 = require "utf8"

local scene = {}

---@type love.Source|nil
local preview = nil
local previewTimes = {0,math.huge}

local function playSong(songInfo)
    if preview then preview:stop() end
    if not songInfo then return end
    if not songInfo.songData then return end
    preview = Assets.Source(songInfo.songData.songPath)
    previewTimes = songInfo.songData.songPreview or {0,math.huge}
    if preview then
        preview:setLooping(true)
        preview:seek(previewTimes[1], "seconds")
        preview:play()
    end
end

function scene.update(dt)
    if preview then
        if preview:tell("seconds") >= previewTimes[2] then
            preview:seek(preview:tell("seconds") - (previewTimes[2] - previewTimes[1]), "seconds")
        end
    end

    local blendAmt = 1/((5/4) ^ 60)
    local blend = blendAmt^dt
    SongSelectOffsetView = blend*(SongSelectOffsetView - SongSelectOffsetViewTarget) + SongSelectOffsetViewTarget
end

local difficulties = {
    "easy", "medium", "hard", "extreme", "overvolt"
}

function scene.load()
    scene.campaigns = json.decode(love.filesystem.read("campaign/campaigns.json"))
    SongSelectSelectedSong = SongSelectSelectedSong or 1
    SongSelectSelectedSection = SongSelectSelectedSection or 1
    SongSelectOffsetView = SongSelectOffsetView or 0
    SongSelectOffsetViewTarget = SongSelectOffsetViewTarget or 0
    SongSelectDifficulty = SongSelectDifficulty or 3
    scene.totalCharge = 0
    scene.totalOvercharge = 0
    scene.potentialCharge = 0
    scene.potentialOvercharge = 0
    scene.positions = {}
    scene.songCount = 0
    local lastPosition = 0
    for c,campaign in ipairs(scene.campaigns) do
        for s,section in ipairs(campaign.sections) do
            for S,song in ipairs(section.songs) do
                scene.positions[song] = lastPosition
                lastPosition = lastPosition + 1
                scene.songCount = scene.songCount + 1
                section.songs[S] = {
                    name = song,
                    songData = LoadSongData("songs/" .. song),
                    cover = Assets.GetCover("songs/" .. song)
                }
                for name,difficulty in pairs((section.songs[S].songData or {}).charts or {}) do
                    scene.potentialCharge = scene.potentialCharge + 160
                    scene.potentialOvercharge = scene.potentialOvercharge + 40
                    local savedRating = Save.Read("songs."..song.."."..name)
                    if savedRating then
                        scene.totalCharge = scene.totalCharge + savedRating.charge
                        scene.totalOvercharge = scene.totalOvercharge + savedRating.overcharge
                    end
                end
            end
        end
    end
    playSong(scene.campaigns[1].sections[SongSelectSelectedSection].songs[SongSelectSelectedSong])
end

local function finishSelection()
    local selected = scene.campaigns[1].sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
    if selected.songData then
        if not selected.songData:hasLevel(difficulties[SongSelectDifficulty]) then
            for i = 1, 3 do
                if selected.songData:hasLevel(difficulties[SongSelectDifficulty-i]) then
                    SongSelectDifficulty = SongSelectDifficulty-i
                    break
                end
                if selected.songData:hasLevel(difficulties[SongSelectDifficulty+i]) then
                    SongSelectDifficulty = SongSelectDifficulty+i
                    break
                end
            end
        end
    end
    playSong(selected)
end

function scene.keypressed(k)
    if k == "f8" then
        if preview then
            preview:stop()
            preview:setLooping(false)
        end
        SceneManager.Transition("scenes/editor")
    end
    if k == "right" then
        SongSelectSelectedSong = SongSelectSelectedSong + 1
        if SongSelectSelectedSong > #scene.campaigns[1].sections[SongSelectSelectedSection].songs then
            SongSelectSelectedSection = (SongSelectSelectedSection % #scene.campaigns[1].sections) + 1
            SongSelectSelectedSong = 1
        end
        SongSelectOffsetViewTarget = scene.positions[scene.campaigns[1].sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].name] * 128
        finishSelection()
    end
    if k == "left" then
        SongSelectSelectedSong = SongSelectSelectedSong - 1
        if SongSelectSelectedSong <= 0 then
            SongSelectSelectedSection = ((SongSelectSelectedSection - 2) % #scene.campaigns[1].sections) + 1
            SongSelectSelectedSong = #scene.campaigns[1].sections[1].songs
        end
        SongSelectOffsetViewTarget = scene.positions[scene.campaigns[1].sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].name] * 128
        finishSelection()
    end
    if k == "up" then
        local selected = scene.campaigns[1].sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
        if selected.songData then
            -- SongSelectDifficulty = (SongSelectDifficulty % 5) + 1
            repeat
                SongSelectDifficulty = (SongSelectDifficulty % 5) + 1
            until selected.songData:hasLevel(difficulties[SongSelectDifficulty])
        end
    end
    if k == "down" then
        local selected = scene.campaigns[1].sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]
        if selected.songData then
            -- SongSelectDifficulty = ((SongSelectDifficulty - 2) % 5) + 1
            repeat
                SongSelectDifficulty = ((SongSelectDifficulty - 2) % 5) + 1
            until selected.songData:hasLevel(difficulties[SongSelectDifficulty])
        end
    end

    if k == "return" then
        local songData = scene.campaigns[1].sections[SongSelectSelectedSection].songs[SongSelectSelectedSong].songData
        if songData then
            if preview then
                preview:stop()
                preview:setLooping(false)
            end
            SceneManager.Transition("scenes/game", {songData = songData, difficulty = difficulties[SongSelectDifficulty]})
        end
    end
end

local songselectText = love.graphics.newImage("images/songselect.png")

function scene.draw()
    local selected = scene.campaigns[1].sections[SongSelectSelectedSection].songs[SongSelectSelectedSong]

    local function drawSong(song)
        local pos = scene.positions[song.name] * 128
        local x = 320 + pos - SongSelectOffsetView
        if x < -64 or x >= 704 then return end

        local offset = math.max(-1, math.min(1, (pos - SongSelectOffsetView)/128))
        local s = 1-(math.abs(offset)*0.25)

        local savedRating = Save.Read("songs."..song.name.."."..difficulties[SongSelectDifficulty])
        if savedRating and savedRating.fullOvercharge then
            -- draw the overcharge outline
            for Y = -0.5, 5.5 do
                for X = -0.5, 5.5 do
                    local color = TerminalColors[OverchargeColors[(math.floor(love.timer.getTime()*6 + (Y-X))%#OverchargeColors)+1]]
                    love.graphics.setColor(color)
                    love.graphics.print("██", x-48*s+X*16*s, 280-48*s+Y*16*s, 0, s, s)
                end
                -- do
                --     local color = TerminalColors[OverchargeColors[(math.floor(love.timer.getTime()*6 + Y)%#OverchargeColors)+1]]
                --     love.graphics.setColor(color)
                --     love.graphics.print("██", x-48*s+-0.5*16*s, 280-48*s+Y*16*s, 0, s, s)
                -- end
                -- do
                --     local color = TerminalColors[OverchargeColors[(math.floor(love.timer.getTime()*6 - Y)%#OverchargeColors)+1]]
                --     love.graphics.setColor(color)
                --     love.graphics.print("██", x-48*s+5.5*16*s, 280-48*s+Y*16*s, 0, s, s)
                -- end
                -- end
            end
            -- for X = 0.5, 4.5 do
            --     -- for X = -0.5, 5.5 do
            --     do
            --         local color = TerminalColors[OverchargeColors[(math.floor(love.timer.getTime()*6 - X)%#OverchargeColors)+1]]
            --         love.graphics.setColor(color)
            --         love.graphics.print("██", x-48*s+X*16*s, 280-48*s+-0.5*16*s, 0, s, s)
            --     end
            --     do
            --         local color = TerminalColors[OverchargeColors[(math.floor(love.timer.getTime()*6 + X)%#OverchargeColors)+1]]
            --         love.graphics.setColor(color)
            --         love.graphics.print("██", x-48*s+X*16*s, 280-48*s+5.5*16*s, 0, s, s)
            --     end
            --     -- end
            -- end
        end

        love.graphics.setColor(0.5,0.5,0.5)
        if song == selected then
            love.graphics.setColor(1,1,1)
        end
        love.graphics.draw(song.cover, x, 280, 0, s, s, 48, 48)
        love.graphics.setColor(1,1,1)
    end

    love.graphics.setColor(1,1,1)

    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(songselectText, 320, 32, 0, 2, 2, songselectText:getWidth()/2, 0)

    DrawBoxHalfWidth(2, 6, 74, 6)
    local savedRating = Save.Read("songs."..selected.name.."."..difficulties[SongSelectDifficulty])
    if not savedRating then
        love.graphics.printf("- NO DATA -", 0, 152, 640, "center")
    else
        love.graphics.printf("BEST RANK", 0, 112, 640, "center")

        local ratingImage = Ranks[savedRating.rank].image
        love.graphics.draw(ratingImage, 320, 160, 0, 2, 2, ratingImage:getWidth()/2, ratingImage:getHeight()/2)

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

        for i,rating in ipairs(NoteRatings) do
            local x,y = 320+96, 96+(i)*16
            local countString = tostring(savedRating.ratings[i])
            NoteRatings[i].draw(x,y,false)
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.print(countString, x+8*(20-#(countString)), y)
        end
        -- love.graphics.print("CHARGE: " .. (savedRating.charge or 0) .. " + " .. (savedRating.overcharge or 0) .. "¤", 48, 128)
        love.graphics.print("CHARGE", 64, 128)
        love.graphics.print("OVERCHARGE", 64, 144)
        love.graphics.print("X-CHARGE", 64, 160)
        love.graphics.print("ACCURACY", 64, 176)
        
        love.graphics.print((savedRating.charge or 0) .. "¤", 64+8*(19-#tostring(savedRating.charge or 0)), 128)
        love.graphics.print("+" .. (savedRating.overcharge or 0) .. "¤", 64+8*(19-#("+" .. tostring(savedRating.overcharge or 0))), 144)
        love.graphics.print((savedRating.xcharge or 0) .. "¤", 64+8*(19-#tostring(savedRating.xcharge or 0)), 160)
        love.graphics.print(math.floor((savedRating.accuracy or 0)*100)  .. "%", 64+8*(19-#tostring(math.floor((savedRating.accuracy or 0)*100))), 176)
    end

    DrawBoxHalfWidth(2, 21, 74, 2)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local songName = (selected.songData or {}).name or "Unrecognized Song"
    love.graphics.print(songName, (640-utf8.len(songName)*8)/2, 352)
    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    love.graphics.printf((selected.songData or {}).author or "???", 0, 368, 640, "center")
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local charter = "???"
    if selected.songData then
        local chart = selected.songData:loadChart(difficulties[SongSelectDifficulty])
        if chart then
            charter = chart.charter or "???"
        end
    end
    love.graphics.printf("CHARTER: " .. charter, 32, 352, 640, "left")
    love.graphics.printf("COVER ARTIST: " .. ((selected.songData or {}).coverArtist or "???"), 32, 368, 640, "left")
    -- local difficultyName = SongDifficulty[difficulties[SongSelectDifficulty] or "easy"].name or scene.difficulty:upper()
    -- local difficultyColor = SongDifficulty[difficulties[SongSelectDifficulty] or "easy"].color or TerminalColors[ColorID.WHITE]
    local difficultyLevel = 0
    if selected.songData then
        difficultyLevel = selected.songData:getLevel(difficulties[SongSelectDifficulty])
    end
    -- love.graphics.setColor(difficultyColor)
    -- love.graphics.print(difficultyName, 608 - (#difficultyName + 1 + #tostring(difficultyLevel) + 2) * 8, 360)
    PrintDifficulty(592,360,difficulties[SongSelectDifficulty],difficultyLevel,"right")
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    -- love.graphics.print(tostring(difficultyLevel), 608 - (#tostring(difficultyLevel) + 2) * 8, 360)
    love.graphics.print("🡙", 600, 360)

    -- love.graphics.printf("Press F8 to create a new song in the editor", 32, 400, 576, "left")
    -- love.graphics.printf("Total Charge: " .. scene.totalCharge .. "¤ (" .. math.floor(scene.totalCharge / scene.potentialCharge * 100) .. "%)", 32, 400, 576, "left")
    -- love.graphics.printf("Total Overcharge: " .. scene.totalOvercharge .. "¤ (" .. math.floor(scene.totalOvercharge / scene.potentialOvercharge * 100) .. "%)", 32, 400, 576, "right")

    for _,section in ipairs(scene.campaigns[1].sections) do
        for i,song in ipairs(section.songs) do
            drawSong(song)
        end
    end
end

return scene