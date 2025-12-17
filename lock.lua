Lock = {}
Lock.__index = Lock

local ignoreMerger = function(a,b) return a end
local overwriteMerger = function(a,b) return b end

local function songName(name)
    return (LoadSongData("songs/"..name) or {name = name}).name
end

local mergers = {
    play_song = ignoreMerger,
    charge = function(a,b)
        a.amount = math.max(a.amount or 0, b.amount or 0)
        return a
    end,
    overcharge = function(a,b)
        a.amount = math.max(a.amount or 0, b.amount or 0)
        return a
    end,
    xcharge = function(a,b)
        a.amount = math.max(a.amount or 0, b.amount or 0)
        return a
    end
}

local unlockers = {
    play_song = function(condition, disk)
        local diffs = Save.Read("songs."..condition.song)
        if not diffs then return 0, 1 end
        if not condition.difficulty then return 1, 0 end
        return (diffs[condition.difficulty] ~= nil) and 1 or 0, 1
    end,
    charge = function(condition, disk)
        local required = condition.amount
        local test = disk.metrics.charge
        if condition.song then
            test = 0
            local diffs = Save.Read("songs."..condition.song)
            if diffs then
                if condition.difficulty then
                    local rating = diffs[condition.difficulty]
                    if rating then
                        test = rating.charge*ChargeValues[condition.difficulty].charge
                    end
                else
                    for diff,rating in ipairs(diffs) do
                        test = test + rating.charge*ChargeValues[diff].charge
                    end
                end
            end
        end
        return test, required
    end,
    overcharge = function(condition, disk)
        local required = condition.amount
        local test = disk.metrics.overcharge
        if condition.song then
            test = 0
            local diffs = Save.Read("songs."..condition.song)
            if diffs then
                if condition.difficulty then
                    local rating = diffs[condition.difficulty]
                    if rating then
                        test = rating.overcharge*ChargeValues[condition.difficulty].charge
                    end
                else
                    for diff,rating in ipairs(diffs) do
                        test = test + rating.overcharge*ChargeValues[diff].charge
                    end
                end
            end
        end
        return test, required
    end,
    xcharge = function(condition, disk)
        local required = condition.amount
        local test = disk.metrics.xcharge
        if condition.song then
            test = 0
            local diffs = Save.Read("songs."..condition.song)
            if diffs then
                if condition.difficulty then
                    local rating = diffs[condition.difficulty]
                    if rating then
                        test = (rating.charge+rating.overcharge)/ChargeYield*XChargeYield*ChargeValues[condition.difficulty].xcharge
                    end
                else
                    for diff,rating in ipairs(diffs) do
                        test = test + (rating.charge+rating.overcharge)/ChargeYield*XChargeYield*ChargeValues[diff].xcharge
                    end
                end
            end
        end
        return test, required
    end
}

local displays = {
    play_song = function(condition, disk)
        return "Play " .. songName(condition.song) .. " on " .. (condition.difficulty ~= nil and condition.difficulty:upper() or "any difficulty")
    end,
    charge = function(condition, disk)
        local progress, max = unlockers.charge(condition, disk)
        if condition.song then
            return "Gather " .. condition.amount .. " charge in " .. condition.song .. " on " .. (condition.difficulty ~= nil and condition.difficulty:upper() or "any difficulty") .. " (" .. math.floor(progress) .. " / " .. max .. ")"
        else
            return "Gather " .. condition.amount .. " total charge in this disk (" .. math.floor(progress) .. " / " .. max .. ")"
        end
    end,
    overcharge = function(condition, disk)
        local progress, max = unlockers.overcharge(condition, disk)
        if condition.song then
            return "Gather " .. condition.amount .. " overcharge in " .. condition.song .. " on " .. (condition.difficulty ~= nil and condition.difficulty:upper() or "any difficulty") .. " (" .. math.floor(progress) .. " / " .. max .. ")"
        else
            return "Gather " .. condition.amount .. " total overcharge in this disk (" .. math.floor(progress) .. " / " .. max .. ")"
        end
    end,
    xcharge = function(condition, disk)
        local progress, max = unlockers.xcharge(condition, disk)
        if condition.song then
            return "Gather " .. condition.amount .. " X-charge in " .. condition.song .. " on " .. (condition.difficulty ~= nil and condition.difficulty:upper() or "any difficulty") .. " (" .. math.floor(progress) .. " / " .. max .. ")"
        else
            return "Gather " .. condition.amount .. " total X-charge in this disk (" .. math.floor(progress) .. " / " .. max .. ")"
        end
    end
}

function Lock:new(data)
    if not data then return nil end

    local lock = setmetatable({}, Lock)

    lock.hideUntilUnlocked = data.hideUntilUnlocked
    lock.conditions = {}

    for _,diff in ipairs(SongDifficultyOrder) do
        lock.conditions[diff] = {}
        for _,condition in ipairs((data.conditions or {}).global or {}) do
            if unlockers[condition.type] then
                table.insert(lock.conditions[diff], table.merge({}, condition))
            end
        end
        for _,condition in ipairs((data.conditions or {})[diff] or {}) do
            if unlockers[condition.type] then
                local merged = false
                for i,other in ipairs(lock.conditions[diff]) do
                    if condition.type == other.type and condition.song == other.song then
                        local result = mergers[condition.type](other, condition)
                        if result then
                            lock.conditions[diff][i] = result
                            merged = true
                            break
                        end
                    end
                end
                if not merged then
                    table.insert(lock.conditions[diff], table.merge({}, condition))
                end
            end
        end
    end

    return lock
end

function Lock:check(disk, difficulty)
    local result = {passed = true, conditions = {}}
    for _,condition in ipairs(self.conditions[difficulty] or {}) do
        local unlocker = unlockers[condition.type]
        if unlocker then
            local progress, max, showProgress = unlocker(condition, disk)
            local display = "Meet unlock condition: " .. json.encode(condition)
            if displays[condition.type] then
                display = displays[condition.type](condition, disk)
            end
            table.insert(result.conditions, {condition = condition, display = display, progress = progress, required = max, passed = progress >= max, showProgress = showProgress})
            if progress < max then
                result.passed = false
            end
        end
    end
    return result
end