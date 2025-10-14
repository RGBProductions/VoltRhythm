Save = {
    Profile = ""
}

local profiles = {}

local disallowed = "[%s-\\/:%*%?\"<>|]"

local defaultSave = {
    name = "Profile",
    icon = "icon1",
    main_color = ColorID.LIGHT_RED,
    accent_color = ColorID.BLUE,
    songs = {},
    keybinds = {
        lanes = {
            {{"key","a"},{"gtrigger","triggerleft"}},
            {{"key","s"},{"gbutton","leftshoulder"}},
            {{"key","k"},{"gbutton","rightshoulder"}},
            {{"key","l"},{"gtrigger","triggerright"}}
        },
        pause = {{"key","escape"},{"gbutton","start"}},
        back = {{"key","escape"},{"gbutton","b"}},
        confirm = {{"key","return"},{"gbutton","a"}},
        restart = {{"key","r"},{"gbutton","y"}},
        overvolt = {{"key","o"},{"gbutton","y"}},
        show_more = {{"key","tab"},{"gbutton","x"}},
        edit_profile = {{"key","e"},{"gbutton","y"}},
        menu_left = {{"key","left"},{"gbutton","dpleft"}}, -- implicit: left stick left
        menu_right = {{"key","right"},{"gbutton","dpright"}}, -- implicit: left stick right
        menu_up = {{"key","up"},{"gbutton","dpup"}}, -- implicit: left stick up
        menu_down = {{"key","down"},{"gbutton","dpdown"}} -- implicit: left stick down
    },
    note_colors = {ColorID.LIGHT_RED, ColorID.YELLOW, ColorID.LIGHT_GREEN, ColorID.LIGHT_BLUE},
    mine_color = ColorID.RED,
    border = "none",
    note_skin = "dots",
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
        
        -- Keybinds upgrade
        local binds = profiles[file:sub(1,-6)].keybinds
        if type(binds[1]) == "table" then
            -- Broken format; needs to be fixed
            local old = profiles[file:sub(1,-6)].keybinds
            binds = table.merge({}, defaultSave.keybinds)
            binds.lanes = old
        end
        if type(binds[1]) == "string" then
            -- Old format; needs to upgrade
            binds.lanes = {
                {{"key",binds[1]},{"gtrigger","triggerleft"}},
                {{"key",binds[2]},{"gbutton","leftshoulder"}},
                {{"key",binds[3]},{"gbutton","rightshoulder"}},
                {{"key",binds[4]},{"gtrigger","triggerright"}}
            }
            binds[1] = nil
            binds[2] = nil
            binds[3] = nil
            binds[4] = nil
        end
        profiles[file:sub(1,-6)].keybinds = binds
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
    Save.Profile = profile:lower():gsub(disallowed, "_")
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