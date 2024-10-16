Save = {
    Profile = ""
}

local profiles = {}

local defaultSave = {
    name = "Broken Profile",
    charge = 0,
    overcharge = 0
}

function Save.Flush()
    for name,data in pairs(profiles) do
        love.filesystem.write("save/" .. name .. ".json", json.encode(data))
    end
    love.filesystem.write("lastprofile", Save.Profile)
end

function Save.Load()
    for _,file in ipairs(love.filesystem.getDirectoryItems("save")) do
        local s,r = pcall(json.decode, love.filesystem.read("save/" .. file))
        if s then
            profiles[file:sub(1,-6)] = table.merge(table.merge({}, defaultSave), r)
        else
            profiles[file:sub(1,-6)] = table.merge({}, defaultSave)
        end
    end
    local lastProfile = love.filesystem.read("lastprofile")
    if lastProfile and profiles[lastProfile] then
        Save.Profile = lastProfile
        return true
    end
    return false
end

---@param profile string
function Save.SetProfile(profile)
    Save.Profile = profile:lower():gsub("[%s-]", "_")
    if not profiles[Save.Profile] then
        profiles[Save.Profile] = table.merge({}, defaultSave)
        profiles[Save.Profile].name = profile
    end
end

function Save.Write(key,value)
    profiles[Save.Profile][key] = value
end

function Save.Read(key)
    return profiles[Save.Profile][key]
end