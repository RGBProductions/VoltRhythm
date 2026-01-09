return function()
    local data = love.filesystem.read("version")
    while data:find("\r") do
        data = data:gsub("\r","")
    end
    local lines = data:split("\n")
    return {name = lines[1], version = lines[2], code = tonumber(lines[3])}
end