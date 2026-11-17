local scene = {}

local options = {}

function scene.load(args)
    StartMenuBGM()
    options = {}
    SongDiskSelectIndex = SongDiskSelectIndex or 1
    CampaignView = CampaignView or 0
    CampaignViewTarget = CampaignViewTarget or 0
    SongDisk.RecalculateScores()
    scene.disk = SongDisk.Disks[SongDiskSelectIndex]
    scene.scores = scene.disk.metrics
    for _,c in ipairs(SongDisk.Disks) do
        table.insert(options, {c.name,c.icon})
    end

    if SystemSettings.discord_rpc_level > RPCLevels.PLAYING then
        Discord.setActivity("Not playing")
        Discord.updatePresence()
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
    if SceneManager.TransitionState.Transitioning then return end

    if a == "left" then
        SongDiskSelectIndex = ((SongDiskSelectIndex-2) % #SongDisk.Disks) + 1
        scene.disk = SongDisk.Disks[SongDiskSelectIndex]
        scene.scores = scene.disk.metrics
        CampaignViewTarget = CampaignViewTarget - 1
        PlayNavSound()
    end
    if a == "right" then
        SongDiskSelectIndex = ((SongDiskSelectIndex) % #SongDisk.Disks) + 1
        scene.disk = SongDisk.Disks[SongDiskSelectIndex]
        scene.scores = scene.disk.metrics
        CampaignViewTarget = CampaignViewTarget + 1
        PlayNavSound()
    end
    if a == "confirm" then
        StopMenuBGM()
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

    if not scene.disk.unscored then
        local chargem = scene.scores.totalCharge
        local ochargem = scene.scores.totalOvercharge
        local xchargem = scene.scores.totalXCharge
        local charge = scene.scores.charge
        local ocharge = scene.scores.overcharge
        local xcharge = scene.scores.xcharge
        local chargep = charge / math.max(1,chargem)
        local ochargep = ocharge / math.max(1,ochargem)
        local xchargep = xcharge / math.max(1,xchargem)

        local chargeTxt = math.floor(charge) .. "¤"
        local ochargeTxt = math.floor(ocharge) .. "¤"
        local xchargeTxt = math.floor(xcharge) .. "¤"
        local chargepTxt = math.floor(chargep*100) .. "%"
        local ochargepTxt = math.floor(ochargep*100) .. "%"
        local xchargepTxt = math.floor(xchargep*100) .. "%"

        local labelCharge = Localize("score_charge")
        local labelOvercharge = Localize("score_overcharge")
        local labelXCharge = Localize("score_xcharge")

        local mx = math.max(Font:getWidth(labelCharge),Font:getWidth(labelOvercharge),Font:getWidth(labelXCharge))

        local barX = math.ceil((mx + 40) / 8)
        local barW = 59-barX

        local line = ("─"):rep(barW)
        local space = (" "):rep(barW)

        DrawText("┌" .. line  .. "┬──────┬───────┐", barX*8,  8*16)
        DrawText("│" .. space .. "│      │       │", barX*8,  9*16)
        DrawText("├" .. line  .. "┼──────┼───────┤", barX*8, 10*16)
        DrawText("│" .. space .. "│      │       │", barX*8, 11*16)
        DrawText("├" .. line  .. "┼──────┼───────┤", barX*8, 12*16)
        DrawText("│" .. space .. "│      │       │", barX*8, 13*16)
        DrawText("└" .. line  .. "┴──────┴───────┘", barX*8, 14*16)

        DrawText(labelCharge, 4*8,  9*16, mx, "right")
        DrawText(labelOvercharge, 4*8,  11*16, mx, "right")
        DrawText(labelXCharge, 4*8,  13*16, mx, "right")
        
        love.graphics.setColor(TerminalColors[ColorID.LIGHT_GREEN])
        DrawText(("█"):rep(barW*chargep), (barX+1)*8, 9*16)
        local ocChunks = math.floor(barW*ochargep)
        for i = 1, ocChunks do
            local chunkColor = (math.floor(-love.timer.getTime()*#OverchargeColors)+i-1)%#OverchargeColors
            love.graphics.setColor(TerminalColors[OverchargeColors[chunkColor+1]])
            DrawText("█", (barX+i)*8, 11*16)
        end
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        DrawText(("█"):rep(barW*xchargep), (barX+1)*8, 13*16)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        DrawText(chargeTxt, (69)*8, 9*16, 5*8, "right")
        DrawText(ochargeTxt, (69)*8, 11*16, 5*8, "right")
        DrawText(xchargeTxt, (69)*8, 13*16, 5*8, "right")
        DrawText(chargepTxt, (62)*8, 9*16, 4*8, "right")
        DrawText(ochargepTxt, (62)*8, 11*16, 4*8, "right")
        DrawText(xchargepTxt, (62)*8, 13*16, 4*8, "right")
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
            DrawText("┬\n│\n│\n│\n┴", math.floor(x/8-width/2 + 8)*8, y-16)
        end
        if I < 2 then
            love.graphics.draw(option[2], math.floor(x/8-width/2)*8+12, y, 0, math.min(48,math.floor(width)*8)/48, 1)
        end

        if I < 1 then
            local w,wrap = Font:getWrap(option[1], (width-10)*8)
            DrawText(option[1], math.floor((x-32)/8)*8, y+16-(8*(#wrap-1)), 144, "center")
        end
    end

    local x = 320-4-(#options-1)/2*16
    DrawText((" "):rep(#options*2+1), x-8, 352)
    for i = 1, #options do
        love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
        if i == SongDiskSelectIndex then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end
        DrawText("○", x+(i-1)*16, 352)
    end
end

return scene