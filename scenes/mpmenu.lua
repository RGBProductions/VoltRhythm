local scene = {}

function scene.keypressed(k)
    if k == "escape" then
        SceneManager.Transition("scenes/menu")
    end
end

function scene.draw()
    love.graphics.printf("wait why are you here\nmultiplayer isnt even implemented yet\n\npress escape to go back to the REAL game", 0, 240-16-16, 640, "center")
end

return scene