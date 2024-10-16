Transition = {}

local dither = {
    0x0,0x8,0x2,0xA,
    0xC,0x4,0xE,0x6,
    0x3,0xB,0x1,0x9,
    0xF,0x7,0xD,0x5
}

function Transition.Draw()
    for y = 0, 29 do
        for x = 0, 39 do
            local v = ((y/30)+(x/40))/2
            local ditherOffset = dither[(y%4)*4+(x%4)+1]/15
            local draw = false
            local colorized = false
            if SceneManager.TransitioningIn() then
                -- Fade in
                if SceneManager.TransitionState.Time/SceneManager.TransitionState.Duration >= (v + ditherOffset)/2 then
                    draw = true
                end
                if math.abs(SceneManager.TransitionState.Time/SceneManager.TransitionState.Duration - v) <= 1/50 then
                    colorized = true
                end
            end
            if SceneManager.TransitioningOut() then
                -- Fade out
                if SceneManager.TransitionState.Time/SceneManager.TransitionState.Duration-1 < (v + ditherOffset)/2 then
                    draw = true
                end
                if math.abs(SceneManager.TransitionState.Time/SceneManager.TransitionState.Duration-1 - v) <= 1/50 then
                    colorized = true
                end
            end
            if draw then
                love.graphics.setColor(TerminalColors[ColorID.BLACK])
                if colorized then
                    love.graphics.setColor(TerminalColors[OverchargeColors[x%#OverchargeColors + 1]])
                end
                love.graphics.print("██", x*16, y*16)
            end
        end
    end
end