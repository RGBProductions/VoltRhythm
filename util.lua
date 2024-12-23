function string.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function getPathOf(file)
    local spl = string.split(file, "/")
    table.remove(spl, #spl)
    return table.concat(spl, "/")
end

function table.merge(a,b)
    for k,v in pairs(b) do
        if type(v) == "table" then
            if type(a[k]) ~= "table" then
                a[k] = {}
            end
            a[k] = table.merge(a[k], v)
        else
            a[k] = v
        end
    end
    return a
end