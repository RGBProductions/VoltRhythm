local utf8 = require "utf8"

local scene = {}

local placementModes = {
    select = 0,
    normal = 1,
    swap = 2,
    merge = 3,
    bpm = 4,
    effect = 5
}

local notes = {"normal", "swap", "merge"}

local editorMenu = {
    {
        id = "file",
        type = "menu",
        label = "FILE",
        open = false,
        contents = {
            {
                id = "file.new",
                type = "action",
                label = "NEW",
                onclick = function()
                    print("new song")
                    return true
                end
            },
            {
                id = "file.open",
                type = "action",
                label = "OPEN",
                onclick = function()
                    print("open song")
                    return true
                end
            },
            {
                id = "file.recent",
                type = "menu",
                label = "OPEN RECENT",
                open = false,
                contents = {
                    {
                        type = "action",
                        label = "CUTE",
                        onclick = function()
                            print("open CUTE")
                            return true
                        end
                    },
                }
            },
            {
                id = "file.save",
                type = "action",
                label = "SAVE",
                onclick = function()
                    print("save song")
                    return true
                end
            },
            {
                id = "file.saveas",
                type = "action",
                label = "SAVE AS",
                onclick = function()
                    print("save song as")
                    return true
                end
            },
            {
                id = "file.exit",
                type = "action",
                label = "EXIT",
                onclick = function()
                    SavedEditorTime = nil
                    SceneManager.Transition("scenes/menu")
                    SetCursor()
                    return true
                end
            },
        }
    },
    {
        id = "edit",
        type = "menu",
        label = "EDIT",
        open = false,
        contents = {
            {
                id = "edit.metadata",
                type = "action",
                label = "METADATA",
                onclick = function()
                    print("edit song metadata")
                    return true
                end
            },
            {
                id = "edit.difficulties",
                type = "action",
                label = "DIFFICULTIES",
                onclick = function()
                    print("edit song difficulties")
                    return true
                end
            }
        }
    },
    {
        id = "note",
        type = "menu",
        label = "NOTE",
        open = false,
        contents = {
            {
                id = "note.select",
                type = "action",
                label = "SELECT",
                onclick = function()
                    SetCursor("🮰", 0, 0)
                    scene.placementMode = placementModes.select
                    return true
                end
            },
            {
                id = "note.normal",
                type = "action",
                label = "NORMAL",
                onclick = function()
                    SetCursor("○", 4, 8)
                    scene.placementMode = placementModes.normal
                    return true
                end
            },
            {
                id = "note.swap",
                type = "action",
                label = "SWAP",
                onclick = function()
                    SetCursor("◇", 4, 8)
                    scene.placementMode = placementModes.swap
                    return true
                end
            },
            {
                id = "note.merge",
                type = "action",
                label = "MERGE",
                onclick = function()
                    SetCursor("▥", 4, 8)
                    scene.placementMode = placementModes.merge
                    return true
                end
            },
            {
                id = "note.bpm",
                type = "action",
                label = "BPM CHANGE",
                onclick = function()
                    SetCursor("¤", 4, 8)
                    scene.placementMode = placementModes.bpm
                    return true
                end
            },
            {
                id = "note.bpm",
                type = "action",
                label = "EFFECT",
                onclick = function()
                    SetCursor("¤", 4, 8)
                    scene.placementMode = placementModes.effect
                    return true
                end
            }
        }
    },
    {
        id = "play",
        type = "menu",
        label = "PLAY",
        open = false,
        contents = {
            {
                id = "play.playtest",
                type = "action",
                label = "PLAYTEST",
                onclick = function()
                    scene.chart:sort()
                    scene.chart:recalculateCharge()
                    SavedEditorTime = scene.chartTimeTemp
                    Autoplay = false
                    Showcase = false
                    SceneManager.Transition("scenes/game", {songData = scene.songData, difficulty = scene.difficulty})
                    SetCursor()
                    return true
                end
            },
            {
                id = "play.auto",
                type = "action",
                label = "AUTO SHOWCASE",
                onclick = function()
                    scene.chart:sort()
                    scene.chart:recalculateCharge()
                    SavedEditorTime = scene.chartTimeTemp
                    Autoplay = true
                    Showcase = true
                    SceneManager.Transition("scenes/game", {songData = scene.songData, difficulty = scene.difficulty})
                    SetCursor()
                    return true
                end
            }
        }
    },
    {
        label = "                          ",
        type = "action",
        onclick = function() end
    },
    {
        id = "hotreload",
        label = "HOT RELOAD",
        type = "action",
        onclick = function()
            SceneManager.Transition("scenes/neditor", {songData = scene.songData, difficulty = scene.difficulty})
        end
    }
}

local function closeMenu(tab)
    if tab.type ~= "menu" then return end
    for _,itm in ipairs(tab.contents) do
        if itm.type == "menu" then
            closeMenu(itm)
        end
    end
    tab.open = false
end

local function getMenuItemById(id)
    local function scan(cur)
        for _,itm in ipairs(cur) do
            if itm.id == id then
                return itm
            end
            if itm.type == "menu" then
                local result = scan(itm.contents)
                if result then
                    return result
                end
            end
        end
    end

    return scan(editorMenu)
end

function scene.load(args)
    scene.songData = args.songData
    scene.difficulty = args.difficulty

    scene.chart = scene.songData:loadChart(scene.difficulty)
    -- if scene.chart then
    --     local soundData = love.sound.newSoundData(scene.chart.song)
    --     scene.waveform = love.graphics.newCanvas(64,soundData:getSampleCount()/1000)
    --     local c = love.graphics.getCanvas()
    --     love.graphics.setCanvas(scene.waveform)
    --     for i = 0, soundData:getSampleCount()/1000-1 do
    --         -- scene.wave[i+1] = soundData:getSample(i*2)
    --         local sample = soundData:getSample(i*1000,1)
    --         love.graphics.line(64, scene.waveform:getHeight()-i-1, 64-math.abs(sample)*64, scene.waveform:getHeight()-i-1)
    --     end
    --     love.graphics.setCanvas(c)
    --     scene.scalePerPixel = 1/(soundData:getSampleRate()/1000)
    --     -- scene.wave = {}
    --     -- for i = 0, soundData:getSampleCount()-1 do
    --     --     scene.wave[i+1] = soundData:getSample(i*2)
    --     -- end
    -- end

    scene.chartTimeTemp = SavedEditorTime or 0
    scene.lastNoteTime = 0
    scene.lastNoteLane = 0

    scene.placementMode = placementModes.select
    scene.placement = {
        placing = false,
        type = "normal",
        note = nil,
        start = {0,0},
        stop = {0,0}
    }

    SetCursor("🮰", 0, 0)
end

function scene.update(dt)
    do
        local i = 1
        local num = #Particles
        while i <= num do
            local particle = Particles[i]
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.life = particle.life - dt
            if particle.life <= 0 then
                table.remove(Particles, i)
                i = i - 1
            end
            i = i + 1
            num = #Particles
        end
    end
    
    if love.keyboard.isDown("up") then
        scene.chartTimeTemp = scene.chartTimeTemp + dt*(love.keyboard.isDown("lshift") and 4 or 1)*(love.keyboard.isDown("lctrl") and 8 or 1)
    end
    if love.keyboard.isDown("down") then
        scene.chartTimeTemp = scene.chartTimeTemp - dt*(love.keyboard.isDown("lshift") and 4 or 1)*(love.keyboard.isDown("lctrl") and 8 or 1)
    end

    local source = Assets.Source(scene.chart.song)
    if source then
        scene.chartTimeTemp = math.max(0,math.min(source:getDuration("seconds"), scene.chartTimeTemp))
    end
    -- if (scene.chart or {}).song then
        -- local source = Assets.Source(scene.chart.song)
    if source then
        if source:isPlaying() then
            scene.chartTimeTemp = scene.chartTimeTemp + dt
            local sourceTime = source:tell("seconds")
            if math.abs(scene.chartTimeTemp - sourceTime) >= 0.03 then
                scene.chartTimeTemp = source:tell("seconds")
            end
        end
    end
    -- end
    if scene.placement.placing then
        scene.placement.stop = {scene.lastNoteLane, scene.lastNoteTime}

        local noteType = scene.placement.type
        local note = scene.placement.note
        if note then
            if noteType == "swap" then
                local lane = note.lane - (note.extra.dir or 0)
                local dir = scene.placement.stop[1]-scene.placement.start[1]
                local endLane = math.max(0,math.min(3,lane + dir))
                note.extra.dir = math.max(-1,math.min(1,endLane - lane))
                note.lane = scene.placement.start[1]+note.extra.dir
            end
            if noteType == "merge" then
                local dir = scene.placement.stop[1]-scene.placement.start[1]
                local endLane = math.max(0,math.min(3,note.lane + dir))
                note.extra.dir = endLane - note.lane
            end
            if noteType ~= "merge" then
                local a,b = math.min(scene.placement.start[2],scene.placement.stop[2]),math.max(scene.placement.start[2],scene.placement.stop[2])
                note.length = math.max(0,b-a)
                note.time = a
            end
        end
    end
    if scene.scrollbarGrab then
        local source = Assets.Source(scene.chart.song)
        if source then
            local dur = source:getDuration("seconds")
            local y = math.max(0,math.min(1, (MouseY - 120) / 240))
            scene.chartTimeTemp = (1-y)*dur
        end
    end
end

function scene.keypressed(k)
    if k == "space" then
        if (scene.chart or {}).song then
            local source = Assets.Source(scene.chart.song)
            if source then
                if scene.chartTimeTemp < source:getDuration("seconds") then
                    if source:isPlaying() then
                        source:pause()
                    else
                        source:play()
                        source:seek(math.max(0,scene.chartTimeTemp), "seconds")
                    end
                end
            end
        end
    end
end

local function clickTab(tab,x,y,cx,cy)
    local width = 0
    for _,item in ipairs(tab.contents) do
        width = math.max(utf8.len(item.label .. (item.type == "menu" and " ▷" or "")), width)
    end
    width = width + 2
    for i,elem in ipairs(tab.contents) do
        local X,Y,W,H = x, y+32*(i-1), 8*utf8.len(elem.label), 32
        if elem.open then
            local clicked = clickTab(elem, X + 8*(width+2), Y, cx, cy)
            if clicked then
                return clicked
            end
        end
        if cx >= X and cx < X+16 + 8*width and cy >= Y+8 and cy < Y+8 + H then
            return elem
        end
    end
    tab.open = nil
    return nil
end

local function drawTab(tab,x,y)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local width = 0
    for _,item in ipairs(tab.contents) do
        width = math.max(utf8.len(item.label .. (item.type == "menu" and " ▷" or "")), width)
    end
    DrawBoxHalfWidth(x/8, y/16, width+2, math.max(0,(#tab.contents)*2-1))
    for i,elem in ipairs(tab.contents) do
        local X,Y,W,H = x, y+32*(i-1), 8*utf8.len(elem.label), 16
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if elem.open then
            drawTab(elem, X + 8*(width+4), Y)
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        love.graphics.print(elem.label .. (elem.type == "menu" and " ▷" or ""), X+16, Y+16)
        if i ~= #tab.contents then
            love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
            love.graphics.print(("┈"):rep(width+2), X+8, Y+32)
        end
    end
end

function scene.draw()
    DrawBoxHalfWidth((80-(scene.chart.lanes*4-1))/2 - 1, 6, scene.chart.lanes*4-1, 16)
    
    for i = 1, 4-1 do
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        local x = (80-(scene.chart.lanes*4-1))/2 - 1+(i-1)*4 + 1
        love.graphics.print(("   ┊\n"):rep(16), x*8, 7*16)
    end

    local bpmChanges = {
        -- {time = TimeBPM(144,95), bpm = 190}
    }

    local currentTime = 0
    local currentBPM = scene.chart.bpm
    local numSteps = 0
    local nextBPMChange = 1
    local lastBPMTime = 0

    local closestY = math.huge
    scene.lastNoteTime = math.huge
    scene.lastNoteLane = math.floor( ( MouseX - ((80-(scene.chart.lanes*4-1))/2 - 1)*8 - 4 ) / (8*4) )

    local chartPos = 7
    local chartHeight = 16
    local speed = 25

    while currentTime <= scene.chartTimeTemp+1 do
        do
            local pos = currentTime - scene.chartTimeTemp
            local drawPos = chartPos+chartHeight-pos*speed - 1
            if drawPos >= chartPos and drawPos < chartPos+chartHeight then
                love.graphics.setColor(TerminalColors[numSteps%4 == 0 and ColorID.LIGHT_GRAY or ColorID.DARK_GRAY])
                love.graphics.print("┈┈┈╬┈┈┈╬┈┈┈╬┈┈┈", (80-(scene.chart.lanes*4-1))/2 * 8, drawPos*16-8)
            end
            local mouseDist = math.abs((drawPos*16-8) - (MouseY-8))
            if mouseDist < closestY then
                closestY = mouseDist
                scene.lastNoteTime = currentTime
            end
        end

        local step = TimeBPM(1,currentBPM)
        local bpmChange = (bpmChanges[nextBPMChange] or {time = math.huge, bpm = currentBPM})
        if currentTime+step > bpmChange.time then
            local pos = WhichSixteenth(bpmChange.time-lastBPMTime, currentBPM)
            local nextBeatAt = (1 - (pos % 1)) % 1
            currentTime = currentTime + TimeBPM(nextBeatAt,currentBPM)
            currentBPM = bpmChange.bpm
            lastBPMTime = bpmChange.time
            nextBPMChange = nextBPMChange + 1
            if nextBeatAt ~= 0 then
                numSteps = numSteps + 1
            end
        else
            currentTime = currentTime + step
            numSteps = numSteps + 1
        end
    end

    do
        local pos = 0
        local drawPos = chartPos+chartHeight-pos*speed - 1
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        love.graphics.print("┈┈┈╬┈┈┈╬┈┈┈╬┈┈┈", (80-(scene.chart.lanes*4-1))/2 * 8, drawPos*16-8)
    end

    -- for i = math.max(0,math.floor(scene.chartTimeTemp/scene.waveSpread))+1, math.max(0,math.floor((scene.chartTimeTemp+2)/scene.waveSpread))+1, (chartPos+chartHeight)/speed do
    --     if not scene.wave[math.floor(i)] then
    --         break
    --     end
    --     local pos = scene.waveSpread*(i-1) - scene.chartTimeTemp
    --     local drawPos = chartPos+chartHeight-pos*speed - 1
    --     if drawPos < chartPos then
    --         break
    --     end
    --     -- 1 = chartPos+chartHeight-pos*speed - 1
    --     local x = (80-(scene.chart.lanes*4-1))/2 * 8 - 8
    --     love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
    --     love.graphics.line(x, drawPos*16, x-math.abs(scene.wave[math.floor(i)])*64, drawPos*16)
    --     love.graphics.setColor(TerminalColors[ColorID.WHITE])
    --     love.graphics.line(x, drawPos*16, x-math.abs(scene.wave[math.floor(i)])*32, drawPos*16)
    -- end

    -- love.graphics.draw(scene.waveform)

    for _,note in ipairs(scene.chart.notes) do
        local t = NoteTypes[note.type]
        if t and type(t.draw) == "function" then
            love.graphics.setFont(NoteFont)
            t.draw(note,scene.chartTimeTemp,speed,chartPos, chartHeight-1,(80-(scene.chart.lanes*4-1))/2 - 1 + 2,true)
            love.graphics.setFont(Font)
        end
    end

    if scene.lastNoteLane >= 0 and scene.lastNoteLane < 4 then
        local t = (scene.placementMode == placementModes.normal and NoteTypes.normal) or (scene.placementMode == placementModes.swap and NoteTypes.swap) or (scene.placementMode == placementModes.merge and NoteTypes.merge)
        if t then
            love.graphics.setFont(NoteFont)
            t.draw({
                lane = scene.lastNoteLane,
                time = scene.lastNoteTime,
                length = 0,
                extra = {
                    dir = 0
                }
            }, scene.chartTimeTemp, speed, chartPos, chartHeight-1, (80-(scene.chart.lanes*4-1))/2 - 1 + 2, true)
            love.graphics.setFont(Font)
        end
    end

    for _,particle in ipairs(Particles) do
        love.graphics.setColor(TerminalColors[particle.color])
        love.graphics.print(particle.char, particle.x-4, particle.y-8)
    end



    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBox(2, 1, 37, 1)
    local tabPosition = 32
    for i,tab in ipairs(editorMenu) do
        local X,Y,W,H = tabPosition, 32, 8*utf8.len(tab.label), 16
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if tab.open then
            drawTab(tab, X-8, Y+16)
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        love.graphics.print(tab.label, tabPosition, 32)
        tabPosition = tabPosition + 8*(utf8.len(tab.label)+4)
    end
    
    DrawBoxHalfWidth(52, 6, 1, 16)
    local source = Assets.Source(scene.chart.song)
    if source then
        local dur = source:getDuration("seconds")
        local pos = scene.chartTimeTemp/dur
        local y = pos*240
        love.graphics.print("█", 424, 352-y)
    end

    local level = scene.songData:getLevel(scene.difficulty)
    love.graphics.printf(scene.songData.name, 0, 400, 608, "right")
    PrintDifficulty(608, 416, scene.difficulty or "easy", level or 0, "right")
end

function scene.mousepressed(x,y,b)
    if b == 1 then
        local hadOpen = false
        local tabPosition = 32
        for i,tab in ipairs(editorMenu) do
            local X,Y,W,H = tabPosition, 32, 8*utf8.len(tab.label), 16
            if tab.open then
                hadOpen = true
                local click = clickTab(tab, X, Y+16, MouseX, MouseY)
                if not click then
                    tab.open = false
                else
                    if click.type == "menu" then
                        click.open = not click.open
                    else
                        if click.onclick() then
                            for _,TAB in ipairs(editorMenu) do
                                closeMenu(TAB)
                            end
                            return
                        end
                    end
                end
            end
            tabPosition = tabPosition + 8*(utf8.len(tab.label)+4)
        end
        tabPosition = 32
        for i,tab in ipairs(editorMenu) do
            local X,Y,W,H = tabPosition, 32-8, 8*utf8.len(tab.label), 32
            if MouseX >= X and MouseY >= Y and MouseX < X+W and MouseY < Y+H then
                if tab.type == "menu" then
                    tab.open = true
                    return
                else
                    tab.onclick()
                    return
                end
            end
            tabPosition = tabPosition + 8*(utf8.len(tab.label)+4)
        end
        if hadOpen then return end
        
        if scene.placementMode ~= placementModes.select then
            if scene.placementMode < placementModes.bpm then
                if scene.lastNoteLane >= 0 and scene.lastNoteLane <= 3 then
                    -- print("insert a " .. notes[scene.placementMode] .. " note on lane " .. scene.lastNoteLane .. " time " .. scene.lastNoteTime)
                    local noteType = notes[scene.placementMode]
                    scene.placement.placing = true
                    scene.placement.type = noteType
                    scene.placement.start = {scene.lastNoteLane, scene.lastNoteTime}
                    local note = Note:new(scene.lastNoteTime, scene.lastNoteLane, 0, noteType, {})
                    if noteType == "merge" or noteType == "swap" then
                        note.extra.dir = 0
                    end
                    scene.placement.note = note
                    table.insert(scene.chart.notes, note)
                    for _=1,8 do
                        table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = love.math.random(1,16), char = "¤"})
                    end
                end
            end
        end

        local source = Assets.Source(scene.chart.song)
        if source then
            local dur = source:getDuration("seconds")
            local pos = scene.chartTimeTemp/dur
            local Y = pos*240
            if y >= 112 and y < 368 and x >= 424 and x < 424+8 then
                scene.scrollbarGrab = true
            end
        end
    end

    if b == 2 then
        for i,note in ipairs(scene.chart.notes) do
            local A,B = math.min(note.lane, note.lane+(note.extra.dir or 0)),math.max(note.lane, note.lane+(note.extra.dir or 0))
            if note.type == "swap" then
                A,B = math.min(note.lane, note.lane-(note.extra.dir or 0)),math.max(note.lane, note.lane-(note.extra.dir or 0))
            end

            local C,D = note.time-0.05,note.time+note.length+0.05
            if (scene.lastNoteLane >= A and scene.lastNoteLane <= B) and (scene.lastNoteTime >= C and scene.lastNoteTime <= D) then
                table.remove(scene.chart.notes, i)
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                end
                break
            end
        end
    end
end

function scene.mousereleased(x,y,b)
    scene.placement.placing = false
    scene.scrollbarGrab = false
end

return scene