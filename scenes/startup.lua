local utf8 = require "utf8"

local scene = {}

local num = 0
local done = 0
local missed = {}

local index = 1
local timer = 0
local accepting = {false,0,0}
local reading = {false,""}

local lines = {}
local loadedProfile = false

local opening = {
    {type = "line", text = "VOLTRPPGS INIT STARTED", duration = 0.01},
    {type = "line", text = Version.name .. " v" .. Version.version, duration = 0.01},
    {type = "line", text = "Scanning for boot devices...", duration = 0.08},
    {type = "line", text = "Booting from /dev/fd0", duration = 0.1},
    {type = "line", text = "READING SONG DATA AT /dev/fd1", duration = 0},
    {type = "run", func = function()
        local channels = {}
        local threads = {}
        local did = {}
        local numThreads = 8
        for i = 1, numThreads do
            threads[i] = love.thread.newThread("thread/previewloader.lua")
            channels[i] = {love.thread.getChannel("previewloader"..i.."i"),love.thread.getChannel("previewloader"..i.."o")}
        end
        local queue = {}
        local t = love.timer.getTime()
        for _,song in ipairs(love.filesystem.getDirectoryItems("songs")) do
            local s,songInfo = pcall(json.decode, love.filesystem.read("songs/"..song.."/info.json"))
            if s then
                if queue["songs/"..song.."/"..songInfo.song] == nil  then
                    queue["songs/"..song.."/"..songInfo.song] = songInfo.songPreview
                    num = num + 1
                end
            end
        end
        for _,song in ipairs(love.filesystem.getDirectoryItems("custom")) do
            local s,songInfo = pcall(json.decode, love.filesystem.read("custom/"..song.."/info.json"))
            if s then
                if queue["custom/"..song.."/"..songInfo.song] == nil then
                    queue["custom/"..song.."/"..songInfo.song] = songInfo.songPreview or {}
                    num = num + 1
                end
            end
        end
        do
            local i = 1
            for path,section in pairs(queue) do
                channels[i][1]:push({t="gen",p=path,s=section})
                i = (i%numThreads)+1
            end
        end
        for i = 1, numThreads do
            threads[i]:start(i)
        end
        while done < num and love.timer.getTime()-t < 5 do
            for i = 1, numThreads do
                for j = 1, channels[i][2]:getCount() do
                    local m = channels[i][2]:pop()
                    did[m[1]] = true
                    Assets.ManualAddPreview(m[1],m[2])
                    done = done + 1
                    if channels[i][1]:getCount() == 0 then
                        channels[i][1]:push({t="done"})
                    end
                end
            end
        end
        for name,_ in pairs(queue) do
            if not did[name] then
                table.insert(missed, name)
            end
        end
    end},
    {type = "dynamic", func = function()
        return done < num and (num-done .. " SONGS FAILED TO RETRIEVE, EXPECT MINOR STUTTERING (" .. table.concat(missed, ", ") .. ")") or ("FOUND " .. num .. " SONGS")
    end},
    {type = "line", text = "RETRIEVING PROFILE INFORMATION", duration = 0.05},
    {type = "run", func = function()
        loadedProfile = Save.Load()
        if loadedProfile then
            index = 12
        end
    end},
    {type = "line", text = "NO PROFILES FOUND", duration = 0},
    {type = "line", text = "VOLTOS BOOT FINISHED", duration = 0.05},
    {type = "pause", duration = 0.5},
    {type = "run", func = function()
        SuppressBorder = false
        if not loadedProfile then
            SceneManager.LoadScene("scenes/setup", {destination = "menu", set = true, transition = true, quitOnFail = true})
        else
            SceneManager.Transition("scenes/menu")
            NoteFont = NoteFonts[Save.Read("note_skin")] or NoteFonts.dots
            Input.ReadBinds()
        end
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