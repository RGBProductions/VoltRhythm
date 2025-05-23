local utf8 = require "utf8"

local scene = {}

local credits = json.decode(love.filesystem.read("credits.json"))
local maxX = 0
local maxY = 0
for _,credit in ipairs(credits) do
    maxY = math.max(maxY, #credit.items)
    maxX = math.max(maxX, utf8.len(credit.name)+2)
    for _,item in ipairs(credit.items) do
        maxX = math.max(maxX, utf8.len(item)+2)
    end
end

CreditsSelection = 0
CreditsView = 0

function scene.keypressed(k)
    if k == "escape" then
        SceneManager.Transition("scenes/menu")
    end
    if k == "up" then
        CreditsSelection = (CreditsSelection - 1) % #credits
    end
    if k == "down" then
        CreditsSelection = (CreditsSelection + 1) % #credits
    end
    if k == "return" and credits[CreditsSelection+1].url then
        love.system.openURL(credits[CreditsSelection+1].url)
    end
end

function scene.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    CreditsView = blend*(CreditsView-CreditsSelection)+CreditsSelection
    if math.abs(CreditsSelection-CreditsView) <= 8/128 then
        CreditsView = CreditsSelection
    end
end

local creditsText = love.graphics.newImage("images/title/credits.png")

function scene.draw()
    local y = CreditsView
    for i,credit in ipairs(credits) do
        love.graphics.setColor(TerminalColors[CreditsSelection == i-1 and ColorID.WHITE or ColorID.DARK_GRAY])
        local itmY = (i-y)*(64+16*maxY)+16*((maxY-#credit.items)/2+1)
        local itmX = (640-maxX*8)/2
        DrawBoxHalfWidth(itmX/8-1, itmY/16-1, maxX, #credit.items+2)
        love.graphics.printf(credit.name .. (credit.url and " 🔗" or ""), itmX, itmY+((credit.type == "menu" or credit.type == "action") and 16 or 0), maxX*8, "center")
        love.graphics.setColor(TerminalColors[CreditsSelection == i-1 and ColorID.LIGHT_GRAY or ColorID.DARK_GRAY])
        for j,itm in ipairs(credit.items) do
            love.graphics.printf(itm, itmX, itmY+16*(j+1), maxX*8, "center")
        end
    end

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(creditsText, 320, 32, 0, 2, 2, creditsText:getWidth()/2, 0)
end

return scene