-- Reads RestedXP's own data (its steps, its arrow, its menus) and turns it into plain tables the rest of this addon
-- speaks and shows. RestedXP keeps everything in a private table; it registers itself with AceAddon under the name
-- "RXPGuides" and also leaves it as the global RXP, which is how this addon reaches it. Every function takes that
-- table, so the tests hand it a mock.
local ns = WowVision.restedXP
local L = ns.L
local Text = ns.Text

local Source = {}
ns.Source = Source

-- ---------------------------------------------------------------- the addon

function Source.rxp()
    local global = rawget(_G, "RXP")
    if type(global) == "table" and global.RXPFrame ~= nil then
        return global
    end
    local stub = rawget(_G, "LibStub")
    if stub ~= nil then
        local ok, registry = pcall(stub, "AceAddon-3.0", true)
        if ok and registry ~= nil and registry.GetAddon ~= nil then
            local found = registry:GetAddon("RXPGuides", true)
            if type(found) == "table" and found.RXPFrame ~= nil then
                return found
            end
        end
    end
    return nil
end

-- ------------------------------------------------------------------ guide

-- RestedXP loads an empty placeholder guide while none is chosen.
local function realGuide(rxp)
    local guide = rxp.currentGuide
    if type(guide) ~= "table" or guide.empty or type(guide.steps) ~= "table" or #guide.steps == 0 then
        return nil
    end
    return guide
end

function Source.hasGuide(rxp)
    return realGuide(rxp) ~= nil
end

-- { name, subgroup, steps, step } for the guide being followed, nil when none is chosen.
function Source.guide(rxp)
    local guide = realGuide(rxp)
    if guide == nil then
        return nil
    end
    local name
    if type(rxp.GetGuideName) == "function" then
        local ok, value = pcall(rxp.GetGuideName, guide)
        if ok then
            name = value
        end
    end
    name = Text.plain(guide.title or name or guide.displayname or guide.name)
    local step = 1
    if type(rxp.GetGuideProgress) == "function" then
        local ok, value = pcall(rxp.GetGuideProgress, guide)
        if ok and tonumber(value) ~= nil then
            step = tonumber(value)
        end
    end
    return { name = name, subgroup = Text.plain(guide.subgroup), steps = #guide.steps, step = step }
end

-- --------------------------------------------------------------- the steps

-- The game's clock in seconds, nil where there is none.
function Source.now()
    if GetTime ~= nil then
        return GetTime()
    end
    return nil
end

-- What each line read as a moment ago. Working a line out asks RestedXP to resolve the creature names in it, which
-- it does through the game's tooltip; a screen that is rebuilt every frame would do that sixty times a second.
-- A line is read again when its text changes or after MEMO_SECONDS.
local MEMO_SECONDS = 2
local memo = setmetatable({}, { __mode = "k" })

-- A line of a step as the window shows it: the guide's text, localised, with the creature ids resolved.
function Source.elementText(rxp, element)
    local raw = element.text
    if type(raw) ~= "string" or raw == " " then
        return nil
    end
    local now = Source.now()
    if now ~= nil then
        local entry = memo[element]
        if entry ~= nil and entry.raw == raw and now - entry.time < MEMO_SECONDS then
            return entry.text or nil
        end
    end
    local text = Source.readElementText(rxp, raw)
    if now ~= nil then
        memo[element] = { raw = raw, text = text or false, time = now }
    end
    return text
end

function Source.readElementText(rxp, raw)
    local text = raw
    local get = type(rxp.locale) == "table" and rxp.locale.Get or nil
    if type(get) == "function" then
        local ok, value = pcall(get, raw)
        if ok and type(value) == "string" then
            text = value
        end
    end
    if type(rxp.ReplaceNpcIds) == "function" then
        local ok, value = pcall(rxp.ReplaceNpcIds, text)
        if ok and type(value) == "string" then
            text = value
        end
    end
    return Text.plain(text)
end

local function stepTitle(step)
    if step.tip then
        return Text.plain(step.title) or L["Tip"]
    end
    if step.sticky then
        return Text.plain(step.title)
    end
    return Text.plain(step.title) or (step.index ~= nil and string.format(L["Step %d"], step.index) or nil)
end

-- Whether a line is done now (read from RestedXP's element each time: the line itself is a snapshot).
local function lineDone(line)
    local element = line.element
    return not line.info and (element.completed == true or element.skip == true)
end
Source.isDone = lineDone

-- Whether the line's box can be changed now: it has none to tick, or RestedXP has not greyed it out.
function Source.isLocked(line)
    local button = line.button
    return button ~= nil and button.IsEnabled ~= nil and not button:IsEnabled()
end

-- The lines of one step: { element, number, text, info, done, optional, button }. number is the element's place in
-- the step (a lasting identity for the line); info is a line that only informs (it has no box to tick).
local function stepLines(rxp, step)
    local lines = {}
    for number, element in ipairs(step.elements or {}) do
        local text = Source.elementText(rxp, element)
        if text ~= nil then
            local frame = type(element.frame) == "table" and element.frame or nil
            local line = {
                element = element,
                number = number,
                text = text,
                info = element.textOnly == true,
                optional = element.optional == true,
                button = frame ~= nil and frame.button or nil,
            }
            line.done = lineDone(line)
            lines[#lines + 1] = line
        end
    end
    return lines
end

-- The steps the window shows now: { step, index, tip, title, lines }. A step the guide hides (hidewindow, hidetip)
-- or with nothing to read is left out.
function Source.activeSteps(rxp)
    local window = rxp.RXPFrame
    local active = type(window) == "table" and window.activeSteps or nil
    local result = {}
    if type(active) ~= "table" then
        return result
    end
    for _, step in ipairs(active) do
        if not (step.hidewindow or step.hidetip) then
            local lines = stepLines(rxp, step)
            if #lines > 0 then
                result[#result + 1] = {
                    step = step,
                    index = step.index,
                    tip = step.tip == true,
                    title = stepTitle(step),
                    lines = lines,
                }
            end
        end
    end
    return result
end

-- What a step reads as, for Text.step.
function Source.stepSpeech(entry)
    local lines = {}
    for _, line in ipairs(entry.lines) do
        lines[#lines + 1] = { text = line.text, done = line.done }
    end
    return Text.step(entry.title, lines)
end

-- Everything now active, one step after the other.
function Source.activeSpeech(rxp)
    local parts = {}
    for _, entry in ipairs(Source.activeSteps(rxp)) do
        parts[#parts + 1] = Source.stepSpeech(entry)
    end
    return table.concat(parts, ". ")
end

-- The steps after the current one, the next `count` the window would list: { index, title, lines }.
function Source.upcoming(rxp, count, playerLevel)
    local guide = realGuide(rxp)
    local result = {}
    if guide == nil then
        return result
    end
    local current = Source.guide(rxp).step
    for index = current + 1, #guide.steps do
        if #result >= count then
            break
        end
        local step = guide.steps[index]
        local hidden = step.hidewindow or step.hidetip or step.optional or step.tip
            or (playerLevel ~= nil and (tonumber(step.level) or 0) > playerLevel)
        if not hidden then
            local lines = stepLines(rxp, step)
            if #lines > 0 then
                local entry = { step = step, index = index, title = stepTitle(step), lines = lines }
                result[#result + 1] = entry
            end
        end
    end
    return result
end

-- ----------------------------------------------------------- doing things

-- Ticks or unticks a line's box, the way a click on it does (RestedXP's own handler does the rest). A box the guide
-- ticked by itself is greyed and stays. Returns true when the line now has the wanted state.
function Source.setLine(rxp, line, wanted)
    if line.info or line.optional then
        return false
    end
    local button = line.button
    if button ~= nil then
        if Source.isLocked(line) then
            return false
        end
        if (button:GetChecked() and true or false) == wanted then
            return true
        end
        button:SetChecked(wanted)
        if type(rxp.ActiveStepElementPostClick) == "function" then
            rxp.ActiveStepElementPostClick(button)
            return true
        end
    end
    -- No box to click (the window is not showing it): do what the click would.
    local element = line.element
    if wanted then
        if type(rxp.SetElementComplete) ~= "function" then
            return false
        end
        rxp.SetElementComplete(element)
    else
        element.skip = false
        element.completed = false
        rxp.updateSteps = true
        if type(rxp.UpdateMap) == "function" then
            rxp.UpdateMap()
        end
    end
    return true
end

-- Ticks every box of the steps now shown that is not ticked: RestedXP then moves on by itself. Returns how many.
function Source.skipActive(rxp)
    local count = 0
    for _, entry in ipairs(Source.activeSteps(rxp)) do
        if not entry.tip then
            for _, line in ipairs(entry.lines) do
                if not line.done and Source.setLine(rxp, line, true) then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- Goes to a step of the guide (1 to the last). Returns the step it went to, nil without a guide.
function Source.goToStep(rxp, step)
    local info = Source.guide(rxp)
    if info == nil or type(rxp.SetStep) ~= "function" then
        return nil
    end
    step = math.floor(tonumber(step) or 1)
    if step < 1 then
        step = 1
    elseif step > info.steps then
        step = info.steps
    end
    rxp.SetStep(step)
    return step
end

-- --------------------------------------------------------------- the arrow

local function arrowTitle(element)
    if element.title ~= nil then
        return Text.plain(element.title)
    end
    local step = element.step
    if type(step) ~= "table" then
        return nil
    end
    local title = step.arrowtext or step.title
    if title == nil and step.index ~= nil then
        title = string.format(L["Step %d"], step.index)
    end
    return Text.plain(title)
end

-- The arrow's destination: { none } without one, else { title, wx, wy, instance, otherContinent, distance,
-- degrees }. wx and wy are HereBeDragons' world coordinates; distance (yards) and degrees (see
-- Text.relativeDegrees) are there when the player's position and facing are known. hbd is HereBeDragons-2.0,
-- facing is GetPlayerFacing().
function Source.arrow(rxp, hbd, facing)
    local frame = rxp.arrowFrame
    local element = type(frame) == "table" and frame.element or nil
    if type(element) ~= "table" or type(element.wx) ~= "number" or type(element.wy) ~= "number" then
        return { none = true }
    end
    local info = {
        element = element,
        title = arrowTitle(element),
        wx = element.wx,
        wy = element.wy,
        instance = element.instance,
        otherContinent = frame.wrongContinent == true,
    }
    if hbd ~= nil and not info.otherContinent then
        local x, y, instance = hbd:GetPlayerWorldPosition()
        if x ~= nil and y ~= nil then
            local angle, distance = hbd:GetWorldVector(instance, x, y, element.wx, element.wy)
            info.distance = distance
            if angle ~= nil and facing ~= nil then
                info.degrees = Text.relativeDegrees(angle, facing)
            end
        end
    end
    return info
end

-- ------------------------------------------------------------------ menus

-- RestedXP's right-click menu as a list of items (the same table the drop-down shows), rebuilt first so it matches
-- the guides and settings of the moment.
function Source.menu(rxp)
    local window = rxp.RXPFrame
    if type(window) ~= "table" then
        return nil
    end
    if type(window.GenerateMenuTable) == "function" then
        -- RestedXP calls it without self; it keeps its result in RXPFrame.menuList
        pcall(window.GenerateMenuTable)
    end
    return window.menuList
end

-- ------------------------------------------------- active items and targets

local function global(name)
    return rawget(_G, name)
end
Source.global = global

local function isShown(frame)
    return type(frame) == "table" and frame.IsShown ~= nil and frame:IsShown()
end

-- The buttons RestedXP shows for the items to use now: { frame, label }.
function Source.activeItems()
    local result = {}
    for index = 1, 12 do
        local button = global("RXPItemFrameButton" .. index)
        if button == nil then
            break
        end
        if isShown(button) then
            local label = Text.plain(button.name)
            if label == nil and button.itemId ~= nil and GetItemInfo ~= nil then
                label = Text.plain((GetItemInfo(button.itemId)))
            end
            result[#result + 1] = { frame = button, label = label or string.format(L["Item %d"], index) }
        end
    end
    return result
end

-- The buttons for the creatures to target: kind is "Enemy" or "Friendly". { frame, label }.
function Source.activeTargets(kind)
    local result = {}
    for index = 1, 12 do
        local button = global("RXPTargetFrame_" .. kind .. "Button" .. index)
        if button == nil then
            break
        end
        if isShown(button) then
            local data = button.targetData
            local label = type(data) == "table" and Text.plain(data.name) or nil
            result[#result + 1] = { frame = button, label = label or string.format(L["Target %d"], index) }
        end
    end
    return result
end
