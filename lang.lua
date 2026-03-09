local format = (require "lume").format

local languages = {}

function LoadLanguages()
    languages = {}
    for _,itm in ipairs(love.filesystem.getDirectoryItems("lang")) do
        local name = itm:sub(1,-6)
        languages[name] = json.decode(love.filesystem.read("lang/" .. itm))
    end
end

LoadLanguages()

function GetLanguages()
    local res = {}
    for code,lang in pairs(languages) do
        table.insert(res, {code = code, name = lang.language_name or code})
    end
    table.sort(res, function (a, b)
        if b.code:sub(1,2) == "en" and a.code:sub(1,2) ~= "en" then
            return false
        end
        if a.code:sub(1,2) == "en" and b.code:sub(1,2) ~= "en" then
            return true
        end
        return a.code < b.code
    end)
    return res
end

function Localize(str, ...)
    local lang = SystemSettings.language or "en-US"
    if not languages[lang] then lang = "en-US" end
    local chain = {}
    while languages[lang][str] == nil and lang ~= "en-US" and not chain[lang] do
        chain[lang] = true
        lang = languages[lang].fallback or "en-US"
    end
    return format(languages[lang][str] or str, {...})
end

function GetLangName(lang)
    return languages[lang]["language_name"]
end