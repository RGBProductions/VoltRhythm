Save = {
    Profile = ""
}

local profiles = {}

local defaultSave = {
    name = "Profile",
    icon = "icon1",
    main_color = ColorID.LIGHT_RED,
    accent_color = ColorID.BLUE,
    songs = {},
    keybinds = {"a","s","k","l"},
    note_colors = {ColorID.LIGHT_RED, ColorID.YELLOW, ColorID.LIGHT_GREEN, ColorID.LIGHT_BLUE},
    mine_color = ColorID.RED,
    border = "none",
    scroll_speed = 25,
    enable_hit_sounds = false
}

function Save.Flush()
    if not love.filesystem.getInfo("save") then
        love.filesystem.createDirectory("save")
    end
    for name,data in pairs(profiles) do
        love.filesystem.write("save/" .. name .. ".json", json.encode(data))
    end
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
    love.filesystem.write("lastprofile", Save.Profile)
end

---@param key string
---@param value any
function Save.Write(key,value)
    if not profiles[Save.Profile] then return end
    local cur = profiles[Save.Profile]
    local spl = key:split("%.")
    local finalKey = table.remove(spl,#spl)
    finalKey = tonumber(finalKey) or finalKey
    for _,v in ipairs(spl) do
        v = tonumber(v) or v
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
    finalKey = tonumber(finalKey) or finalKey
    for _,v in ipairs(spl) do
        v = tonumber(v) or v
        if not cur[v] then
            return
        end
        cur = cur[v]
    end
    return cur[finalKey]
end

function Save.GetProfileList()
    local list = {}
    local saveProfile = Save.Profile
    for k,v in pairs(profiles) do
        Save.Profile = k
        local scores = SongDisk.GetTotalProgress()
        table.insert(list, {id = k, name = v.name, icon = v.icon, main_color = v.main_color, accent_color = v.accent_color, scores = scores, lastAccess = v.lastAccess or 0})
    end
    Save.Profile = saveProfile
    table.sort(list, function (a, b)
        return (a.lastAccess or 0) > (b.lastAccess or 0)
    end)
    return list
end