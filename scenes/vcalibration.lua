local scene = {}

function scene.load()
    scene.going = false
    scene.complete = false
    scene.offset = 0
    scene.hits = 0
    scene.time = 0
end

function scene.action(a)
    if a == "back" then
        SceneManager.Transition("scenes/settings", {stay=true})
        return
    end
    if a == "confirm" then
        if not scene.going and not scene.complete then
            scene.going = true
            scene.wait = true
        elseif not scene.complete then
            scene.going = false
            scene.complete = true
            if scene.hits > 0 then
                SystemSettings.video_offset = math.floor(scene.offset/scene.hits*1000)/1000
            end
        else
            SceneManager.Transition("scenes/settings", {stay=true})
        end
    elseif scene.going then
        if scene.wait then
            scene.wait = false
            return
        end
        local len = SixteenthsToSeconds(16, 130)
        local t = scene.time/len*4
        local off = ((t-1) % 4) - 2
        local hitOffset = off*len/4
        scene.offset = scene.offset + hitOffset
        scene.hits = scene.hits + 1
    end
end

---@param k love.KeyConstant
function scene.keypressed(k)
    if k == "lalt" or k == "ralt" or k == "tab" then
        return true
    end
end

function scene.update(dt)
    if scene.going and not (SceneManager.TransitioningIn() or SceneManager.TransitioningOut()) then
        scene.time = (scene.time + dt) % SixteenthsToSeconds(16, 130)
    end
end

function scene.draw()
    local binds = {
        confirm = HasGamepad and Save.Keybind("confirm")[2] or Save.Keybind("confirm")[1]
    }

    if not scene.going and not scene.complete then
        DrawText(Localize("calibration_begin"):format(KeyLabel(binds.confirm)), 0, 240-8, 640, "center")
    end
    if scene.going then
        DrawText(Localize(HasGamepad and "vcalibration_instructions_gamepad" or "vcalibration_instructions"):format(KeyLabel(binds.confirm), math.floor((scene.offset/scene.hits)*1000)), 0, 240-16-16, 640, "center")
        for i = 0, 3 do
            local t = 1 - ((scene.time/SixteenthsToSeconds(4, 130) - i) % 4)
            love.graphics.setColor(TerminalColors[t >= 5/6 and ColorID.WHITE or (t >= 4/6 and ColorID.LIGHT_GRAY or ColorID.DARK_GRAY)])
            love.graphics.circle("fill", 320-32-64+i*64, 240+64, 16)
        end
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if scene.time/SixteenthsToSeconds(4,130) < 3 then
            love.graphics.circle("fill", 320-32-64+math.min(SixteenthsToSeconds(12, 130), scene.time)/SixteenthsToSeconds(4, 130)*64, 240+64, 16)
        end
    end
    if scene.complete then
        if scene.hits == 0 then
            DrawText(Localize("calibration_failed"):format(KeyLabel(binds.confirm)), 0, 240-8-16, 640, "center")
        else
            DrawText(Localize("calibration_finished"):format(math.floor((scene.offset/scene.hits)*1000), KeyLabel(binds.confirm)), 0, 240-8-16, 640, "center")
        end
    end
end

return scene