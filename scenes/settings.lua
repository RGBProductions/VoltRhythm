local scene = {}

local rebinding = nil
local rebindTime = 0

local hitsound = love.audio.newSource("sounds/hit.ogg", "stream")
local soundprev = love.audio.newSource("sounds/menunav.ogg", "stream")

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
                    label = "PAUSE ON LOST FOCUS",
                    type = "toggle",
                    read = function()
                        return SystemSettings.pause_on_lost_focus
                    end,
                    write = function(value)
                        SystemSettings.pause_on_lost_focus = value
                    end
                },
                {
                    label = "SHOW FRAMERATE",
                    type = "toggle",
                    read = function()
                        return SystemSettings.show_fps
                    end,
                    write = function(value)
                        SystemSettings.show_fps = value
                    end
                },
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
                    label = "CHART BG",
                    type = "toggle",
                    read = function()
                        return SystemSettings.enable_background
                    end,
                    write = function(value)
                        SystemSettings.enable_background = value
                    end
                },
                {
                    label = "ADJUST SCREEN FX",
                    type = "menu",
                    options = {
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
                                ChromaticModifier:set(2)
                                ChromaticModifier:start(0, "linear", 0.5)
                                SystemSettings.screen_effects.chromatic_aberration = value/20
                            end
                        },
                        {
                            label = "SCREEN TEARING",
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
                                return SystemSettings.screen_effects.screen_tearing*20
                            end,
                            write = function(value)
                                MissTime = 2
                                SystemSettings.screen_effects.screen_tearing = value/20
                            end
                        },
                        {
                            label = "ZOOM BLUR",
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
                                return SystemSettings.screen_effects.zoom_blur*20
                            end,
                            write = function(value)
                                ZoomBlurStrengthModifier:set(1)
                                ZoomBlurStrengthModifier:start(0, "linear", 0.5)
                                SystemSettings.screen_effects.zoom_blur = value/20
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
                        soundprev:stop()
                        soundprev:setVolume(1)
                        soundprev:play()
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
                        soundprev:stop()
                        soundprev:setVolume(SystemSettings.song_volume)
                        soundprev:play()
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
                        soundprev:stop()
                        soundprev:setVolume(SystemSettings.sound_volume)
                        soundprev:play()
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
                        if value then
                            hitsound:stop()
                            hitsound:setVolume(SystemSettings.sound_volume)
                            hitsound:play()
                        end
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
                },
                {
                    label = "CALIBRATE OFFSET",
                    type = "action",
                    run = function()
                        SceneManager.Transition("scenes/calibration")
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
                    read = function(i)
                        return Save.Read("keybinds.lanes.1")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.lanes.1."..i, {t, value})
                    end
                },
                {
                    label = "LANE 2",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.lanes.2")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.lanes.2."..i, {t, value})
                    end
                },
                {
                    label = "LANE 3",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.lanes.3")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.lanes.3."..i, {t, value})
                    end
                },
                {
                    label = "LANE 4",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.lanes.4")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.lanes.4."..i, {t, value})
                    end
                },
                {
                    label = "PAUSE",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.pause")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.pause."..i, {t, value})
                    end
                },
                {
                    label = "CONFIRM",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.confirm")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.confirm."..i, {t, value})
                    end
                },
                {
                    label = "BACK",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.back")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.back."..i, {t, value})
                    end
                },
                {
                    label = "QUICK RESTART",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.restart")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.restart."..i, {t, value})
                    end
                },
                {
                    label = "OVERVOLT MENU",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.overvolt")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.overvolt."..i, {t, value})
                    end
                },
                {
                    label = "SHOW MORE",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.show_more")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.show_more."..i, {t, value})
                    end
                },
                {
                    label = "EDIT PROFILE",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.edit_profile")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.edit_profile."..i, {t, value})
                    end
                },
                {
                    label = "MENU LEFT",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.menu_left")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.menu_left."..i, {t, value})
                    end
                },
                {
                    label = "MENU RIGHT",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.menu_right")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.menu_right."..i, {t, value})
                    end
                },
                {
                    label = "MENU UP",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.menu_up")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.menu_up."..i, {t, value})
                    end
                },
                {
                    label = "MENU DOWN",
                    type = "key",
                    read = function(i)
                        return Save.Read("keybinds.menu_down")[i]
                    end,
                    write = function(value,t,i)
                        Save.Write("keybinds.menu_down."..i, {t, value})
                    end
                }
            }
        },
        {
            label = "GAME UI",
            type = "menu",
            x = -80,
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
                        return BorderOptions[value]:upper():gsub("_", " ")
                    end,
                    read = function()
                        return table.index(BorderOptions, Save.Read("border")) or 1
                    end,
                    write = function(value)
                        Save.Write("border", BorderOptions[value])
                    end
                },
                {
                    label = "NOTE SKIN",
                    type = "number",
                    min = 1,
                    max = #NoteFontOptions,
                    step = 1,
                    text = function(value)
                        return NoteFontOptions[value]:upper():gsub("_", " ")
                    end,
                    read = function()
                        return table.index(NoteFontOptions, Save.Read("note_skin")) or 1
                    end,
                    write = function(value)
                        Save.Write("note_skin", NoteFontOptions[value])
                        NoteFont = NoteFonts[NoteFontOptions[value]]
                    end
                }
            }
        }
    }
}

function scene.action(a)
    if a == "back" then
        if #SettingsStack > 0 then
            local pop = table.remove(SettingsStack, #SettingsStack)
            SettingsCurrent = pop[1]
            SettingsSelection = pop[2]
            SettingsView = SettingsSelection
        else
            SceneManager.Transition("scenes/menu")
        end
    end
    if a == "up" then
        SettingsSelection = (SettingsSelection - 1) % #SettingsCurrent.options
    end
    if a == "down" then
        SettingsSelection = (SettingsSelection + 1) % #SettingsCurrent.options
    end
    if SettingsCurrent.options[SettingsSelection+1] then
        local cur = SettingsCurrent.options[SettingsSelection+1]
        local t = cur.type
        local write = cur.write
        local read = cur.read

        local enabled = true
        if type(cur.enable) == "function" then
            enabled = cur.enable()
        end
        if not enabled then
            return
        end

        if t == "key" then
            if a == "right" then
                SettingsSelection2 = (SettingsSelection2 + 1) % 2
            end
            if a == "left" then
                SettingsSelection2 = (SettingsSelection2 - 1) % 2
            end
        end

        if a == "confirm" then
            -- menus, toggles, and keys use this
            if t == "menu" then
                table.insert(SettingsStack, {SettingsCurrent,SettingsSelection})
                SettingsCurrent = cur
                SettingsSelection = 0
                SettingsView = SettingsSelection
            end
            if t == "key" then
                rebinding = {cur,SettingsSelection2}
                rebindTime = 5
            end
            if t == "action" then
                cur.run()
            end
        end
        if a == "confirm" or a == "right" or a == "left" then
            if t == "toggle" then
                write(not read())
            end
        end
        if t == "number" then
            local m,M,s = cur.min or 0, cur.max or 1, cur.step or 0.1
            if love.keyboard.isDown("lshift") then
                s = s * 2
            end
            if love.keyboard.isDown("lctrl") then
                s = s / 5
            end
            if a == "right" then
                write(math.max(m,math.min(M, read() + s)))
            end
            if a == "left" then
                write(math.max(m,math.min(M, read() - s)))
            end
        end
        if t == "color" then
            if a == "right" then
                write((read()%16)+1)
            end
            if a == "left" then
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

function scene.gamepadpressed(stick,button)
    if rebinding then
        rebinding[1].write(button,"gbutton",SettingsSelection2+1)
        rebinding = nil
        return true
    end
end

---@param stick love.Joystick
---@param axis love.GamepadAxis
---@param value number
function scene.gamepadaxis(stick,axis,value)
    if math.abs(value) >= 0.5 and rebinding then
        rebinding[1].write(axis,"gtrigger",SettingsSelection2+1)
        rebinding = nil
        return true
    end
end

function scene.keypressed(k)
    if rebinding then
        rebinding[1].write(k,"key",SettingsSelection2+1)
        rebinding = nil
        return true
    end
end

function scene.load(args)
    if not args.stay then
        SettingsSelection = 0
        SettingsSelection2 = 0
        SettingsView = 0
        SettingsStack = {}
        SettingsCurrent = root
    else
        SettingsSelection = SettingsSelection or 0
        SettingsSelection2 = SettingsSelection2 or 0
        SettingsView = SettingsView or 0
        SettingsStack = SettingsStack or {}
        SettingsCurrent = SettingsCurrent or root
    end
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
    if rebinding and rebindTime > 0 then
        rebindTime = rebindTime - dt
        if rebindTime <= 0 then
            rebinding = nil
        end
    end

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
    SettingsView = blend*(SettingsView-SettingsSelection)+SettingsSelection
    if math.abs(SettingsSelection-SettingsView) <= 8/128 then
        SettingsView = SettingsSelection
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

local settingsText = love.graphics.newImage("images/title/settings.png")

function scene.draw()
    local menuX = SettingsCurrent.x or 0
    local y = SettingsView-2
    for i,option in ipairs(SettingsCurrent.options) do
        if option.type == "key" then
            -- special behavior...
            local values = {option.read(1),option.read(2)}
            local itmY = (i-y)*80
            local itmX = (640-128)/2+menuX
            love.graphics.setColor(TerminalColors[SettingsSelection == i-1 and ColorID.WHITE or ColorID.DARK_GRAY])
            love.graphics.printf(option.label or "", itmX-144, itmY+16, 128, "center")
            for j = 1, 2 do
                local text = KeyLabel(values[j])
                if rebinding and (rebinding[1] == option and rebinding[2] == j-1) then
                    text = "[...]"
                end
                love.graphics.setColor(TerminalColors[(SettingsSelection == i-1 and SettingsSelection2 == j-1) and ColorID.WHITE or ColorID.DARK_GRAY])
                DrawBoxHalfWidth(itmX/8-1 + (j-1)*18, itmY/16-1, 128/8, 3)
                love.graphics.printf(text:upper(), itmX + (j-1)*144, itmY+16, 128, "center")
            end
        else
            local enabled = true
            if type(option.enable) == "function" then
                enabled = option.enable()
            end
            love.graphics.setColor(TerminalColors[SettingsSelection == i-1 and ColorID.WHITE or ColorID.DARK_GRAY])
            local text = ""
            local value
            if option.type ~= "menu" and option.type ~= "label" and option.type ~= "action" then
                text = option.read()
                value = option.read()
                if option.type == "toggle" then
                    text = (text and "ON" or "OFF")
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
            love.graphics.printf(option.label or "", itmX, itmY+((option.type == "menu" or option.type == "action") and 16 or 0), 256, "center")
            if option.type == "color" then
                love.graphics.setColor(TerminalColors[tonumber(text) or 1])
                love.graphics.rectangle("fill", itmX+(256-16)/2, itmY+32, 16, 16)
            else
                love.graphics.setColor(TerminalColors[SettingsSelection == i-1 and ColorID.LIGHT_GRAY or ColorID.DARK_GRAY])
                love.graphics.printf(tostring(text), itmX, itmY+32, 256, "center")
            end
            if option.type == "number" or option.type == "color" then
                love.graphics.setColor(TerminalColors[SettingsSelection == i-1 and ColorID.WHITE or ColorID.DARK_GRAY])
                if value > (option.min or -math.huge) then love.graphics.print("◁", itmX+28, itmY+16) end
                if value < (option.max or math.huge) then love.graphics.print("▷", itmX+220, itmY+16) end
            end
        end
    end

    if SettingsCurrent.showChart then
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