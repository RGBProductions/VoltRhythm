Borders = {
    Borders = {
        none = {info = {name = "NONE"}, script = nil}
    },
    Categories = {}
}

local function imageBorder(path)
    local image = love.graphics.newImage(path.."/border.png")
    return {
        draw = function() love.graphics.draw(image) end
    }
end

function Borders.Load(path)
    local s,info = pcall(json.decode, love.filesystem.read(path.."/info.json"))
    if not s then return nil end
    local images = {}
    for k,v in pairs(info.images or {}) do
        local s2,im = pcall(love.graphics.newImage, path.."/"..v)
        if s2 then
            images[k] = im
        end
    end
    local script = nil
    local c,e = love.filesystem.load(path.."/border.lua")
    if c then
        local s2,sc = pcall(c, images)
        if s2 then
            script = sc
        end
    end
    if not script and love.filesystem.getInfo(path.."/border.png") then
        script = imageBorder(path)
    end
    return {info = info, script = script}
end

function Borders.LoadAll(dir)
    local result = {}
    for _,itm in ipairs(love.filesystem.getDirectoryItems(dir)) do
        local p = dir.."/"..itm
        local info = love.filesystem.getInfo(p)
        if info.type == "directory" then
            if love.filesystem.getInfo(p.."/info.json") then
                local border = Borders.Load(p)
                if border then
                    table.insert(result, {id = itm, border = border})
                end
            else
                for _,border in ipairs(Borders.LoadAll(p)) do
                    table.insert(result, border)
                end
            end
        end
    end
    return result
end

function Borders.Retrieve()
    local allcat = {
        name = "ALL",
        borders = {}
    }
    local borders = Borders.LoadAll("borders")
    for _,border in ipairs(borders) do
        Borders.Borders[border.id] = border.border
        for _,category in ipairs(border.border.info.categories or {}) do
            if not Borders.Categories[category] then
                local cat = {name = category, borders = {}}
                table.insert(Borders.Categories, cat)
                Borders.Categories[category] = cat
            end
            table.insert(Borders.Categories[category].borders, border.id)
        end
        table.insert(allcat.borders, border.id)
    end
    table.sort(Borders.Categories, function (a, b)
        return a.name < b.name
    end)
    table.insert(Borders.Categories, 1, allcat)
    Borders.Categories["ALL"] = allcat
    for _,category in ipairs(Borders.Categories) do
        table.sort(category.borders, function (a, b)
            return Borders.Borders[a].info.name < Borders.Borders[b].info.name
        end)
        table.insert(category.borders, 1, "none")
    end
end

function Borders.Get(id)
    return Borders.Borders[id]
end