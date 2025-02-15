local utf8 = require "utf8"

local scene = {}

local num = 0

local index = 1
local timer = 0
local accepting = {false,0,0}
local reading = {false,""}

local lines = {}

local opening = {
    {type = "line", text = "VOLTRPPGS INIT STARTED", duration = 0.01},
    {type = "line", text = Version.name .. " v" .. Version.version, duration = 0.01},
    {type = "line", text = "Scanning for boot devices...", duration = 0.08},
    {type = "line", text = "Booting from /dev/fd0", duration = 0.1},
    {type = "line", text = "READING SONG DATA AT /dev/fd1", duration = 0},
    {type = "run", func = function()
        for _,song in ipairs(love.filesystem.getDirectoryItems("songs")) do
            local songData = LoadSongData("songs/" .. song)
            if songData then
                Assets.Preview(songData.songPath, songData.songPreview)
                num = num + 1
            end
        end
    end},
    {type = "dynamic", func = function()
        return "FOUND " .. num .. " SONGS"
    end},
    {type = "line", text = "READING STORY DATA AT /dev/fd2", duration = 0.05},
    {type = "line", text = "E: could not read /dev/fd2: no such file or directory", color = ColorID.LIGHT_RED, duration = 0.01},
    {type = "line", text = "RETRIEVING PROFILE INFORMATION", duration = 0.05},
    {type = "run", func = function()
        local loadedProfile = Save.Load()
        if loadedProfile then
            index = 20
        end
        print(loadedProfile)
    end},
    {type = "line", text = "NO PROFILES FOUND", duration = 0},
    {type = "accept", text = "CREATE A PROFILE? (Y/N) ", yes = 16, no = 14},
    {type = "line", text = "REJECTED, SHUTTING DOWN", duration = 2},
    {type = "run", func = function()
        love.event.push("quit")
    end},
    {type = "read", text = "TYPE A PROFILE NAME: "},
    {type = "dynamic", func = function()
        return "CREATING PROFILE " .. reading[2]
    end, duration = 0},
    {type = "run", func = function()
        Save.SetProfile(reading[2])
    end},
    {type = "pause", duration = 1},
    {type = "line", text = "PROFILE CREATED", duration = 0.1},
    {type = "line", text = "VOLTOS BOOT FINISHED", duration = 0.05},
    {type = "run", func = function()
        SuppressBorder = false
        SceneManager.Transition("scenes/menu")
    end}
}

SuppressBorder = true

local function handle()
    if opening[index] then
        local d = opening[index]
        local t = d.type
        if t == "line" then
            table.insert(lines, {text = d.text, color = d.color or ColorID.WHITE})
        end
        if t == "accept" then
            table.insert(lines, {text = d.text, color = d.color or ColorID.WHITE})
            accepting[1] = true
            accepting[2] = d.yes
            accepting[3] = d.no
        end
        if t == "read" then
            table.insert(lines, {text = d.text, color = d.color or ColorID.WHITE})
            reading[1] = true
            reading[2] = ""
        end
        if t == "dynamic" then
            table.insert(lines, {text = d.func(), color = d.color or ColorID.WHITE})
        end
        if t == "run" then
            d.func()
        end
    end
end

handle()

function scene.update(dt)
    timer = timer + dt
    if not accepting[1] and not reading[1] and timer >= ((opening[index] or {}).duration or 0) then
        timer = 0
        index = index + 1
        if opening[index] then
            handle()
        end
    end
end

function scene.keypressed(k)
    if accepting[1] then
        if k == "y" or k == "return" then
            accepting[1] = false
            index = accepting[2]-1
            timer = 0
            lines[#lines].text = lines[#lines].text .. "Y"
        end
        if k == "n" or k == "escape" then
            accepting[1] = false
            index = accepting[3]-1
            timer = 0
            lines[#lines].text = lines[#lines].text .. "N"
        end
    end
    if reading[1] then
        if k == "backspace" then
            local offset = utf8.offset(reading[2], -1)
            if offset then
                reading[2] = reading[2]:sub(1,offset-1)
            end
        end
        if k == "return" then
            lines[#lines].text = lines[#lines].text .. reading[2]
            reading[1] = false
            timer = 0
        end
    end
end

function scene.textinput(t)
    if reading[1] then
        reading[2] = reading[2] .. t
    end
end

function scene.draw()
    local pos = 0
    local x = 0
    for _,line in ipairs(lines) do
        love.graphics.setColor(TerminalColors[line.color or ColorID.WHITE])
        local _,wrap = Font:getWrap(line.text, 640)
        love.graphics.printf(line.text, 16, pos+16, 640)
        pos = pos + 16 * #wrap
        x = Font:getWidth(wrap[#wrap])
    end
    if reading[1] then
        love.graphics.print(reading[2],x+16,pos)
        x = x + Font:getWidth(reading[2])
    end
    love.graphics.print(love.timer.getTime() % 0.5 <= 0.25 and "█" or "",(accepting[1] or reading[1]) and x+16 or 16, (accepting[1] or reading[1]) and pos or pos+16)
end

return scene