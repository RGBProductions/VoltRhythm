local scene = {}

local langs = GetLanguages()

local pause = 0
local selected = false

LanguageSelection = 0
LanguageView = 0
for i,lang in ipairs(langs) do
    if lang.code == SystemSettings.language then
        LanguageSelection = i-1
        LanguageView = i-1
    end
end

function scene.load(args)
    scene.destination = args.destination or (love.filesystem.getInfo("hidepswarning") and "startup" or "photosensitivity")
    scene.transition = args.transition
    scene.quitOnFail = args.quitOnFail
end

function scene.action(a)
    if a == "up" then
        LanguageSelection = (LanguageSelection - 1) % #langs
    end
    if a == "down" then
        LanguageSelection = (LanguageSelection + 1) % #langs
    end
    if a == "confirm" then
        SystemSettings.language = langs[LanguageSelection+1].code
        if scene.transition then
            SceneManager.Transition("scenes/"..scene.destination, {stay = true})
        else
            selected = true
        end
    end
    if a == "back" then
        if scene.quitOnFail then
            love.event.push("quit")
        else
            SceneManager[scene.transition and "Transition" or "LoadScene"]("scenes/"..scene.destination, {stay = true})
        end
    end
end

function scene.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    LanguageView = blend*(LanguageView-LanguageSelection)+LanguageSelection
    if math.abs(LanguageSelection-LanguageView) <= 8/128 then
        LanguageView = LanguageSelection
    end
    if selected then
        pause = pause + dt
        if pause >= 0.5 then
            SceneManager.LoadScene("scenes/"..scene.destination, {stay = true})
        end
    end
end

function scene.draw()
    if selected then return end
    
    for i,lang in ipairs(langs) do
        love.graphics.setColor(TerminalColors[LanguageSelection == i-1 and ColorID.WHITE or ColorID.DARK_GRAY])
        DrawBoxHalfWidth(21, 14 + (i-1-LanguageView)*3, 36, 1)
        DrawText(lang.name, 0, 240+(i-1-LanguageView)*48, 640, "center")
    end

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth(9, 1, 60, 1)
    DrawText(Localize("language"), 0, 32, 640, "center")
end

return scene