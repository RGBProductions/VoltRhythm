Campaign = {
    NumCampaigns = 0
}

local campaigns = {}
local loaded = {}
local songnames = {}

function Campaign.Retrieve()
    for _,file in ipairs(love.filesystem.getDirectoryItems("campaign")) do
        local s,r = pcall(json.decode, love.filesystem.read("campaign/" .. file))
        if s then
            for _,campaign in ipairs(r) do
                local foundC = false
                for _,data in ipairs(campaigns) do
                    if data.name == campaign.name then
                        for _,section in ipairs(campaign.sections) do
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
                    table.insert(campaigns, campaign)
                end
            end
        end
    end
    Campaign.NumCampaigns = #campaigns
end

function Campaign.Get(campaign)
    for _,data in ipairs(campaigns) do
        if data.name == campaign then
            return data
        end
    end
    return nil
end

function Campaign.GetChargeMetrics(campaign)
    if type(campaign) == "string" then
        campaign = Campaign.Get(campaign)
    end
    local metrics = {
        totalCharge = 0,
        totalOvercharge = 0,
        totalXCharge = 0,
        potentialCharge = 0,
        potentialOvercharge = 0,
        potentialXCharge = 0
    }
    if not campaign then return metrics end
    for s,section in ipairs(campaign.sections) do
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

function Campaign.Load(campaign)
    if loaded[campaign] then
        return loaded[campaign]
    end
    if type(campaign) == "string" then
        campaign = Campaign.Get(campaign)
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
    if not campaign then return metrics end
    local lastPosition = 0
    local lastOVPosition = 0
    for s,section in ipairs(campaign.sections) do
        for S,song in ipairs(section.songs) do
            metrics.songCount = metrics.songCount + 1
            section.songs[S] = {
                name = song.song,
                difficulties = song.difficulties,
                lock = song.lock or {},
                songData = LoadSongData("songs/" .. song.song),
                cover = Assets.GetCover("songs/" .. song.song),
            }
            if section.songs[S].songData then
                section.songs[S].preview = Assets.Preview(section.songs[S].songData.songPath, section.songs[S].songData.songPreview)
            end
            metrics.songNames[song.song] = (section.songs[S].songData or {}).name or song.song
            for _,name in ipairs(song.difficulties) do
                if name == "overvolt" or name == "hidden" then
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
    loaded[campaign.name] = metrics
    return metrics
end

function Campaign.GetTotalProgress()
    local scores = {
        totalCharge = 0,
        totalOvercharge = 0,
        totalXCharge = 0,
        potentialCharge = 0,
        potentialOvercharge = 0,
        potentialXCharge = 0
    }
    for _,campaign in pairs(campaigns) do
        if not campaign.unscored then
            for s,section in ipairs(campaign.sections) do
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

function Campaign.GetScores(campaign)
    if type(campaign) == "string" then
        campaign = Campaign.Get(campaign)
    end
    local scores = {
        totalCharge = 0,
        totalOvercharge = 0,
        totalXCharge = 0,
        potentialCharge = 0,
        potentialOvercharge = 0,
        potentialXCharge = 0
    }
    if not campaign then return scores end
    if campaign.unscored then
        return scores
    end
    for s,section in ipairs(campaign.sections) do
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

function Campaign.GetByIndex(i)
    return campaigns[((i-1) % #campaigns) + 1]
end