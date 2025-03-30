local scene = {}

local selection = 0
local rebinding = nil

local options = {
    {
        label = "VIDEO",
        type = "menu",
        options = {
            {
                label = "SCROLL SPEED",
                type = "number",
                min = 10,
                max = 50,
                step = 5,
                enable = function()
                    return SystemSettings.enable_screen_effects
                end,
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
        label = "CUSTOMIZATION",
        type = "menu",
        options = {
            {
                label = "NOTE COLORS",
                type = "label"
            },
            {
                label = "LANE 1",
                type = "color",
                read = function()
                    return Save.Read("note_colors.1")
                end,
                write = function(value)
                    Save.Write("note_colors.1", value)
                end
            },
            {
                label = "LANE 2",
                type = "color",
                read = function()
                    return Save.Read("note_colors.2")
                end,
                write = function(value)
                    Save.Write("note_colors.2", value)
                end
            },
            {
                label = "LANE 3",
                type = "color",
                read = function()
                    return Save.Read("note_colors.3")
                end,
                write = function(value)
                    Save.Write("note_colors.3", value)
                end
            },
            {
                label = "LANE 4",
                type = "color",
                read = function()
                    return Save.Read("note_colors.4")
                end,
                write = function(value)
                    Save.Write("note_colors.4", value)
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

local stack = {}
local current = options

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
        else
            SceneManager.Transition("scenes/menu")
        end
    end
    if k == "up" then
        selection = (selection - 1) % #current
    end
    if k == "down" then
        selection = (selection + 1) % #current
    end
    if current[selection+1] then
        local t = current[selection+1].type
        local write = current[selection+1].write
        local read = current[selection+1].read

        local enabled = true
        if type(current[selection+1].enable) == "function" then
            enabled = current[selection+1].enable()
        end
        if not enabled then
            return
        end

        if k == "return" then
            -- menus, toggles, and keys use this
            if t == "menu" then
                table.insert(stack, {current,selection})
                current = current[selection+1].options
                selection = 0
            end
            if t == "key" then
                rebinding = current[selection+1]
            end
        end
        if k == "return" or k == "right" or k == "left" then
            if t == "toggle" then
                write(not read())
            end
        end
        if t == "number" then
            local m,M,s = current[selection+1].min or 0, current[selection+1].max or 1, current[selection+1].step or 0.1
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
        end
    end
end

function scene.load()
end

local settingsText = love.graphics.newImage("images/settings.png")

function scene.draw()
    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(settingsText, 320, 32, 0, 2, 2, settingsText:getWidth()/2, 0)

    for i,option in ipairs(current) do
        local enabled = true
        if type(option.enable) == "function" then
            enabled = option.enable()
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if not enabled then
            love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        end
        if selection == i-1 then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
            if not enabled then
                love.graphics.setColor(TerminalColors[ColorID.BLUE])
            end
        end
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
        love.graphics.print(option.label or "", 128, (i+3)*32)
        if option.type == "color" then
            love.graphics.setColor(TerminalColors[tonumber(text) or 1])
            love.graphics.rectangle("fill", 256, (i+3)*32, 16, 16)
        else
            love.graphics.print(tostring(text), 256, (i+3)*32)
        end
    end
end

return scene