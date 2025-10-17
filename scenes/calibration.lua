local scene = {}

function scene.load()
    scene.going = false
    scene.complete = false
    scene.offset = 0
    scene.hits = 0
    scene.source = Assets.Source("sounds/calibration.ogg")
end

function scene.action(a)
    if a == "back" then
        scene.source:stop()
        SceneManager.Transition("scenes/settings", {stay=true})
        return
    end
    if a == "confirm" then
        if not scene.going and not scene.complete then
            scene.going = true
            scene.wait = true
            scene.source:play()
        elseif not scene.complete then
            scene.going = false
            scene.complete = true
            scene.source:stop()
            if scene.hits > 0 then
                SystemSettings.audio_offset = math.floor(scene.offset/scene.hits*1000)/1000
            end
        else
            SceneManager.Transition("scenes/settings", {stay=true})
        end
    elseif scene.going then
        if scene.wait then
            scene.wait = false
            return
        end
        local len = scene.source:getDuration("seconds")
        local t = scene.source:tell("seconds")/len*4
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
    if scene.going and not scene.source:isPlaying() and not (SceneManager.TransitioningIn() or SceneManager.TransitioningOut()) then
        scene.source:seek(0, "seconds")
        scene.source:play()
    end
end

function scene.draw()
    local binds = {
        confirm = HasGamepad and Save.Read("keybinds.confirm")[2] or Save.Read("keybinds.confirm")[1]
    }

    if not scene.going and not scene.complete then
        love.graphics.printf("Press " .. KeyLabel(binds.confirm) .. " to begin calibration.", 0, 240-8, 640, "center")
    end
    if scene.going then
        love.graphics.printf("Press any " .. (HasGamepad and "button" or "key") .. " on the fourth beat.\nPress " .. KeyLabel(binds.confirm) .. " to stop.\n\nOffset is " .. math.floor((scene.offset/scene.hits)*1000) .. "ms", 0, 240-16-16, 640, "center")
    end
    if scene.complete then
        if scene.hits == 0 then
            love.graphics.printf("No inputs were made. Your offset has not changed.\n\nPress " .. KeyLabel(binds.confirm) .. " to exit", 0, 240-8-16, 640, "center")
        else
            love.graphics.printf("Your new offset is " .. math.floor((scene.offset/scene.hits)*1000) .. "ms.\n\nPress " .. KeyLabel(binds.confirm) .. " to exit", 0, 240-8-16, 640, "center")
        end
    end
end

return scene