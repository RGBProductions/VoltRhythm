local utf8 = require "utf8"

DialogLabel = {}
DialogLabel.__index = DialogLabel

function DialogLabel:new(x,y,width,text,align)
    local label = setmetatable({}, DialogLabel)

    label.x = x
    label.y = y
    label.width = width
    label.text = text
    label.align = align

    return label
end

function DialogLabel:draw(x,y)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.printf(self.text, self.x+x, self.y+y, self.width, self.align or "left")
end



DialogDifficulty = {}
DialogDifficulty.__index = DialogDifficulty

function DialogDifficulty:new(x,y,width,difficulty,level,align)
    local label = setmetatable({}, DialogDifficulty)

    label.x = x
    label.y = y
    label.width = width
    label.difficulty = difficulty
    label.level = level
    label.align = align

    return label
end

function DialogDifficulty:draw(x,y)
    PrintDifficulty(self.x+x,self.y+y,self.difficulty,self.level,self.align or "left")
end



DialogBox = {}
DialogBox.__index = DialogBox

function DialogBox:new(x,y,width,height)
    local label = setmetatable({}, DialogBox)

    label.x = x
    label.y = y
    label.width = width
    label.height = height

    return label
end

function DialogBox:draw(x,y)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth((self.x+x)/8-1, (self.y+y)/16-1, self.width/8, self.height/16)
end



DialogButton = {}
DialogButton.__index = DialogButton

function DialogButton:new(x,y,width,height,label,onpress)
    local button = setmetatable({}, DialogButton)

    button.x = x
    button.y = y
    button.width = width
    button.height = height
    button.label = label
    button.onpress = onpress

    return button
end

function DialogButton:draw(x,y)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth((self.x+x)/8-1, (self.y+y)/16-1, self.width/8, self.height/16)
    love.graphics.printf(self.label, self.x+x, self.y+y, self.width, "center")
end

function DialogButton:click(x,y)
    if x >= self.x-8 and x < self.x+self.width+8 and y >= self.y-16 and y < self.y+self.height+16 then
        if type(self.onpress) == "function" then
            self:onpress()
        end
        return true
    end
    return false
end



DialogInput = {}
DialogInput.__index = DialogInput

function DialogInput:new(x,y,width,height,label,max,oninput,oncomplete)
    local input = setmetatable({}, DialogInput)

    input.x = x
    input.y = y
    input.width = width
    input.height = height
    input.label = label
    input.max = max
    input.oninput = oninput
    input.oncomplete = oncomplete

    input.content = ""
    input.selected = false

    return input
end

function DialogInput:draw(x,y)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    -- DrawBoxHalfWidth((self.x+x)/8-1, (self.y+y)/16-1, self.width/8, self.height/16)
    if #self.content <= 0 then
        love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
        love.graphics.printf(self.label, self.x+x, self.y+y, self.width, "center")
    else
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        love.graphics.printf(self.content, self.x+x, self.y+y, self.width, "center")
    end
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    if self.selected then
        local X = Font:getWidth(self.content)
        love.graphics.print("█", self.x+x+(self.width+X)/2, self.y+y)
    end
    local width = self.max*8
    love.graphics.line(self.x+x, self.y+y+16, self.x+x+self.width, self.y+y+16)
end

function DialogInput:click(x,y)
    if x >= self.x and x < self.x+self.width and y >= self.y and y < self.y+self.height then
        self.selected = true
        return true
    end
    return false
end

function DialogInput:unclick()
    self.selected = false
    if type(self.oncomplete) == "function" then
        self:oncomplete()
    end
end

function DialogInput:textinput(t)
    if self.selected then
        self.content = (self.content .. t):sub(1,self.max)
        if type(self.oninput) == "function" then
            self:oninput()
        end
    end
end

function DialogInput:keypressed(k)
    if self.selected and k == "backspace" then
        local offset = utf8.offset(self.content, -1)
        if offset then
            self.content = self.content:sub(1, offset-1)
            if type(self.oninput) == "function" then
                self:oninput()
            end
        end
    end
end



DialogFileInput = {}
DialogFileInput.__index = DialogFileInput

function DialogFileInput:new(x,y,width,height,label)
    local input = setmetatable({}, DialogFileInput)

    input.x = x
    input.y = y
    input.width = width
    input.height = height
    input.label = label
    ---@type love.DroppedFile?
    input.file = nil
    input.filename = ""
    input.open = false

    return input
end

function DialogFileInput:draw(x,y)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBoxHalfWidth((self.x+x)/8-1, (self.y+y)/16-1, self.width/8, self.height/16)
    if self.file then
        local width = math.min(self.width, Font:getWidth(self.filename))
        love.graphics.printf(self.filename:sub(-math.floor(width/8), -1), self.x+x, self.y+y, self.width, "center")
    elseif self.open then
        love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
        love.graphics.printf("DROP A FILE", self.x+x, self.y+y, self.width, "center")
    else
        love.graphics.printf(self.label, self.x+x, self.y+y, self.width, "center")
    end
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
end

function DialogFileInput:click(x,y)
    if x >= self.x-8 and x < self.x+self.width+8 and y >= self.y-16 and y < self.y+self.height+16 then
        -- TODO: open a "load file" dialog?
        self.open = not self.open
        return true
    end
    return false
end

function DialogFileInput:unclick(x,y)
    self.open = false
end

function DialogFileInput:filedropped(x,y,file)
    -- if x >= self.x-8 and x < self.x+self.width+8 and y >= self.y-16 and y < self.y+self.height+16 then
    if self.open then
        self.file = file
        self.filename = file:getFilename()
        return true
    end
    return false
end