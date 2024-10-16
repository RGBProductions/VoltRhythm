Assets = {}

local sources = {}

---@return love.Source?
function Assets.Source(path)
    if not path then return nil end
    if sources[path] then return sources[path] end
    if not love.filesystem.getInfo(path) then return nil end
    local s,r = pcall(love.audio.newSource, path, "stream")
    if not s then return nil end
    sources[path] = r
    return sources[path]
end

local videos = {}

---@return love.Video?
function Assets.Video(path)
    if not path then return nil end
    if videos[path] then return videos[path] end
    if not love.filesystem.getInfo(path) then return nil end
    local s,r = pcall(love.graphics.newVideo, path)
    if not s then return nil end
    videos[path] = r
    return videos[path]
end

local backgrounds = {}

---@return table?
function Assets.Background(path)
    if not path then return nil end
    if backgrounds[path] then return backgrounds[path] end
    if not love.filesystem.getInfo(path) then return nil end
    local c,e = love.filesystem.load(path)
    if not c then return nil end
    local s,r = pcall(c)
    if not s then return nil end
    backgrounds[path] = r
    return backgrounds[path]
end