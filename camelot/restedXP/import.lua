-- Importing guides. RestedXP's "Import guide" window is a paste box, an Import button, a list of the guides already
-- imported with Delete and Purge buttons, and a Reload button. It cannot be used from here as it is, so this reads
-- what RestedXP's importer knows, does what its buttons do through its own functions, and says what it reports.
-- The paste goes through RestedXP's own box: that box takes the characters one by one as they arrive, which is what
-- keeps even a huge text out of an edit box, so the text is never put in one of ours. No game calls here but
-- RestedXP's own and the two globals it keeps (RXPData, for Battle.net).
local ns = WowVision.restedXP
local L = ns.L
local Text = ns.Text

local unpack = unpack or table.unpack

local Import = {}
ns.Import = Import

-- ------------------------------------------------------------------ reading

-- RestedXP's importer module, nil when this RestedXP has none.
function Import.importer(rxp)
    local importer = type(rxp) == "table" and rxp.guideImporter or nil
    if type(importer) ~= "table" or type(importer.Open) ~= "function" or type(importer.Validate) ~= "function" then
        return nil
    end
    return importer
end

local function widgets(importer)
    local list = importer.widgets
    if type(list) == "table" then
        return list
    end
    return {}
end

local function isShown(frame)
    if type(frame) ~= "table" or type(frame.IsShown) ~= "function" then
        return false
    end
    local ok, value = pcall(frame.IsShown, frame)
    return ok and value == true
end

-- A message of the importer as one spoken sentence: its lines joined, no colour codes, no full stop at the end of a
-- line. nil when nothing is left.
function Import.sentence(message)
    if message == nil then
        return nil
    end
    local parts = {}
    for line in tostring(message):gmatch("[^\n]+") do
        local text = Text.plain(line)
        if text ~= nil then
            text = text:gsub("%.+$", "")
            if text ~= "" then
                parts[#parts + 1] = text
            end
        end
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ". ")
end

-- What the importer holds now:
--   characters: how long the pasted text is; ready: a text waits to be imported
--   busy: an import is running; connected: Battle.net answered (RestedXP checks it before it imports)
--   current, total: guides loaded so far in the import that runs or ran; failed: that import ended on an error
--   last: the latest message of the importer, as a sentence
-- nil when there is no importer.
function Import.state(rxp)
    local importer = Import.importer(rxp)
    if importer == nil then
        return nil
    end
    local cache = type(importer.importCache) == "table" and importer.importCache or {}
    local buffer = cache.bufferString
    local characters = type(buffer) == "string" and #buffer or 0
    local gui = type(importer.gui) == "table" and importer.gui or {}
    local data = rawget(_G, "RXPData")
    local state = {
        characters = characters,
        ready = importer.importReady == true and characters > 0,
        busy = importer.importCoroutine ~= nil or isShown(rxp.workerFrame),
        connected = type(data) == "table" and data.cache ~= nil,
        failed = gui.progressError == true,
    }
    local current, total = tostring(gui.progressMessage or ""):match("(%d+)/(%d+)")
    state.current, state.total = tonumber(current), tonumber(total)
    local history = gui.importStatusHistory
    if type(history) == "table" and history[1] ~= nil then
        state.last = Import.sentence(history[1])
    end
    return state
end

-- Why an action is not possible, as a sentence. "failed" is not here: the importer says its own error.
function Import.why(reason)
    if reason == "missing" then
        return L["RestedXP has no guide importer."]
    elseif reason == "busy" then
        return L["An import is already running."]
    elseif reason == "closed" then
        return L["RestedXP's import window cannot be opened now."]
    elseif reason == "nothing" then
        return L["Nothing has been pasted yet. Paste a guide string first."]
    elseif reason == "offline" then
        return L["RestedXP cannot reach Battle.net, so it cannot import guides now. Close the game, restart Battle.net and try again."]
    end
    return nil
end

-- Where the import stands, as a sentence.
function Import.statusText(rxp)
    local state = Import.state(rxp)
    if state == nil then
        return L["RestedXP has no guide importer."]
    end
    if state.busy then
        if state.current ~= nil and state.total ~= nil then
            return string.format(L["Importing: %d of %d guides loaded."], state.current, state.total)
        end
        return L["Importing the guides."]
    end
    if not state.connected then
        return Import.why("offline")
    end
    if state.ready then
        return string.format(L["%d characters pasted, ready to import."], state.characters)
    end
    return L["Nothing pasted yet."]
end

-- ------------------------------------------------------------------ doing

-- Gets the paste box under the keyboard: RestedXP's window is opened (its box has to be shown to take the keys)
-- and the box is focused. The player then pastes with Ctrl+V; RestedXP takes the text a tenth of a second after the
-- last character and lets go of the keyboard. Returns true, or false and a reason for Import.why.
function Import.beginPaste(rxp)
    local importer = Import.importer(rxp)
    if importer == nil then
        return false, "missing"
    end
    local state = Import.state(rxp)
    if state.busy then
        return false, "busy"
    end
    if not pcall(importer.Open, importer) then
        return false, "closed"
    end
    local box = widgets(importer).importBox
    if type(box) ~= "table" or type(box.GetEditBox) ~= "function" then
        return false, "closed"
    end
    local _, editBox = pcall(box.GetEditBox, box)
    if type(editBox) ~= "table" then
        return false, "closed"
    end
    if not pcall(editBox.SetFocus, editBox) then
        return false, "closed"
    end
    return true
end

-- What the Import button does: reads the pasted text and loads the guides in it (a little at a time, over the next
-- frames). Returns true, or false and a reason. "failed": the importer refused the text and has said why (its
-- message comes along); "error": its code failed (the error comes along).
function Import.run(rxp)
    local importer = Import.importer(rxp)
    if importer == nil then
        return false, "missing"
    end
    local state = Import.state(rxp)
    if state.busy then
        return false, "busy"
    end
    if not state.ready then
        return false, "nothing"
    end
    if not state.connected then
        -- RestedXP asks Battle.net again when it has no answer
        if type(importer.CheckBattleNet) == "function" then
            pcall(importer.CheckBattleNet, importer)
        end
        if not Import.state(rxp).connected then
            return false, "offline"
        end
    end
    local list = widgets(importer)
    if list.importButton == nil or list.importBox == nil then
        return false, "closed"
    end
    local ok, result = pcall(importer.Validate, importer)
    if not ok then
        return false, "error", tostring(result)
    end
    if type(result) == "string" then
        return false, "failed", result
    end
    return true
end

-- RestedXP's window is put away when the screen closes (it is shown only so that its box can be used).
function Import.hide(rxp)
    local importer = Import.importer(rxp)
    if importer == nil then
        return false
    end
    local window = widgets(importer).import
    if type(window) ~= "table" or type(window.Hide) ~= "function" then
        return false
    end
    local ok = pcall(window.Hide, window)
    return ok
end

local function refresh(importer)
    if type(importer.UpdateImportUI) == "function" then
        pcall(importer.UpdateImportUI, importer)
    end
end

-- The guides that came by import (or from RestedXP's saved copy of an import), sorted by place then name:
-- { key, name, place, version, label }. RestedXP's own list of them, as its drop-down shows.
function Import.guides(rxp)
    local list = {}
    if type(rxp) ~= "table" or type(rxp.guides) ~= "table" then
        return list
    end
    local settings = type(rxp.settings) == "table" and rxp.settings.profile or nil
    local debugging = type(settings) == "table" and settings.debug
    for _, guide in pairs(rxp.guides) do
        if
            type(guide) == "table"
            and (guide.imported or guide.cache)
            and (guide.group ~= "RXPGuides" or debugging)
            and type(guide.key) == "string"
        then
            local group, subgroup, name = guide.key:match("^(.*)|(.*)|(.*)")
            if group ~= nil then
                if subgroup ~= "" then
                    group = group .. "/" .. subgroup
                end
                local entry = {
                    key = guide.key,
                    name = Text.plain(name) or name,
                    place = Text.plain(group) or group,
                    version = guide.version,
                }
                if entry.version ~= nil then
                    entry.label = string.format(L["%s, in %s, version %s"], entry.name, entry.place, tostring(entry.version))
                else
                    entry.label = string.format(L["%s, in %s"], entry.name, entry.place)
                end
                list[#list + 1] = entry
            end
        end
    end
    table.sort(list, function(a, b)
        if a.place ~= b.place then
            return a.place:lower() < b.place:lower()
        end
        if a.name ~= b.name then
            return a.name:lower() < b.name:lower()
        end
        return a.key < b.key
    end)
    return list
end

-- What the Delete button does: the guide leaves RestedXP's lists. RestedXP's button also clears the saved copy under
-- the guide's key, but the saved copies are kept under that key followed by a number, so the copies that name this
-- guide are cleared here too: otherwise it comes back at the next reload.
function Import.remove(rxp, key)
    local importer = Import.importer(rxp)
    if importer == nil or type(key) ~= "string" or type(rxp.RemoveGuide) ~= "function" then
        return false
    end
    local ok, removed = pcall(rxp.RemoveGuide, key)
    if not ok or not removed then
        return false
    end
    local profile = type(rxp.db) == "table" and rxp.db.profile or nil
    local saved = type(profile) == "table" and profile.guides or nil
    if type(saved) == "table" then
        local doomed = {}
        for savedKey, copy in pairs(saved) do
            if savedKey == key or (type(copy) == "table" and copy.key == key) then
                doomed[#doomed + 1] = savedKey
            end
        end
        for _, savedKey in ipairs(doomed) do
            saved[savedKey] = nil
        end
    end
    if type(importer.gui) == "table" then
        importer.gui.selectedDeleteGuide = ""
    end
    refresh(importer)
    return true
end

-- What the Purge button does: every saved guide goes, and with them what RestedXP keeps about the quests that were
-- skipped or put first (its own purge does the same).
function Import.purge(rxp)
    local importer = Import.importer(rxp)
    local profile = type(rxp) == "table" and type(rxp.db) == "table" and rxp.db.profile or nil
    if importer == nil or type(profile) ~= "table" then
        return false
    end
    profile.guides = {}
    local settings = type(rxp.settings) == "table" and rxp.settings.profile or nil
    if type(settings) == "table" then
        settings.skipQuest = {}
        settings.questPrio = {}
        settings.questPrioIndex = {}
    end
    profile.guideId = nil
    profile.guideLength = nil
    profile.guideContent = nil
    if type(rxp.CreateMetaDataTable) == "function" then
        pcall(rxp.CreateMetaDataTable, rxp, true)
    end
    refresh(importer)
    return true
end

-- --------------------------------------------------------------- announcing

-- What a message of the importer says out loud. `memory` keeps where the progress was last said, so that a long
-- import is said at the start and at each quarter, not once per guide.
function Import.announce(memory, message, isError, speak)
    local details, current, total = {}, nil, nil
    for line in tostring(message):gmatch("[^\n]+") do
        local done, count = line:match("(%d+)/(%d+)")
        if done ~= nil then
            current, total = tonumber(done), tonumber(count)
        else
            details[#details + 1] = line
        end
    end
    local text = Import.sentence(table.concat(details, "\n"))
    if text ~= nil then
        if isError then
            speak(string.format(L["Import error: %s"], text))
        else
            speak(text)
        end
    end
    if current == nil or total == nil then
        return
    end
    if isError then
        speak(string.format(L["%d of %d guides loaded."], current, total))
    elseif current == 0 then
        memory.quarter = 0
        speak(string.format(L["Importing %d guides."], total))
    elseif current < total then
        local quarter = math.floor(current * 4 / total)
        if quarter > (memory.quarter or 0) then
            memory.quarter = quarter
            speak(string.format(L["%d of %d guides loaded."], current, total))
        end
    end
end

-- The importer says its news out loud: the messages it keeps for its window (progress, errors, the end), and what
-- came of a paste. RestedXP calls these as methods of its importer module, so wrapping them is enough. Once only.
function Import.hook(rxp, speak)
    local importer = Import.importer(rxp)
    if
        importer == nil
        or importer.wowVisionHooked
        or type(importer.UpdateImportStatusHistory) ~= "function"
        or type(importer.ProcessBuffer) ~= "function"
    then
        return false
    end
    importer.wowVisionHooked = true
    local memory = {}
    local quiet = 0

    local status = importer.UpdateImportStatusHistory
    importer.UpdateImportStatusHistory = function(self, data, isError, ...)
        local result = { status(self, data, isError, ...) }
        if quiet == 0 and type(data) == "string" then
            local ok, message = pcall(string.format, data, ...)
            if not ok then
                message = data
            end
            pcall(Import.announce, memory, message, isError, speak)
        end
        return unpack(result)
    end

    -- RestedXP reports the size of a paste in its own words while it takes it; this says it in ours, once
    local process = importer.ProcessBuffer
    importer.ProcessBuffer = function(self, ...)
        quiet = quiet + 1
        local result = { pcall(process, self, ...) }
        quiet = quiet - 1
        if not result[1] then
            error(result[2], 0)
        end
        pcall(function()
            local state = Import.state(rxp)
            if state ~= nil and state.ready then
                speak(string.format(L["%d characters pasted. You can now import them."], state.characters))
            else
                speak(L["Nothing was pasted."])
            end
        end)
        return unpack(result, 2)
    end
    return true
end
