require "dialogs"

local scene = {}

local placementModes = {
    select = 0,
    normal = 1,
    swap = 2,
    merge = 3,
    mine = 4,
    warning = 5,
    bpm = 6,
    effect = 7
}

local notes = {"normal", "swap", "merge", "mine", "warning"}

local function updateDiscord()
    if SystemSettings.discord_rpc_level > RPCLevels.PLAYING then
        if SystemSettings.discord_rpc_level == RPCLevels.FULL and scene.songData then
            Discord.setActivity("Editing " .. scene.songData.name .. " by " .. scene.songData.author, scene.chart == nil and "No chart loaded" or (SongDifficulty[scene.difficulty].name .. " - " .. (scene.songData:getLevel(scene.difficulty) or "?")))
        else
            Discord.setActivity("In chart editor")
        end
        Discord.updatePresence()
    end
end

local function getDirectorySeparator()
	if love.system.getOS() == "Windows" then
		return "\\"
	else
		return "/"
	end
end

local function protectedAction(label, action)
    if EditorDirty then
        local dialog = {
            title = Localize("editor_dialog_dirty_title"),
            width = 16,
            height = 9,
            contents = {
                DialogLabel:new(0, 16, 240, Localize("editor_dialog_dirty"), "center"),
                DialogButton:new(136, 80, 64, 16, Localize("editor_action_cancel"), function ()
                    table.remove(scene.dialogs, 1)
                end),
                DialogButton:new(40, 80, 64, 16, label, function ()
                    action()
                    table.remove(scene.dialogs, 1)
                end)
            }
        }
        table.insert(scene.dialogs, 1, dialog)
    else
        action()
    end
end

local buildRecentMenu

local function hoistHistory(path,name)
    local found = false
    for i,item in ipairs(scene.history) do
        if item.path == path and item.name == name then
            table.insert(scene.history, 1, table.remove(scene.history, i))
            found = true
            break
        end
    end
    if not found then
        table.insert(scene.history, 1, {path = path, name = name})
    end
    buildRecentMenu()
end

local filesource = love.filesystem.getSource()

local function aabb(x1,y1,w1,h1, x2,y2,w2,h2)
    return
        x1 <= x2+w2 and
        x2 <= x1+w1 and
        y1 <= y2+h2 and
        y2 <= y1+h1
end

local function findOverlaps()
    scene.overlaps = {}
    if not scene.chart then return end
    for _,note in ipairs(scene.chart.notes) do
        if note.type ~= "warning" then
            local A1,B1 = math.min(note.lane, note.lane+(note.extra.dir or 0)),math.max(note.lane, note.lane+(note.extra.dir or 0))
            if note.type == "swap" then
                A1,B1 = note.lane, note.lane
            end
            local C1,D1 = note.time-0.01,note.time+(note.length or 0)+0.01

            for _,other in ipairs(scene.chart.notes) do
                if other ~= note and other.type ~= "warning" then
                    local A2,B2 = math.min(other.lane, other.lane+(other.extra.dir or 0)),math.max(other.lane, other.lane+(other.extra.dir or 0))
                    if other.type == "swap" then
                        A2,B2 = other.lane, other.lane
                    end
                    local C2,D2 = other.time-0.01,other.time+(other.length or 0)+0.01

                    if C2 >= D1 + 0.5 then
                        break
                    end

                    if aabb(A1,C1,B1-A1,D1-C1, A2,C2,B2-A2,D2-C2) then
                        scene.overlaps[note] = true
                        scene.overlaps[other] = true
                    end
                end
            end
        end
    end
end

local function writeChart(name)
    local oSongPath = scene.songData.songPath
    local oPath = scene.songData.path
    if oPath:sub(1,#filesource) == filesource then
        oPath = oPath:sub(#filesource,-1)
    end
    local splitSong = scene.songData.songPath:split("/")
    local songName = splitSong[#splitSong]
    local splitPath = scene.songData.path:split("/")
    name = name or splitPath[#splitPath]
    for _,chart in pairs(scene.songData.charts) do
        if not chart.version then
            chart.version = {}
        end
        chart.version.name = Version.name
        chart.version.version = Version.version
        chart.version.code = Version.chart_version
    end
    scene.songData:save("editor_save/" .. name)
    if oSongPath ~= "editor_save/"..name.."/"..songName then
        local contents_s,size_s = love.filesystem.read(oSongPath)
        love.filesystem.write("editor_save/"..name.."/"..songName, contents_s)
    end
    if oPath ~= "editor_save/"..name then
        local contents_c,size_c = love.filesystem.read(oPath .. "/cover.png")
        if contents_c then
            love.filesystem.write("editor_save/"..name.."/cover.png", contents_c)
        end
    end
    hoistHistory(scene.songData.path, scene.songData.name)
    EditorDirty = false
    print("Wrote chart to " .. scene.songData.path)
end

local function readChart(name)
    local songData = LoadSongData("editor_save/" .. name)
    if not songData then return false end
    scene.songData = songData
    for diff,_ in pairs(scene.songData.charts) do
        scene.difficulty = diff
        break
    end
    scene.chart = scene.songData:loadChart(scene.difficulty)
    scene.chartTimeTemp = 0
    hoistHistory(songData.path, songData.name)
    if scene.chart then scene.lastRating = scene.chart:getDifficulty() end
    findOverlaps()
    updateDiscord()
    EditorDirty = false
    return true
end

local function shutoffMusic()
    local source = Assets.Source((scene.chart or {}).song)
    if source then
        source:stop()
    end
end

local function fileDialog(type)
    local filenameInput = DialogInput:new(0, 224, 256, 16, Localize("editor_label_song_id"), 32)
    if scene.songData then
        local splitPath = scene.songData.path:split(getDirectorySeparator())
        filenameInput.content = splitPath[#splitPath]
    end
    local existing = love.filesystem.getDirectoryItems("editor_save")
    local dialog = {
        title = Localize(type == "r" and "editor_dialog_open_title" or "editor_dialog_save_title"),
        width = 32,
        height = 18,
        contents = {
            DialogButton:new(272, 224, 96, 16, Localize("editor_action_cancel"), function ()
                table.remove(scene.dialogs, 1)
            end),
            DialogButton:new(392, 224, 96, 16, Localize(type == "r" and "editor_action_open" or "editor_action_save"), function ()
                if #filenameInput.content <= 0 then return end
                if type == "w" then
                    if table.index(existing, filenameInput.content) then
                        local savedialog = {
                            title = Localize("editor_dialog_save_title"),
                            width = 16,
                            height = 9,
                            contents = {
                                DialogLabel:new(0, 16, 240, "YOU ARE OVERWRITING AN EXISTING FILE! ARE YOU SURE?", "center"),
                                DialogButton:new(136, 80, 64, 16, Localize("editor_action_cancel"), function ()
                                    table.remove(scene.dialogs, 1)
                                end),
                                DialogButton:new(40, 80, 64, 16, Localize("editor_action_save"), function ()
                                    writeChart(filenameInput.content)
                                    table.remove(scene.dialogs, 1)
                                    table.remove(scene.dialogs, 1)
                                end)
                            }
                        }
                        table.insert(scene.dialogs, 1, savedialog)
                    else
                        writeChart(filenameInput.content)
                        table.remove(scene.dialogs, 1)
                    end
                end
                if type == "r" then
                    protectedAction(Localize("editor_action_open"), function()
                        shutoffMusic()
                        if readChart(filenameInput.content) then
                            table.remove(scene.dialogs, 1)
                        end
                    end)
                end
            end),
            DialogBox:new(4,0,488,200),
            filenameInput
        }
    }
    local page = 1
    local idx
    local function reloadPage()
        while dialog.contents[idx+1] do
            table.remove(dialog.contents, idx+1)
        end
        local pos = 0
        for i = (page-1)*4+1, math.min((page-1)*4+4, #existing) do
            table.insert(dialog.contents, DialogButton:new(20,pos*48+16,408,16,existing[i],function()
                filenameInput.content = existing[i]
            end))
            pos = pos + 1
        end
    end
    table.insert(dialog.contents, DialogButton:new(452,16,24,16,"UP", function ()
        page = math.max(1, page-1)
        reloadPage()
    end))
    table.insert(dialog.contents, DialogButton:new(452,160,24,16,"DN", function ()
        page = math.min(math.floor(#existing/4)+1, page+1)
        reloadPage()
    end))
    idx = #dialog.contents
    reloadPage()
    table.insert(scene.dialogs, dialog)
end

local function easingMethodDialog(onSelected)
    local setPage
    local dialog = {
        title = Localize("editor_dialog_easing_function_title"),
        width = 32,
        height = 24,
        contents = {
            DialogButton:new(196, 320, 96, 16, Localize("editor_action_cancel"), function ()
                table.remove(scene.dialogs, 1)
            end),
            DialogButton:new(456, 16, 32, 16, "UP", function ()
                setPage(0)
            end),
            DialogButton:new(456, 256, 32, 16, "DN", function ()
                setPage(1)
            end)
        }
    }
    local container = DialogContainer:new(0,0,64,16)
    table.insert(dialog.contents, container)
    local methods = {
        "none",      "linear",     nil,            nil,
        "inQuad",    "outQuad",    "inOutQuad",    "outInQuad",
        "inCubic",   "outCubic",   "inOutCubic",   "outInCubic",
        "inQuart",   "outQuart",   "inOutQuart",   "outInQuart",
        "inQuint",   "outQuint",   "inOutQuint",   "outInQuint",
        "inSine",    "outSine",    "inOutSine",    "outInSine",
        "inExpo",    "outExpo",    "inOutExpo",    "outInExpo",
        "inCirc",    "outCirc",    "inOutCirc",    "outInCirc",
        "inElastic", "outElastic", "inOutElastic", "outInElastic",
        "inBack",    "outBack",    "inOutBack",    "outInBack",
        "inBounce",  "outBounce",  "inOutBounce",  "outInBounce"
    }
    setPage = function(n)
        container.contents = {}
        local by = n*6
        for y = by+1, math.min(by+6, #methods/4) do
            for x = 1, 4 do
                ---@type string?
                local method = methods[(y-1)*4+x]
                local result = method
                if method then
                    if method == "none" then
                        result = nil
                    end
                    table.insert(container.contents, DialogButton:new((x-1)*112, (y-1-by)*48+16, 96, 16, method:upper(), function()
                        if type(onSelected) == "function" then onSelected(result) end
                        table.remove(scene.dialogs, 1)
                    end))
                end
            end
        end
    end
    setPage(0)
    table.insert(scene.dialogs, 1, dialog)
end

function EasingDialog(effect)
    local method = effect.data.easeMethod
    local duration = effect.data.easeDuration or 1
    local display = DialogEasing:new(0, 0, 240, 64, method)
    display.duration = duration
    local methodButton
    methodButton = DialogButton:new(264, 16, 96, 16, (method or "none"):upper(), function ()
        easingMethodDialog(function(result)
            method = result
            display.method = method
            methodButton.label = (method or "none"):upper()
        end)
    end)
    local durationIn = DialogInput:new(264, 48, 96, 16, Localize("editor_label_duration"), 8, nil, function(self)
        self.content = self.content:lower()
        local multiplier = 1
        if self.content:sub(-1,-1) == "b" then
            multiplier = SixteenthsToSeconds(4, scene.chart.bpm)
            self.content = self.content:sub(1,-2)
        end
        duration = (tonumber(self.content) or 0) * multiplier
        display.duration = duration
        self.content = tostring(math.floor(duration*10000)/10000)
    end)
    durationIn.content = tostring(display.duration or 1)
    local dialog = {
        title = Localize("editor_dialog_easing_title"),
        width = 24,
        height = 10,
        contents = {
            display,
            methodButton,
            durationIn,
            DialogButton:new(168+32, 96, 64, 16, Localize("editor_action_cancel"), function ()
                table.remove(scene.dialogs, 1)
            end),
            DialogButton:new(72+32, 96, 64, 16, Localize("editor_action_apply"), function ()
                effect.data.easeMethod = method
                if effect.data.easeMethod then
                    effect.data.easeDuration = duration
                else
                    effect.data.easeDuration = nil
                end
                table.remove(scene.dialogs, 1)
            end)
        }
    }
    table.insert(scene.dialogs, 1, dialog)
end

local function effectPlacementDialog(effect, editing)
    local copy = table.merge({}, effect)
    local container = DialogContainer:new(0,96,304,304,{})
    local typeButton
    local apply = function(self) end
    local function set(effectType)
        copy.type = effectType
        typeButton.label = Localize("effect_"..effectType)
        container.contents = {}
        local t = EffectTypes[effectType] or {}
        if type(t.editor) == "function" then
            apply = t.editor(copy, container)
        end
    end

    local effectType = copy.type or "none"
    typeButton = DialogButton:new(0, 0, 304, 16, Localize("editor_label_effect_type"), function()
        local buttons = {}
        local names = {}
        for name,_ in pairs(EffectTypes) do
            table.insert(names, name)
        end
        table.sort(names,function (a, b)
            return a < b
        end)
        local optionContainer = DialogContainer:new(0,0,304,240,{})
        local scroll = 0
        local function setscroll(n) end
        local max = 0
        local dialog = {
            title = Localize("editor_dialog_effect_type_title"),
            width = 20,
            height = 20,
            contents = {
                optionContainer,
                DialogButton:new(120, 256, 64, 16, Localize("editor_action_cancel"), function ()
                    table.remove(scene.dialogs, 1)
                end),
                DialogButton:new(16, 256, 32, 16, "UP", function ()
                    setscroll(math.max(scroll-5, 0))
                end),
                DialogButton:new(264, 256, 32, 16, "DN", function ()
                    setscroll(math.min(scroll+5,math.ceil(max/5)*5-5))
                end)
            }
        }
        local pos = 0
        for _,name in pairs(names) do
            local button = DialogButton:new(16, 48*pos, 272, 16, Localize("effect_"..name), function ()
                effectType = name
                set(effectType)
                table.remove(scene.dialogs, 1)
            end)
            max = max + 1
            table.insert(buttons, button)
            pos = pos + 1
        end
        setscroll = function(n)
            scroll = n
            optionContainer.contents = {}
            for i,button in ipairs(buttons) do
                button.y = 48*(i-1-scroll)
                if button.y >= 0 and button.y < 240 then
                    table.insert(optionContainer.contents, button)
                end
            end
        end
        setscroll(scroll)
        table.insert(scene.dialogs, 1, dialog)
    end)
    local timeInput = DialogInput:new(0, 32, 304, 16, Localize("editor_label_effect_time"), 35, nil, function(self)
        copy.time = tonumber(self.content) or 0
        self.content = tostring(copy.time)
    end)
    local data = copy.data
    set(effectType)
    timeInput.content = tostring(copy.time)
    local pos = 0
    local dataElements = {}
    local dialog = {
        title = Localize(editing and "editor_dialog_effect_edit_title" or "editor_dialog_effect_title"),
        width = 20,
        height = 22,
        contents = {
            typeButton,
            timeInput,
            DialogLabel:new(0, 64, 304, Localize("editor_label_effect_data"), "center"),
            container,
            DialogButton:new(216, 288, 64, 16, Localize("editor_action_cancel"), function ()
                table.remove(scene.dialogs, 1)
            end),
            DialogButton:new(120, 288, 64, 16, Localize("editor_action_nudge"), function ()
                effect.time = effect.time + 0.001
                copy.time = copy.time + 0.001
                timeInput.content = tostring(copy.time)
            end),
            DialogButton:new(24, 288, 64, 16, Localize(editing and "editor_action_apply" or "editor_action_place"), function ()
                EditorDirty = true
                effect.type = effectType
                effect.time = copy.time
                if type(apply) == "function" then
                    apply(effect)
                end
                if not editing then
                    local final = {time = copy.time, type = effect.type, data = effect.data}
                    table.insert(scene.chart.effects, final)
                    scene.chart:sort()
                end
                table.remove(scene.dialogs, 1)
            end)
        }
    }
    table.insert(scene.dialogs, 1, dialog)
end

local function metadataDialog()
    local nameInput = DialogInput:new(0, 16, 368, 16, Localize("editor_label_song_name"), 38, nil, function(self)
        scene.songData.name = self.content
    end)
    local authorInput = DialogInput:new(0, 64, 368, 16, Localize("editor_label_song_author"), 38, nil, function(self)
        scene.songData.author = self.content
    end)
    local bpmInput = DialogInput:new(160, 96, 120, 16, Localize("editor_label_song_bpm"), 15, nil, function(self)
        scene.songData.bpm = tonumber(self.content) or 0
        self.content = tostring(scene.songData.bpm)
    end)
    local artistInput = DialogInput:new(0, 144, 368, 16, Localize("editor_label_cover_artist"), 20, nil, function(self)
        scene.songData.coverArtist = self.content
    end)

    nameInput.content = scene.songData.name
    authorInput.content = scene.songData.author
    bpmInput.content = tostring(scene.songData.bpm)
    artistInput.content = scene.songData.coverArtist

    local preview = nil
    local playPreviewButton

    local function stopPreview()
        playPreviewButton.label = Localize("editor_action_play")
        if preview then
            preview:stop()
        end
    end

    local source = Assets.Source((scene.songData or {}).songPath)
    if source then
        scene.songData.songPreview = scene.songData.songPreview or {0,math.floor(source:getDuration()*100000)/100000}
    end

    local previewStartInput = DialogInput:new(56, 208, 80, 16, Localize("editor_label_start"), 10, nil, function(self)
        stopPreview()
        self.content = tostring(tonumber(self.content) or 0)
        scene.songData.songPreview[1] = tonumber(self.content) or scene.songData.songPreview[1]
    end)
    local previewEndInput = DialogInput:new(232, 208, 80, 16, Localize("editor_label_end"), 10, nil, function(self)
        stopPreview()
        self.content = tostring(tonumber(self.content) or 0)
        scene.songData.songPreview[2] = tonumber(self.content) or scene.songData.songPreview[2]
    end)
    previewStartInput.content = tostring(scene.songData.songPreview[1] or "")
    previewEndInput.content = tostring(scene.songData.songPreview[2] or "")

    local playing = false
    playPreviewButton = DialogButton:new(152, 208, 64, 16, Localize("editor_action_play"), function (self)
        if not playing then
            self.label = Localize("editor_action_stop")
            Assets.ErasePreview(scene.songData.songPath)
            preview = Assets.Preview(scene.songData.songPath, scene.songData.songPreview)
            if preview then
                preview:setLooping(true)
                preview:play()
            end
            playing = true
        else
            stopPreview()
            playing = false
        end
    end)

    local dialog = {
        title = Localize("editor_dialog_metadata_title"),
        width = 24,
        height = 20,
        contents = {
            DialogLabel:new(148, 0, 72, Localize("editor_label_song_name")),
            nameInput,
            DialogLabel:new(140, 48, 88, Localize("editor_label_song_author")),
            authorInput,
            DialogLabel:new(88, 96, 64, Localize("editor_label_song_bpm")),
            bpmInput,
            DialogLabel:new(136, 128, 96, Localize("editor_label_cover_artist")),
            artistInput,
            DialogLabel:new(136, 176, 96, Localize("editor_label_song_preview")),
            previewStartInput,
            previewEndInput,
            playPreviewButton,
            DialogButton:new(152, 256, 64, 16, Localize("editor_action_close"), function ()
                EditorDirty = true
                stopPreview()
                table.remove(scene.dialogs, 1)
            end)
        }
    }
    table.insert(scene.dialogs, 1, dialog)
end

local function groupDialog()
    local groupnameInput = DialogInput:new(0, 16, 240, 16, Localize("editor_label_group_name"), 30)
    table.insert(scene.dialogs, 1, {
        title = Localize("editor_dialog_group_title"):format(#scene.selectedNotes),
        width = 16,
        height = 9,
        contents = {
            groupnameInput,
            DialogButton:new(136, 80, 64, 16, Localize("editor_action_cancel"), function ()
                table.remove(scene.dialogs, 1)
            end),
            DialogButton:new(40, 80, 64, 16, Localize("editor_action_group"), function ()
                EditorDirty = true
                for _,note in ipairs(scene.selectedNotes) do
                    note.extra.group = groupnameInput.content
                end
                table.remove(scene.dialogs, 1)
            end)
        }
    })
end

local function notePropertiesDialog(note)
    local copy = table.merge({}, note)
    local container = DialogContainer:new(0,64,304,304,{})
    local typeButton
    local apply = function(self)
        self.type = copy.type
        self.time = copy.time
        self.data = copy.data
    end
    
    local function set(noteType)
        copy.type = noteType
        typeButton.label = Localize("note_"..noteType)
        container.contents = {}
    end

    local noteType = copy.type or "none"
    typeButton = DialogButton:new(0, 0, 304, 16, Localize("editor_label_note_type"), function()
        local buttons = {}
        local names = {}
        for name,_ in pairs(NoteTypes) do
            table.insert(names, name)
        end
        table.sort(names,function (a, b)
            return a < b
        end)
        local optionContainer = DialogContainer:new(0,0,304,240,{})
        local scroll = 0
        local function setscroll(n) end
        local max = 0
        local dialog = {
            title = Localize("editor_dialog_note_type_title"),
            width = 20,
            height = 20,
            contents = {
                optionContainer,
                DialogButton:new(120, 256, 64, 16, Localize("editor_action_cancel"), function ()
                    table.remove(scene.dialogs, 1)
                end),
                DialogButton:new(16, 256, 32, 16, "UP", function ()
                    setscroll(math.max(scroll-5, 0))
                end),
                DialogButton:new(264, 256, 32, 16, "DN", function ()
                    setscroll(math.min(scroll+5,math.ceil(max/5)*5-5))
                end)
            }
        }
        local pos = 0
        for _,name in pairs(names) do
            local button = DialogButton:new(16, 48*pos, 272, 16, Localize("note_"..name), function ()
                noteType = name
                set(noteType)
                table.remove(scene.dialogs, 1)
            end)
            max = max + 1
            table.insert(buttons, button)
            pos = pos + 1
        end
        setscroll = function(n)
            scroll = n
            optionContainer.contents = {}
            for i,button in ipairs(buttons) do
                button.y = 48*(i-1-scroll)
                if button.y >= 0 and button.y < 240 then
                    table.insert(optionContainer.contents, button)
                end
            end
        end
        setscroll(scroll)
        table.insert(scene.dialogs, 1, dialog)
    end)
    local timeInput = DialogInput:new(0, 48, 304, 16, Localize("editor_label_note_time"), 24, nil, function(self)
        copy.time = tonumber(self.content) or copy.time
        self.content = tostring(copy.time)
    end)
    timeInput.content = tostring(copy.time)
    local data = copy.data
    set(noteType)
    local pos = 0
    local dataElements = {}
    local dialog = {
        title = Localize("editor_dialog_note_title"),
        width = 20,
        height = 20,
        contents = {
            typeButton,
            timeInput,
            container,
            DialogButton:new(216, 256, 64, 16, Localize("editor_action_cancel"), function ()
                table.remove(scene.dialogs, 1)
            end),
            DialogButton:new(24, 256, 64, 16, Localize("editor_action_apply"), function ()
                EditorDirty = true
                note.type = copy.type
                note.time = copy.time
                note.extra = copy.extra
                if type(apply) == "function" then
                    apply(note)
                end
                scene.chart:sort()
                table.remove(scene.dialogs, 1)
            end)
        }
    }
    table.insert(scene.dialogs, 1, dialog)
end

local function exitEditor()
    protectedAction(Localize("editor_action_exit"), function()
        EditorDirty = false
        shutoffMusic()
        SavedEditorTime = nil
        SavedEditorZoom = nil
        SceneManager.Transition("scenes/menu")
        SetCursor()
    end)
end

local editorMenu = {
    {
        id = "file",
        type = "menu",
        label = Localize("editor_menu_file"),
        open = false,
        contents = {
            {
                id = "file.new",
                type = "action",
                label = Localize("editor_menu_new"),
                onclick = function()
                    local nameInput = DialogInput:new(0, 0, 368, 16, Localize("editor_label_song_name"), 38)
                    local authorInput = DialogInput:new(0, 24, 368, 16, Localize("editor_label_song_author"), 38)
                    local songInput = DialogFileInput:new(0, 64, 368, 16, Localize("editor_label_song_audio"))
                    local bpmInput = DialogInput:new(196, 96, 48, 16, Localize("editor_label_song_bpm"), 15, nil, function(self)
                        self.content = tostring(tonumber(self.content) or 0)
                    end)
                    bpmInput.content = "120"
                    local coverInput = DialogFileInput:new(0, 128, 368, 16, Localize("editor_label_song_cover"))
                    local artistInput = DialogInput:new(0, 160, 368, 16, Localize("editor_label_cover_artist"), 20)
                    local dialog = {
                        width = 24,
                        height = 17,
                        title = Localize("editor_dialog_new_title"),
                        contents = {
                            nameInput,
                            authorInput,
                            songInput,
                            bpmInput,
                            coverInput,
                            artistInput,
                            DialogLabel:new(124, 96, 64, Localize("editor_label_song_bpm")),
                            DialogButton:new(200, 208, 64, 16, Localize("editor_action_cancel"), function ()
                                table.remove(scene.dialogs, 1)
                            end),
                            DialogButton:new(104, 208, 64, 16, Localize("editor_action_create"), function ()
                                if songInput.file == nil then return end
                                protectedAction(Localize("editor_action_create"), function()
                                    EditorDirty = true
                                    if love.filesystem.getInfo("editor_chart") then
                                        for _,item in ipairs(love.filesystem.getDirectoryItems("editor_chart")) do
                                            love.filesystem.remove("editor_chart/"..item)
                                        end
                                    end
                                    
                                    local splitName = songInput.filename:split(getDirectorySeparator())
                                    love.filesystem.createDirectory("editor_chart")
                                    if coverInput.file ~= nil then
                                        love.filesystem.write("editor_chart/cover.png", coverInput.file:read())
                                    end
                                    love.filesystem.write("editor_chart/" .. splitName[#splitName], songInput.file:read())
                                    love.filesystem.write("editor_chart/info.json", json.encode({
                                        name = nameInput.content,
                                        author = authorInput.content,
                                        coverArtist = artistInput.content,
                                        song = splitName[#splitName],
                                        bpm = tonumber(bpmInput.content),
                                        charts = {}
                                    }))
                                    local songData = LoadSongData("editor_chart")
                                    scene.songData = songData
                                    scene.difficulty = "hard"
                                    scene.chart = scene.songData:loadChart(scene.difficulty)
                                    Assets.EraseCover("editor_chart")
                                    table.remove(scene.dialogs, 1)
                                end)
                            end)
                        }
                    }
                    table.insert(scene.dialogs, dialog)
                    return true
                end
            },
            {
                id = "file.open",
                type = "action",
                label = Localize("editor_menu_open"),
                onclick = function()
                    fileDialog("r")
                    return true
                end
            },
            {
                id = "file.recent",
                type = "menu",
                label = Localize("editor_menu_open_recent"),
                open = false,
                contents = {}
            },
            {
                id = "file.fromdisk",
                type = "menu",
                label = Localize("editor_menu_open_from_disk"),
                open = false,
                contents = {}
            },
            {
                id = "file.save",
                type = "action",
                label = Localize("editor_menu_save"),
                onclick = function()
                    if not scene.songData then return true end
                    local splitPath = scene.songData.path:split(getDirectorySeparator())
                    if splitPath[#splitPath] == "editor_chart" then
                        fileDialog("w")
                    else
                        writeChart()
                    end
                    return true
                end
            },
            {
                id = "file.saveas",
                type = "action",
                label = Localize("editor_menu_save_as"),
                onclick = function()
                    fileDialog("w")
                    return true
                end
            },
            {
                id = "file.opensavefolder",
                type = "action",
                label = Localize("editor_menu_open_save_folder"),
                onclick = function()
                    love.system.openURL("file://"..love.filesystem.getSaveDirectory() .. getDirectorySeparator() .. "editor_save")
                    return true
                end
            },
            {
                id = "file.exit",
                type = "action",
                label = Localize("editor_menu_exit"),
                onclick = function()
                    exitEditor()
                    return true
                end
            },
        }
    },
    {
        id = "edit",
        type = "menu",
        label = Localize("editor_menu_edit"),
        open = false,
        contents = {
            {
                id = "edit.metadata",
                type = "action",
                label = Localize("editor_menu_metadata"),
                onclick = function()
                    if not scene.songData then return true end
                    metadataDialog()
                    return true
                end
            },
            {
                id = "edit.difficulties",
                type = "action",
                label = Localize("editor_menu_difficulties"),
                onclick = function()
                    if not scene.songData then return true end
                    local difficulties = {
                        "easy", "medium", "hard", "extreme", "overvolt"
                    }
                    local difficultyBaseLevels = {
                        easy = 1, medium = 6, hard = 11, extreme = 16, overvolt = 21
                    }
                    local dialog = {
                        width = 20,
                        height = 19,
                        title = Localize("editor_dialog_difficulties_title"),
                        contents = {
                            DialogButton:new(88, 240, 128, 16, "CLOSE", function ()
                                table.remove(scene.dialogs, 1)
                            end)
                        }
                    }
                    for i,difficulty in ipairs(difficulties) do
                        local hasDifficulty = scene.songData:hasLevel(difficulty)
                        local level = hasDifficulty and scene.songData:getLevel(difficulty) or ""
                        local difficultyLabel = DialogDifficulty:new(16,48*(i-1),128,difficulty,nil,"left")

                        local levelInput = DialogInput:new(96,48*(i-1),32,16,Localize("editor_label_level"),4,nil,function(self)
                            EditorDirty = true
                            scene.songData.levels[difficulty] = tonumber(self.content) or self.content
                            scene.songData.charts[difficulty].level = tonumber(self.content) or self.content
                    
                            updateDiscord()
                        end)
                        levelInput.content = tostring(level)

                        local charterInput = DialogInput:new(216,48*(i-1),80,16,Localize("editor_label_chart_designer"),10,nil,function(self)
                            (scene.songData.charts[difficulty] or {}).charter = self.content
                        end)
                        charterInput.content = (scene.songData.charts[difficulty] or {}).charter or ""

                        local addButton
                        local removeButton
                        local editButton = DialogButton:new(152,48*(i-1),16,16,"E",function()
                            scene.difficulty = difficulty
                            scene.chart = scene.songData:loadChart(difficulty)
                            if scene.chart then scene.lastRating = scene.chart:getDifficulty() end
                    
                            updateDiscord()

                            table.remove(scene.dialogs, 1)
                        end)
                        removeButton = DialogButton:new(184,48*(i-1),16,16,"-",function()
                            local removedialog = {
                                title = Localize("editor_dialog_remove_title"):format(Localize("difficulty_"..difficulty)),
                                width = 16,
                                height = 9,
                                contents = {
                                    DialogLabel:new(0, 16, 240, Localize("editor_dialog_irreversible"), "center"),
                                    DialogButton:new(136, 80, 64, 16, Localize("editor_action_cancel"), function ()
                                        table.remove(scene.dialogs, 1)
                                    end),
                                    DialogButton:new(40, 80, 64, 16, Localize("editor_action_remove"), function ()
                                        EditorDirty = true
                                        scene.songData:removeChart(difficulty)
                                        if scene.difficulty == difficulty then
                                            scene.difficulty = nil
                                            scene.chart = nil
                    
                                            updateDiscord()
                                        end
                                        table.remove(dialog.contents, table.index(dialog.contents, removeButton))
                                        table.remove(dialog.contents, table.index(dialog.contents, editButton))
                                        table.remove(dialog.contents, table.index(dialog.contents, levelInput))
                                        table.remove(dialog.contents, table.index(dialog.contents, charterInput))
                                        table.insert(dialog.contents, addButton)

                                        table.remove(scene.dialogs, 1)
                                    end)
                                }
                            }
                            table.insert(scene.dialogs, 1, removedialog)
                        end)
                        addButton = DialogButton:new(184,48*(i-1),16,16,"+",function()
                            EditorDirty = true
                            local chart = scene.songData:newChart(difficulty, difficultyBaseLevels[difficulty])
                            levelInput.content = tostring(scene.songData:getLevel(difficulty))
                            table.remove(dialog.contents, table.index(dialog.contents, addButton))
                            table.insert(dialog.contents, levelInput)
                            table.insert(dialog.contents, charterInput)
                            table.insert(dialog.contents, editButton)
                            table.insert(dialog.contents, removeButton)
                        end)

                        table.insert(dialog.contents, DialogBox:new(8,48*(i-1),128,16))
                        table.insert(dialog.contents, difficultyLabel)
                        if hasDifficulty then
                            table.insert(dialog.contents, levelInput)
                            table.insert(dialog.contents, charterInput)
                            table.insert(dialog.contents, editButton)
                            table.insert(dialog.contents, removeButton)
                        else
                            table.insert(dialog.contents, addButton)
                        end
                    end
                    table.insert(scene.dialogs, dialog)
                    return true
                end
            },
            {
                id = "edit.copy_effects",
                type = "action",
                label = Localize("editor_menu_copy_effects"),
                onclick = function()
                    if not scene.songData then return true end
                    local difficulties = {
                        "easy", "medium", "hard", "extreme", "overvolt"
                    }
                    local dialog = {
                        width = 15,
                        height = 6,
                        title = Localize("editor_dialog_copy_effects_title"),
                        contents = {}
                    }
                    local y = 16
                    for i,difficulty in ipairs(difficulties) do
                        local numEffects = #((scene.songData:loadChart(difficulty) or {}).effects or {})
                        local hasDifficulty = scene.songData:hasLevel(difficulty) and numEffects > 0 and difficulty ~= scene.difficulty
                        if hasDifficulty then
                            local difficultyLabel = DialogDifficulty:new(32,y,128,difficulty,nil,"left")
                            local numLabel = DialogLabel:new(32, y, 160, numEffects .. " EFFECT" .. (numEffects ~= 1 and "S" or ""), "right")
                            table.insert(dialog.contents, DialogButton:new(16,y,192,16,"",function()
                                local savedialog = {
                                    title = Localize("editor_dialog_copy_effects_confirm_title"):format(Localize("difficulty_"..difficulty)),
                                    width = 16,
                                    height = 10,
                                    contents = {
                                        DialogLabel:new(0, 16, 240, Localize("editor_dialog_copy_effects"), "center"),
                                        DialogButton:new(136, 96, 64, 16, Localize("editor_action_cancel"), function ()
                                            table.remove(scene.dialogs, 1)
                                        end),
                                        DialogButton:new(40, 96, 64, 16, Localize("editor_action_copy"), function ()
                                            EditorDirty = true
                                            scene.chart.effects = table.merge({}, scene.songData:loadChart(difficulty).effects)
                                            table.remove(scene.dialogs, 1)
                                            table.remove(scene.dialogs, 1)
                                        end)
                                    }
                                }
                                table.insert(scene.dialogs, 1, savedialog)
                            end))
                            table.insert(dialog.contents, difficultyLabel)
                            table.insert(dialog.contents, numLabel)
                            y = y + 48
                            dialog.height = dialog.height + 3
                        end
                    end
                    table.insert(dialog.contents, DialogButton:new(48, y+16, 128, 16, Localize("editor_action_cancel"), function ()
                        table.remove(scene.dialogs, 1)
                    end))
                    table.insert(scene.dialogs, dialog)
                    return true
                end
            },
            {
                id = "edit.copy_chart",
                type = "action",
                label = Localize("editor_menu_copy_chart"),
                onclick = function()
                    if not scene.songData then return true end
                    local difficulties = {
                        "easy", "medium", "hard", "extreme", "overvolt"
                    }
                    local dialog = {
                        width = 15,
                        height = 6,
                        title = Localize("editor_dialog_copy_chart_title"),
                        contents = {}
                    }
                    local y = 16
                    for i,difficulty in ipairs(difficulties) do
                        local chart = scene.songData:loadChart(difficulty) or {}
                        local numEffects = #(chart.effects or {})
                        local numNotes = #(chart.notes or {})
                        local hasDifficulty = scene.songData:hasLevel(difficulty) and (numNotes > 0 or numEffects > 0) and difficulty ~= scene.difficulty
                        if hasDifficulty then
                            local difficultyLabel = DialogDifficulty:new(32,y,128,difficulty,nil,"left")
                            local numLabel = DialogLabel:new(32, y, 160, numNotes .. " NOTE" .. (numNotes ~= 1 and "S" or ""), "right")
                            table.insert(dialog.contents, DialogButton:new(16,y,192,16,"",function()
                                local savedialog = {
                                    title = Localize("editor_dialog_copy_chart_confirm_title"):format(Localize("difficulty_"..difficulty)),
                                    width = 16,
                                    height = 10,
                                    contents = {
                                        DialogLabel:new(0, 16, 240, Localize("editor_dialog_copy_chart"), "center"),
                                        DialogButton:new(136, 96, 64, 16, Localize("editor_action_cancel"), function ()
                                            table.remove(scene.dialogs, 1)
                                        end),
                                        DialogButton:new(40, 96, 64, 16, Localize("editor_action_copy"), function ()
                                            EditorDirty = true
                                            local other = scene.songData:loadChart(difficulty)
                                            if other then
                                                scene.chart.notes = table.merge({}, other.notes)
                                                scene.chart.effects = table.merge({}, other.effects)
                                                scene.chart.bpmChanges = table.merge({}, other.bpmChanges)
                                                scene.chart.background = other.background
                                                scene.chart.backgroundInit = table.merge({}, other.backgroundInit)
                                                scene.chart.level = other.level
                                                scene.chart.charter = other.charter
                                                scene.chart.bpm = other.bpm
                                                scene.chart.lanes = other.lanes
                                                scene.songData.levels[scene.difficulty] = scene.songData.levels[difficulty]
                                                scene.chart:recalculateCharge()
                                                scene.lastRating = scene.chart:getDifficulty()
                                            end
                                            table.remove(scene.dialogs, 1)
                                            table.remove(scene.dialogs, 1)
                                        end)
                                    }
                                }
                                table.insert(scene.dialogs, 1, savedialog)
                            end))
                            table.insert(dialog.contents, difficultyLabel)
                            table.insert(dialog.contents, numLabel)
                            y = y + 48
                            dialog.height = dialog.height + 3
                        end
                    end
                    table.insert(dialog.contents, DialogButton:new(48, y+16, 128, 16, Localize("editor_action_cancel"), function ()
                        table.remove(scene.dialogs, 1)
                    end))
                    table.insert(scene.dialogs, dialog)
                    return true
                end
            },
            {
                id = "edit.delete_effects",
                type = "action",
                label = Localize("editor_menu_clear_effects"),
                onclick = function()
                    local dialog = {
                        title = Localize("editor_dialog_clear_effects_title"),
                        width = 16,
                        height = 9,
                        contents = {
                            DialogLabel:new(0, 16, 240, Localize("editor_dialog_irreversible"), "center"),
                            DialogButton:new(136, 80, 64, 16, Localize("editor_action_cancel"), function ()
                                table.remove(scene.dialogs, 1)
                            end),
                            DialogButton:new(40, 80, 64, 16, Localize("editor_action_clear"), function ()
                                EditorDirty = true
                                scene.chart.effects = {}
                                table.remove(scene.dialogs, 1)
                            end)
                        }
                    }
                    table.insert(scene.dialogs, 1, dialog)
                    return true
                end
            },
            {
                id = "edit.clear_chart",
                type = "action",
                label = Localize("editor_menu_clear_chart"),
                onclick = function()
                    local dialog = {
                        title = Localize("editor_dialog_clear_chart_title"),
                        width = 16,
                        height = 9,
                        contents = {
                            DialogLabel:new(0, 16, 240, Localize("editor_dialog_clear_chart"), "center"),
                            DialogButton:new(136, 80, 64, 16, Localize("editor_action_cancel"), function ()
                                table.remove(scene.dialogs, 1)
                            end),
                            DialogButton:new(40, 80, 64, 16, Localize("editor_action_clear"), function ()
                                EditorDirty = true
                                scene.chart.effects = {}
                                scene.chart.notes = {}
                                scene.chart.bpmChanges = {}

                                table.remove(scene.dialogs, 1)
                            end)
                        }
                    }
                    table.insert(scene.dialogs, 1, dialog)
                    return true
                end
            }
        }
    },
    {
        id = "note",
        type = "menu",
        label = Localize("editor_menu_note"),
        open = false,
        contents = {
            {
                id = "note.select",
                type = "action",
                label = Localize("editor_menu_select"),
                onclick = function()
                    SetCursor("🮰", 0, 0)
                    scene.placementMode = placementModes.select
                    return true
                end
            },
            {
                id = "note.normal",
                type = "action",
                label = Localize("note_normal"),
                onclick = function()
                    SetCursor("○", 4, 8)
                    scene.placementMode = placementModes.normal
                    return true
                end
            },
            {
                id = "note.swap",
                type = "action",
                label = Localize("note_swap"),
                onclick = function()
                    SetCursor("◇", 4, 8)
                    scene.placementMode = placementModes.swap
                    return true
                end
            },
            {
                id = "note.merge",
                type = "action",
                label = Localize("note_merge"),
                onclick = function()
                    SetCursor("▥", 4, 8)
                    scene.placementMode = placementModes.merge
                    return true
                end
            },
            {
                id = "note.mine",
                type = "action",
                label = Localize("note_mine"),
                onclick = function()
                    SetCursor("☓", 4, 8)
                    scene.placementMode = placementModes.mine
                    return true
                end
            },
            {
                id = "note.warning",
                type = "action",
                label = Localize("note_warning"),
                onclick = function()
                    SetCursor("⚠", 4, 8)
                    scene.placementMode = placementModes.warning
                    return true
                end
            },
            {
                id = "note.bpm",
                type = "action",
                label = Localize("editor_menu_bpm_change"),
                onclick = function()
                    SetCursor("▷", 4, 8)
                    scene.placementMode = placementModes.bpm
                    return true
                end
            },
            {
                id = "note.bpm",
                type = "action",
                label = Localize("editor_menu_effect"),
                onclick = function()
                    SetCursor("¤", 4, 8)
                    scene.placementMode = placementModes.effect
                    return true
                end
            }
        }
    },
    {
        id = "play",
        type = "menu",
        label = Localize("editor_menu_play"),
        open = false,
        contents = {
            {
                id = "play.playtest",
                type = "action",
                label = Localize("editor_menu_playtest"),
                onclick = function()
                    if not scene.chart then return true end
                    shutoffMusic()
                    scene.chart:sort()
                    scene.chart:recalculateCharge()
                    SavedEditorTime = scene.chartTimeTemp
                    SavedEditorZoom = scene.zoom
                    Autoplay = false
                    Showcase = false
                    SceneManager.Transition("scenes/game", {songData = scene.songData, difficulty = scene.difficulty, isEditor = true})
                    SetCursor()
                    return true
                end
            },
            {
                id = "play.auto",
                type = "action",
                label = Localize("editor_menu_showcase"),
                onclick = function()
                    if not scene.chart then return true end
                    shutoffMusic()
                    scene.chart:sort()
                    scene.chart:recalculateCharge()
                    SavedEditorTime = scene.chartTimeTemp
                    SavedEditorZoom = scene.zoom
                    Autoplay = true
                    Showcase = true
                    SceneManager.Transition("scenes/game", {songData = scene.songData, difficulty = scene.difficulty, isEditor = true})
                    SetCursor()
                    return true
                end
            }
        }
    },
    {
        label = "                          ",
        type = "action",
        onclick = function() end
    },
    {
        id = "hotreload",
        label = Localize("editor_menu_hot_reload"),
        type = "action",
        onclick = function()
            SceneManager.Transition("scenes/neditor", {songData = scene.songData, difficulty = scene.difficulty})
        end
    }
}

local function closeMenu(tab)
    if tab.type ~= "menu" then return end
    for _,itm in ipairs(tab.contents) do
        if itm.type == "menu" then
            closeMenu(itm)
        end
    end
    tab.open = false
end

local function getMenuItemById(id)
    local function scan(cur)
        for _,itm in ipairs(cur) do
            if itm.id == id then
                return itm
            end
            if itm.type == "menu" then
                local result = scan(itm.contents)
                if result then
                    return result
                end
            end
        end
    end

    return scan(editorMenu)
end

buildRecentMenu = function()
    local i,n = 1,#scene.history
    while i <= n do
        if not love.filesystem.getInfo(scene.history[i].path) then
            table.remove(scene.history, i)
            i = i - 1
        end
        i = i + 1
        n = #scene.history
    end
    love.filesystem.write("editor_history.json", json.encode(scene.history))

    local menu = getMenuItemById("file.recent")
    if not menu then return end
    menu.contents = {}
    for _,itm in ipairs(scene.history) do
        local splitPath = itm.path:split("/")
        local id = splitPath[#splitPath]
        table.insert(menu.contents, {
            id = "file.recent." .. id,
            label = itm.name,
            type = "action",
            onclick = function()
                protectedAction(Localize("editor_action_open"), function()
                    shutoffMusic()
                    readChart(id)
                end)
                return true
            end
        })
        if #menu.contents >= 6 then
            break
        end
    end
end

local function buildExistingMenu()
    local menu = getMenuItemById("file.fromdisk")
    if not menu then return end
    menu.contents = {}
    for _,itm in ipairs(SongDisk.Disks) do
        table.insert(menu.contents, {
            id = "file.fromdisk." .. itm.name,
            label = itm.name,
            type = "action",
            onclick = function()
                shutoffMusic()
                SceneManager.Transition("scenes/songselect", {campaign = itm.name, source = "neditor", destination = "neditor"})
                return true
            end
        })
    end
end

local scrollbarX = 472

function scene.load(args)
    scene.audioOffset = Save.Read("audio_offset") or 0
    scene.songData = args.songData
    scene.difficulty = args.difficulty

    if scene.songData then
        scene.chart = scene.songData:loadChart(scene.difficulty)
    end

    local source = Assets.Source((scene.songData or {}).songPath)
    if source then
        source:setPitch(1)
    end

    scene.lastRating = 1
    if scene.chart then
        scene.lastRating = scene.chart:getDifficulty()
    end

    scene.chartTimeTemp = SavedEditorTime or 0
    scene.zoom = SavedEditorZoom or 1
    scene.lastNoteTime = 0
    scene.lastNoteLane = 0

    scene.placementMode = placementModes.select
    scene.placement = {
        placing = false,
        type = "normal",
        note = nil,
        start = {0,0},
        stop = {0,0}
    }
    scene.selection = {
        selecting = false,
        dragging = false,
        start = {0,0},
        stop = {0,0}
    }

    scene.selectedNotes = {}
    scene.clipboard = {}

    scene.dialogs = {}

    scene.scrollbarGrab = false
    scene.playingWhenGrabbed = false

    if love.filesystem.getInfo("editor_history.json") then
        scene.history = json.decode(love.filesystem.read("editor_history.json"))
    else
        scene.history = {}
    end
    buildRecentMenu()
    buildExistingMenu()

    if scene.songData then
        hoistHistory(scene.songData.path, scene.songData.name)
    end

    SetCursor("🮰", 0, 0)

    love.keyboard.setKeyRepeat(true)

    if HasGamepad then
        table.insert(scene.dialogs, 1, {
            title = Localize("editor_dialog_gamepad_title"),
            width = 16,
            height = 14,
            contents = {
                DialogLabel:new(0, 0, 240, Localize("editor_dialog_gamepad"):format(KeyLabel(Save.Keybind("back")[2])), "center"),
                DialogButton:new(88, 160, 64, 16, "OK", function ()
                    table.remove(scene.dialogs, 1)
                end)
            }
        })
    end

    updateDiscord()
    findOverlaps()
end

function scene.update(dt)
    do
        local i = 1
        local num = #Particles
        while i <= num do
            local particle = Particles[i]
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.life = particle.life - dt
            if particle.life <= 0 then
                table.remove(Particles, i)
                i = i - 1
            end
            i = i + 1
            num = #Particles
        end
    end
    
    if love.keyboard.isDown("up") then
        scene.chartTimeTemp = scene.chartTimeTemp + dt*(love.keyboard.isDown("lshift") and 4 or 1)*(love.keyboard.isDown("lctrl") and 8 or 1)
    end
    if love.keyboard.isDown("down") then
        scene.chartTimeTemp = scene.chartTimeTemp - dt*(love.keyboard.isDown("lshift") and 4 or 1)*(love.keyboard.isDown("lctrl") and 8 or 1)
    end

    local source = Assets.Source((scene.chart or {}).song)
    if source then
        source:setVolume(SystemSettings.song_volume)
        scene.chartTimeTemp = math.max(-scene.audioOffset,math.min(source:getDuration("seconds"), scene.chartTimeTemp))
    end
    
    if source then
        if source:isPlaying() then
            scene.chartTimeTemp = scene.chartTimeTemp + dt
            
            local st = source:tell("seconds")-scene.audioOffset
            local drift = st-scene.chart.time
            -- Only fix drift if we're NOT at the end of song AND we are too much offset
            if math.abs(drift) >= 0.05 and drift > -source:getDuration("seconds") then
                scene.chartTimeTemp = source:tell("seconds")-scene.audioOffset
            end
        end
    end
    
    if scene.placement.placing then
        scene.placement.stop = {scene.lastNoteLane, scene.lastNoteTime}

        local noteType = scene.placement.type
        local note = scene.placement.note
        if note then
            if noteType == "swap" then
                local lane = note.lane - (note.extra.dir or 0)
                local dir = scene.placement.stop[1]-scene.placement.start[1]
                local endLane = math.max(0,math.min(3,lane + dir))
                note.extra.dir = math.max(-3,math.min(3,endLane - lane))
                note.lane = scene.placement.start[1]+note.extra.dir
            end
            if noteType == "merge" then
                local dir = scene.placement.stop[1]-scene.placement.start[1]
                local endLane = math.max(0,math.min(3,note.lane + dir))
                note.extra.dir = endLane - note.lane
            end
            if noteType ~= "merge" and noteType ~= "mine" then
                local a,b = math.min(scene.placement.start[2],scene.placement.stop[2]),math.max(scene.placement.start[2],scene.placement.stop[2])
                note.length = math.max(0,b-a)
                note.time = a
                if noteType == "warning" then
                    note.length = math.max(0,-(a-b))
                    note.time = b
                end
            end
        end

        scene.lastRating = scene.chart:getDifficulty()
    end
    if scene.selection.dragging then
        local dragX,dragY = scene.lastNoteLane-scene.selection.start[1], scene.lastNoteTime-scene.selection.start[2]
        local songTime = math.huge
        if source then
            songTime = source:getDuration("seconds")
        end
        for _,note in ipairs(scene.selectedNotes) do
            dragX = math.max(0,math.min(scene.chart.lanes-1, note.lane + dragX))-note.lane
            dragY = math.max(0,math.min(songTime, note.time + dragY))-note.time
        end
        for _,note in ipairs(scene.selectedNotes) do
            note.lane = note.lane + dragX
            note.time = note.time + dragY
        end
        scene.selection.start = {scene.lastNoteLane, scene.lastNoteTime}
    end
    if scene.selection.selecting or scene.selection.dragging then
        scene.selection.stop = {scene.lastNoteLane, scene.lastNoteTime}
    end
    if scene.scrollbarGrab then
        if source then
            local dur = source:getDuration("seconds")
            local y = math.max(0,math.min(1, (MouseY - 120) / 240))
            scene.chartTimeTemp = (1-y)*dur
            source:pause()
        end
    end
end

function scene.textinput(t)
    if #scene.dialogs > 0 then
        local dialog = scene.dialogs[1]
        for _,element in ipairs(dialog.contents) do
            if type(element.textinput) == "function" then
                element:textinput(t)
            end
        end
        return
    end
end

function scene.filedropped(file)
    if #scene.dialogs > 0 then
        local dialog = scene.dialogs[1]
        local dx = (80-dialog.width*2)/2+1
        local dy = (30-dialog.height)/2+2
        for _,element in ipairs(dialog.contents) do
            if type(element.filedropped) == "function" then
                element:filedropped(MouseX-dx*8,MouseY-dy*16,file)
            end
        end
        return
    end
end

local function fullCopy(a,b)
    if not love.filesystem.getInfo(b) then
        love.filesystem.createDirectory(b)
    end
    for _,itm in ipairs(love.filesystem.getDirectoryItems(a)) do
        local p1 = a.."/"..itm
        local p2 = b.."/"..itm
        if love.filesystem.getInfo(p1).type == "directory" then
            fullCopy(p1,p2)
        else
            love.filesystem.write(p2, love.filesystem.read(p1))
        end
    end
end

function scene.directorydropped(path)
    protectedAction(Localize("editor_action_import"), function()
        love.filesystem.mount(path, "temp_import")
        local splitPath = path:split("/")
        local name = splitPath[#splitPath]
        love.filesystem.createDirectory("editor_save/"..name)
        fullCopy("temp_import", "editor_save/"..name)
        love.filesystem.unmount(path)
        shutoffMusic()
        readChart(name)
    end)
end

function scene.wheelmoved(x,y)
    if love.keyboard.isDown("lctrl") then
        scene.zoom = math.max(1,math.min(16,scene.zoom + y))
    else
        scene.chartTimeTemp = scene.chartTimeTemp + y/10/scene.zoom
    end
end

function scene.action(a)
    if a == "back" and HasGamepad then
        exitEditor()
    end
end

---@param k love.KeyConstant
function scene.keypressed(k)
    if #scene.dialogs > 0 then
        local dialog = scene.dialogs[1]
        for _,element in ipairs(dialog.contents) do
            if type(element.keypressed) == "function" then
                element:keypressed(k)
            end
        end
        return
    end
    
    if k == "+" or k == "=" or k == "kp+" then
        scene.zoom = math.min(16, scene.zoom + 1)
    end
    if k == "-" or k == "_" or k == "kp-" then
        scene.zoom = math.max(1,scene.zoom - 1)
    end

    if k == "space" then
        if (scene.chart or {}).song then
            local source = Assets.Source(scene.chart.song)
            if source then
                if scene.chartTimeTemp < source:getDuration("seconds") then
                    if scene.scrollbarGrab then
                        scene.playingWhenGrabbed = not scene.playingWhenGrabbed
                    else
                        if source:isPlaying() then
                            source:pause()
                        else
                            source:play()
                            source:seek(math.max(-scene.audioOffset,scene.chartTimeTemp+scene.audioOffset), "seconds")
                        end
                    end
                end
            end
        end
    end
    if k == "c" and love.keyboard.isDown("lctrl") then
        -- Copy
        scene.clipboard = scene.selectedNotes
    end
    if k == "x" and love.keyboard.isDown("lctrl") then
        -- Cut
        EditorDirty = true
        scene.clipboard = scene.selectedNotes
        for _,note in ipairs(scene.selectedNotes) do
            table.remove(scene.chart.notes, table.index(scene.chart.notes, note))
        end
        scene.selectedNotes = {}
        scene.lastRating = scene.chart:getDifficulty()
        findOverlaps()
    end
    if k == "v" and love.keyboard.isDown("lctrl") then
        -- Paste
        EditorDirty = true
        scene.selectedNotes = {}
        local baseX,baseY = math.huge,math.huge
        for _,note in ipairs(scene.clipboard) do
            baseX,baseY = math.min(baseX,note.lane),math.min(baseY,note.time)
        end
        for _,note in ipairs(scene.clipboard) do
            local newNote = table.merge({}, note)
            if love.keyboard.isDown("lshift") then
                newNote.lane = note.lane - baseX + scene.lastNoteLane
                newNote.time = note.time - baseY + scene.lastNoteTime
            end
            table.insert(scene.chart.notes, newNote)
            table.insert(scene.selectedNotes, newNote)
        end
        scene.lastRating = scene.chart:getDifficulty()
        findOverlaps()
    end
    if k == "delete" then
        EditorDirty = true
        for _,note in ipairs(scene.selectedNotes) do
            table.remove(scene.chart.notes, table.index(scene.chart.notes, note))
        end
        scene.selectedNotes = {}
        scene.lastRating = scene.chart:getDifficulty()
        findOverlaps()
    end
    if k == "a" and love.keyboard.isDown("lctrl") then
        scene.selectedNotes = {}
        for _,note in ipairs(scene.chart.notes) do
            table.insert(scene.selectedNotes, note)
        end
    end
    if k == "g" and love.keyboard.isDown("lctrl") then
        groupDialog()
    end
end

local function clickTab(tab,x,y,cx,cy)
    local width = 0
    for _,item in ipairs(tab.contents) do
        width = math.max(utf8.len(item.label .. (item.type == "menu" and " ▷" or "")), width)
    end
    width = width + 2
    for i,elem in ipairs(tab.contents) do
        local X,Y,W,H = x, y+32*(i-1), 8*utf8.len(elem.label), 32
        if elem.open then
            local clicked = clickTab(elem, X + 8*(width+2), Y, cx, cy)
            if clicked then
                return clicked
            end
        end
        if cx >= X and cx < X+16 + 8*width and cy >= Y+8 and cy < Y+8 + H then
            return elem
        end
    end
    tab.open = nil
    return nil
end

local function drawTab(tab,x,y)
    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    local width = 0
    for _,item in ipairs(tab.contents) do
        width = math.max(utf8.len(item.label .. (item.type == "menu" and " ▷" or "")), width)
    end
    DrawBoxHalfWidth(x/8, y/16, width+2, math.max(0,(#tab.contents)*2-1))
    for i,elem in ipairs(tab.contents) do
        local X,Y,W,H = x, y+32*(i-1), 8*utf8.len(elem.label), 16
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if elem.open then
            drawTab(elem, X + 8*(width+4), Y)
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        DrawText(elem.label, X+16, Y+16)
        if elem.type == "menu" then
            DrawText("▷", X+8+width*8, Y+16)
        end
        if i ~= #tab.contents then
            love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
            DrawText(("┈"):rep(width+2), X+8, Y+32)
        end
    end
end

function scene.draw()
    if scene.chart then
        DrawBoxHalfWidth((80-(scene.chart.lanes*4-1))/2 - 1, 6, scene.chart.lanes*4-1, 16)
        
        for i = 1, 4-1 do
            love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
            local x = (80-(scene.chart.lanes*4-1))/2 - 1+(i-1)*4 + 1
            DrawText(("   ┊\n"):rep(16), x*8, 7*16)
        end

        local bpmChanges = scene.chart.bpmChanges

        local currentTime = 0
        local currentBPM = scene.chart.bpm
        local numSteps = 0
        local nextBPMChange = 1
        local lastBPMTime = 0

        local closestY = math.huge
        scene.lastNoteTime = math.huge
        scene.lastNoteLane = math.floor( ( MouseX - ((80-(scene.chart.lanes*4-1))/2 - 1)*8 - 4 ) / (8*4) )

        local zoom = scene.zoom
        local chartPos = 7
        local chartHeight = 16
        local speed = 25*zoom

        while currentTime <= scene.chartTimeTemp+1/zoom do
            do
                local pos = currentTime - scene.chartTimeTemp

                local drawPos = GetNoteCellY(pos, speed, 1, 0, chartPos, chartHeight)-1
                if drawPos >= chartPos and drawPos < chartPos+chartHeight then
                    love.graphics.setColor(TerminalColors[numSteps%(4*zoom) == 0 and ColorID.LIGHT_GRAY or ColorID.DARK_GRAY])
                    DrawText("┈┈┈╬┈┈┈╬┈┈┈╬┈┈┈", (80-(scene.chart.lanes*4-1))/2 * 8, drawPos*16-8)
                end
                local mouseDist = math.abs((drawPos*16-8) - (MouseY-8))
                if mouseDist < closestY then
                    closestY = mouseDist
                    scene.lastNoteTime = currentTime
                end
            end

            local step = SixteenthsToSeconds(1/zoom,currentBPM)
            local bpmChange = (bpmChanges[nextBPMChange] or {time = math.huge, bpm = currentBPM})
            if currentTime+step - bpmChange.time >= -0.001 then
                local pos = SecondsToSixteenths(bpmChange.time-lastBPMTime, currentBPM*zoom)
                local nextBeatAt = math.ceil((1 - (pos % 1)) % 1)
                currentTime = currentTime + SixteenthsToSeconds(nextBeatAt,currentBPM*zoom)
                currentBPM = bpmChange.bpm
                lastBPMTime = bpmChange.time
                nextBPMChange = nextBPMChange + 1
                if nextBeatAt ~= 0 then
                    numSteps = numSteps + 1
                end
            else
                currentTime = currentTime + step
                numSteps = numSteps + 1
            end
        end

        do
            local pos = 0
            local drawPos = GetNoteCellY(pos, speed, 1, 0, chartPos, chartHeight)-1
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            DrawText("┈┈┈╬┈┈┈╬┈┈┈╬┈┈┈", (80-(scene.chart.lanes*4-1))/2 * 8, drawPos*16-8)
        end

        local chartX = (80-(scene.chart.lanes*4-1))/2 - 1 + 2
        for _,note in ipairs(scene.chart.notes) do
            local t = NoteTypes[note.type]
            if t and type(t.draw) == "function" then
                love.graphics.setFont(NoteFont)
                love.graphics.setColor(1,1,1)
                t.draw(note,scene.chartTimeTemp,speed,chartPos, chartHeight-1,chartX,true)
                if table.index(scene.selectedNotes, note) then
                    love.graphics.setColor(1,1,1,0.5)

                    local A,B = math.min(note.lane, note.lane+(note.extra.dir or 0)),math.max(note.lane, note.lane+(note.extra.dir or 0))
                    if note.type == "swap" then
                        A = note.lane-(note.extra.dir or 0)
                        B = A
                    end
        
                    local C,D = note.time,note.time+note.length

                    local pos1 = C-scene.chartTimeTemp
                    local drawPos1 = chartPos+chartHeight-pos1*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
                    local pos2 = D-scene.chartTimeTemp
                    local drawPos2 = chartPos+chartHeight-pos2*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
                    local a = (chartX+A*4)*8-4
                    local b = (chartX+B*4)*8+12
                    love.graphics.rectangle("fill", a, drawPos2*16-24, math.abs(b-a), math.abs((drawPos2*16)-(drawPos1*16))+16)
                end
                if scene.overlaps[note] then
                    love.graphics.setColor(1,0,0,0.25)

                    local A,B = math.min(note.lane, note.lane+(note.extra.dir or 0)),math.max(note.lane, note.lane+(note.extra.dir or 0))
                    if note.type == "swap" then
                        A = note.lane-(note.extra.dir or 0)
                        B = A
                    end
        
                    local C,D = note.time,note.time+note.length

                    local pos1 = C-scene.chartTimeTemp
                    local drawPos1 = chartPos+chartHeight-pos1*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
                    local pos2 = D-scene.chartTimeTemp
                    local drawPos2 = chartPos+chartHeight-pos2*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
                    local a = (chartX+A*4)*8-4
                    local b = (chartX+B*4)*8+12
                    love.graphics.rectangle("fill", a, drawPos2*16-24, math.abs(b-a), math.abs((drawPos2*16)-(drawPos1*16))+16)
                end
                love.graphics.setFont(Font)
            end
        end

        love.graphics.setFont(Font)
        love.graphics.setColor(TerminalColors[ColorID.CYAN])
        for _,change in ipairs(bpmChanges) do
            local drawPos = GetNoteCellY(change.time - scene.chartTimeTemp, speed, 1, 0, chartPos, chartHeight)
            local txt = change.bpm .. " BPM ▷"
            local w = 8*#txt
            DrawText(txt, chartX*8-24 - w, drawPos*16-24, w, "right")
        end

        love.graphics.setFont(Font)
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        local effectPos = {}
        local lastEffectPos = -math.huge
        for _,effect in ipairs(scene.chart.effects or {}) do
            local samePos = chartPos+chartHeight-(effect.time)*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            if math.abs(lastEffectPos - samePos) <= 1 then
                samePos = lastEffectPos
            else
                lastEffectPos = samePos
            end
            local pos = effect.time - scene.chartTimeTemp
            local drawPos = GetNoteCellY(pos, speed, 1, 0, chartPos, chartHeight)
            local actualPos = drawPos*8
            if actualPos < 0 then
                break
            end
            local x = effectPos[lastEffectPos] or 0
            local txt = "¤"
            local w = 8
            if effect.data.easeMethod or effect.data.smoothing then
                local duration = (effect.data.smoothing and (math.log(1 / 0.004846, effect.data.smoothing)) or (effect.data.easeDuration or 1))
                local cells = duration * math.abs(speed)
                for i = 0.5, cells do
                    local barPos = pos+i/speed
                    local extPos = chartPos+chartHeight-barPos*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
                    if extPos >= chartPos and extPos-(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1) < chartPos+(chartHeight-1) then
                        DrawText("┊", chartX*8+136 + (x*12) - w, math.floor(extPos*16-8-0), w, "left")
                    end
                end
            end
            DrawText(txt, chartX*8+136 + (x*12) - w, drawPos*16-24, w, "left")
            effectPos[lastEffectPos] = x + 1
        end


        if scene.selection.selecting then
            love.graphics.setColor(1,1,1,0.5)
            
            local A,B = math.min(scene.selection.start[1], scene.selection.stop[1]),math.max(scene.selection.start[1], scene.selection.stop[1])
            local C,D = math.min(scene.selection.start[2], scene.selection.stop[2]),math.max(scene.selection.start[2], scene.selection.stop[2])

            local pos1 = C-scene.chartTimeTemp
            local drawPos1 = chartPos+chartHeight-pos1*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local pos2 = D-scene.chartTimeTemp
            local drawPos2 = chartPos+chartHeight-pos2*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local x1,x2 = (chartX+A*4)*8-4,(chartX+B*4)*8-4
            love.graphics.rectangle("fill", x1, drawPos2*16-24, x2-x1+16, math.abs((drawPos2*16)-(drawPos1*16))+16)
        end

        if scene.lastNoteLane >= 0 and scene.lastNoteLane < 4 then
            local t = (scene.placementMode == placementModes.normal and NoteTypes.normal) or (scene.placementMode == placementModes.swap and NoteTypes.swap) or (scene.placementMode == placementModes.merge and NoteTypes.merge) or (scene.placementMode == placementModes.mine and NoteTypes.mine) or (scene.placementMode == placementModes.warning and NoteTypes.warning)
            if t then
                love.graphics.setFont(NoteFont)
                love.graphics.setColor(1,1,1)
                t.draw({
                    lane = scene.lastNoteLane,
                    time = scene.lastNoteTime,
                    length = 0,
                    extra = {
                        dir = 0
                    }
                }, scene.chartTimeTemp, speed, chartPos, chartHeight-1, (80-(scene.chart.lanes*4-1))/2 - 1 + 2, true)
                love.graphics.setFont(Font)
            end
        end

        love.graphics.setFont(Font)
        love.graphics.setColor(TerminalColors[ColorID.CYAN])
        if scene.placementMode == placementModes.bpm then
            local drawPos = GetNoteCellY(scene.lastNoteTime - scene.chartTimeTemp, speed, 1, 0, chartPos, chartHeight)
            local txt = "▷"
            local w = 8*#txt
            DrawText(txt, chartX*8-24 - w, drawPos*16-24, w, "right")
        end


        love.graphics.setFont(Font)
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        lastEffectPos = -math.huge
        local lastEffectTime = 0
        for _,effect in ipairs(scene.chart.effects or {}) do
            local samePos = chartPos+chartHeight-(effect.time)*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            if math.abs(lastEffectPos - samePos) <= 1 then
                samePos = lastEffectPos
            else
                lastEffectPos = samePos
            end
            if (lastEffectTime-0.01) < scene.lastNoteTime and (effect.time+0.01) >= scene.lastNoteTime then
                break
            end
            effectPos[lastEffectPos] = (effectPos[lastEffectPos] or 0) + 1
        end

        love.graphics.setFont(Font)
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        if scene.placementMode == placementModes.effect then
            local samePos = chartPos+chartHeight-(scene.lastNoteTime)*speed+(ViewOffset:get()+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            if math.abs(lastEffectPos - samePos) <= 1 then
                samePos = lastEffectPos
            else
                lastEffectPos = samePos
            end
            local drawPos = GetNoteCellY(scene.lastNoteTime - scene.chartTimeTemp, speed, 1, 0, chartPos, chartHeight)
            local txt = "¤"
            local w = 8
            DrawText(txt, chartX*8+136 + (effectPos[lastEffectPos] or 0)*12 - w, drawPos*16-24, w, "right")
        end
    
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        DrawBoxHalfWidth(scrollbarX/8-1, 6, 1, 16)
        local source = Assets.Source((scene.chart or {}).song)
        if source then
            local dur = source:getDuration("seconds")
            local pos = scene.chartTimeTemp/dur
            local y = pos*240
            love.graphics.print("█", scrollbarX, 352-y)
        end

        DrawText(Localize("editor_zoom"):format(math.floor(zoom*1000)/1000), scrollbarX+24, 96)
    else
        if scene.songData then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            DrawText(Localize("editor_no_chart"), 64, 232, 512, "center")
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            DrawText(Localize("editor_no_chart_subtext"), 64, 248, 512, "center")
        else
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            DrawText(Localize("editor_no_song"), 64, 232, 512, "center")
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            DrawText(Localize("editor_no_song_subtext"), 64, 248, 512, "center")
        end
    end

    for _,particle in ipairs(Particles) do
        love.graphics.setColor(TerminalColors[particle.color])
        DrawText(particle.char, particle.x-4, particle.y-8)
    end



    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    DrawBox(2, 1, 37, 1)
    local tabPosition = 32
    for i,tab in ipairs(editorMenu) do
        local X,Y,W,H = tabPosition, 32, 8*utf8.len(tab.label), 16
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        if tab.open then
            drawTab(tab, X-8, Y+16)
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_BLUE])
        end
        DrawText(tab.label, tabPosition, 32)
        tabPosition = tabPosition + 8*(utf8.len(tab.label)+4)
    end

    if scene.difficulty then
        local level = scene.songData:getLevel(scene.difficulty)
        DrawText(scene.songData.name, 0, 400, 568, "right")
        if EditorDirty then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_RED])
            DrawText("*", 568-Font:getWidth(scene.songData.name)-16, 400)
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
        end
        PrintDifficulty(568, 416, scene.difficulty or "easy", level or 0, "right")

        local cover = Assets.GetCover(scene.songData.path, scene.songData.coverAnimSpeed)
        love.graphics.draw(cover, 576, 400, 0, 32/cover:getWidth(), 32/cover:getHeight())
    end

    if scene.chart then
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        DrawText(Localize("editor_level"), 32, 400, 128, "right")
        DrawText(Localize("editor_level_raw"), 32, 416, 128, "right")
        local difficulty = math.max(1, scene.lastRating)
        if math.floor(difficulty + 0.5) < SongDifficulty[scene.difficulty].range[1] or math.floor(difficulty + 0.5) > SongDifficulty[scene.difficulty].range[2] then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_RED])
        end
        DrawText(tostring(math.floor(difficulty + 0.5)), 168, 400)
        DrawText(tostring(math.floor(difficulty*1000)/1000), 168, 416)
    end

    for i = #scene.dialogs, 1, -1 do
        love.graphics.setColor(0,0,0,0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        local dialog = scene.dialogs[i]
        local x = (80-dialog.width*2)/2-1
        local y = (30-dialog.height)/2-1
        DrawBoxHalfWidth(x,y,dialog.width*2,dialog.height)
        for _,element in ipairs(dialog.contents) do
            element:draw((x+2)*8, (y+3)*16)
        end
        DrawText(dialog.title, (x+1)*8, (y+1)*16, dialog.width*16, "center")
    end
end

function scene.mousepressed(x,y,b,t,p)
    if b == 1 then
        if #scene.dialogs > 0 then
            local dialog = scene.dialogs[1]
            local dx = (80-dialog.width*2)/2+1
            local dy = (30-dialog.height)/2+2
            local clicked
            for _,element in ipairs(dialog.contents) do
                if type(element.click) == "function" then
                    if element:click(MouseX-dx*8,MouseY-dy*16) then
                        clicked = element
                        break
                    end
                end
            end
            for _,element in ipairs(dialog.contents) do
                if element ~= clicked and type(element.unclick) == "function" then
                    element:unclick(MouseX-dx*8,MouseY-dy*16)
                end
            end
            return
        end

        local hadOpen = false
        local tabPosition = 32
        for i,tab in ipairs(editorMenu) do
            local X,Y,W,H = tabPosition, 32, 8*utf8.len(tab.label), 16
            if tab.open then
                hadOpen = true
                local click = clickTab(tab, X, Y+16, MouseX, MouseY)
                if not click then
                    tab.open = false
                else
                    if click.type == "menu" then
                        click.open = not click.open
                    else
                        if click.onclick() then
                            for _,TAB in ipairs(editorMenu) do
                                closeMenu(TAB)
                            end
                            return
                        end
                    end
                end
            end
            tabPosition = tabPosition + 8*(utf8.len(tab.label)+4)
        end
        tabPosition = 32
        for i,tab in ipairs(editorMenu) do
            local X,Y,W,H = tabPosition, 32-8, 8*utf8.len(tab.label), 32
            if MouseX >= X and MouseY >= Y and MouseX < X+W and MouseY < Y+H then
                if tab.type == "menu" then
                    tab.open = true
                    return
                else
                    tab.onclick()
                    return
                end
            end
            tabPosition = tabPosition + 8*(utf8.len(tab.label)+4)
        end
        if hadOpen then return end

        local source = Assets.Source((scene.chart or {}).song)
        if source then
            local dur = source:getDuration("seconds")
            local pos = scene.chartTimeTemp/dur
            local Y = pos*240
            if y >= 112 and y < 368 and x >= scrollbarX and x < scrollbarX+8 then
                scene.scrollbarGrab = true
                scene.playingWhenGrabbed = source:isPlaying()
            end
        end
        
        if scene.chart then
            local chartX = (80-(scene.chart.lanes*4-1))/2 - 1 + 2
            local chartPos = 7
            local chartHeight = 16
            local speed = 25
            if scene.placementMode ~= placementModes.select then
                if scene.placementMode < placementModes.bpm then
                    EditorDirty = true
                    if scene.lastNoteLane >= 0 and scene.lastNoteLane <= 3 then
                        local noteType = notes[scene.placementMode]
                        scene.placement.placing = true
                        scene.placement.type = noteType
                        scene.placement.start = {scene.lastNoteLane, scene.lastNoteTime}
                        local note = Note:new(scene.lastNoteTime, scene.lastNoteLane, 0, noteType, {})
                        if noteType == "merge" or noteType == "swap" then
                            note.extra.dir = 0
                        end
                        scene.placement.note = note
                        table.insert(scene.chart.notes, note)
                        for _=1,8 do
                            table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = love.math.random(1,16), char = "¤"})
                        end
                        scene.lastRating = scene.chart:getDifficulty()
                        findOverlaps()
                    end
                end
                if scene.placementMode == placementModes.bpm then
                    local time = scene.lastNoteTime
                    local bpmInput = DialogInput:new(0, 16, 240, 16, Localize("editor_label_new_bpm"), 15, nil, function(self)
                        self.content = tostring(tonumber(self.content) or 0)
                    end)
                    bpmInput.content = "120"
                    table.insert(scene.dialogs, 1, {
                        title = Localize("editor_dialog_bpm_change_title"),
                        width = 16,
                        height = 9,
                        contents = {
                            bpmInput,
                            DialogButton:new(136, 80, 64, 16, Localize("editor_action_cancel"), function ()
                                table.remove(scene.dialogs, 1)
                            end),
                            DialogButton:new(40, 80, 64, 16, Localize("editor_action_place"), function ()
                                EditorDirty = true
                                table.insert(scene.chart.bpmChanges, {time = time, bpm = tonumber(bpmInput.content)})
                                table.remove(scene.dialogs, 1)
                                scene.chart:sort()
                            end)
                        }
                    })
                end
                if scene.placementMode == placementModes.effect then
                    effectPlacementDialog({time = scene.lastNoteTime, data = {}}, false)
                end
            elseif not scene.scrollbarGrab then
                local effectPos = {}
                for i,effect in ipairs(scene.chart.effects or {}) do
                    local drawPos = GetNoteCellY(effect.time - scene.chartTimeTemp, speed, 1, 0, chartPos, chartHeight)
                    local samePos = math.floor(drawPos*2)
                    local eX = effectPos[samePos] or 0
                    local txt = "¤"
                    local w = 8
                    effectPos[samePos] = eX + 1
                    
                    local X,Y = chartX*8+136 + (eX*12) - w, drawPos*16-24
                    if x >= X and x < X+w and y >= Y-8 and y < Y+16+8 then
                        if p == 2 then
                            effectPlacementDialog(effect, true)
                        end
                        return
                    end
                end

                local preserveSelection = false

                for i,note in ipairs(scene.selectedNotes) do
                    local A,B = math.min(note.lane, note.lane+(note.extra.dir or 0)),math.max(note.lane, note.lane+(note.extra.dir or 0))
                    if note.type == "swap" then
                        A,B = math.min(note.lane, note.lane-(note.extra.dir or 0)),math.max(note.lane, note.lane-(note.extra.dir or 0))
                    end
        
                    local C,D = note.time-0.05,note.time+note.length+0.05
                    if (scene.lastNoteLane >= A and scene.lastNoteLane <= B) and (scene.lastNoteTime >= C and scene.lastNoteTime <= D) then
                        if p == 2 then
                            if #scene.selectedNotes == 1 then
                                notePropertiesDialog(note)
                            else
                                groupDialog()
                                preserveSelection = true
                            end
                        else
                            scene.selection.dragging = true
                            scene.selection.start = {scene.lastNoteLane, scene.lastNoteTime}
                            scene.selection.stop = {scene.lastNoteLane, scene.lastNoteTime}
                        end
                        break
                    end
                end

                if not scene.selection.dragging and not preserveSelection then
                    if not love.keyboard.isDown("lshift") then
                        scene.selectedNotes = {}
                    end
                    scene.selection.selecting = true
                    scene.selection.start = {scene.lastNoteLane, scene.lastNoteTime}
                end
            end
        end
    end

    if b == 2 and scene.chart then
        local chartX = (80-(scene.chart.lanes*4-1))/2 - 1 + 2
        local chartPos = 7
        local chartHeight = 16
        local speed = 25
        for i,change in ipairs(scene.chart.bpmChanges or {}) do
            local drawPos = GetNoteCellY(change.time - scene.chartTimeTemp, speed, 1, 0, chartPos, chartHeight)
            local txt = change.bpm .. " BPM ▷"
            local w = 8*#txt
            
            local X,Y = chartX*8-24 - w, drawPos*16-24
            if x >= X and x < X+w and y >= Y-16 and y < Y+16+16 then
                EditorDirty = true
                table.remove(scene.chart.bpmChanges or {}, i)
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                end
                return
            end
        end


        local effectPos = {}
        for i,effect in ipairs(scene.chart.effects or {}) do
            local drawPos = GetNoteCellY(effect.time - scene.chartTimeTemp, speed, 1, 0, chartPos, chartHeight)
            local samePos = math.floor(drawPos*2)
            local eX = effectPos[samePos] or 0
            local txt = "¤"
            local w = 8
            effectPos[samePos] = eX + 1
            
            local X,Y = chartX*8+136 + (eX*12) - w, drawPos*16-24
            if x >= X and x < X+w and y >= Y-8 and y < Y+16+8 then
                EditorDirty = true
                table.remove(scene.chart.effects or {}, i)
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                end
                return
            end
        end

        for i,note in ipairs(scene.chart.notes) do
            local A,B = math.min(note.lane, note.lane+(note.extra.dir or 0)),math.max(note.lane, note.lane+(note.extra.dir or 0))
            if note.type == "swap" then
                A,B = math.min(note.lane, note.lane-(note.extra.dir or 0)),math.max(note.lane, note.lane-(note.extra.dir or 0))
            end

            local length = (note.length or 0)
            if note.type == "warning" then
                length = -length
            end

            local C,D = math.min(note.time, note.time+length)-0.05, math.max(note.time, note.time+length)+0.05
            if (scene.lastNoteLane >= A and scene.lastNoteLane <= B) and (scene.lastNoteTime >= C and scene.lastNoteTime <= D) then
                EditorDirty = true
                table.remove(scene.chart.notes, i)
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                end
                scene.lastRating = scene.chart:getDifficulty()
                findOverlaps()
                break
            end
        end
    end
end

function scene.mousereleased(x,y,b)
    if scene.placement.placing then
        EditorDirty = true
        local noteType = scene.placement.type
        local note = scene.placement.note
        if note and noteType == "merge" and note.extra.dir == 0 then
            scene.placement.type = "normal"
            note.type = "normal"
            note.extra.dir = nil
        end
        findOverlaps()
    end
    if scene.selection.dragging then
        EditorDirty = true
        findOverlaps()
    end
    scene.placement.placing = false
    if scene.scrollbarGrab then
        scene.scrollbarGrab = false
        if scene.playingWhenGrabbed then
            local source = Assets.Source((scene.chart or {}).song)
            if source then
                source:seek(scene.chartTimeTemp, "seconds")
                source:play()
            end
        end
    end
    if scene.selection.selecting then
        for i,note in ipairs(scene.chart.notes) do
            local A1,B1 = math.min(note.lane, note.lane+(note.extra.dir or 0)),math.max(note.lane, note.lane+(note.extra.dir or 0))
            if note.type == "swap" then
                A1,B1 = math.min(note.lane, note.lane-(note.extra.dir or 0)),math.max(note.lane, note.lane-(note.extra.dir or 0))
            end
            local C1,D1 = note.time-0.05,note.time+note.length+0.05

            local A2,B2 = math.min(scene.selection.start[1], scene.selection.stop[1]),math.max(scene.selection.start[1], scene.selection.stop[1])
            local C2,D2 = math.min(scene.selection.start[2], scene.selection.stop[2]),math.max(scene.selection.start[2], scene.selection.stop[2])

            if aabb(A1,C1,B1-A1,D1-C1, A2,C2,B2-A2,D2-C2) then
                table.insert(scene.selectedNotes, note)
            end
        end
    end
    scene.selection.selecting = false
    scene.selection.dragging = false
end

function scene.unload()
    Particles = {}
    love.keyboard.setKeyRepeat(false)
end

return scene