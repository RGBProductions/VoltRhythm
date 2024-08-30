SceneManager = {
    ActiveScene = {}
}

function SceneManager.LoadScene(fn, args)
    local sceneLoadEvent = {
        path = fn,
        args = args,
        cancelled = false
    }
    if not sceneLoadEvent.cancelled then
        if love.filesystem.getInfo(fn .. ".lua") ~= nil then
            SceneManager.ActiveScene = require(fn)
            if SceneManager.ActiveScene.load ~= nil then
                SceneManager.ActiveScene.load(args or {})
            end
        end
    end
    local s,r = pcall(love.mouse.getSystemCursor,"arrow")
    if s then
        love.mouse.setCursor(r)
    end
end

function SceneManager.Update(dt)
    if SceneManager.ActiveScene.update ~= nil then
        SceneManager.ActiveScene.update(dt)
    end
end

function SceneManager.Draw()
    if SceneManager.ActiveScene.draw ~= nil then
        SceneManager.ActiveScene.draw()
    end
end

function SceneManager.MousePressed(x, y, b, t, p)
    if SceneManager.ActiveScene.mousepressed ~= nil then
        SceneManager.ActiveScene.mousepressed(x, y, b, t, p)
    end
end

function SceneManager.MouseReleased(x, y, b)
    if SceneManager.ActiveScene.mousereleased ~= nil then
        SceneManager.ActiveScene.mousereleased(x, y, b)
    end
end

function SceneManager.MouseMoved(x, y, dx, dy)
    if SceneManager.ActiveScene.mousemoved ~= nil then
        SceneManager.ActiveScene.mousemoved(x, y, dx, dy)
    end
end

function SceneManager.WheelMoved(x, y)
    if SceneManager.ActiveScene.wheelmoved ~= nil then
        SceneManager.ActiveScene.wheelmoved(x, y)
    end
end

function SceneManager.KeyPressed(k)
    if SceneManager.ActiveScene.keypressed ~= nil then
        SceneManager.ActiveScene.keypressed(k)
    end
end

function SceneManager.TextInput(t)
    if SceneManager.ActiveScene.textinput ~= nil then
        SceneManager.ActiveScene.textinput(t)
    end
end

function SceneManager.Focus(f)
    if SceneManager.ActiveScene.focus ~= nil then
        SceneManager.ActiveScene.focus(f)
    end
end

function SceneManager.TouchPressed(...)
    if SceneManager.ActiveScene.touchpressed ~= nil then
        SceneManager.ActiveScene.touchpressed(...)
    end
end

function SceneManager.TouchMoved(...)
    if SceneManager.ActiveScene.touchmoved ~= nil then
        SceneManager.ActiveScene.touchmoved(...)
    end
end

function SceneManager.TouchReleased(...)
    if SceneManager.ActiveScene.touchreleased ~= nil then
        SceneManager.ActiveScene.touchreleased(...)
    end
end

function SceneManager.GamepadPressed(stick,button)
    if SceneManager.ActiveScene.gamepadpressed ~= nil then
        SceneManager.ActiveScene.gamepadpressed(stick,button)
    end
end