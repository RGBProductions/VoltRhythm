SongDisk = {
    NumDisks = 0
}

local disks = {}
local loaded = {}
local songnames = {}

function SongDisk.Retrieve()
    local function l(disk)
        local foundC = false
        for _,data in ipairs(disks) do
            if data.name == disk.name then
                for _,section in ipairs(disk.sections) do
                    local foundS = false
                    for _,section2 in ipairs(data.sections) do
                        if section2.name == section.name then
                            for _,song in ipairs(section.songs) do
                                table.insert(section2.songs, song)
                            end
                            foundS = true
                            break
                        end
                    end
                    if not foundS then
                        table.insert(data.sections, section)
                    end
                end
                foundC = true
                break
            end
        end
        if not foundC then
            table.insert(disks, disk)
        end
    end
    for _,file in ipairs(love.filesystem.getDirectoryItems("songdisk")) do
        local s,r = pcall(json.decode, love.filesystem.read("songdisk/" .. file))
        if s then
            for _,disk in ipairs(r) do
                l(disk)
                l({
                    name = "FULL LIBRARY",
                    sections = table.merge({}, disk.sections)
                })
            end
        end
    end
    if #love.filesystem.getDirectoryItems("custom") > 0 then
        local songs = {}
        for _,song in ipairs(love.filesystem.getDirectoryItems("custom")) do
            local s,info = pcall(json.decode, love.filesystem.read("custom/"..song.."/info.json"))
            if s then
                local data = {song = song, difficulties = {}}
                for name,_ in pairs(info.charts) do
                    table.insert(data.difficulties, name)
                end
                table.insert(songs, data)
            end
        end
        local disk = {
            name = "CUSTOM SONGS",
            source = "custom",
            icon = "images/menu/edit.png",
            sections = {
                {
                    name = "custom",
                    songs = songs
                }
            }
        }
        l(disk)
    end
    SongDisk.NumDisks = #disks
end

function SongDisk.Get(disk)
    for _,data in ipairs(disks) do
        if data.name == disk then
            return data
        end
    end
    return nil
end

function SongDisk.GetChargeMetrics(disk)
    if type(disk) == "string" then
        disk = SongDisk.Get(disk)
    end
    local metrics = {
        totalCharge = 0,
        totalOvercharge = 0,
        totalXCharge = 0,
        potentialCharge = 0,
        potentialOvercharge = 0,
        potentialXCharge = 0
    }
    if not disk then return metrics end
    for s,section in ipairs(disk.sections) do
        for S,song in ipairs(section.songs) do
            for _,name in ipairs(song.difficulties) do
                metrics.potentialCharge = metrics.potentialCharge + 160*ChargeValues[name].charge
                metrics.potentialOvercharge = metrics.potentialOvercharge + 40*ChargeValues[name].charge
                metrics.potentialXCharge = metrics.potentialXCharge + 50*ChargeValues[name].xcharge
                local savedRating = Save.Read("songs."..song.name.."."..name)
                if savedRating then
                    metrics.totalCharge = metrics.totalCharge + savedRating.charge*ChargeValues[name].charge
                    metrics.totalOvercharge = metrics.totalOvercharge + savedRating.overcharge*ChargeValues[name].charge
                    metrics.totalXCharge = metrics.totalXCharge + (savedRating.charge+savedRating.overcharge)/ChargeYield*XChargeYield*ChargeValues[name].xcharge
                end
            end
        end
    end
    return metrics
end

function SongDisk.Load(disk)
    if loaded[disk] then
        return loaded[disk]
    end
    if type(disk) == "string" then
        disk = SongDisk.Get(disk)
    end
    local metrics = {
        songCount = 0,
        songNames = {},
        positions = {},
        positionsByName = {},
        overvoltPositions = {},
        overvoltPositionsByName = {},
        totalCharge = 0,
        totalOvercharge = 0,
        totalXCharge = 0,
        potentialCharge = 0,
        potentialOvercharge = 0,
        potentialXCharge = 0
    }
    if not disk then return metrics end
    local lastPosition = 0
    local lastOVPosition = 0
    for s,section in ipairs(disk.sections) do
        for S,song in ipairs(section.songs) do
            metrics.songCount = metrics.songCount + 1
            section.songs[S] = {
                name = song.song,
                difficulties = song.difficulties,
                lock = song.lock or {},
                songData = LoadSongData((disk.source or "songs") .. "/" .. song.song),
                cover = Assets.GetCover((disk.source or "songs") .. "/" .. song.song),
            }
            if section.songs[S].songData then
                section.songs[S].preview = Assets.Preview(section.songs[S].songData.songPath, section.songs[S].songData.songPreview)
            end
            metrics.songNames[song.song] = (section.songs[S].songData or {}).name or song.song
            for _,name in ipairs(song.difficulties) do
                if name == "overvolt" or name == "hidden" then
                    disk.hasOvervolt = true
                    metrics.overvoltPositions[section.songs[S]] = lastOVPosition
                    metrics.overvoltPositionsByName[song.song] = lastOVPosition
                    lastOVPosition = lastOVPosition + 1
                elseif not metrics.positions[section.songs[S]] then
                    metrics.positions[section.songs[S]] = lastPosition
                    metrics.positionsByName[song.song] = lastPosition
                    lastPosition = lastPosition + 1
                end
                metrics.potentialCharge = metrics.potentialCharge + 160*ChargeValues[name].charge
                metrics.potentialOvercharge = metrics.potentialOvercharge + 40*ChargeValues[name].charge
                metrics.potentialXCharge = metrics.potentialXCharge + 50*ChargeValues[name].xcharge
                local savedRating = Save.Read("songs."..song.song.."."..name)
                if savedRating then
                    metrics.totalCharge = metrics.totalCharge + savedRating.charge*ChargeValues[name].charge
                    metrics.totalOvercharge = metrics.totalOvercharge + savedRating.overcharge*ChargeValues[name].charge
                    metrics.totalXCharge = metrics.totalXCharge + (savedRating.charge+savedRating.overcharge)/ChargeYield*XChargeYield*ChargeValues[name].xcharge
                    local reRank, rePlus = GetRank(savedRating.accuracy)
                    Save.Write("songs."..song.song.."."..name..".rank", reRank)
                    Save.Write("songs."..song.song.."."..name..".plus", rePlus)
                end
            end
        end
    end
    loaded[disk.name] = metrics
    return metrics
end

function SongDisk.GetTotalProgress()
    local scores = {
        totalCharge = 0,
        totalOvercharge = 0,
        totalXCharge = 0,
        potentialCharge = 0,
        potentialOvercharge = 0,
        potentialXCharge = 0
    }
    for _,disk in pairs(disks) do
        if not disk.unscored then
            for s,section in ipairs(disk.sections) do
                for S,song in ipairs(section.songs) do
                    for _,name in ipairs(song.difficulties) do
                        scores.potentialCharge = scores.potentialCharge + 160*ChargeValues[name].charge
                        scores.potentialOvercharge = scores.potentialOvercharge + 40*ChargeValues[name].charge
                        scores.potentialXCharge = scores.potentialXCharge + 50*ChargeValues[name].xcharge
                        local savedRating = Save.Read("songs."..(song.song or song.name).."."..name)
                        if savedRating then
                            scores.totalCharge = scores.totalCharge + savedRating.charge*ChargeValues[name].charge
                            scores.totalOvercharge = scores.totalOvercharge + savedRating.overcharge*ChargeValues[name].charge
                            scores.totalXCharge = scores.totalXCharge + (savedRating.charge+savedRating.overcharge)/ChargeYield*XChargeYield*ChargeValues[name].xcharge
                        end
                    end
                end
            end
        end
    end
    scores.percentCompleted = (scores.totalCharge+scores.totalOvercharge)/(scores.potentialCharge+scores.potentialOvercharge)
    return scores
end

function SongDisk.GetScores(disk)
    if type(disk) == "string" then
        disk = SongDisk.Get(disk)
    end
    local scores = {
        totalCharge = 0,
        totalOvercharge = 0,
        totalXCharge = 0,
        potentialCharge = 0,
        potentialOvercharge = 0,
        potentialXCharge = 0
    }
    if not disk then return scores end
    if disk.unscored then
        return scores
    end
    for s,section in ipairs(disk.sections) do
        for S,song in ipairs(section.songs) do
            for _,name in ipairs(song.difficulties) do
                scores.potentialCharge = scores.potentialCharge + 160*ChargeValues[name].charge
                scores.potentialOvercharge = scores.potentialOvercharge + 40*ChargeValues[name].charge
                scores.potentialXCharge = scores.potentialXCharge + 50*ChargeValues[name].xcharge
                local savedRating = Save.Read("songs."..(song.song or song.name).."."..name)
                if savedRating then
                    scores.totalCharge = scores.totalCharge + savedRating.charge*ChargeValues[name].charge
                    scores.totalOvercharge = scores.totalOvercharge + savedRating.overcharge*ChargeValues[name].charge
                    scores.totalXCharge = scores.totalXCharge + (savedRating.charge+savedRating.overcharge)/ChargeYield*XChargeYield*ChargeValues[name].xcharge
                end
            end
        end
    end
    return scores
end

function SongDisk.GetByIndex(i)
    return disks[((i-1) % #disks) + 1]
end