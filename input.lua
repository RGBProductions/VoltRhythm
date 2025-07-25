Input = {
    Held = {false,false,false,false},
    Binds = {
        {{"key","a"},{"gtrigger","triggerleft"}},
        {{"key","s"},{"gbutton","leftshoulder"}},
        {{"key","k"},{"gbutton","rightshoulder"}},
        {{"key","l"},{"gtrigger","triggerright"}}
    }
}

function Input.ReadBinds()
    Input.Binds = Save.Read("keybinds.lanes") or Input.Binds
end

function Input.WriteBinds()
    Save.Write("keybinds.lanes", Input.Binds)
end

function Input.KeyPressed(k)
    for i = 1, #Input.Binds do
        local bind = Input.Binds[i]
        for j = 1, 2 do
            if bind[j][1] == "key" and bind[j][2] == k then
                Input.Held[i] = true
            end
        end
    end
end

function Input.KeyReleased(k)
    for i = 1, #Input.Binds do
        local bind = Input.Binds[i]
        for j = 1, 2 do
            if bind[j][1] == "key" and bind[j][2] == k then
                Input.Held[i] = false
            end
        end
    end
end

function Input.GamepadPressed(stick,button)
    for i = 1, #Input.Binds do
        local bind = Input.Binds[i]
        for j = 1, 2 do
            if bind[j][1] == "gbutton" and bind[j][2] == button then
                Input.Held[i] = true
            end
        end
    end
end

function Input.GamepadReleased(stick,button)
    for i = 1, #Input.Binds do
        local bind = Input.Binds[i]
        for j = 1, 2 do
            if bind[j][1] == "gbutton" and bind[j][2] == button then
                Input.Held[i] = false
            end
        end
    end
end

function Input.GamepadAxis(stick,axis,value)
    for i = 1, #Input.Binds do
        local bind = Input.Binds[i]
        for j = 1, 2 do
            if bind[j][1] == "gtrigger" and bind[j][2] == axis then
                Input.Held[i] = math.abs(value) >= 0.5
            end
        end
    end
end

function BindContains(binds, t, v)
    if not binds then return false end
    for _,b in ipairs(binds) do
        if b[1] == t and b[2] == v then
            return true
        end
    end
    return false
end