SongDisk = {
    Disks = {}
}

local defaultIcon = love.graphics.newImage("images/songdisk/default.png")

local function scaffold(name,iconPath)
    local disk = {
        name = name,
        icon = defaultIcon,
        normalSongs = {},
        overvoltSongs = {},
        allSongs = {},
        unscored = false,
        metrics = {
            totalCharge = 0,
            totalOvercharge = 0,
            totalXCharge = 0,
            charge = 0,
            overcharge = 0,
            xcharge = 0
        }
    }
    local s,r = pcall(love.graphics.newImage, iconPath)
    if s then
        disk.icon = r
    end
    return disk
end

local function add(list, object)
    if not list[object.identifier] then
        table.insert(list, object)
        list[object.identifier] = object
    end
end

local function copy(obj)
    return {
        position = obj.position,
        identifier = obj.identifier,
        linkedTo = obj.linkedTo,
        songData = obj.songData,
        scorePrefix = obj.scorePrefix,
        difficulties = obj.difficulties,
        lock = obj.lock
    }
end

local fullLibrary = scaffold("FULL LIBRARY", "images/songdisk/full_library.png")
fullLibrary.unscored = true

function SongDisk.AddSongs(disk, songs, songSource, addToFL)
    for _,song in ipairs(songs) do
        local songData = LoadSongData(songSource .. "/" .. song.song)
        if songData then
            local lock = Lock:new(song.lock)
            local normalObject = {
                position = #disk.normalSongs,
                identifier = song.song,
                linkedTo = songData.linkedTo,
                songData = songData,
                scorePrefix = song.scorePrefix,
                difficulties = {},
                lock = lock
            }
            local overvoltObject = {
                position = #disk.overvoltSongs,
                identifier = song.song,
                linkedTo = songData.linkedTo,
                songData = songData,
                scorePrefix = song.scorePrefix,
                difficulties = {},
                lock = lock
            }
            for _,diff in ipairs(song.difficulties) do
                if diff ~= "overvolt" and diff ~= "hidden" then
                    table.insert(normalObject.difficulties, diff)
                else
                    table.insert(overvoltObject.difficulties, diff)
                end

                disk.metrics.totalCharge = disk.metrics.totalCharge + 160*ChargeValues[diff].charge
                disk.metrics.totalOvercharge = disk.metrics.totalOvercharge + 40*ChargeValues[diff].charge
                disk.metrics.totalXCharge = disk.metrics.totalXCharge + 50*ChargeValues[diff].xcharge
                local savedRating = Save.Read("songs."..(song.scorePrefix or "")..(song.song or song.name).."."..diff)
                if savedRating then
                    disk.metrics.charge = disk.metrics.charge + savedRating.charge*ChargeValues[diff].charge
                    disk.metrics.overcharge = disk.metrics.overcharge + savedRating.overcharge*ChargeValues[diff].charge
                    disk.metrics.xcharge = disk.metrics.xcharge + (savedRating.charge+savedRating.overcharge)/ChargeYield*XChargeYield*ChargeValues[diff].xcharge
                end
            end

            local flNObject = copy(normalObject)
            local flOObject = copy(normalObject)
            flNObject.position = #fullLibrary.normalSongs
            flOObject.position = #fullLibrary.overvoltSongs

            if #normalObject.difficulties > 0 then
                add(disk.normalSongs, normalObject)
                table.insert(disk.allSongs, normalObject)
                if addToFL then add(fullLibrary.normalSongs, flNObject) table.insert(fullLibrary.allSongs, flNObject) end
            end
            if #overvoltObject.difficulties > 0 then
                add(disk.overvoltSongs, overvoltObject)
                table.insert(disk.allSongs, overvoltObject)
                if addToFL then add(fullLibrary.overvoltSongs, flOObject) table.insert(fullLibrary.allSongs, flOObject) end
            end
        end
    end
end

function SongDisk.Load(path, songSource)
    songSource = songSource or "songs"

    local s,data = pcall(json.decode, love.filesystem.read(path))
    if not s then return end

    local disk = scaffold(data.name, data.icon)

    SongDisk.AddSongs(disk, data.songs, songSource, true)

    table.insert(SongDisk.Disks, disk)
    SongDisk.Disks[disk.name] = disk
end

function SongDisk.LoadAll()
    local items = love.filesystem.getDirectoryItems("songdisk") or {}
    table.sort(items)
    for _,itm in ipairs(items) do
        SongDisk.Load("songdisk/" .. itm, "songs")
    end
    if #SongDisk.Disks > 1 then
        table.insert(SongDisk.Disks, fullLibrary)
        SongDisk.Disks[fullLibrary.name] = fullLibrary
    end
    local customSongs = love.filesystem.getDirectoryItems("custom")
    if #customSongs > 0 then
        local custom = scaffold("CUSTOM", "images/songdisk/custom.png")
        local songs = {}
        for _,itm in ipairs(customSongs) do
            local data = LoadSongData("custom/"..itm)
            if data then
                local diffs = {}
                for _,diff in ipairs(SongDifficultyOrder) do
                    if data:hasLevel(diff) then
                        table.insert(diffs, diff)
                    end
                end
                table.insert(songs, {
                    song = itm,
                    scorePrefix = "custom_",
                    difficulties = diffs
                })
            end
        end
        custom.unscored = true
        SongDisk.AddSongs(custom, songs, "custom", false)
        table.insert(SongDisk.Disks, custom)
        SongDisk.Disks[custom.name] = custom
    end
end

local function rescore(disk,song)
    for _,diff in ipairs(song.difficulties) do
        disk.metrics.totalCharge = disk.metrics.totalCharge + 160*ChargeValues[diff].charge
        disk.metrics.totalOvercharge = disk.metrics.totalOvercharge + 40*ChargeValues[diff].charge
        disk.metrics.totalXCharge = disk.metrics.totalXCharge + 50*ChargeValues[diff].xcharge
        local savedRating = Save.Read("songs."..(song.scorePrefix or "")..(song.identifier or song.name).."."..diff)
        if savedRating then
            disk.metrics.charge = disk.metrics.charge + savedRating.charge*ChargeValues[diff].charge
            disk.metrics.overcharge = disk.metrics.overcharge + savedRating.overcharge*ChargeValues[diff].charge
            disk.metrics.xcharge = disk.metrics.xcharge + (savedRating.charge+savedRating.overcharge)/ChargeYield*XChargeYield*ChargeValues[diff].xcharge
        end
    end
end

function SongDisk.RecalculateScores()
    for _,disk in ipairs(SongDisk.Disks) do
        disk.metrics.totalCharge = 0
        disk.metrics.totalOvercharge = 0
        disk.metrics.totalXCharge = 0
        disk.metrics.charge = 0
        disk.metrics.overcharge = 0
        disk.metrics.xcharge = 0
        for _,song in ipairs(disk.normalSongs) do
            rescore(disk, song)
        end
        for _,song in ipairs(disk.overvoltSongs) do
            rescore(disk, song)
        end
    end
end