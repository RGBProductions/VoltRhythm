local scene = {}

function scene.load()
    scene.going = false
    scene.complete = false
    scene.offset = 0
    scene.hits = 0
    scene.source = Assets.Source("sounds/calibration.ogg")
end

---@param k love.KeyConstant
function scene.keypressed(k)
    if k == "lalt" or k == "ralt" or k == "tab" then
        return
    end
    if k == "escape" then
        scene.source:stop()
        SceneManager.Transition("scenes/menu")
        return
    end
    if k == "return" then
        if not scene.going and not scene.complete then
            scene.going = true
            scene.source:play()
        elseif not scene.complete then
            scene.going = false
            scene.complete = true
            scene.source:stop()
            SystemSettings.audio_offset = math.floor(scene.offset/scene.hits*1000)/1000
        else
            SceneManager.Transition("scenes/menu")
        end
    elseif scene.going then
        local len = scene.source:getDuration("seconds")
        local t = scene.source:tell("seconds")/len*4
        local off = ((t-1) % 4) - 2
        local hitOffset = off*len/4
        print(hitOffset)
        scene.offset = scene.offset + hitOffset
        scene.hits = scene.hits + 1
    end
end

function scene.update(dt)
    if scene.going and not scene.source:isPlaying() then
        scene.source:seek(0, "seconds")
        scene.source:play()
    end
end

function scene.draw()
    if not scene.going and not scene.complete then
        love.graphics.printf("Press enter to begin calibration.", 0, 240-8, 640, "center")
    end
    if scene.going then
        love.graphics.printf("Press any key on the fourth beat.\nPress enter to stop.\n\nOffset is " .. math.floor((scene.offset/scene.hits)*1000) .. "ms", 0, 240-16-16, 640, "center")
    end
    if scene.complete then
        love.graphics.printf("Your new offset is " .. math.floor((scene.offset/scene.hits)*1000) .. "ms.\n\nPress enter to exit", 0, 240-8-16, 640, "center")
    end
end

return scene