local scene = {}

local function resetBorderView(border)
    BordersBorderView = 1
    BordersBorderSelection = 1
    for i = 1, #Borders.Categories[BordersCategorySelection].borders do
        if Borders.Categories[BordersCategorySelection].borders[i] == border then
            BordersBorderView = i
            BordersBorderSelection = i
            break
        end
    end
end

function scene.load()
    BordersCategoryView = 1
    BordersCategorySelection = 1
    resetBorderView(Save.Read("border"))
    BorderPreview = Borders.Categories[BordersCategorySelection].borders[BordersBorderSelection]
end

function scene.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    BordersCategoryView = blend*(BordersCategoryView-BordersCategorySelection)+BordersCategorySelection
    if math.abs(BordersCategorySelection-BordersCategoryView) <= 8/128 then
        BordersCategoryView = BordersCategorySelection
    end
    BordersBorderView = blend*(BordersBorderView-BordersBorderSelection)+BordersBorderSelection
    if math.abs(BordersBorderSelection-BordersBorderView) <= 8/128 then
        BordersBorderView = BordersBorderSelection
    end
end

function scene.draw()
    for i = 1, #Borders.Categories[BordersCategorySelection].borders do
        local id = Borders.Categories[BordersCategorySelection].borders[i]
        local border = Borders.Borders[id] or {info = {name = "UNDEFINED"}, script = nil}
        love.graphics.setColor(TerminalColors[Save.Read("border") == id and (BordersBorderSelection == i and ColorID.LIGHT_GREEN or ColorID.GREEN) or (BordersBorderSelection == i and ColorID.WHITE or ColorID.DARK_GRAY)])
        DrawBoxHalfWidth(27, ((i-BordersBorderView)*64+240-8)/16-1, 24, 1)
        love.graphics.printf(border.info.name, 320-96, (i-BordersBorderView)*64+240-8, 192, "center")
    end
    for i = 1, #Borders.Categories do
        love.graphics.setColor(TerminalColors[BordersCategorySelection == i and ColorID.WHITE or ColorID.DARK_GRAY])
        DrawBoxHalfWidth(((i-BordersCategoryView)*192+320-64)/8-1, 4, 16, 1)
        love.graphics.printf(Borders.Categories[i].name, (i-BordersCategoryView)*192+320-64, 80, 128, "center")
    end

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth(9, 1, 60, 1)
    love.graphics.printf("BORDERS", 0, 32, 640, "center")
end

function scene.action(a)
    if a == "*" then return end
    
    if a == "back" then
        BorderPreview = nil
        SceneManager.Transition("scenes/settings", {stay=true})
        return
    end

    if a == "confirm" then
        Save.Write("border", Borders.Categories[BordersCategorySelection].borders[BordersBorderSelection])
    end

    if not SceneManager.TransitioningIn() then
        if a == "left" then
            local border = Borders.Categories[BordersCategorySelection].borders[BordersBorderSelection]
            BordersCategorySelection = (BordersCategorySelection - 2) % #Borders.Categories + 1
            resetBorderView(border)
        end
        if a == "right" then
            local border = Borders.Categories[BordersCategorySelection].borders[BordersBorderSelection]
            BordersCategorySelection = BordersCategorySelection % #Borders.Categories + 1
            resetBorderView(border)
        end
        if a == "up" then
            BordersBorderSelection = (BordersBorderSelection - 2) % #Borders.Categories[BordersCategorySelection].borders + 1
        end
        if a == "down" then
            BordersBorderSelection = BordersBorderSelection % #Borders.Categories[BordersCategorySelection].borders + 1
        end
        BorderPreview = Borders.Categories[BordersCategorySelection].borders[BordersBorderSelection]
    end
end

return scene