SceneManager = {
    ActiveScene = {},
    TransitionState = {
        Transitioning = false,
        Duration = 0.5,
        Time = 0,
        NextScene = {fn = "", args = {}}
    }
}

function SceneManager.LoadScene(fn, args)
    local sceneLoadEvent = {
        path = fn,
        args = args,
        cancelled = false
    }
    if not sceneLoadEvent.cancelled then
        if love.filesystem.getInfo(fn .. ".lua") ~= nil then
            local c,e = love.filesystem.load(fn..".lua")
            if c then
                local s,nextScene = pcall(c)
                if s then
                    if SceneManager.ActiveScene.unload ~= nil then
                        SceneManager.ActiveScene.unload()
                    end
                    SceneManager.ActiveScene = nextScene
                    if SceneManager.ActiveScene.load ~= nil then
                        SceneManager.ActiveScene.load(args or {})
                    end
                else
                    print("Error loading scene: " .. tostring(nextScene))
                end
            else
                print("Error loading scene: " .. tostring(e))
            end
        end
    end
    local s,r = pcall(love.mouse.getSystemCursor,"arrow")
    if s then
        love.mouse.setCursor(r)
    end
end

function SceneManager.Transition(fn, args)
    SceneManager.TransitionState.Transitioning = true
    SceneManager.TransitionState.NextScene = {fn = fn, args = args}
end

function SceneManager.UpdateTransition(dt)
    if not SceneManager.TransitionState.Transitioning then return end
    if (SceneManager.TransitionState.Pause or 0) > 0 then
        SceneManager.TransitionState.Pause = SceneManager.TransitionState.Pause - 1
        return
    end
    local lastTime = SceneManager.TransitionState.Time
    SceneManager.TransitionState.Time = SceneManager.TransitionState.Time + dt
    if lastTime < SceneManager.TransitionState.Duration and SceneManager.TransitionState.Time >= SceneManager.TransitionState.Duration then
        SceneManager.LoadScene(SceneManager.TransitionState.NextScene.fn, SceneManager.TransitionState.NextScene.args or {})
    end
    if SceneManager.TransitionState.Time >= SceneManager.TransitionState.Duration*2 then
        SceneManager.TransitionState.Transitioning = false
        SceneManager.TransitionState.Time = 0
    end
end

function SceneManager.DrawTransition()
    if not SceneManager.TransitionState.Transitioning then return end
    if Transition and Transition.Draw then
        Transition.Draw()
    end
end

function SceneManager.TransitioningIn()
    return SceneManager.TransitionState.Transitioning and SceneManager.TransitionState.Time < SceneManager.TransitionState.Duration
end

function SceneManager.TransitioningOut()
    return SceneManager.TransitionState.Transitioning and SceneManager.TransitionState.Time >= SceneManager.TransitionState.Duration
end

function SceneManager.Update(dt)
    if SceneManager.ActiveScene.update ~= nil then
        return SceneManager.ActiveScene.update(dt)
    end
end

function SceneManager.Draw()
    if SceneManager.ActiveScene.draw ~= nil then
        return SceneManager.ActiveScene.draw()
    end
end

function SceneManager.MousePressed(x, y, b, t, p)
    if SceneManager.ActiveScene.mousepressed ~= nil then
        return SceneManager.ActiveScene.mousepressed(x, y, b, t, p)
    end
end

function SceneManager.MouseReleased(x, y, b)
    if SceneManager.ActiveScene.mousereleased ~= nil then
        return SceneManager.ActiveScene.mousereleased(x, y, b)
    end
end

function SceneManager.MouseMoved(x, y, dx, dy)
    if SceneManager.ActiveScene.mousemoved ~= nil then
        return SceneManager.ActiveScene.mousemoved(x, y, dx, dy)
    end
end

function SceneManager.WheelMoved(x, y)
    if SceneManager.ActiveScene.wheelmoved ~= nil then
        return SceneManager.ActiveScene.wheelmoved(x, y)
    end
end

function SceneManager.KeyPressed(k)
    if SceneManager.ActiveScene.keypressed ~= nil then
        return SceneManager.ActiveScene.keypressed(k)
    end
end

function SceneManager.KeyReleased(k)
    if SceneManager.ActiveScene.keyreleased ~= nil then
        return SceneManager.ActiveScene.keyreleased(k)
    end
end

function SceneManager.TextInput(t)
    if SceneManager.ActiveScene.textinput ~= nil then
        return SceneManager.ActiveScene.textinput(t)
    end
end

function SceneManager.Focus(f)
    if SceneManager.ActiveScene.focus ~= nil then
        return SceneManager.ActiveScene.focus(f)
    end
end

function SceneManager.TouchPressed(...)
    if SceneManager.ActiveScene.touchpressed ~= nil then
        return SceneManager.ActiveScene.touchpressed(...)
    end
end

function SceneManager.TouchMoved(...)
    if SceneManager.ActiveScene.touchmoved ~= nil then
        return SceneManager.ActiveScene.touchmoved(...)
    end
end

function SceneManager.TouchReleased(...)
    if SceneManager.ActiveScene.touchreleased ~= nil then
        return SceneManager.ActiveScene.touchreleased(...)
    end
end

function SceneManager.GamepadPressed(stick,button)
    if SceneManager.ActiveScene.gamepadpressed ~= nil then
        return SceneManager.ActiveScene.gamepadpressed(stick,button)
    end
end

function SceneManager.GamepadReleased(stick,button)
    if SceneManager.ActiveScene.gamepadreleased ~= nil then
        return SceneManager.ActiveScene.gamepadreleased(stick,button)
    end
end

function SceneManager.GamepadAxis(stick,axis,value)
    if SceneManager.ActiveScene.gamepadaxis ~= nil then
        return SceneManager.ActiveScene.gamepadaxis(stick,axis,value)
    end
end

function SceneManager.FileDropped(file)
    if SceneManager.ActiveScene.filedropped ~= nil then
        return SceneManager.ActiveScene.filedropped(file)
    end
end

function SceneManager.DirectoryDropped(path)
    if SceneManager.ActiveScene.directorydropped ~= nil then
        return SceneManager.ActiveScene.directorydropped(path)
    end
end

function SceneManager.Action(action)
    if SceneManager.ActiveScene.action ~= nil then
        return SceneManager.ActiveScene.action(action)
    end
end