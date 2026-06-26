local scene = {}

local credits = json.decode(love.filesystem.read("credits.json"))

local objects = {}
local objpos = 0
local objwidth = 0
for _,credit in ipairs(credits) do
    local object = {y = objpos, height = #credit.items+2, credit = credit}
    objwidth = math.max(objwidth, Font:getWidth(credit.name)/8+2)
    for _,item in ipairs(credit.items) do
        objwidth = math.max(objwidth, Font:getWidth(item)/8+2)
    end
    objpos = objpos + object.height+4
    table.insert(objects, object)
end

CreditsSelection = 0
CreditsView = objects[CreditsSelection+1].y + objects[CreditsSelection+1].height/2

function scene.action(a)
    if a == "back" then
        SceneManager.Transition("scenes/menu")
    end
    if a == "up" then
        CreditsSelection = (CreditsSelection - 1) % #credits
    end
    if a == "down" then
        CreditsSelection = (CreditsSelection + 1) % #credits
    end
    if a == "confirm" and credits[CreditsSelection+1].url then
        love.system.openURL(credits[CreditsSelection+1].url)
    end
end

function scene.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    local cvtarget = objects[CreditsSelection+1].y + objects[CreditsSelection+1].height/2
    CreditsView = blend*(CreditsView-cvtarget)+cvtarget
    if math.abs(cvtarget-CreditsView) <= 8/128 then
        CreditsView = cvtarget
    end
end

local creditsText = love.graphics.newImage("images/title/credits.png")

function scene.draw()
    local itmX = (640-objwidth*8)/2
    for i,object in ipairs(objects) do
        local credit = object.credit
        love.graphics.setColor(TerminalColors[CreditsSelection == i-1 and ColorID.WHITE or ColorID.DARK_GRAY])
        local itmY = object.y*16 - CreditsView*16 + 240
        DrawBoxHalfWidth(itmX/8-1, itmY/16-1, objwidth, object.height)
        DrawText(credit.name .. (credit.url and " 🔗" or ""), itmX, itmY+((credit.type == "menu" or credit.type == "action") and 16 or 0), objwidth*8, "center")
        love.graphics.setColor(TerminalColors[CreditsSelection == i-1 and ColorID.LIGHT_GRAY or ColorID.DARK_GRAY])
        for j,itm in ipairs(credit.items) do
            DrawText(itm, itmX, itmY+16*(j+1), objwidth*8, "center")
        end
    end

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(creditsText, 320, 32, 0, 2, 2, creditsText:getWidth()/2, 0)
end

return scene