EasingMethods = require "easing"

---@alias easingmethod "linear"|"inQuad"|"outQuad"|"inOutQuad"|"outInQuad"|"inCubic"|"outCubic"|"inOutCubic"|"outInCubic"|"inQuart"|"outQuart"|"inOutQuart"|"outInQuart"|"inQuint"|"outQuint"|"inOutQuint"|"outInQuint"|"inSine"|"outSine"|"inOutSine"|"outInSine"|"inExpo"|"outExpo"|"inOutExpo"|"outInExpo"|"inCirc"|"outCirc"|"inOutCirc"|"outInCirc"|"inElastic"|"outElastic"|"inOutElastic"|"outInElastic"|"inBack"|"outBack"|"inOutBack"|"outInBack"|"inBounce"|"outBounce"|"inOutBounce"|"outInBounce"

---@class Easer
Easer = {}
Easer.__index = Easer

---Creates an Easer.
---@return Easer
function Easer:new(value)
    local easer = setmetatable({}, Easer)

    easer.method = "linear"
    easer.base = 0
    easer.target = value or 0
    easer.duration = 0
    easer.time = 0

    return easer
end

---Starts the Easer.
---@param target number
---@param method easingmethod
---@param duration number
function Easer:start(target, method, duration)
    self.base = self:get()
    self.target = target
    self.method = method or "linear"
    self.duration = duration or 1
    self.time = 0
end

---Gets the current value of the Easer.
---@return number
function Easer:get()
    if self.time == self.duration then return self.target end
    if self.time == 0 then return self.base end
    local method = EasingMethods[self.method or "linear"] or EasingMethods.linear
    return method(self.time, self.base, self.target - self.base, self.duration)
end

---Immediately sets the value of the Easer.
---@param value number
function Easer:set(value)
    self:start(value, "linear", 0)
end

---Updates the Easer.
---@param dt number
function Easer:update(dt)
    self.time = math.max(0, math.min(self.duration, self.time + dt))
end


--- VOLTRHYTHM BACKWARDS COMPATIBILITY ---


-- magic number that controls how close is considered "zero" for smoothing
local zeroThreshold = 0.004846

---Starts the Easer using VoltRhythm's old smoothing parameter.
---@param target number
---@param smoothing number
function Easer:fromSmoothing(target, smoothing)
    if smoothing <= 0 then
        self:set(target)
    else
        self:start(target, "outExpo", math.log(math.abs(target - self:get()) / zeroThreshold, smoothing))
    end
end