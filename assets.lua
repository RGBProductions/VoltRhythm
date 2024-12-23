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
    local rate = r:getSampleRate()
    local channels = r:getChannelCount()
    local result = love.sound.newSoundData(math.floor((section[2]-section[1])*rate), rate, r:getBitDepth(), channels)
    local A = math.floor(section[1]*rate)*channels-2
    local OOR = 0
    for i = A, math.floor(section[2]*rate)*channels-3 do
        pcall(result.setSample, result, i-A,r:getSample(i))
    end
    local source = love.audio.newSource(result)
    previews[path] = source
    return previews[path]
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

local defaultCovers = {
    love.graphics.newImage("images/default0.png"),
    love.graphics.newImage("images/default1.png"),
    love.graphics.newImage("images/default2.png"),
    love.graphics.newImage("images/default3.png"),
    love.graphics.newImage("images/default4.png"),
    love.graphics.newImage("images/default5.png")
}

function Assets.GetDefaultCover(name)
    local hashed = love.data.hash("md5", name)
    return defaultCovers[((hashed:byte(1,1) % hashed:byte(2,2)) % #defaultCovers) + 1]
end

local covers = {}

function Assets.GetCover(path)
    if covers[path] then return covers[path] end
    if not love.filesystem.getInfo(path.."/cover.png") then
        covers[path] = Assets.GetDefaultCover(path)
    else
        covers[path] = love.graphics.newImage(path.."/cover.png")
    end
    return covers[path]
end