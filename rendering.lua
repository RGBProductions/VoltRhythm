Font = love.graphics.newFont("fonts/VOLTRPPGS.ttf", 16)
LegacyFont = love.graphics.newImageFont("images/font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%()[].,'\"`~\\|!?/:;@#$^&*<>{}+-_=┌─┐│└┘├┤┴┬┼█▓▒░┊┈╬○◇▷◁║¤👑▧▥▨◐◑◻☓⚠🡙ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρσςτυφχψω🮰✨�Ħ🔗ⒶⒷⓍⓎⓛⓡⓁⓇⓑⓢ⮜⮞⮝⮟⒧⒭ⓧⓄⓈⓉⓞⓗⓥⓕⓜⓟ➀➁")

---@param text string
---@param x number
---@param y number
---@param maxWidth number?
---@param align love.AlignMode?
---@param bgColor {[1]: number, [2]: number, [3]: number, [4]: number?}?
function DrawText(text, x, y, maxWidth, align, bgColor, rt, sx, sy, ox, oy, kx, ky)
    align = align or "left"
    bgColor = bgColor or TerminalColors[ColorID.BLACK]
    maxWidth = maxWidth or Font:getWidth(text)

    love.graphics.push()
    love.graphics.applyTransform(love.math.newTransform(x, y, rt, sx, sy, ox, oy, kx, ky))

    local r,g,b,a = love.graphics.getColor()
    local _,lines = Font:getWrap(text, maxWidth)
    for i, line in ipairs(lines) do
        local lineWidth = Font:getWidth(line)
        local lineX, lineY = (align == "center" and (maxWidth-lineWidth)/2 or (align == "right" and (maxWidth-lineWidth) or 0)), (i-1) * Font:getHeight()
        love.graphics.setColor(bgColor)
        love.graphics.rectangle("fill", lineX, lineY, lineWidth, Font:getHeight())
        love.graphics.setColor(r,g,b,a)
        love.graphics.print(line, lineX, lineY)
    end

    love.graphics.pop()
end

function DrawBox(x,y,w,h)
    DrawText("┌"..("──"):rep(w).."┐\n"..("│"..("  "):rep(w).."│\n"):rep(h).."└"..("──"):rep(w).."┘", x*8, y*16)
end

function DrawFilledBox(x,y,w,h)
    DrawText("█"..("██"):rep(w).."█\n"..("█"..("██"):rep(w).."█\n"):rep(h).."█"..("██"):rep(w).."█", x*8, y*16)
end

function DrawBoxHalfWidth(x,y,w,h)
    DrawText("┌"..("─"):rep(w).."┐\n"..("│"..(" "):rep(w).."│\n"):rep(h).."└"..("─"):rep(w).."┘", x*8, y*16)
end