local utf8 = require "utf8"

require "dialogs"

local scene = {}

local placementModes = {
    select = 0,
    normal = 1,
    swap = 2,
    merge = 3,
    bpm = 4,
    effect = 5
}

local notes = {"normal", "swap", "merge"}

local function getDirectorySeparator()
	if love.system.getOS() == "Windows" then
		return "\\"
	else
		return "/"
	end
end

local buildRecentMenu

local function hoistHistory(path,name)
    local found = false
    for i,item in ipairs(scene.history) do
        if item.path == path or item.name == name then
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
    return true
end

local function shutoffMusic()
    local source = Assets.Source((scene.chart or {}).song)
    if source then
        source:stop()
    end
end

local function fileDialog(type)
    local filenameInput = DialogInput:new(0, 224, 256, 16, "SONG ID", 32)
    if scene.songData then
        local splitPath = scene.songData.path:split(getDirectorySeparator())
        filenameInput.content = splitPath[#splitPath]
    end
    local typename = (type == "r" and "OPEN" or "SAVE")
    local existing = love.filesystem.getDirectoryItems("editor_save")
    local dialog = {
        title = typename .. " SONG",
        width = 32,
        height = 18,
        contents = {
            DialogButton:new(272, 224, 96, 16, "CANCEL", function ()
                table.remove(scene.dialogs, 1)
            end),
            DialogButton:new(392, 224, 96, 16, typename, function ()
                if #filenameInput.content <= 0 then return end
                if type == "w" then
                    if table.index(existing, filenameInput.content) then
                        local savedialog = {
                            title = "SAVE SONG",
                            width = 16,
                            height = 9,
                            contents = {
                                DialogLabel:new(0, 16, 240, "YOU ARE OVERWRITING AN EXISTING FILE! ARE YOU SURE?", "center"),
                                DialogButton:new(136, 80, 64, 16, "CANCEL", function ()
                                    table.remove(scene.dialogs, 1)
                                end),
                                DialogButton:new(40, 80, 64, 16, "SAVE", function ()
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
                    shutoffMusic()
                    if not readChart(filenameInput.content) then
                        
                    else
                        table.remove(scene.dialogs, 1)
                    end
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

local function effectPlacementDialog(effect, editing)
    local copy = table.merge({}, effect)
    local typeInput = DialogInput:new(0, 0, 304, 16, "EFFECT TYPE", 35, nil)
    local data = copy.data
    typeInput.content = copy.type or ""
    local pos = 0
    local dataElements = {}
    local dialog = {
        title = (editing and "EDITING" or "PLACING") .. " EFFECT",
        width = 20,
        height = 20,
        contents = {
            typeInput,
            DialogLabel:new(0, 32, 304, "EFFECT DATA", "center"),
            DialogButton:new(216, 256, 64, 16, "CANCEL", function ()
                table.remove(scene.dialogs, 1)
            end),
            DialogButton:new(120, 256, 64, 16, "NUDGE", function ()
                effect.time = effect.time + 0.001
                copy.time = copy.time + 0.001
            end),
            DialogButton:new(24, 256, 64, 16, editing and "APPLY" or "PLACE", function ()
                effect.type = typeInput.content
                effect.data = {}
                for _,item in ipairs(dataElements) do
                    local v = item.value.content
                    effect.data[item.key.content] = tonumber(v) or v
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
    local function addDataElement(k,v) end
    local addButton = DialogButton:new(264,pos+64,32,16,"+",function(self)
        addDataElement("","")
    end)
    addDataElement = function(k,v)
        addButton.y = addButton.y + 48
        local i = #dataElements+1
        local key = DialogInput:new(0,pos+64,128,16,"KEY", 16, nil, nil)
        local equals = DialogLabel:new(132, pos+64, 8, "=", "center")
        local value = DialogInput:new(144,pos+64,96,16,"VALUE", 12, nil, nil)
        local remove = DialogButton:new(264,pos+64,32,16,"-",function(self)
            table.remove(dataElements,i)
            table.remove(dialog.contents, table.index(dialog.contents, key))
            table.remove(dialog.contents, table.index(dialog.contents, equals))
            table.remove(dialog.contents, table.index(dialog.contents, value))
            table.remove(dialog.contents, table.index(dialog.contents, self))
            for j = i, #dataElements do
                dataElements[j].key.y = dataElements[j].key.y - 48
                dataElements[j].equals.y = dataElements[j].equals.y - 48
                dataElements[j].value.y = dataElements[j].value.y - 48
                dataElements[j].remove.y = dataElements[j].remove.y - 48
            end
            addButton.y = addButton.y - 48
            pos = pos - 48
        end)
        key.content = k
        value.content = tostring(v)
        table.insert(dialog.contents, key)
        table.insert(dialog.contents, equals)
        table.insert(dialog.contents, value)
        table.insert(dialog.contents, remove)
        dataElements[i] = { key = key, equals = equals, value = value, remove = remove }
        pos = pos + 48
    end
    for k,v in pairs(data) do
        addDataElement(k,v)
    end
    table.insert(dialog.contents, addButton)
    table.insert(scene.dialogs, 1, dialog)
end

local function metadataDialog()
    local nameInput = DialogInput:new(0, 16, 368, 16, "SONG NAME", 38, nil, function(self)
        scene.songData.name = self.content
    end)
    local authorInput = DialogInput:new(0, 64, 368, 16, "SONG AUTHOR", 38, nil, function(self)
        scene.songData.author = self.content
    end)
    local bpmInput = DialogInput:new(160, 96, 120, 16, "BPM", 15, nil, function(self)
        self.content = tostring(tonumber(self.content) or 0)
    end)
    local artistInput = DialogInput:new(0, 144, 368, 16, "COVER ARTIST", 20, nil, function(self)
        scene.songData.coverArtist = self.content
    end)

    nameInput.content = scene.songData.name
    authorInput.content = scene.songData.author
    bpmInput.content = tostring(scene.songData.bpm)
    artistInput.content = scene.songData.coverArtist

    local preview = nil
    local playPreviewButton

    local function stopPreview()
        playPreviewButton.label = "PLAY"
        if preview then
            preview:stop()
        end
    end

    local source = Assets.Source((scene.songData or {}).songPath)
    if source then
        scene.songData.songPreview = scene.songData.songPreview or {0,math.floor(source:getDuration()*100000)/100000}
    end

    local previewStartInput = DialogInput:new(56, 208, 80, 16, "START", 10, nil, function(self)
        stopPreview()
        self.content = tostring(tonumber(self.content) or 0)
        scene.songData.songPreview[1] = tonumber(self.content) or scene.songData.songPreview[1]
    end)
    local previewEndInput = DialogInput:new(232, 208, 80, 16, "END", 10, nil, function(self)
        stopPreview()
        self.content = tostring(tonumber(self.content) or 0)
        scene.songData.songPreview[2] = tonumber(self.content) or scene.songData.songPreview[2]
    end)
    previewStartInput.content = tostring(scene.songData.songPreview[1] or "")
    previewEndInput.content = tostring(scene.songData.songPreview[2] or "")

    playPreviewButton = DialogButton:new(152, 208, 64, 16, "PLAY", function (self)
        if self.label == "PLAY" then
            self.label = "STOP"
            Assets.ErasePreview(scene.songData.songPath)
            preview = Assets.Preview(scene.songData.songPath, scene.songData.songPreview)
            if preview then
                preview:setLooping(true)
                preview:play()
            end
        else
            stopPreview()
        end
    end)

    local dialog = {
        title = "SONG METADATA",
        width = 24,
        height = 20,
        contents = {
            DialogLabel:new(148, 0, 72, "SONG NAME"),
            nameInput,
            DialogLabel:new(140, 48, 88, "SONG AUTHOR"),
            authorInput,
            DialogLabel:new(88, 96, 64, "SONG BPM"),
            bpmInput,
            DialogLabel:new(136, 128, 96, "COVER ARTIST"),
            artistInput,
            DialogLabel:new(136, 176, 96, "SONG PREVIEW"),
            previewStartInput,
            previewEndInput,
            playPreviewButton,
            DialogButton:new(152, 256, 64, 16, "CLOSE", function ()
                stopPreview()
                table.remove(scene.dialogs, 1)
            end)
        }
    }
    table.insert(scene.dialogs, 1, dialog)
end

local editorMenu = {
    {
        id = "file",
        type = "menu",
        label = "FILE",
        open = false,
        contents = {
            {
                id = "file.new",
                type = "action",
                label = "NEW",
                onclick = function()
                    local nameInput = DialogInput:new(0, 0, 368, 16, "SONG NAME", 38)
                    local authorInput = DialogInput:new(0, 24, 368, 16, "SONG AUTHOR", 38)
                    local songInput = DialogFileInput:new(0, 64, 368, 16, "SONG AUDIO")
                    local bpmInput = DialogInput:new(196, 96, 48, 16, "BPM", 15, nil, function(self)
                        self.content = tostring(tonumber(self.content) or 0)
                    end)
                    bpmInput.content = "120"
                    local coverInput = DialogFileInput:new(0, 128, 368, 16, "SONG COVER")
                    local artistInput = DialogInput:new(0, 160, 368, 16, "COVER ARTIST", 20)
                    local dialog = {
                        width = 24,
                        height = 17,
                        title = "NEW SONG",
                        contents = {
                            nameInput,
                            authorInput,
                            songInput,
                            bpmInput,
                            coverInput,
                            artistInput,
                            DialogLabel:new(124, 96, 64, "SONG BPM"),
                            DialogButton:new(200, 208, 64, 16, "CANCEL", function ()
                                table.remove(scene.dialogs, 1)
                            end),
                            DialogButton:new(104, 208, 64, 16, "CREATE", function ()
                                if songInput.file == nil then return end
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
                        }
                    }
                    table.insert(scene.dialogs, dialog)
                    return true
                end
            },
            {
                id = "file.open",
                type = "action",
                label = "OPEN",
                onclick = function()
                    fileDialog("r")
                    return true
                end
            },
            {
                id = "file.recent",
                type = "menu",
                label = "OPEN RECENT",
                open = false,
                contents = {}
            },
            {
                id = "file.save",
                type = "action",
                label = "SAVE",
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
                label = "SAVE AS",
                onclick = function()
                    fileDialog("w")
                    return true
                end
            },
            {
                id = "file.exit",
                type = "action",
                label = "EXIT",
                onclick = function()
                    shutoffMusic()
                    SavedEditorTime = nil
                    SavedEditorZoom = nil
                    SceneManager.Transition("scenes/menu")
                    SetCursor()
                    return true
                end
            },
        }
    },
    {
        id = "edit",
        type = "menu",
        label = "EDIT",
        open = false,
        contents = {
            {
                id = "edit.metadata",
                type = "action",
                label = "METADATA",
                onclick = function()
                    -- print("edit song metadata")
                    if not scene.songData then return true end
                    metadataDialog()
                    return true
                end
            },
            {
                id = "edit.difficulties",
                type = "action",
                label = "DIFFICULTIES",
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
                        title = "DIFFICULTIES",
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

                        local levelInput = DialogInput:new(96,48*(i-1),32,16,"LVL",4,nil,function(self)
                            self.content = tostring(tonumber(self.content) or 0)
                            scene.songData.levels[difficulty] = tonumber(self.content) or 0
                            scene.songData.charts[difficulty].level = tonumber(self.content) or 0
                        end)
                        levelInput.content = tostring(level)

                        local charterInput = DialogInput:new(216,48*(i-1),80,16,"CHARTER",10,nil,function(self)
                            (scene.songData.charts[difficulty] or {}).charter = self.content
                        end)
                        charterInput.content = (scene.songData.charts[difficulty] or {}).charter or ""

                        local addButton
                        local removeButton
                        local editButton = DialogButton:new(152,48*(i-1),16,16,"E",function()
                            scene.difficulty = difficulty
                            scene.chart = scene.songData:loadChart(difficulty)
                            if scene.chart then scene.lastRating = scene.chart:getDifficulty() end
                            table.remove(scene.dialogs, 1)
                        end)
                        removeButton = DialogButton:new(184,48*(i-1),16,16,"-",function()
                            local removedialog = {
                                title = "REMOVE " .. SongDifficulty[difficulty].name:upper(),
                                width = 16,
                                height = 9,
                                contents = {
                                    DialogLabel:new(0, 16, 240, "ARE YOU SURE?\nTHIS CANNOT BE UNDONE!", "center"),
                                    DialogButton:new(136, 80, 64, 16, "CANCEL", function ()
                                        table.remove(scene.dialogs, 1)
                                    end),
                                    DialogButton:new(40, 80, 64, 16, "REMOVE", function ()
                                        scene.songData:removeChart(difficulty)
                                        if scene.difficulty == difficulty then
                                            scene.difficulty = nil
                                            scene.chart = nil
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
            }
        }
    },
    {
        id = "note",
        type = "menu",
        label = "NOTE",
        open = false,
        contents = {
            {
                id = "note.select",
                type = "action",
                label = "SELECT",
                onclick = function()
                    SetCursor("🮰", 0, 0)
                    scene.placementMode = placementModes.select
                    return true
                end
            },
            {
                id = "note.normal",
                type = "action",
                label = "NORMAL",
                onclick = function()
                    SetCursor("○", 4, 8)
                    scene.placementMode = placementModes.normal
                    return true
                end
            },
            {
                id = "note.swap",
                type = "action",
                label = "SWAP",
                onclick = function()
                    SetCursor("◇", 4, 8)
                    scene.placementMode = placementModes.swap
                    return true
                end
            },
            {
                id = "note.merge",
                type = "action",
                label = "MERGE",
                onclick = function()
                    SetCursor("▥", 4, 8)
                    scene.placementMode = placementModes.merge
                    return true
                end
            },
            {
                id = "note.bpm",
                type = "action",
                label = "BPM CHANGE",
                onclick = function()
                    SetCursor("▷", 4, 8)
                    scene.placementMode = placementModes.bpm
                    return true
                end
            },
            {
                id = "note.bpm",
                type = "action",
                label = "EFFECT",
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
        label = "PLAY",
        open = false,
        contents = {
            {
                id = "play.playtest",
                type = "action",
                label = "PLAYTEST",
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
                label = "AUTO SHOWCASE",
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
        label = "HOT RELOAD",
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
                shutoffMusic()
                readChart(id)
                return true
            end
        })
        if #menu.contents >= 6 then
            break
        end
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

    if scene.songData then
        hoistHistory(scene.songData.path, scene.songData.name)
    end

    SetCursor("🮰", 0, 0)
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
                note.extra.dir = math.max(-1,math.min(1,endLane - lane))
                note.lane = scene.placement.start[1]+note.extra.dir
            end
            if noteType == "merge" then
                local dir = scene.placement.stop[1]-scene.placement.start[1]
                local endLane = math.max(0,math.min(3,note.lane + dir))
                note.extra.dir = endLane - note.lane
            end
            if noteType ~= "merge" then
                local a,b = math.min(scene.placement.start[2],scene.placement.stop[2]),math.max(scene.placement.start[2],scene.placement.stop[2])
                note.length = math.max(0,b-a)
                note.time = a
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
    love.filesystem.mount(path, "temp_import")
    local splitPath = path:split("/")
    local name = splitPath[#splitPath]
    love.filesystem.createDirectory("editor_save/"..name)
    fullCopy("temp_import", "editor_save/"..name)
    love.filesystem.unmount(path)
    shutoffMusic()
    readChart(name)
end

function scene.wheelmoved(x,y)
    if love.keyboard.isDown("lctrl") then
        scene.zoom = math.max(1,math.min(16,scene.zoom + y))
    else
        scene.chartTimeTemp = scene.chartTimeTemp + y/10/scene.zoom
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
        scene.clipboard = scene.selectedNotes
        for _,note in ipairs(scene.selectedNotes) do
            table.remove(scene.chart.notes, table.index(scene.chart.notes, note))
        end
        scene.selectedNotes = {}
        scene.lastRating = scene.chart:getDifficulty()
    end
    if k == "v" and love.keyboard.isDown("lctrl") then
        -- Paste
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
            scene.lastRating = scene.chart:getDifficulty()
        end
    end
    if k == "delete" then
        for _,note in ipairs(scene.selectedNotes) do
            table.remove(scene.chart.notes, table.index(scene.chart.notes, note))
        end
        scene.selectedNotes = {}
        scene.lastRating = scene.chart:getDifficulty()
    end
    if k == "a" and love.keyboard.isDown("lctrl") then
        scene.selectedNotes = {}
        for _,note in ipairs(scene.chart.notes) do
            table.insert(scene.selectedNotes, note)
        end
    end
    if k == "g" and love.keyboard.isDown("lctrl") then
        local groupnameInput = DialogInput:new(0, 16, 240, 16, "GROUP NAME", 30)
        table.insert(scene.dialogs, 1, {
            title = "GROUPING " .. #scene.selectedNotes .. " NOTES",
            width = 16,
            height = 9,
            contents = {
                groupnameInput,
                DialogButton:new(136, 80, 64, 16, "CANCEL", function ()
                    table.remove(scene.dialogs, 1)
                end),
                DialogButton:new(40, 80, 64, 16, "GROUP", function ()
                    for _,note in ipairs(scene.selectedNotes) do
                        note.extra.group = groupnameInput.content
                    end
                    table.remove(scene.dialogs, 1)
                end)
            }
        })
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
        love.graphics.print(elem.label .. (elem.type == "menu" and " ▷" or ""), X+16, Y+16)
        if i ~= #tab.contents then
            love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
            love.graphics.print(("┈"):rep(width+2), X+8, Y+32)
        end
    end
end

function scene.draw()
    if scene.chart then
        DrawBoxHalfWidth((80-(scene.chart.lanes*4-1))/2 - 1, 6, scene.chart.lanes*4-1, 16)
        
        for i = 1, 4-1 do
            love.graphics.setColor(TerminalColors[ColorID.DARK_GRAY])
            local x = (80-(scene.chart.lanes*4-1))/2 - 1+(i-1)*4 + 1
            love.graphics.print(("   ┊\n"):rep(16), x*8, 7*16)
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
                local drawPos = chartPos+chartHeight-pos*speed - 1
                if drawPos >= chartPos and drawPos < chartPos+chartHeight then
                    love.graphics.setColor(TerminalColors[numSteps%(4*zoom) == 0 and ColorID.LIGHT_GRAY or ColorID.DARK_GRAY])
                    love.graphics.print("┈┈┈╬┈┈┈╬┈┈┈╬┈┈┈", (80-(scene.chart.lanes*4-1))/2 * 8, drawPos*16-8)
                end
                local mouseDist = math.abs((drawPos*16-8) - (MouseY-8))
                if mouseDist < closestY then
                    closestY = mouseDist
                    scene.lastNoteTime = currentTime
                end
            end

            local step = TimeBPM(1/zoom,currentBPM)
            local bpmChange = (bpmChanges[nextBPMChange] or {time = math.huge, bpm = currentBPM})
            if currentTime+step - bpmChange.time >= -0.001 then
                local pos = WhichSixteenth(bpmChange.time-lastBPMTime, currentBPM*zoom)
                local nextBeatAt = math.ceil((1 - (pos % 1)) % 1)
                currentTime = currentTime + TimeBPM(nextBeatAt,currentBPM*zoom)
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
            local drawPos = chartPos+chartHeight-pos*speed - 1
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.print("┈┈┈╬┈┈┈╬┈┈┈╬┈┈┈", (80-(scene.chart.lanes*4-1))/2 * 8, drawPos*16-8)
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
                    local drawPos1 = chartPos+chartHeight-pos1*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
                    local pos2 = D-scene.chartTimeTemp
                    local drawPos2 = chartPos+chartHeight-pos2*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
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
            local drawPos = chartPos+chartHeight-(change.time - scene.chartTimeTemp)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local txt = change.bpm .. " BPM ▷"
            local w = 8*#txt
            love.graphics.printf(txt, chartX*8-24 - w, drawPos*16-24, w, "right")
        end

        love.graphics.setFont(Font)
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        local effectPos = {}
        local lastEffectPos = -math.huge
        for _,effect in ipairs(scene.chart.effects or {}) do
            local samePos = chartPos+chartHeight-(effect.time)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            if math.abs(lastEffectPos - samePos) <= 1 then
                samePos = lastEffectPos
            else
                lastEffectPos = samePos
            end
            local drawPos = chartPos+chartHeight-(effect.time - scene.chartTimeTemp)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local actualPos = drawPos*8
            if actualPos < 0 then
                break
            end
            local x = effectPos[lastEffectPos] or 0
            local txt = "¤"
            local w = 8
            love.graphics.printf(txt, chartX*8+136 + (x*12) - w, drawPos*16-24, w, "left")
            effectPos[lastEffectPos] = x + 1
        end


        if scene.selection.selecting then
            love.graphics.setColor(1,1,1,0.5)
            
            local A,B = math.min(scene.selection.start[1], scene.selection.stop[1]),math.max(scene.selection.start[1], scene.selection.stop[1])
            local C,D = math.min(scene.selection.start[2], scene.selection.stop[2]),math.max(scene.selection.start[2], scene.selection.stop[2])

            local pos1 = C-scene.chartTimeTemp
            local drawPos1 = chartPos+chartHeight-pos1*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local pos2 = D-scene.chartTimeTemp
            local drawPos2 = chartPos+chartHeight-pos2*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local x1,x2 = (chartX+A*4)*8-4,(chartX+B*4)*8-4
            love.graphics.rectangle("fill", x1, drawPos2*16-24, x2-x1+16, math.abs((drawPos2*16)-(drawPos1*16))+16)
        end

        if scene.lastNoteLane >= 0 and scene.lastNoteLane < 4 then
            local t = (scene.placementMode == placementModes.normal and NoteTypes.normal) or (scene.placementMode == placementModes.swap and NoteTypes.swap) or (scene.placementMode == placementModes.merge and NoteTypes.merge)
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
            local drawPos = chartPos+chartHeight-(scene.lastNoteTime - scene.chartTimeTemp)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local txt = "▷"
            local w = 8*#txt
            love.graphics.printf(txt, chartX*8-24 - w, drawPos*16-24, w, "right")
        end


        love.graphics.setFont(Font)
        love.graphics.setColor(TerminalColors[ColorID.MAGENTA])
        lastEffectPos = -math.huge
        local lastEffectTime = 0
        for _,effect in ipairs(scene.chart.effects or {}) do
            local samePos = chartPos+chartHeight-(effect.time)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
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
            local samePos = chartPos+chartHeight-(scene.lastNoteTime)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            if math.abs(lastEffectPos - samePos) <= 1 then
                samePos = lastEffectPos
            else
                lastEffectPos = samePos
            end
            local drawPos = chartPos+chartHeight-(scene.lastNoteTime - scene.chartTimeTemp)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local txt = "¤"
            local w = 8
            love.graphics.printf(txt, chartX*8+136 + (effectPos[lastEffectPos] or 0)*12 - w, drawPos*16-24, w, "right")
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

        love.graphics.print("Zoom: " .. math.floor(zoom*1000)/1000 .. "x", scrollbarX+24, 96)
    else
        if scene.songData then
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.printf("- NO CHART LOADED -", 64, 232, 512, "center")
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            love.graphics.printf("GO TO EDIT / DIFFICULTIES TO CREATE A NEW CHART", 64, 248, 512, "center")
        else
            love.graphics.setColor(TerminalColors[ColorID.WHITE])
            love.graphics.printf("- NO SONG LOADED -", 64, 232, 512, "center")
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_GRAY])
            love.graphics.printf("GO TO FILE / NEW TO CREATE A NEW SONG", 64, 248, 512, "center")
        end
    end

    for _,particle in ipairs(Particles) do
        love.graphics.setColor(TerminalColors[particle.color])
        love.graphics.print(particle.char, particle.x-4, particle.y-8)
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
        love.graphics.print(tab.label, tabPosition, 32)
        tabPosition = tabPosition + 8*(utf8.len(tab.label)+4)
    end

    if scene.difficulty then
        local level = scene.songData:getLevel(scene.difficulty)
        love.graphics.printf(scene.songData.name, 0, 400, 568, "right")
        PrintDifficulty(568, 416, scene.difficulty or "easy", level or 0, "right")

        local cover = Assets.GetCover(scene.songData.path)
        love.graphics.draw(cover, 576, 400, 0, 32/cover:getWidth(), 32/cover:getHeight())
    end

    if scene.chart then
        love.graphics.setColor(TerminalColors[ColorID.WHITE])
        love.graphics.print("Suggested Level: ", 32, 400)
        love.graphics.print("     Full Level: ", 32, 416)
        local difficulty = math.max(1, scene.lastRating)
        if math.floor(difficulty + 0.5) < SongDifficulty[scene.difficulty].range[1] or math.floor(difficulty + 0.5) > SongDifficulty[scene.difficulty].range[2] then
            love.graphics.setColor(TerminalColors[ColorID.LIGHT_RED])
        end
        love.graphics.print(tostring(math.floor(difficulty + 0.5)), 168, 400)
        love.graphics.print(tostring(math.floor(difficulty*1000)/1000), 168, 416)
    end

    love.graphics.setColor(TerminalColors[ColorID.WHITE])
    for i = #scene.dialogs, 1, -1 do
        local dialog = scene.dialogs[i]
        local x = (80-dialog.width*2)/2-1
        local y = (30-dialog.height)/2-1
        DrawBoxHalfWidth(x,y,dialog.width*2,dialog.height)
        for _,element in ipairs(dialog.contents) do
            element:draw((x+2)*8, (y+3)*16)
        end
        love.graphics.printf(dialog.title, (x+1)*8, (y+1)*16, dialog.width*16, "center")
    end
end

function scene.mousepressed(x,y,b)
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
            if scene.placementMode ~= placementModes.select then
                if scene.placementMode < placementModes.bpm then
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
                    end
                end
                if scene.placementMode == placementModes.bpm then
                    local time = scene.lastNoteTime
                    local bpmInput = DialogInput:new(0, 16, 240, 16, "NEW BPM", 15, nil, function(self)
                        self.content = tostring(tonumber(self.content) or 0)
                    end)
                    bpmInput.content = "120"
                    table.insert(scene.dialogs, 1, {
                        title = "PLACING BPM CHANGE",
                        width = 16,
                        height = 9,
                        contents = {
                            bpmInput,
                            DialogButton:new(136, 80, 64, 16, "CANCEL", function ()
                                table.remove(scene.dialogs, 1)
                            end),
                            DialogButton:new(40, 80, 64, 16, "PLACE", function ()
                                table.insert(scene.chart.bpmChanges, {time = time, bpm = tonumber(bpmInput.content)})
                                table.remove(scene.dialogs, 1)
                            end)
                        }
                    })
                end
                if scene.placementMode == placementModes.effect then
                    effectPlacementDialog({time = scene.lastNoteTime, data = {}, type = ""}, false)
                end
            elseif not scene.scrollbarGrab then
                for i,note in ipairs(scene.selectedNotes) do
                    local A,B = math.min(note.lane, note.lane+(note.extra.dir or 0)),math.max(note.lane, note.lane+(note.extra.dir or 0))
                    if note.type == "swap" then
                        A,B = math.min(note.lane, note.lane-(note.extra.dir or 0)),math.max(note.lane, note.lane-(note.extra.dir or 0))
                    end
        
                    local C,D = note.time-0.05,note.time+note.length+0.05
                    if (scene.lastNoteLane >= A and scene.lastNoteLane <= B) and (scene.lastNoteTime >= C and scene.lastNoteTime <= D) then
                        scene.selection.dragging = true
                        scene.selection.start = {scene.lastNoteLane, scene.lastNoteTime}
                        scene.selection.stop = {scene.lastNoteLane, scene.lastNoteTime}
                        break
                    end
                end

                if not scene.selection.dragging then
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
            local drawPos = chartPos+chartHeight-(change.time - scene.chartTimeTemp)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local txt = change.bpm .. " BPM ▷"
            local w = 8*#txt
            
            local X,Y = chartX*8-24 - w, drawPos*16-24
            if x >= X and x < X+w and y >= Y-16 and y < Y+16+16 then
                table.remove(scene.chart.bpmChanges or {}, i)
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                end
                return
            end
        end


        local effectPos = {}
        for i,effect in ipairs(scene.chart.effects or {}) do
            local drawPos = chartPos+chartHeight-(effect.time - scene.chartTimeTemp)*speed+((ViewOffset or 0)+(ViewOffsetFreeze or 0))*(ScrollSpeed or 25)*(ScrollSpeedMod or 1)
            local samePos = math.floor(drawPos*2)
            local eX = effectPos[samePos] or 0
            local txt = "¤"
            local w = 8
            effectPos[samePos] = eX + 1
            
            local X,Y = chartX*8+136 + (eX*12) - w, drawPos*16-24
            if x >= X and x < X+w and y >= Y-8 and y < Y+16+8 then
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

            local C,D = note.time-0.05,note.time+note.length+0.05
            if (scene.lastNoteLane >= A and scene.lastNoteLane <= B) and (scene.lastNoteTime >= C and scene.lastNoteTime <= D) then
                table.remove(scene.chart.notes, i)
                for _=1,8 do
                    table.insert(Particles, {x = x, y = y, vx = (love.math.random()*2-1)*64, vy = (love.math.random()*2-1)*64, life = (love.math.random()*0.5+0.5)*0.25, color = ColorID.RED, char = "¤"})
                end
                scene.lastRating = scene.chart:getDifficulty()
                break
            end
        end
    end
end

local function aabb(x1,y1,w1,h1, x2,y2,w2,h2)
    return
        x1 <= x2+w2 and
        x2 <= x1+w1 and
        y1 <= y2+h2 and
        y2 <= y1+h1
end

function scene.mousereleased(x,y,b)
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
end

return scene