Save = {}

local file = {}

function Save.Flush()
    love.filesystem.write("save.json", json.encode(file))
end

function Save.Load()
    local s,r = pcall(json.decode, love.filesystem.read("save.json"))
    if s then
        file = r
        return true
    else
        return false,r
    end
end

function Save.Write(key,value)
    file[key] = value
end

function Save.Read(key)
    return file[key]
end