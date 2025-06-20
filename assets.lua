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

local previews = {}

---@return love.Source?
function Assets.Preview(path,section)
    if not path then return nil end
    if previews[path] then return previews[path] end
    if not love.filesystem.getInfo(path) then return nil end
    local s,r = pcall(love.sound.newSoundData, path)
    if not s then return nil end
    section = section or {0,r:getDuration()}
    section[1] = math.max(0,section[1] or 0)
    section[2] = math.min(r:getDuration(),section[2] or r:getDuration())
    local rate = r:getSampleRate()
    local channels = r:getChannelCount()
    local result = love.sound.newSoundData(math.floor((section[2]-section[1])*rate), rate, r:getBitDepth(), channels)
    local A = math.floor(section[1]*rate)*channels-2
    for i = A, math.floor(section[2]*rate)*channels-3 do
        local S,R = pcall(r.getSample, r, i)
        if S then
            pcall(result.setSample, result, i-A, R)
        end
    end
    local source = love.audio.newSource(result)
    previews[path] = source
    return previews[path]
end

function Assets.ManualAddPreview(path,data)
    previews[path] = data
end

function Assets.ErasePreview(path)
    previews[path] = nil
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

function Assets.GetDefaultCover(name)
    local hashed = love.data.hash("md5", name)
    return defaultCovers[((hashed:byte(1,1) % hashed:byte(2,2)) % #defaultCovers) + 1]
end

local covers = {}
local animatedCovers = {}

function Assets.GetAnimatedCover(path,animSpeed)
    if animatedCovers[path] then return animatedCovers[path][math.floor(love.timer.getTime() * animSpeed) % #animatedCovers[path] + 1] end
    if not love.filesystem.getInfo(path.."/cover.png") then
        return Assets.GetCover(path)
    end
    animatedCovers[path] = {}
    local data = love.image.newImageData(path.."/cover.png")
    local s = data:getHeight()
    local sprites = math.floor(data:getWidth()/s)
    for i = 1, sprites do
        local img = love.image.newImageData(s,s)
        img:paste(data, 0, 0, (i-1)*s, 0, s, s)
        animatedCovers[path][i] = love.graphics.newImage(img)
    end
    return animatedCovers[path][math.floor(love.timer.getTime() * animSpeed) % #animatedCovers[path] + 1]
end

function Assets.GetCover(path,animSpeed)
    if animSpeed then
        return Assets.GetAnimatedCover(path,animSpeed)
    end
    if covers[path] then return covers[path] end
    if not love.filesystem.getInfo(path.."/cover.png") then
        local splitPath = path:split("/")
        covers[path] = Assets.GetDefaultCover(splitPath[#splitPath])
    else
        covers[path] = love.graphics.newImage(path.."/cover.png")
    end
    return covers[path]
end

function Assets.EraseCover(path)
    covers[path] = nil
end

local icons = {}

function Assets.ProfileIcon(name)
    if icons[name] then return icons[name] end
    if not love.filesystem.getInfo("images/profile/"..name..".png") then
        return nil
    end
    icons[name] = love.graphics.newImage("images/profile/"..name..".png")
    return icons[name]
end

local emblems = {}

function Assets.Emblem(name)
    if emblems[name] then return emblems[name] end
    if not name then
        return nil
    end
    if not love.filesystem.getInfo("images/emblem/"..name..".png") then
        return nil
    end
    emblems[name] = love.graphics.newImage("images/emblem/"..name..".png")
    return emblems[name]
end