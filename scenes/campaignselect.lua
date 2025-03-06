local utf8 = require "utf8"

local scene = {}

local options = {}

function scene.load(args)
    CampaignSelectIndex = CampaignSelectIndex or 1
    CampaignView = CampaignView or 0
    CampaignViewTarget = CampaignViewTarget or 0
    scene.campaign = Campaign.GetByIndex(CampaignSelectIndex)
    scene.scores = Campaign.GetScores(scene.campaign)
    for i = 1, Campaign.NumCampaigns do
        local c = Campaign.GetByIndex(i)
        table.insert(options, {c.name,love.graphics.newImage(c.icon or "images/menu/sp.png")})
    end
end

function scene.update(dt)
    local blend = math.pow(1/((5/4)^60), dt)
    CampaignView = blend*(CampaignView-CampaignViewTarget)+CampaignViewTarget
    if math.abs(CampaignViewTarget-CampaignView) <= 8/128 then
        CampaignView = CampaignViewTarget
    end
    if CampaignView < 0 then
        CampaignView = CampaignView+#options
        CampaignViewTarget = CampaignViewTarget + #options
    end
    if CampaignView > #options then
        CampaignView = CampaignView-#options
        CampaignViewTarget = CampaignViewTarget - #options
    end
end

function scene.keypressed(k)
    if SceneManager.TransitioningIn() then return end
    if k == "left" then
        CampaignSelectIndex = ((CampaignSelectIndex-2) % Campaign.NumCampaigns) + 1
        scene.campaign = Campaign.GetByIndex(CampaignSelectIndex)
        scene.scores = Campaign.GetScores(scene.campaign)
        CampaignViewTarget = CampaignViewTarget - 1
    end
    if k == "right" then
        CampaignSelectIndex = ((CampaignSelectIndex) % Campaign.NumCampaigns) + 1
        scene.campaign = Campaign.GetByIndex(CampaignSelectIndex)
        scene.scores = Campaign.GetScores(scene.campaign)
        CampaignViewTarget = CampaignViewTarget + 1
    end
    if k == "return" then
        SceneManager.Transition("scenes/songselect", {campaign = options[CampaignSelectIndex][1], source = "campaignselect", destination = "game"})
    end
    if k == "escape" then
        SceneManager.Transition("scenes/menu")
    end
end

local function lerp(a,b,t)
    return t*(b-a)+a
end

local campaignselectText = love.graphics.newImage("images/campaignselect.png")

function scene.draw()
    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(campaignselectText, 320, 32, 0, 2, 2, campaignselectText:getWidth()/2, 0)

    if not scene.campaign.unscored then
        love.graphics.print("┌─────────────────────────────────────────────┬────┐", 14*8,  8*16)
        love.graphics.print("│                                             │    │", 14*8,  9*16)
        love.graphics.print("├─────────────────────────────────────────────┼────┤", 14*8, 10*16)
        love.graphics.print("│                                             │    │", 14*8, 11*16)
        love.graphics.print("├─────────────────────────────────────────────┼────┤", 14*8, 12*16)
        love.graphics.print("│                                             │    │", 14*8, 13*16)
        love.graphics.print("└─────────────────────────────────────────────┴────┘", 14*8, 14*16)
        
        local charge = scene.scores.totalCharge / math.max(1,scene.scores.potentialCharge)
        local ocharge = scene.scores.totalOvercharge / math.max(1,scene.scores.potentialOvercharge)
        local xcharge = scene.scores.totalXCharge / math.max(1,scene.scores.potentialXCharge)
        love.graphics.setColor(TerminalColors[ColorID.LIGHT_GREEN])
        love.graphics.print(("█"):rep(45*charge), 15*8, 9*16)
        local ocChunks = math.floor(45*ocharge)
        for i = 1, ocChunks do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print("█", (14+i)*8, 11*16)
        end
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        love.graphics.print(("█"):rep(45*xcharge), 15*8, 13*16)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        local chargeTxt = math.floor(charge*100) .. "%"
        local ochargeTxt = math.floor(ocharge*100) .. "%"
        local xchargeTxt = math.floor(xcharge*100) .. "%"
        love.graphics.printf(chargeTxt, (65-utf8.len(chargeTxt))*8, 9*16, utf8.len(chargeTxt)*8, "right")
        love.graphics.printf(ochargeTxt, (65-utf8.len(ochargeTxt))*8, 11*16, utf8.len(ochargeTxt)*8, "right")
        love.graphics.printf(xchargeTxt, (65-utf8.len(xchargeTxt))*8, 13*16, utf8.len(xchargeTxt)*8, "right")
    end

    for i = CampaignViewTarget-2, CampaignViewTarget+2 do
        local option = options[i%#options+1]

        local x = 320+(i-CampaignView)*192
        local y = 272

        local I = math.abs(CampaignViewTarget-i)
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        if I == 0 then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end

        local width = math.floor(lerp(28, 7, math.abs(CampaignView-i)))
        DrawBoxHalfWidth(math.floor(x/8-width/2), y/16-1, width, 3)
        if width > 8 then
            love.graphics.print("┬\n│\n│\n│\n┴", math.floor(x/8-width/2 + 8)*8, y-16)
        end
        if I < 2 then
            love.graphics.draw(option[2], math.floor(x/8-width/2)*8+12, y, 0, math.min(48,math.floor(width)*8)/48, 1)
        end

        if I < 1 then
            local w,wrap = Font:getWrap(option[1], (width-10)*8)
            love.graphics.printf(option[1], math.floor((x-32)/8)*8, y+16-(8*(#wrap-1)), 144, "center")
        end
    end

    local x = 320-4-(#options-1)/2*16
    love.graphics.print((" "):rep(#options*2+1), x-8, 352)
    for i = 1, #options do
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        if i == CampaignSelectIndex then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end
        love.graphics.print("○", x+(i-1)*16, 352)
    end
end

return scene