local scene = {}

SuppressBorder = true

function scene.draw()
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.printf("VoltRhythm may contain rapidly-moving patterns and flashing lights that could cause health problems for those with photosensitive conditions.\n\nIf you suffer from one of these conditions, please use extreme caution while playing or avoid playing entirely.", 64, 128, 512, "center")
    love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
    love.graphics.printf("Continue", 64, 256, 512, "center")
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.printf("Continue (Effects Off)", 64, 256+16, 512, "center")
    love.graphics.printf("Exit", 64, 256+32, 512, "center")
end

return scene