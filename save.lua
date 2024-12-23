Save = {
    Profile = ""
}

local profiles = {}

local defaultSave = {
    name = "Broken Profile",
    songs = {}
}

function Save.Flush()
    if not love.filesystem.getInfo("save") then
        love.filesystem.createDirectory("save")
    end
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
        Save.SetProfile(lastProfile)
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
    profiles[Save.Profile].lastAccess = os.time()
end

---@param key string
---@param value any
function Save.Write(key,value)
    if not profiles[Save.Profile] then return end
    local cur = profiles[Save.Profile]
    local spl = key:split("%.")
    local finalKey = table.remove(spl,#spl)
    for _,v in ipairs(spl) do
        if not cur[v] then
            cur[v] = {}
        end
        cur = cur[v]
    end
    cur[finalKey] = value
end

function Save.Read(key)
    if not profiles[Save.Profile] then return end
    local cur = profiles[Save.Profile]
    local spl = key:split("%.")
    local finalKey = table.remove(spl,#spl)
    for _,v in ipairs(spl) do
        if not cur[v] then
            return
        end
        cur = cur[v]
    end
    return cur[finalKey]
end

function Save.GetProfileList()
    local list = {}
    for k,v in pairs(profiles) do
        table.insert(list, {id = k, name = v.name, lastAccess = v.lastAccess or 0})
    end
    table.sort(list, function (a, b)
        return (a.lastAccess or 0) > (b.lastAccess or 0)
    end)
    return list
end