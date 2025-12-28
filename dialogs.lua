local utf8 = require "utf8"

DialogContainer = {}
DialogContainer.__index = DialogContainer

function DialogContainer:new(x,y,width,height,contents)
    local container = setmetatable({},DialogContainer)

    container.x = x
    container.y = y
    container.width = width
    container.height = height
    container.contents = contents or {}

    return container
end

function DialogContainer:draw(x,y)
    for _,itm in ipairs(self.contents) do
        if type(itm.draw) == "function" then
            itm:draw(self.x+x,self.y+y)
        end
    end
end

function DialogContainer:click(x,y)
    for _,itm in ipairs(self.contents) do
        if type(itm.click) == "function" then
            if itm:click(x-self.x,y-self.y) then
                return true
            end
        end
    end
    return false
end

function DialogContainer:unclick(x,y)
    for _,itm in ipairs(self.contents) do
        if type(itm.unclick) == "function" then
            itm:unclick(x-self.x,y-self.y)
        end
    end
end

function DialogContainer:filedropped(x,y,file)
    for _,itm in ipairs(self.contents) do
        if type(itm.filedropped) == "function" then
            if itm:filedropped(x-self.x,y-self.y,file) then
                return true
            end
        end
    end
    return false
end

function DialogContainer:textinput(t)
    for _,itm in ipairs(self.contents) do
        if type(itm.textinput) == "function" then
            itm:textinput(t)
        end
    end
end

function DialogContainer:keypressed(k)
    for _,itm in ipairs(self.contents) do
        if type(itm.keypressed) == "function" then
            itm:keypressed(k)
        end
    end
end

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



DialogToggle = {}
DialogToggle.__index = DialogToggle

function DialogToggle:new(x,y,width,height,label,onpress)
    local button = setmetatable({}, DialogToggle)

    button.x = x
    button.y = y
    button.width = width
    button.height = height
    button.label = label
    button.onpress = onpress
    button.active = true

    return button
end

function DialogToggle:draw(x,y)
    love.graphics.setColor(TerminalColors[self.active and ColorID.LIGHT_BLUE or ColorID.WHITE])
    DrawBoxHalfWidth((self.x+x)/8-1, (self.y+y)/16-1, self.width/8, self.height/16)
    love.graphics.printf(self.label .. " - " .. (self.active and "ON" or "OFF"), self.x+x, self.y+y, self.width, "center")
end

function DialogToggle:click(x,y)
    if x >= self.x-8 and x < self.x+self.width+8 and y >= self.y-16 and y < self.y+self.height+16 then
        self.active = not self.active
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
    if self.selected and type(self.oncomplete) == "function" then
        self:oncomplete()
    end
    self.selected = false
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



DialogEasing = {}
DialogEasing.__index = DialogEasing

---@param method easingmethod
function DialogEasing:new(x,y,width,height,method,duration)
    local display = setmetatable({},DialogEasing)

    display.x = x
    display.y = y
    display.width = width
    display.height = height
    display.method = method
    display.duration = duration or 1

    return display
end

function DialogEasing:draw(x,y)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.setLineWidth(2)
    love.graphics.setLineStyle("rough")
    local h = self.height - 24
    DrawBoxHalfWidth((self.x+x)/8-1, (self.y+y)/16-1, self.width/8, self.height/16)
    if not EasingMethods[self.method] then
        love.graphics.printf("- NO EASING -", self.x+x, self.y+y+(self.height-16)/2, self.width, "center")
        return
    end
    love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
    love.graphics.line(self.x+x, self.y+y, self.x+self.width+x, self.y+y)
    love.graphics.line(self.x+x, self.y+y+h, self.x+self.width+x, self.y+y+h)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local method = EasingMethods[self.method]
    for X = 0, 15 do
        local t1 = X/16
        local t2 = (X+1)/16
        local v1 = method(t1, 0, 1, 1)
        local v2 = method(t2, 0, 1, 1)
        love.graphics.line((X/16)*self.width+self.x+x, self.y+y+h*(1-v1), ((X+1)/16)*self.width+self.x+x, self.y+y+h*(1-v2))
    end
    local t = (love.timer.getTime() % self.duration) / self.duration
    local X = method(t, 0, 1, 1)
    love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
    love.graphics.line(t*self.width+self.x+x, self.y+y, t*self.width+self.x+x, self.y+y+h)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    love.graphics.circle("fill", t*self.width+self.x+x, self.y+y+h*(1-X), 4)
    love.graphics.circle("fill", X*(self.width-16)+self.x+x+8, self.y+y+h+16, 8)
end