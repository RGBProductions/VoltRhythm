require "love.graphics"
require "love.image"
require "love.audio"
require "love.sound"
---@diagnostic disable-next-line: redundant-parameter
require("assets", true)

local id = ...
local channeli = love.thread.getChannel("previewloader" .. id .. "i")
local channelo = love.thread.getChannel("previewloader" .. id .. "o")

local run = true
while run do
    for i = 1, channeli:getCount() do
        local m = channeli:pop()
        if m.t == "done" then
            run = false
            break
        end
        if m.t == "gen" then
            local s,r = pcall(Assets.Preview, m.p, m.s)
            channelo:push({m.p,s and r or nil})
        end
    end
end