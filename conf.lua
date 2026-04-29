Debug = false

for i = 1, #arg do
    if arg[i] == "--debug" then
        Debug = true
    end
end

function love.conf(t)
    t.window.resizable = true
    t.window.width = 960
    t.window.height = 720
    t.identity = "VoltRhythm"
    t.window.title = "VoltRhythm" .. (Debug and " (Debug)" or "")
    t.window.icon = "images/icon/temp4x.png"
end