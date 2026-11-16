utf8 = require "utf8"

function utf8.sub(txt, i, j)
    local o1 = (utf8.offset(txt,i) or (#txt))
    local o2 = (utf8.offset(txt,j+1) or (#txt+1))-1
    return txt:sub(o1,o2)
end

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

function ReadableTime(s)
    s = math.floor(math.max(0, s))
    local m = tostring(math.floor(s/60))
    s = tostring(s % 60)
    return m .. ":" .. ("0"):rep(2-#s)..s
end

function ReadableTimeCenti(s)
    local cs = math.floor(math.max(0, s)*100) % 100
    s = math.floor(math.max(0, s))
    local m = tostring(math.floor(s/60))
    s = tostring(s % 60)
    return m .. ":" .. ("0"):rep(2-#s)..s .. "." .. ("0"):rep(2-#tostring(cs))..cs
end

function SixteenthsToSeconds(t,bpm)
    return 15*t/bpm
end

function SecondsToSixteenths(t,bpm)
    return bpm*t/15
end

function GetNoteCellY(time, speed, laneMod, offset, chartY, chartHeight, upscroll)
    if upscroll then
        return chartY + 2 + (time * laneMod + offset) * speed
    end
    return chartY + chartHeight - (time * laneMod + offset) * speed
end

function ScreenToDisplay(x,y)
    local curveStrength = SystemSettings.enable_screen_effects and SystemSettings.screen_effects.screen_curvature*CurveModifier:get() or 0
    local s = math.min(love.graphics.getWidth()/Display:getWidth(), love.graphics.getHeight()/Display:getHeight())
    x = x - (love.graphics.getWidth()-Display:getWidth()*s)/2
    y = y - (love.graphics.getHeight()-Display:getHeight()*s)/2
    local u,v = x/(Display:getWidth()*s), y/(Display:getHeight()*s)
    local cx,cy = 2*u-1, 2*v-1
    local cl = math.sqrt(cx*cx+cy*cy)
    local cf = math.sqrt(1+curveStrength*cl*cl)/math.sqrt(1+curveStrength)
    local crx,cry = cx*cf,cy*cf
    local U,V = (crx+1)/2, (cry+1)/2
    return U*640, V*480
end