local scene = {}

local selection = 0
local view = 0
local rebinding = nil

SettingsChart = SettingsChart or {
    Note:new(TimeBPM(0, 60), 0, 0, "normal", {}),
    Note:new(TimeBPM(2, 60), 1, 0, "normal", {}),
    Note:new(TimeBPM(4, 60), 2, 0, "normal", {}),
    Note:new(TimeBPM(6, 60), 3, 0, "normal", {}),
    Note:new(TimeBPM(8, 60), 0, TimeBPM(1,60), "normal", {}),
    Note:new(TimeBPM(10, 60), 2, TimeBPM(1,60), "normal", {}),
    Note:new(TimeBPM(12, 60), 1, TimeBPM(1,60), "normal", {}),
    Note:new(TimeBPM(14, 60), 3, TimeBPM(1,60), "normal", {}),
    Note:new(TimeBPM(16, 60), 0, 0, "swap", {dir = -1}),
    Note:new(TimeBPM(18, 60), 3, 0, "swap", {dir = 1}),
    Note:new(TimeBPM(20, 60), 1, TimeBPM(1,60), "swap", {dir = -1}),
    Note:new(TimeBPM(22, 60), 2, TimeBPM(1,60), "swap", {dir = 1}),
    Note:new(TimeBPM(24, 60), 0, 0, "merge", {dir = 1}),
    Note:new(TimeBPM(24, 60), 3, 0, "mine", {}),
    Note:new(TimeBPM(26, 60), 1, 0, "merge", {dir = 1}),
    Note:new(TimeBPM(28, 60), 2, 0, "merge", {dir = 1}),
    Note:new(TimeBPM(28, 60), 0, 0, "mine", {}),
    Note:new(TimeBPM(30, 60), 1, 0, "merge", {dir = 1}),
    -- LOOP #1
    Note:new(TimeBPM(32+0, 60), 0, 0, "normal", {}),
    Note:new(TimeBPM(32+2, 60), 1, 0, "normal", {}),
    Note:new(TimeBPM(32+4, 60), 2, 0, "normal", {}),
    Note:new(TimeBPM(32+6, 60), 3, 0, "normal", {}),
    Note:new(TimeBPM(32+8, 60), 0, TimeBPM(1,60), "normal", {}),
    Note:new(TimeBPM(32+10, 60), 2, TimeBPM(1,60), "normal", {}),
    Note:new(TimeBPM(32+12, 60), 1, TimeBPM(1,60), "normal", {}),
    Note:new(TimeBPM(32+14, 60), 3, TimeBPM(1,60), "normal", {}),
    Note:new(TimeBPM(32+16, 60), 0, 0, "swap", {dir = -1}),
    Note:new(TimeBPM(32+18, 60), 3, 0, "swap", {dir = 1}),
    Note:new(TimeBPM(32+20, 60), 1, TimeBPM(1,60), "swap", {dir = -1}),
    Note:new(TimeBPM(32+22, 60), 2, TimeBPM(1,60), "swap", {dir = 1}),
    Note:new(TimeBPM(32+24, 60), 0, 0, "merge", {dir = 1}),
    Note:new(TimeBPM(32+24, 60), 3, 0, "mine", {}),
    Note:new(TimeBPM(32+26, 60), 1, 0, "merge", {dir = 1}),
    Note:new(TimeBPM(32+28, 60), 2, 0, "merge", {dir = 1}),
    Note:new(TimeBPM(32+28, 60), 0, 0, "mine", {}),
    Note:new(TimeBPM(32+30, 60), 1, 0, "merge", {dir = 1})
}

local root = {
    label = "SETTINGS",
    type = "menu",
    options = {
        {
            label = "VIDEO",
            type = "menu",
            options = {
                {
                    label = "CHART FX",
                    type = "toggle",
                    read = function()
                        return SystemSettings.enable_chart_effects
                    end,
                    write = function(value)
                        SystemSettings.enable_chart_effects = value
                    end
                },
                {
                    label = "SCREEN FX",
                    type = "toggle",
                    read = function()
                        return SystemSettings.enable_screen_effects
                    end,
                    write = function(value)
                        SystemSettings.enable_screen_effects = value
                    end
                },
                {
                    label = "CURVATURE",
                    type = "number",
                    min = 0,
                    max = 20,
                    step = 1,
                    enable = function()
                        return SystemSettings.enable_screen_effects
                    end,
                    text = function(value)
                        return value*5 .. "%"
                    end,
                    read = function()
                        return SystemSettings.screen_effects.screen_curvature*20
                    end,
                    write = function(value)
                        SystemSettings.screen_effects.screen_curvature = value/20
                    end
                },
                {
                    label = "SCANLINES",
                    type = "number",
                    min = 0,
                    max = 20,
                    step = 1,
                    enable = function()
                        return SystemSettings.enable_screen_effects
                    end,
                    text = function(value)
                        return value*5 .. "%"
                    end,
                    read = function()
                        return SystemSettings.screen_effects.scanlines*20
                    end,
                    write = function(value)
                        SystemSettings.screen_effects.scanlines = value/20
                    end
                },
                {
                    label = "BLOOM",
                    type = "number",
                    min = 0,
                    max = 20,
                    step = 1,
                    enable = function()
                        return SystemSettings.enable_screen_effects
                    end,
                    text = function(value)
                        return value*5 .. "%"
                    end,
                    read = function()
                        return SystemSettings.screen_effects.bloom*20
                    end,
                    write = function(value)
                        SystemSettings.screen_effects.bloom = value/20
                    end
                },
                {
                    label = "ABERRATION",
                    type = "number",
                    min = 0,
                    max = 20,
                    step = 1,
                    enable = function()
                        return SystemSettings.enable_screen_effects
                    end,
                    text = function(value)
                        return value*5 .. "%"
                    end,
                    read = function()
                        return SystemSettings.screen_effects.chromatic_aberration*20
                    end,
                    write = function(value)
                        SystemSettings.screen_effects.chromatic_aberration = value/20
                    end
                },
                {
                    label = "SATURATION",
                    type = "number",
                    min = 0,
                    max = 40,
                    step = 1,
                    enable = function()
                        return SystemSettings.enable_screen_effects
                    end,
                    text = function(value)
                        return value*5 .. "%"
                    end,
                    read = function()
                        return SystemSettings.screen_effects.saturation*20
                    end,
                    write = function(value)
                        SystemSettings.screen_effects.saturation = value/20
                    end
                }
            }
        },
        {
            label = "AUDIO",
            type = "menu",
            options = {
                {
                    label = "MASTER VOLUME",
                    type = "number",
                    min = 0,
                    max = 20,
                    step = 1,
                    text = function(value)
                        return value*5 .. "%"
                    end,
                    read = function()
                        return SystemSettings.master_volume*20
                    end,
                    write = function(value)
                        SystemSettings.master_volume = value/20
                    end
                },
                {
                    label = "SONG VOLUME",
                    type = "number",
                    min = 0,
                    max = 20,
                    step = 1,
                    text = function(value)
                        return value*5 .. "%"
                    end,
                    read = function()
                        return SystemSettings.song_volume*20
                    end,
                    write = function(value)
                        SystemSettings.song_volume = value/20
                    end
                },
                {
                    label = "SOUND VOLUME",
                    type = "number",
                    min = 0,
                    max = 20,
                    step = 1,
                    text = function(value)
                        return value*5 .. "%"
                    end,
                    read = function()
                        return SystemSettings.sound_volume*20
                    end,
                    write = function(value)
                        SystemSettings.sound_volume = value/20
                    end
                },
                {
                    label = "HIT SOUNDS",
                    type = "toggle",
                    read = function()
                        return Save.Read("enable_hit_sounds")
                    end,
                    write = function(value)
                        Save.Write("enable_hit_sounds", value)
                    end
                },
                {
                    label = "OFFSET",
                    type = "number",
                    min = -math.huge,
                    max = math.huge,
                    step = 5,
                    text = function(value)
                        return value .. "ms"
                    end,
                    read = function()
                        return SystemSettings.audio_offset*1000
                    end,
                    write = function(value)
                        SystemSettings.audio_offset = value/1000
                    end
                }
            }
        },
        {
            label = "KEYBINDS",
            type = "menu",
            options = {
                {
                    label = "LANE 1",
                    type = "key",
                    read = function()
                        return Save.Read("keybinds.1")
                    end,
                    write = function(value)
                        Save.Write("keybinds.1", value)
                    end
                },
                {
                    label = "LANE 2",
                    type = "key",
                    read = function()
                        return Save.Read("keybinds.2")
                    end,
                    write = function(value)
                        Save.Write("keybinds.2", value)
                    end
                },
                {
                    label = "LANE 3",
                    type = "key",
                    read = function()
                        return Save.Read("keybinds.3")
                    end,
                    write = function(value)
                        Save.Write("keybinds.3", value)
                    end
                },
                {
                    label = "LANE 4",
                    type = "key",
                    read = function()
                        return Save.Read("keybinds.4")
                    end,
                    write = function(value)
                        Save.Write("keybinds.4", value)
                    end
                }
            }
        },
        {
            label = "GAME UI",
            type = "menu",
            x = -80, -- TODO: set this number reasonably
            showChart = true,
            options = {
                {
                    label = "SCROLL SPEED",
                    type = "number",
                    min = 10,
                    max = 50,
                    step = 5,
                    text = function(value)
                        return value
                    end,
                    read = function()
                        return Save.Read("scroll_speed")
                    end,
                    write = function(value)
                        Save.Write("scroll_speed", value)
                    end
                },
                {
                    label = "LANE 1 COLOR",
                    type = "color",
                    read = function()
                        return Save.Read("note_colors.1")
                    end,
                    write = function(value)
                        Save.Write("note_colors.1", value)
                    end
                },
                {
                    label = "LANE 2 COLOR",
                    type = "color",
                    read = function()
                        return Save.Read("note_colors.2")
                    end,
                    write = function(value)
                        Save.Write("note_colors.2", value)
                    end
                },
                {
                    label = "LANE 3 COLOR",
                    type = "color",
                    read = function()
                        return Save.Read("note_colors.3")
                    end,
                    write = function(value)
                        Save.Write("note_colors.3", value)
                    end
                },
                {
                    label = "LANE 4 COLOR",
                    type = "color",
                    read = function()
                        return Save.Read("note_colors.4")
                    end,
                    write = function(value)
                        Save.Write("note_colors.4", value)
                    end
                },
                {
                    label = "MINE COLOR",
                    type = "color",
                    read = function()
                        return Save.Read("mine_color")
                    end,
                    write = function(value)
                        Save.Write("mine_color", value)
                    end
                },
                {
                    label = "BORDER",
                    type = "number",
                    min = 1,
                    max = #BorderOptions,
                    step = 1,
                    text = function(value)
                        return BorderOptions[value]:upper()
                    end,
                    read = function()
                        return table.index(BorderOptions, Save.Read("border")) or 1
                    end,
                    write = function(value)
                        Save.Write("border", BorderOptions[value])
                    end
                }
            }
        }
    }
}

local stack = {}
local current = root

function scene.keypressed(k)
    if rebinding then
        rebinding.write(k)
        rebinding = nil
        return
    end
    if k == "escape" then
        if #stack > 0 then
            local pop = table.remove(stack, #stack)
            current = pop[1]
            selection = pop[2]
            view = selection
        else
            SceneManager.Transition("scenes/menu")
        end
    end
    if k == "up" then
        selection = (selection - 1) % #current.options
    end
    if k == "down" then
        selection = (selection + 1) % #current.options
    end
    if current.options[selection+1] then
        local t = current.options[selection+1].type
        local write = current.options[selection+1].write
        local read = current.options[selection+1].read

        local enabled = true
        if type(current.options[selection+1].enable) == "function" then
            enabled = current.options[selection+1].enable()
        end
        if not enabled then
            return
        end

        if k == "return" then
            -- menus, toggles, and keys use this
            if t == "menu" then
                table.insert(stack, {current,selection})
                current = current.options[selection+1]
                selection = 0
                view = selection
            end
            if t == "key" then
                rebinding = current.options[selection+1]
            end
        end
        if k == "return" or k == "right" or k == "left" then
            if t == "toggle" then
                write(not read())
            end
        end
        if t == "number" then
            local m,M,s = current.options[selection+1].min or 0, current.options[selection+1].max or 1, current.options[selection+1].step or 0.1
            if love.keyboard.isDown("lshift") then
                s = s * 2
            end
            if love.keyboard.isDown("lctrl") then
                s = s / 5
            end
            if k == "right" then
                write(math.max(m,math.min(M, read() + s)))
            end
            if k == "left" then
                write(math.max(m,math.min(M, read() - s)))
            end
        end
        if t == "color" then
            if k == "right" then
                write((read()%16)+1)
            end
            if k == "left" then
                write(((read()-2)%16)+1)
            end
            local colorIndexes = Save.Read("note_colors") or {ColorID.LIGHT_RED, ColorID.YELLOW, ColorID.LIGHT_GREEN, ColorID.LIGHT_BLUE}
            NoteColors = {
                ColorTransitionTable[colorIndexes[1]],
                ColorTransitionTable[colorIndexes[2]],
                ColorTransitionTable[colorIndexes[3]],
                ColorTransitionTable[colorIndexes[4]]
            }
        end
    end
end

function scene.load()
    for _,note in ipairs(SettingsChart) do
        note.destroyed = false
        note.heldFor = nil
        note.holding = nil
        if NoteTypes[note.type].reset then
            NoteTypes[note.type].reset(note)
        end
    end
end

local chartTime = -1
local chartX = 50

local pressAmounts = {}
local hitAmounts = {}
for i = 1, 4 do
    pressAmounts[i] = 0
    hitAmounts[i] = 0
end

local beatCount = 0

function scene.update(dt)
    chartTime = chartTime + dt
    if chartTime >= TimeBPM(32,60) then
        chartTime = chartTime - TimeBPM(32,60)
        for _,note in ipairs(SettingsChart) do
            note.destroyed = false
            note.heldFor = nil
            note.holding = nil
            if NoteTypes[note.type].reset then
                NoteTypes[note.type].reset(note)
            end
        end
    end

    local blend = math.pow(1/((5/4)^60), dt)
    view = blend*(view-selection)+selection
    if math.abs(selection-view) <= 8/128 then
        view = selection
    end

    local lastBeatCount = beatCount
    beatCount = chartTime*4

    do
        local i = 1
        local num = #SettingsChart
        while i <= num do
            local note = SettingsChart[i]
            if note.destroyed then
                goto continue
            end
            do
                local pos = note.time-chartTime
                if pos > 0.5 then -- too far for us to care
                    i = num
                    break
                end
                if pos <= 0 then
                    local t = NoteTypes[note.type]
                    if not t.autoplayIgnores then
                        local hit = true
                        if t.hit then
                            hit = false
                            local a,b = math.min(note.lane, note.lane+(note.type == "merge" and note.extra.dir or 0)),math.max(note.lane, note.lane+(note.type == "merge" and note.extra.dir or 0))
                            for l = 0, 4-1 do
                                local marked = l >= a and l <= b
                                if marked then
                                    pressAmounts[l+1] = 32
                                    hitAmounts[l+1] = 1
                                    if (note.heldFor or 0) <= 0 then
                                        local x = chartX + (l)*4 + 1
                                        for _=1, 4 do
                                            local drawPos = (8)+(15)
                                            table.insert(Particles, {id = "powerhit", x = x*8+12, y = drawPos*16-16, vx = (love.math.random()*2-1)*64, vy = -(love.math.random()*2)*32, life = (love.math.random()*0.5+0.5)*0.25, color = OverchargeColors[love.math.random(1,#OverchargeColors)], char = "¤"})
                                        end
                                    end
                                end
                                hit = true
                            end
                        end
                        if hit then
                            if note.holding and (lastBeatCount%0.5) > (beatCount%0.5) then
                                local x = chartX + (note.lane)*4 + 1
                                for _=1, 4 do
                                    local drawPos = (8)+(15)
                                    table.insert(Particles, {id = "holdgrind", x = x*8+12, y = drawPos*16-16, vx = (love.math.random()*2-1)*32, vy = -(love.math.random()*2)*64, life = (love.math.random()*0.5+0.5)*0.25, color = NoteColors[note.lane+1][3], char = "¤"})
                                end
                            end

                            if note.length <= 0 then
                                note.destroyed = true
                                i = i - 1
                            else
                                note.holding = true
                            end
                        end
                    end
                end
                if note.holding and pos <= 0 then
                    if note.length > 0 then
                        local lastHeldFor = note.heldFor or 0
                        note.heldFor = math.min(note.length, lastHeldFor + dt)
                        HitAmounts[note.lane+1] = 1
                        if note.heldFor >= note.length then
                            note.destroyed = true
                            i = i - 1
                        end
                        PressAmounts[note.lane+1] = 32
                    end
                end
                local t = NoteTypes[note.type]
                if pos <= (t.missImmediately and 0 or -0.25) then
                    local permitted = true
                    note.destroyed = true
                    -- if t.miss then
                    --     permitted = t.miss(note) or permitted
                    -- end
                end
            end
            ::continue::
            i = i + 1
            num = #SettingsChart
        end
    end

    for i = 1, 4 do
        pressAmounts[i] = math.max(0, math.min(math.huge, (pressAmounts[i] or 0) + dt*8*(-1/dt)))
        hitAmounts[i] = math.max(0, math.min(1, (hitAmounts[i] or 0) - dt*8))
    end
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
end

local settingsText = love.graphics.newImage("images/settings.png")

function scene.draw()
    local menuX = current.x or 0
    local y = view-2
    for i,option in ipairs(current.options) do
        local enabled = true
        if type(option.enable) == "function" then
            enabled = option.enable()
        end
        love.graphics.setColor(TerminalColors[selection == i-1 and ColorID.WHITE or ColorID.DARK_GRAY])
        local text = ""
        if option.type ~= "menu" and option.type ~= "label" then
            text = option.read()
            if option.type == "toggle" then
                text = (text and "ON" or "OFF")
            end
            if option.type == "key" then
                if rebinding == option then
                    text = "[...]"
                else
                    text = tostring(text):upper()
                end
            end
            if type(option.text) == "function" then
                text = option.text(text)
            end
        end
        if not enabled then
            text = "- DISABLED -"
        end
        local itmY = (i-y)*80
        local itmX = (640-256)/2+menuX
        DrawBoxHalfWidth(itmX/8-1, itmY/16-1, 256/8, 3)
        love.graphics.printf(option.label or "", itmX, itmY+(option.type == "menu" and 16 or 0), 256, "center")
        if option.type == "color" then
            love.graphics.setColor(TerminalColors[tonumber(text) or 1])
            love.graphics.rectangle("fill", itmX+(256-16)/2, itmY+32, 16, 16)
        else
            love.graphics.setColor(TerminalColors[selection == i-1 and ColorID.LIGHT_GRAY or ColorID.DARK_GRAY])
            love.graphics.printf(tostring(text), itmX, itmY+32, 256, "center")
        end
    end

    if current.showChart then
        -- Chart
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        DrawBoxHalfWidth(chartX, 7, 15, 16)

        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        for i = 1, 3 do
            local x = chartX+(i-1)*4 + 1
            love.graphics.print(("   ┊\n"):rep(16), x*8, 8*16)
        end
        do
            local drawPos = (8)+(15)
            if drawPos >= 8 and drawPos <= 25 then
                love.graphics.print("┈┈┈"..("╬┈┈┈"):rep(4-1), (chartX+1)*8, drawPos*16-16)
            end
        end
        -- End Chart

        for i = 1, 4 do
            local x = chartX + (i-1)*4 + 1
            local v = math.ceil(math.min(1,pressAmounts[i])+hitAmounts[i]*2)
            if v > 0 then
                local drawPos = (8)+(15)
                love.graphics.setColor(TerminalColors[NoteColors[((i-1)%(#NoteColors))+1][v+1]])
                love.graphics.print("███", x*8 + AnaglyphSide*0.75, drawPos*16-16)
            end
        end
        
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        for _,note in ipairs(SettingsChart) do
            if not note.destroyed then
                local t = NoteTypes[note.type]
                if t then
                    love.graphics.setFont(NoteFont)
                    t.draw(note, chartTime, Save.Read("scroll_speed"), 8, nil, chartX+2, false)
                    love.graphics.setFont(Font)
                end
            end
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        for _,particle in ipairs(Particles) do
            love.graphics.setColor(TerminalColors[particle.color])
            love.graphics.print(particle.char, particle.x-4, particle.y-8)
        end
    end

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(settingsText, 320, 32, 0, 2, 2, settingsText:getWidth()/2, 0)
end

return scene