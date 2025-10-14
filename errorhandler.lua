local utf8 = require("utf8")

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

return function (msg)
	Save.Flush()
    love.filesystem.write("settings.json", json.encode(SystemSettings))
	
	msg = tostring(msg)

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

    ---@diagnostic disable-next-line: undefined-field
	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end

	love.graphics.reset()
	Font = love.graphics.newImageFont("images/font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%()[].,'\"`~\\|!?/:;@#$^&*<>{}+-_=┌─┐│└┘├┤┴┬┼█▓▒░┊┈╬○◇▷◁║¤👑▧▥▨◐◑◻☓⚠🡙ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρσςτυφχψω🮰✨�Ħ🔗ⒶⒷⓍⓎⓛⓡⓁⓇⓑⓢ⮜⮞⮝⮟⒧⒭ⓧⓄⓈⓉⓞⓗⓥⓕⓜⓟ➀➁")
    love.graphics.setFont(Font)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback("",2)

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
    ---@diagnostic disable-next-line: cast-local-type
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}
    
	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback:\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

    CurveStrength = 0.5
    
    CurveModifier = 1
    CurveModifierTarget = 1
    CurveModifierSmoothing = 0
    
    Chromatic = 1
    ChromaticModifier = 0
    ChromaticModifierTarget = 0
    ChromaticModifierSmoothing = 0
    
    TearingStrength = 1
    TearingModifier = 0
    TearingModifierTarget = 0
    TearingModifierSmoothing = 0

    ScreenShader = love.graphics.newShader("shaders/screen.frag")
    ScreenShader:send("curveStrength", SystemSettings.screen_effects.screen_curvature*CurveModifier)
    ScreenShader:send("scanlineStrength", 0.5)
    ScreenShader:send("texSize", {Display:getDimensions()})
    ScreenShader:send("tearStrength", 0)
    ScreenShader:send("chromaticStrength", Chromatic*ChromaticModifier)
    ScreenShader:send("horizBlurStrength", 0.5)
    ScreenShader:send("tearTime", love.timer.getTime())

    BloomShader = love.graphics.newShader("shaders/bloom.frag")
    BloomShader:send("strength", 1)

    Display = love.graphics.newCanvas(640,480)
    Display:setFilter("linear", "linear")
    Display2 = love.graphics.newCanvas(640,480)
    Display2:setFilter("linear", "linear")
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    love.graphics.setFont(Font)

    Bloom = love.graphics.newCanvas()
    Final = love.graphics.newCanvas()
    Partial = love.graphics.newCanvas()

	local function draw()
		if not love.graphics.isActive() then return end
        love.graphics.clear(0,0,0)
        do
            love.graphics.setCanvas(Display)
            love.graphics.clear(0,0,0)

            love.graphics.setColor(1,1,1)

            -- ERROR DRAW.
            love.graphics.printf("VoltRhythm has encountered a severe error and needs to shut down.\nPlease reboot the program as soon as possible.\n\nError details:\n" .. p, 32, 32, 576)
            
            love.graphics.setColor(1,1,1)
            love.graphics.print(Version.name .. " v" .. Version.version, 16, 480-16-16)

            love.graphics.setColor(TerminalColors[16])
            -- love.graphics.print("▒", MouseX-4, MouseY-8)
            
            love.graphics.setCanvas(Final)
            love.graphics.clear(0,0,0)
            love.graphics.setColor(1,1,1)

            local s = math.min(love.graphics.getWidth()/Display:getWidth(), love.graphics.getHeight()/Display:getHeight())
            if SystemSettings.enable_screen_effects then love.graphics.setShader(ScreenShader) end
            love.graphics.draw(Display, (love.graphics.getWidth()-Display:getWidth()*s)/2, (love.graphics.getHeight()-Display:getHeight()*s)/2, 0, s, s)
            love.graphics.setShader()
            love.graphics.setCanvas()

            if SystemSettings.enable_screen_effects then
                texture.blur(Final, Partial, Bloom, 8, true)
                texture.blur(Final, Partial, Bloom, 8, true)
                love.graphics.setShader(BloomShader)
                BloomShader:send("blurred", Bloom)
            end

            love.graphics.draw(Final)
            love.graphics.setShader()
        end
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					copyToClipboard()
				end
			end
		end

        -- update(love.timer.getDelta())
		draw()

		if love.timer then
			love.timer.sleep(1/60)
		end
	end
end