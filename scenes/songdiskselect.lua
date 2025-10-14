local utf8 = require "utf8"

local scene = {}

local options = {}

function scene.load(args)
    SongDiskSelectIndex = SongDiskSelectIndex or 1
    CampaignView = CampaignView or 0
    CampaignViewTarget = CampaignViewTarget or 0
    scene.campaign = SongDisk.GetByIndex(SongDiskSelectIndex)
    scene.scores = SongDisk.GetScores(scene.campaign)
    for i = 1, SongDisk.NumDisks do
        local c = SongDisk.GetByIndex(i)
        table.insert(options, {c.name,love.graphics.newImage(c.icon or "images/songdisk/default.png")})
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

function scene.action(a)
    if a == "left" then
        SongDiskSelectIndex = ((SongDiskSelectIndex-2) % SongDisk.NumDisks) + 1
        scene.campaign = SongDisk.GetByIndex(SongDiskSelectIndex)
        scene.scores = SongDisk.GetScores(scene.campaign)
        CampaignViewTarget = CampaignViewTarget - 1
    end
    if a == "right" then
        SongDiskSelectIndex = ((SongDiskSelectIndex) % SongDisk.NumDisks) + 1
        scene.campaign = SongDisk.GetByIndex(SongDiskSelectIndex)
        scene.scores = SongDisk.GetScores(scene.campaign)
        CampaignViewTarget = CampaignViewTarget + 1
    end
    if a == "confirm" then
        SceneManager.Transition("scenes/songselect", {campaign = options[SongDiskSelectIndex][1], source = "songdiskselect", destination = "game"})
    end
    if a == "back" then
        SceneManager.Transition("scenes/menu")
    end
end

local function lerp(a,b,t)
    return t*(b-a)+a
end

local songdiskselectText = love.graphics.newImage("images/title/songdiskselect.png")

function scene.draw()
    DrawBoxHalfWidth(2, 1, 74, 3)
    love.graphics.draw(songdiskselectText, 320, 32, 0, 2, 2, songdiskselectText:getWidth()/2, 0)

    if not scene.campaign.unscored then
        local charge = scene.scores.totalCharge
        local ocharge = scene.scores.totalOvercharge
        local xcharge = scene.scores.totalXCharge
        local chargep = scene.scores.totalCharge / math.max(1,scene.scores.potentialCharge)
        local ochargep = scene.scores.totalOvercharge / math.max(1,scene.scores.potentialOvercharge)
        local xchargep = scene.scores.totalXCharge / math.max(1,scene.scores.potentialXCharge)

        local chargeTxt = math.floor(charge) .. "¤"
        local ochargeTxt = math.floor(ocharge) .. "¤"
        local xchargeTxt = math.floor(xcharge) .. "¤"
        local chargepTxt = math.floor(chargep*100) .. "%"
        local ochargepTxt = math.floor(ochargep*100) .. "%"
        local xchargepTxt = math.floor(xchargep*100) .. "%"

        local mx = math.max(utf8.len(chargeTxt),utf8.len(ochargeTxt),utf8.len(xchargeTxt))

        love.graphics.print("           ┌─────────────────────────────────────────────┬──────┬──────┐", 4*8,  8*16)
        love.graphics.print("    CHARGE │                                             │      │      │", 4*8,  9*16)
        love.graphics.print("           ├─────────────────────────────────────────────┼──────┼──────┤", 4*8, 10*16)
        love.graphics.print("OVERCHARGE │                                             │      │      │", 4*8, 11*16)
        love.graphics.print("           ├─────────────────────────────────────────────┼──────┼──────┤", 4*8, 12*16)
        love.graphics.print("  X-CHARGE │                                             │      │      │", 4*8, 13*16)
        love.graphics.print("           └─────────────────────────────────────────────┴──────┴──────┘", 4*8, 14*16)
        
        love.graphics.setColor(TerminalColors[ColorID.LIGHT_GREEN])
        love.graphics.print(("█"):rep(45*chargep), 16*8, 9*16)
        local ocChunks = math.floor(45*ochargep)
        for i = 1, ocChunks do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            love.graphics.print("█", (15+i)*8, 11*16)
        end
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        love.graphics.print(("█"):rep(45*xchargep), 16*8, 13*16)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        love.graphics.printf(chargeTxt, (74-utf8.len(chargeTxt))*8, 9*16, utf8.len(chargeTxt)*8, "right")
        love.graphics.printf(ochargeTxt, (74-utf8.len(ochargeTxt))*8, 11*16, utf8.len(ochargeTxt)*8, "right")
        love.graphics.printf(xchargeTxt, (74-utf8.len(xchargeTxt))*8, 13*16, utf8.len(xchargeTxt)*8, "right")
        love.graphics.printf(chargepTxt, (67-utf8.len(chargepTxt))*8, 9*16, utf8.len(chargepTxt)*8, "right")
        love.graphics.printf(ochargepTxt, (67-utf8.len(ochargepTxt))*8, 11*16, utf8.len(ochargepTxt)*8, "right")
        love.graphics.printf(xchargepTxt, (67-utf8.len(xchargepTxt))*8, 13*16, utf8.len(xchargepTxt)*8, "right")
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
        if i == SongDiskSelectIndex then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end
        love.graphics.print("○", x+(i-1)*16, 352)
    end
end

return scene