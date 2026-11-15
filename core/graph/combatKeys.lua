local graph = WowVision.graph

-- Menus in combat: the keys of WowVision's menus while the game is in combat lockdown.
--
-- Out of combat the graph host binds the menu keys (arrows, Tab, Enter...) to pooled secure buttons while a window is
-- open and lets them go when the last one closes (graph/Host.lua). The game refuses every binding change by addon
-- code in combat, so the host lets them go at combat start and the menus fall silent until the fight ends. Secure
-- code may still change the bindings of its own frame in combat (RestrictedFrames.lua, HANDLE:SetBindingClick and
-- HANDLE:ClearBinding), and it may call back into addon code (HANDLE:CallMethod, run insecure). So in combat one
-- secure frame holds the menu keys:
--   * a state driver on [combat] (the game's own SecureStateDriver) tells the frame when a fight begins and ends; it
--     takes the menu keys at once when a WowVision window was open as the fight began, and lets every key go after;
--   * a key that opens a WowVision window (a binding declared with opensWindow) takes the menu keys: its own secure
--     button carries a wrapper of this frame (SecureHandlerWrapScript), so the binding does what it always does and
--     the wrapper takes the keys before it, in the same key press;
--   * the close key (Escape) lets them go, so with no menu open every key keeps its game function;
--   * every menu key is handed to addon code by name (onKey below), where the graph does what it does out of combat.
-- The only thing the secure side decides is whether the menu keys are taken. It never needs to know what a key does.
--
-- Every key is the player's own: the WowVision keymaps, or for a menu key its own combat keymap ("In Combat: Up")
-- where one is set. They are written onto the frame out of combat (stage), on every rebind and setting change; a
-- change made in combat applies when the fight ends.
--
-- What cannot work in combat: an entry whose Enter or Backspace is a secure click of a game button (the click
-- button cannot be pointed at another frame in combat). Those say so (Host:combatKey).
local combatKeys = {}
graph.combatKeys = combatKeys

-- The menu keys taken while a menu is open: the graph host's navigation keymaps, the close key, and the focused
-- entry's own keys (Host:combatKey runs the entry's binding for a key where it has one, as out of combat).
combatKeys.MENU_KEYS = {
    "up",
    "down",
    "left",
    "right",
    "next",
    "previous",
    "nextWindow",
    "previousWindow",
    "home",
    "end",
    "contextMenu",
    "close",
    "leftClick",
    "rightClick",
    "tooltip",
}

-- The combat keymap of a menu key: its inputs replace the menu key's in combat when the player set any.
function combatKeys.combatKeymap(key)
    return "combat/" .. key
end

-- The inputs a key has in combat: its combat keymap's when set, else the keymap's own. Keyboard only: the controller
-- keeps its own router (core/ui/input/pad.lua).
function combatKeys.inputsFor(inputManager, key)
    local combat = inputManager:getBinding(combatKeys.combatKeymap(key))
    if combat ~= nil and #combat.inputs > 0 then
        return combat.inputs
    end
    local keymap = inputManager:getBinding(key)
    if keymap == nil then
        return {}
    end
    return keymap.inputs
end

-- The flat list written onto the secure frame: { input, action } per input, in the order of the given keys. An input
-- already taken by an earlier key is skipped (one key, one action).
function combatKeys.entries(inputManager, keys)
    local taken = {}
    local entries = {}
    for _, key in ipairs(keys) do
        for _, input in ipairs(combatKeys.inputsFor(inputManager, key)) do
            if not taken[input] then
                taken[input] = true
                tinsert(entries, { input = input, action = key })
            end
        end
    end
    return entries
end

-- The secure buttons of the bindings that open a WowVision window, as activated right now (one per input).
function combatKeys.openingFrames(inputManager)
    local frames = {}
    for _, binding in ipairs(inputManager.bindings.orderedBindings) do
        if binding.opensWindow then
            for _, activated in ipairs(binding.activated) do
                for _, frame in ipairs(activated.frames) do
                    tinsert(frames, frame)
                end
            end
        end
    end
    return frames
end

-- ---- the secure frame ----
--
-- Attributes: menu-n / menu-k<i> / menu-a<i> the staged inputs and their action names; rc-n / rc-k<i> the inputs of
-- the right click among them; enabled 1 or 0 (the setting); menuopen 1 when a WowVision window is open (kept current
-- out of combat, read as the fight begins); othersopen likewise for windows other than the mirrored ones, and others
-- its value in the fight (a window-opening key sets it, Escape clears it); fighting 1 in a fight with the setting on;
-- taken 1 while the menu keys are bound to the frame.
--
-- Mirrored lists (registerMirror below): a window whose entries need a secure action in combat (Backspace uses a bag
-- item) cannot have addon code point that action at the focused entry. So in such a list the secure side walks the
-- list itself and owns the position, and addon code only lands the window's focus where the secure side says
-- (onMirror). Per mirror m: m-n the entry count; m-v<i> what the secure use action gets for entry i ("" for nothing);
-- m-f<i> / m-l<i> the first and last entry of i's group (a bag: Tab goes from group to group); m-open 1 while its
-- window is open; m-start the entry focused as the fight begins (startmode names that mirror); m-p<i> 1 while entry
-- i's pick button points at its game button (armed out of combat, as the window laid its buttons out the last time);
-- m-trusted 1 when the window lays its buttons out the same on every opening (seen out of combat: then a pick button
-- is right for a window opened in the fight too); m-pickok 1 while the pick buttons hold in the fight (the window
-- was open as the fight began, or opened in it and trusted); mirror-n /
-- mirror-k<i> the mirrors' names; lc-n / lc-k<i> the left click's inputs. mode is the mirror
-- walked now ("" for none), idx its position. ok-n / ok-k<i> / ok-o<i> are the game's own keys that open a mirrored
-- window (the open-bags keys), bound in a fight to that mirror's opener button.

-- Bind the menu keys to the frame; in a mirrored list the right click goes to the secure use button.
combatKeys.TAKE = [[
    if self:GetAttribute("taken") == 1 then
        return
    end
    self:SetAttribute("taken", 1)
    for i = 1, self:GetAttribute("menu-n") or 0 do
        self:SetBindingClick(true, self:GetAttribute("menu-k" .. i), self, self:GetAttribute("menu-a" .. i))
    end
    local mode = self:GetAttribute("mode")
    if mode ~= nil and mode ~= "" then
        self:RunAttribute("_useKeys", true)
    end
]]

-- Let the menu keys go: they are the game's again.
combatKeys.RELEASE = [[
    if self:GetAttribute("taken") ~= 1 then
        return
    end
    self:SetAttribute("taken", 0)
    for i = 1, self:GetAttribute("menu-n") or 0 do
        self:ClearBinding(self:GetAttribute("menu-k" .. i))
    end
]]

-- The right click's inputs: to the secure use button (true) or back to the frame (false).
combatKeys.USE_KEYS = [[
    local on = ...
    local use = self:GetFrameRef("use")
    for i = 1, self:GetAttribute("rc-n") or 0 do
        local key = self:GetAttribute("rc-k" .. i)
        if on then
            self:SetBindingClick(true, key, use, "LeftButton")
        else
            self:SetBindingClick(true, key, self, "rightClick")
        end
    end
]]

-- Point the secure use button at the entry at the position (nothing outside a mirrored list), and the left click at
-- the entry's own game button: its pick button, a secure click of it, where one is armed (m-p<i>) and the fight's
-- layout of the window is the one it was armed for (m-pickok); else the left click is the frame's.
combatKeys.ARM = [[
    local use = self:GetFrameRef("use")
    local mode = self:GetAttribute("mode")
    local idx = self:GetAttribute("idx") or 1
    local value = nil
    local pick = nil
    if mode ~= nil and mode ~= "" then
        value = self:GetAttribute(mode .. "-v" .. idx)
        if self:GetAttribute(mode .. "-pickok") == 1 and self:GetAttribute(mode .. "-p" .. idx) == 1 then
            pick = "WowVisionCombatPick_" .. mode .. idx
        end
    end
    if value == "" then
        value = nil
    end
    -- in the entry's context menu Enter runs the chosen entry: the left click (the pick button) or the right (use)
    if self:GetAttribute("ctx") == 1 and self:GetAttribute("ctxi") == 2 then
        pick = value ~= nil and use:GetName() or nil
    end
    use:SetAttribute("item", value)
    if self:GetAttribute("taken") ~= 1 then
        return
    end
    for i = 1, self:GetAttribute("lc-n") or 0 do
        if pick ~= nil then
            self:SetBindingClick(true, self:GetAttribute("lc-k" .. i), pick, "LeftButton")
        else
            self:SetBindingClick(true, self:GetAttribute("lc-k" .. i), self, "leftClick")
        end
    end
]]

-- Walk a mirrored list from the entry given (the first when there is none or it is out of range); why is passed on
-- to addon code ("open", or "resume" as the fight begins).
combatKeys.ENTER = [[
    local mode, start, why = ...
    local count = self:GetAttribute(mode .. "-n") or 0
    if start == nil or start < 1 or start > count then
        start = 1
    end
    self:SetAttribute("mode", mode)
    self:SetAttribute("idx", start)
    self:SetAttribute(mode .. "-last", start)
    if self:GetAttribute("taken") == 1 then
        self:RunAttribute("_useKeys", true)
    else
        self:RunAttribute("_take")
    end
    self:RunAttribute("_arm")
    self:CallMethod("onMirror", mode, start, why)
]]

-- Ctrl-Tab in a fight with a mirrored window open: the secure side cycles the windows itself, so walking a list goes
-- on in the next. The ring: each open mirrored window in staged order, then one stop for WowVision's other windows
-- (others: they were open as the fight began or a window-opening key was pressed since). A mirrored window is
-- walked on from the entry it was left on (m-last). With no mirrored window open the key goes to addon code, which
-- cycles the windows as ever.
combatKeys.CYCLE = [[
    local step = ...
    local count = self:GetAttribute("mirror-n") or 0
    local mode = self:GetAttribute("mode")
    local current = count + 1
    for i = 1, count do
        if self:GetAttribute("mirror-k" .. i) == mode then
            current = i
        end
    end
    local direction = 1
    if step == "previousWindow" then
        direction = -1
    end
    local target = nil
    for k = 1, count do
        local position = (current - 1 + direction * k) % (count + 1) + 1
        if position <= count then
            local name = self:GetAttribute("mirror-k" .. position)
            if self:GetAttribute(name .. "-open") == 1 then
                target = name
                break
            end
        elseif self:GetAttribute("others") == 1 then
            target = ""
            break
        end
    end
    if target == nil then
        if mode == nil or mode == "" then
            self:CallMethod("onCombatKey", step)
        end
        return
    end
    self:SetAttribute("ctx", 0)
    if target == "" then
        self:RunAttribute("_leave")
        self:CallMethod("onCombatKey", "otherWindow")
        return
    end
    self:RunAttribute("_enter", target, self:GetAttribute(target .. "-last"), "open")
]]

-- Stop walking the mirrored list: the right click is the frame's again.
combatKeys.LEAVE = [[
    local mode = self:GetAttribute("mode")
    if mode == nil or mode == "" then
        return
    end
    self:SetAttribute("mode", "")
    self:SetAttribute("ctx", 0)
    if self:GetAttribute("taken") == 1 then
        self:RunAttribute("_useKeys", false)
    end
    self:RunAttribute("_arm")
]]

-- The fight begins (true) or ends (false). Ending lets every key go. Beginning binds the openers of the mirrored
-- windows, takes the menu keys when a window was open, and keeps walking a mirrored list that had the focus.
combatKeys.COMBAT = [[
    local fighting = ...
    self:ClearBindings()
    self:SetAttribute("taken", 0)
    self:SetAttribute("mode", "")
    self:SetAttribute("ctx", 0)
    self:RunAttribute("_arm")
    if not fighting or self:GetAttribute("enabled") ~= 1 then
        self:SetAttribute("fighting", 0)
        return
    end
    self:SetAttribute("fighting", 1)
    self:SetAttribute("others", self:GetAttribute("othersopen"))
    for i = 1, self:GetAttribute("ok-n") or 0 do
        self:SetBindingClick(true, self:GetAttribute("ok-k" .. i), self:GetAttribute("ok-o" .. i), "LeftButton")
    end
    for i = 1, self:GetAttribute("mirror-n") or 0 do
        local name = self:GetAttribute("mirror-k" .. i)
        local holds = self:GetAttribute(name .. "-open") == 1 or self:GetAttribute(name .. "-trusted") == 1
        self:SetAttribute(name .. "-pickok", holds and 1 or 0)
    end
    if self:GetAttribute("menuopen") == 1 then
        self:RunAttribute("_take")
    end
    local mode = self:GetAttribute("startmode")
    if mode ~= nil and mode ~= "" and self:GetAttribute(mode .. "-open") == 1 then
        self:RunAttribute("_enter", mode, self:GetAttribute(mode .. "-start"), "resume")
    end
]]

-- A menu key press, the action name as the button. Escape lets the menu keys go (and closes a mirrored window). In a
-- mirrored list the walking keys move the position here and addon code lands the focus; Enter, the tooltip and the
-- context menu go to addon code with the position; Ctrl-Tab leaves the list. Everything else goes to addon code.
combatKeys.CLICK = [[
    local mode = self:GetAttribute("mode")
    if mode == "" then
        mode = nil
    end
    if button == "close" and not (mode ~= nil and self:GetAttribute("ctx") == 1) then
        self:SetAttribute("ctx", 0)
        if mode ~= nil then
            self:SetAttribute(mode .. "-open", 0)
            self:SetAttribute(mode .. "-pickok", 0)
            self:RunAttribute("_leave")
            self:CallMethod("onMirror", mode, 0, "close")
        end
        self:SetAttribute("others", 0)
        self:RunAttribute("_release")
        self:CallMethod("onCombatKey", button)
        return
    end
    if mode ~= nil and self:GetAttribute("ctx") == 1 then
        -- the entry's context menu: two entries (left click, right click), Up and Down between them; Escape, Left or
        -- the context key close it; Ctrl-Tab closes it and leaves the list; Enter is bound to the chosen entry
        local ctxi = self:GetAttribute("ctxi") or 1
        if button == "up" or button == "home" then
            ctxi = 1
        elseif button == "down" or button == "end" then
            ctxi = 2
        elseif button == "close" or button == "left" or button == "contextMenu" then
            self:SetAttribute("ctx", 0)
            self:RunAttribute("_arm")
            self:CallMethod("onMirror", mode, self:GetAttribute("idx"), "contextClose")
            return
        elseif button == "nextWindow" or button == "previousWindow" then
            self:RunAttribute("_cycle", button)
            return
        elseif button == "leftClick" then
            -- reached only where the chosen entry has nothing armed
            self:CallMethod("onMirror", mode, self:GetAttribute("idx"), "leftClick")
            return
        else
            return
        end
        self:SetAttribute("ctxi", ctxi)
        self:RunAttribute("_arm")
        self:CallMethod("onMirror", mode, ctxi, "contextMove")
        return
    end
    if button == "nextWindow" or button == "previousWindow" then
        self:RunAttribute("_cycle", button)
        return
    end
    if mode ~= nil then
        if button == "contextMenu" then
            self:SetAttribute("ctx", 1)
            self:SetAttribute("ctxi", 1)
            self:RunAttribute("_arm")
            self:CallMethod("onMirror", mode, self:GetAttribute("idx"), "contextOpen")
            return
        elseif button == "leftClick" or button == "tooltip" then
            self:CallMethod("onMirror", mode, self:GetAttribute("idx"), button)
            return
        elseif button ~= "rightClick" then
            local count = self:GetAttribute(mode .. "-n") or 0
            if count == 0 then
                return
            end
            local i = self:GetAttribute("idx") or 1
            local first = self:GetAttribute(mode .. "-f" .. i) or 1
            local last = self:GetAttribute(mode .. "-l" .. i) or count
            local j = i
            if button == "down" then
                if i < last then
                    j = i + 1
                end
            elseif button == "up" then
                if i > first then
                    j = i - 1
                end
            elseif button == "home" then
                j = first
            elseif button == "end" then
                j = last
            elseif button == "next" then
                j = last + 1
                if j > count then
                    j = 1
                end
            elseif button == "previous" then
                j = first - 1
                if j < 1 then
                    j = count
                end
                j = self:GetAttribute(mode .. "-f" .. j) or j
            end
            self:SetAttribute("idx", j)
            self:SetAttribute(mode .. "-last", j)
            self:RunAttribute("_arm")
            self:CallMethod("onMirror", mode, j, button)
            return
        end
    end
    self:CallMethod("onCombatKey", button)
]]

-- The wrapper on a window-opening binding's button: in a fight, take the menu keys; the button then runs its own
-- action. owner is the secure frame.
combatKeys.OPENING = [[
    if owner:GetAttribute("fighting") == 1 then
        owner:SetAttribute("others", 1)
        owner:RunAttribute("_take")
    end
]]

-- The wrapper on a mirror's opener button (the game's own open-bags key in a fight): a closed window opens (the click
-- runs: a secure click of the game's own button) and its list is walked from the top; an open window not walked now
-- is only stepped into (the click is cancelled); the walked one closes (the click toggles it shut) and the keys go.
combatKeys.OPENER = [[
    if owner:GetAttribute("fighting") ~= 1 then
        return
    end
    local mode = self:GetAttribute("mirror")
    if owner:GetAttribute(mode .. "-open") == 1 then
        if owner:GetAttribute("mode") ~= mode then
            owner:RunAttribute("_enter", mode, 1, "open")
            return false
        end
        owner:SetAttribute(mode .. "-open", 0)
        owner:SetAttribute(mode .. "-pickok", 0)
        owner:RunAttribute("_leave")
        owner:RunAttribute("_release")
        owner:CallMethod("onMirror", mode, 0, "close")
        return
    end
    owner:SetAttribute(mode .. "-open", 1)
    owner:SetAttribute(mode .. "-pickok", owner:GetAttribute(mode .. "-trusted") == 1 and 1 or 0)
    owner:RunAttribute("_enter", mode, 1, "open")
]]

-- The wrapper on the use button and the pick buttons: run from the context menu, the menu closes (Enter is the slot's
-- own click again) and addon code reads the entry on. owner is the secure frame.
combatKeys.CONTEXT_DONE = [[
    if owner:GetAttribute("ctx") ~= 1 then
        return
    end
    owner:SetAttribute("ctx", 0)
    owner:RunAttribute("_arm")
    owner:CallMethod("onMirror", owner:GetAttribute("mode"), owner:GetAttribute("idx"), "contextDone")
]]

-- The state driver's handler: the frame's own COMBAT with the new state. The driver hands the state over as a number
-- where it reads as one (SecureStateDriver.lua, resolveDriver: tonumber(newValue) or newValue).
combatKeys.ON_STATE = [[
    self:GetFrameRef("keys"):RunAttribute("_combat", newstate == 1)
]]

local keysFrame = nil
local stagedOpen = nil
-- The keys or the window-opening buttons changed (a rebind, a module switched on or off, the setting): written on
-- the next update out of combat.
local dirty = true
local wrapped = {}

-- ---- the log ----
--
-- Always on (a test needs no command first): every fight's start and end, what the secure frame changes, every combat
-- key, and a little into each fight what the game runs on each combat key. WowVisionDump.combatKeys, the previous
-- session's in combatKeysBefore; /wv combatkeys prints the last lines.
local LOG_MAX = 300
local logLines = nil

local function log(text)
    if logLines == nil then
        WowVisionDump = WowVisionDump or {}
        if type(WowVisionDump.combatKeys) == "table" and #WowVisionDump.combatKeys > 0 then
            WowVisionDump.combatKeysBefore = WowVisionDump.combatKeys
        end
        logLines = {}
        WowVisionDump.combatKeys = logLines
    end
    tinsert(logLines, date("%H:%M:%S") .. " " .. text)
    if #logLines > LOG_MAX then
        table.remove(logLines, 1)
    end
    local host = WowVision.graphHost
    if host ~= nil and host.keyLog then
        print("WowVision combat keys: " .. text)
    end
end
combatKeys.log = log

local function lockdown()
    return InCombatLockdown() and "lockdown" or "no lockdown"
end

-- What the game runs on each staged combat key right now, one line.
local function bindingLine()
    local parts = {}
    for i = 1, keysFrame:GetAttribute("menu-n") or 0 do
        local input = keysFrame:GetAttribute("menu-k" .. i)
        tinsert(parts, input .. "=" .. tostring(GetBindingAction(input, true)))
    end
    return table.concat(parts, " ")
end

local function stateLine()
    return "fighting "
        .. tostring(keysFrame:GetAttribute("fighting"))
        .. ", taken "
        .. tostring(keysFrame:GetAttribute("taken"))
        .. ", menu open "
        .. tostring(keysFrame:GetAttribute("menuopen"))
        .. ", enabled "
        .. tostring(keysFrame:GetAttribute("enabled"))
        .. ", windows "
        .. #WowVision.graphHost.stacks
end

local function watch(keys, driver)
    keys:HookScript("OnAttributeChanged", function(_, name, value)
        if name == "taken" or name == "fighting" or name == "mode" then
            log(name .. " " .. tostring(value) .. " (" .. lockdown() .. ")")
        end
    end)
    driver:HookScript("OnAttributeChanged", function(_, name, value)
        if name == "state-combat" then
            log("state driver: combat " .. tostring(value) .. " (" .. lockdown() .. ")")
        end
    end)
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    -- the game's own keys that open a mirrored window may have moved
    events:RegisterEvent("UPDATE_BINDINGS")
    events:SetScript("OnEvent", function(_, event)
        if event == "UPDATE_BINDINGS" then
            combatKeys.stageMirrors()
        elseif event == "PLAYER_REGEN_DISABLED" then
            log("fight starts (" .. lockdown() .. "): " .. stateLine())
            C_Timer.After(0.3, function()
                log("in the fight (" .. lockdown() .. "): " .. stateLine())
                log("keys: " .. bindingLine())
            end)
        else
            log("fight ends: " .. stateLine())
        end
    end)
end

local function createFrames()
    local keys = CreateFrame("Button", "WowVisionCombatKeys", UIParent, "SecureHandlerClickTemplate")
    keys:RegisterForClicks("AnyDown")
    keys:SetAttribute("_take", combatKeys.TAKE)
    keys:SetAttribute("_release", combatKeys.RELEASE)
    keys:SetAttribute("_useKeys", combatKeys.USE_KEYS)
    keys:SetAttribute("_arm", combatKeys.ARM)
    keys:SetAttribute("_enter", combatKeys.ENTER)
    keys:SetAttribute("_leave", combatKeys.LEAVE)
    keys:SetAttribute("_cycle", combatKeys.CYCLE)
    keys:SetAttribute("_combat", combatKeys.COMBAT)
    keys:SetAttribute("_onclick", combatKeys.CLICK)
    keys.onCombatKey = function(_, action)
        combatKeys.onKey(action)
    end
    keys.onMirror = function(_, mode, index, why)
        combatKeys.onMirror(mode, index, why)
    end

    -- The use action of a mirrored list: the game's secure item action ("bag slot" uses that slot exactly as its right
    -- click does, SecureCmdUseItem). Bound by key down only, so it must act on the down click.
    local use = CreateFrame("Button", "WowVisionCombatUse", UIParent, "SecureActionButtonTemplate")
    use:RegisterForClicks("AnyDown")
    use:SetAttribute("useOnKeyDown", true)
    use:SetAttribute("type", "item")
    use:HookScript("PostClick", function(self)
        log("use " .. tostring(self:GetAttribute("item")))
    end)
    SecureHandlerSetFrameRef(keys, "use", use)
    SecureHandlerWrapScript(use, "OnClick", keys, combatKeys.CONTEXT_DONE)

    local driver = CreateFrame("Frame", "WowVisionCombatKeysDriver", UIParent, "SecureHandlerStateTemplate")
    SecureHandlerSetFrameRef(driver, "keys", keys)
    driver:SetAttribute("_onstate-combat", combatKeys.ON_STATE)
    watch(keys, driver)
    RegisterStateDriver(driver, "combat", "[combat] 1; 0")
    return keys
end

local function enabled()
    local ui = WowVision.base ~= nil and WowVision.base.ui or nil
    return ui == nil or ui.settings == nil or ui.settings.combatMenus ~= false
end
combatKeys.enabled = enabled

-- Write a numbered list of attributes: prefix-n, and per entry i each field as prefix-<letter><i>.
local function writeList(frame, prefix, entries, fields)
    local previous = frame:GetAttribute(prefix .. "-n") or 0
    for i, entry in ipairs(entries) do
        for letter, field in pairs(fields) do
            frame:SetAttribute(prefix .. "-" .. letter .. i, entry[field])
        end
    end
    for i = #entries + 1, previous do
        for letter in pairs(fields) do
            frame:SetAttribute(prefix .. "-" .. letter .. i, nil)
        end
    end
    frame:SetAttribute(prefix .. "-n", #entries)
end

-- Put the wrapper on the buttons of the window-opening bindings, and only on those: a rebind hands out the pooled
-- buttons afresh, so the old wrappers come off first.
local function wrapOpeningFrames()
    for frame in pairs(wrapped) do
        SecureHandlerUnwrapScript(frame, "OnClick")
    end
    wrapped = {}
    for _, frame in ipairs(combatKeys.openingFrames(WowVision.input)) do
        SecureHandlerWrapScript(frame, "OnClick", keysFrame, combatKeys.OPENING)
        wrapped[frame] = true
    end
end

-- ---- mirrored lists ----
--
-- registerMirror(def), def:
--   key        the mirror's name ("bags")
--   commands   the game's key bindings that open its window (OPENALLBAGS): their keys are bound in a fight to the
--              mirror's opener, a secure click of opener()
--   openers() the game's own buttons whose clicks open and close the window (every bag's own button)
--   trusted()  optional: the window lays its buttons out the same on every opening (seen so far this session)
--   fixedTargets  optional: clickTargets are fixed game frames, armed whether the window is open or not
--   entries()  the list in order: { value = what the secure use action gets ("" for nothing), group = any }; entries
--              of one group stand together (a bag), Tab goes between groups. Read out of combat only: the list
--              must not change in a fight.
--   isOpen()   whether the window is open
--   focusedIndex()  the entry the window's focus is on while it is the focused window, else nil
--   onMirror(index, why)  land the window's focus on entry index; why: "open", "resume" (the fight began on it), the
--              key that moved ("down", "next"...), the key handed over there ("leftClick", "tooltip"), or the
--              entry's context menu: "contextOpen", "contextMove" (index is then the menu entry: 1 left click,
--              2 right click), "contextClose", "contextDone" (an entry ran)
--   contextLabels(index)  { left = ..., right = ... }: the two context menu entries of entry index
--   onClose()  the walked window was closed in the fight: close what the opener's click did not (all the bags)
--   stack()    the window's stack while it is open, else nil (Ctrl-Tab tells it from WowVision's other windows)
--   clickTargets()  optional: entry index -> the game's own button of that entry as the open window lays it out now.
--              Enter on the entry in a fight is a secure click of it, while the window stays as it was when the
--              fight began.
combatKeys.mirrors = {}
local mirrorsByKey = {}
local mirrorsDirty = true
local stagedSignatures = {}
-- per mirror, entry index -> the game button its pick button points at
local pickTargets = {}
local openers = {}

function combatKeys.registerMirror(def)
    tinsert(combatKeys.mirrors, def)
    mirrorsByKey[def.key] = def
    mirrorsDirty = true
end

-- A mirror's list may have changed (a bag swapped): written on the next update out of combat, when it differs.
function combatKeys.stageMirrors()
    mirrorsDirty = true
end

-- The flat attributes of a mirror's list: value, first and last entry of its group.
function combatKeys.mirrorAttributes(list)
    local rows = {}
    local groupStart = 1
    for i, entry in ipairs(list) do
        if i > 1 and entry.group ~= list[i - 1].group then
            groupStart = i
        end
        rows[i] = { value = entry.value or "", first = groupStart }
    end
    local groupEnd = #list
    for i = #list, 1, -1 do
        if i < #list and list[i].group ~= list[i + 1].group then
            groupEnd = i
        end
        rows[i].last = groupEnd
    end
    return rows
end

local function opener(def)
    local button = openers[def.key]
    if button == nil then
        button = CreateFrame("Button", "WowVisionCombatOpen_" .. def.key, UIParent, "SecureActionButtonTemplate")
        button:RegisterForClicks("AnyDown")
        button:SetAttribute("useOnKeyDown", true)
        button:SetAttribute("type", "macro")
        button:SetAttribute("mirror", def.key)
        SecureHandlerWrapScript(button, "OnClick", keysFrame, combatKeys.OPENER)
        openers[def.key] = button
    end
    return button
end

-- The opener clicks the game's own buttons that open the window, one /click each (a secure macro: every bag's own
-- button where the bags are separate windows). Written when the buttons change.
local function updateOpener(def)
    local lines = {}
    for _, target in ipairs(def.openers()) do
        local name = target:GetName()
        if name ~= nil then
            tinsert(lines, "/click " .. name)
        end
    end
    local macro = table.concat(lines, "\n")
    local button = opener(def)
    if button:GetAttribute("macrotext") ~= macro then
        button:SetAttribute("macrotext", macro)
        log(def.key .. " opener: " .. #lines .. " buttons")
    end
end

local function writeMirrors()
    mirrorsDirty = false
    local openKeys = {}
    local names = {}
    for _, def in ipairs(combatKeys.mirrors) do
        tinsert(names, { name = def.key })
        pickTargets[def.key] = pickTargets[def.key] or {}
        local rows = combatKeys.mirrorAttributes(def.entries())
        local parts = {}
        for i, row in ipairs(rows) do
            parts[i] = row.value .. "/" .. row.first .. "/" .. row.last
        end
        local signature = table.concat(parts, ",")
        if stagedSignatures[def.key] ~= signature then
            stagedSignatures[def.key] = signature
            writeList(keysFrame, def.key, rows, { v = "value", f = "first", l = "last" })
            log("staged " .. def.key .. ": " .. #rows .. " entries")
        end
        updateOpener(def)
        local name = opener(def):GetName()
        for _, command in ipairs(def.commands) do
            for _, key in ipairs({ GetBindingKey(command) }) do
                tinsert(openKeys, { key = key, opener = name })
            end
        end
    end
    writeList(keysFrame, "ok", openKeys, { k = "key", o = "opener" })
    writeList(keysFrame, "mirror", names, { k = "name" })
end

-- The pick buttons: per mirror and entry a secure click of the entry's own game button, pointed out of combat at the
-- button the open window shows for it now (WowVisionCombatPick_<mirror><i>). Checked a few times a second while the
-- window is open; written only when a button changed.
local PICK_EVERY = 0.25
local nextPick = 0

local function pickButton(def, index)
    local name = "WowVisionCombatPick_" .. def.key .. index
    local button = _G[name]
    if button == nil then
        button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
        button:RegisterForClicks("AnyDown")
        button:SetAttribute("useOnKeyDown", true)
        button:SetAttribute("type", "click")
        SecureHandlerWrapScript(button, "OnClick", keysFrame, combatKeys.CONTEXT_DONE)
        local key, captured = def.key, index
        button:HookScript("PostClick", function()
            log("pick " .. key .. " " .. captured)
        end)
    end
    return button
end

local function tickPicks(def)
    if def.clickTargets == nil then
        return
    end
    local trusted = def.trusted ~= nil and def.trusted() and 1 or 0
    if keysFrame:GetAttribute(def.key .. "-trusted") ~= trusted then
        keysFrame:SetAttribute(def.key .. "-trusted", trusted)
        log(def.key .. " layout trusted " .. trusted)
    end
    updateOpener(def)
    -- Closed, the window keeps the buttons it laid out last; they stay the pick targets for its next opening. Fixed
    -- buttons (the equipment slots) are armed whether the window is open or not.
    if not def.fixedTargets and not def.isOpen() then
        return
    end
    local targets = pickTargets[def.key]
    local count = keysFrame:GetAttribute(def.key .. "-n") or 0
    local now = def.clickTargets()
    for index = 1, count do
        local target = now[index]
        if targets[index] ~= target then
            targets[index] = target
            local button = pickButton(def, index)
            button:SetAttribute("clickbutton", target)
            keysFrame:SetAttribute(def.key .. "-p" .. index, target ~= nil and 1 or 0)
        end
    end
end

-- Each update out of combat: whether each mirrored window is open, and the entry it is focused on.
-- Whether a stack is a mirrored window's.
function combatKeys.isMirrorStack(stack)
    for _, def in ipairs(combatKeys.mirrors) do
        if def.stack ~= nil and def.stack() == stack then
            return true
        end
    end
    return false
end

local function tickMirrors()
    local others = 0
    for _, stack in ipairs(WowVision.graphHost.stacks) do
        if not combatKeys.isMirrorStack(stack) then
            others = 1
        end
    end
    if keysFrame:GetAttribute("othersopen") ~= others then
        keysFrame:SetAttribute("othersopen", others)
    end
    local startMode = ""
    for _, def in ipairs(combatKeys.mirrors) do
        local open = def.isOpen() and 1 or 0
        if keysFrame:GetAttribute(def.key .. "-open") ~= open then
            keysFrame:SetAttribute(def.key .. "-open", open)
        end
        local index = open == 1 and def.focusedIndex() or nil
        if index ~= nil then
            startMode = def.key
            if keysFrame:GetAttribute(def.key .. "-start") ~= index then
                keysFrame:SetAttribute(def.key .. "-start", index)
            end
        end
    end
    if keysFrame:GetAttribute("startmode") ~= startMode then
        keysFrame:SetAttribute("startmode", startMode)
    end
    local now = GetTime()
    if now >= nextPick then
        nextPick = now + PICK_EVERY
        for _, def in ipairs(combatKeys.mirrors) do
            tickPicks(def)
        end
    end
end

-- ---- staging ----

-- The player's keys, the setting or the window-opening buttons changed: write them anew on the next update out of
-- combat (tick). Cheap, callable any time, also in combat.
function combatKeys.stage()
    dirty = true
end

local function writeStage()
    dirty = false
    mirrorsDirty = true
    if keysFrame == nil then
        keysFrame = createFrames()
    end
    local menu = combatKeys.entries(WowVision.input, combatKeys.MENU_KEYS)
    writeList(keysFrame, "menu", menu, { k = "input", a = "action" })
    local rightClick = {}
    for _, entry in ipairs(menu) do
        if entry.action == "rightClick" then
            tinsert(rightClick, entry)
        end
    end
    writeList(keysFrame, "rc", rightClick, { k = "input" })
    local leftClick = {}
    for _, entry in ipairs(menu) do
        if entry.action == "leftClick" then
            tinsert(leftClick, entry)
        end
    end
    writeList(keysFrame, "lc", leftClick, { k = "input" })
    keysFrame:SetAttribute("enabled", enabled() and 1 or 0)
    wrapOpeningFrames()
    local opening = 0
    for _ in pairs(wrapped) do
        opening = opening + 1
    end
    log("staged " .. #menu .. " menu keys, " .. opening .. " opening buttons, enabled " .. tostring(enabled()))
end

-- Every graph host update out of combat: write what changed, and whether a WowVision window is open, for the next
-- fight's start (written only when it changes).
function combatKeys.tick(open)
    if InCombatLockdown() then
        return
    end
    if dirty then
        writeStage()
    end
    if mirrorsDirty then
        writeMirrors()
    end
    tickMirrors()
    local value = open and 1 or 0
    if stagedOpen ~= value then
        stagedOpen = value
        keysFrame:SetAttribute("menuopen", value)
        log("menu open " .. value)
    end
end

-- Whether the menu keys are held by the secure frame right now.
function combatKeys.taken()
    return keysFrame ~= nil and keysFrame:GetAttribute("taken") == 1
end

-- Whether the graph runs in combat: the setting is on and the frame exists.
function combatKeys.active()
    return keysFrame ~= nil and enabled()
end

-- The game button entry index's pick button points at (the bags' layout check).
function combatKeys.pickTarget(key, index)
    local targets = pickTargets[key]
    return targets ~= nil and targets[index] or nil
end

-- The mirrored list walked right now, or nil.
function combatKeys.walking()
    if keysFrame == nil then
        return nil
    end
    local mode = keysFrame:GetAttribute("mode")
    return mode ~= "" and mode or nil
end

-- A menu key pressed in combat, by action name (from the secure frame).
function combatKeys.onKey(action)
    local L = WowVision:getLocale()
    local host = WowVision.graphHost
    log(action .. ", " .. #host.stacks .. " open")
    if action == "close" then
        -- A popup that waits in front is put aside to Pending, as Escape does out of combat (windows/pending.lua).
        local focused = host:focusedStack()
        if focused ~= nil and focused.config ~= nil and focused.config.waits and focused.config.onRequestClose then
            focused.config.onRequestClose(focused)
        end
        -- Quiet: WowVision's own windows play their closing sound.
        local remaining = WowVision.UIHost.windowManager:closeOwnWindows()
        if #remaining > 0 then
            log("still open: " .. #remaining)
        end
        return
    end
    if not host:isOpen() then
        WowVision:notify(L["No menu open, Escape gives the keys back"])
        return
    end
    if action == "otherWindow" then
        -- Ctrl-Tab from a mirrored window to WowVision's other windows (CYCLE)
        host:focusStack(function(stack)
            return not combatKeys.isMirrorStack(stack)
        end)
        return
    end
    host:combatKey(action)
end

-- Per mirror, the entry whose context menu is open.
local contextEntry = {}

-- A popup that waits opened in a fight while the menu keys are the game's: say which key lands on it, a moment after
-- the popup itself is read.
function combatKeys.hintMenuKey()
    if not combatKeys.active() or combatKeys.taken() then
        return
    end
    local binding = WowVision.input:getBinding("wowvision/menu")
    local input = binding ~= nil and binding.inputs[1] or nil
    if input == nil then
        return
    end
    local keyText = GetBindingText ~= nil and GetBindingText(input) or input
    C_Timer.After(1.5, function()
        if not combatKeys.taken() then
            WowVision:notify(WowVision:getLocale()["To answer, press"] .. " " .. keyText)
        end
    end)
end

-- The secure side moved in a mirrored list, or handed a key over there (from the secure frame).
function combatKeys.onMirror(mode, index, why)
    log(mode .. " " .. tostring(why) .. " " .. tostring(index))
    local def = mirrorsByKey[mode]
    if def == nil then
        return
    end
    if why == "close" then
        def.onClose()
        return
    end
    -- The entry's context menu lives on the secure side; it is spoken here, with no window of its own.
    if why == "contextOpen" or why == "contextMove" then
        if why == "contextOpen" then
            contextEntry[mode] = index
        end
        local labels = def.contextLabels(contextEntry[mode] or 1)
        local L = WowVision:getLocale()
        local chosen = (why == "contextOpen" or index == 1) and labels.left or labels.right
        WowVision.base.speech:uiStop()
        if why == "contextOpen" then
            WowVision.graphHost:_speak(L["Context Menu"] .. ", " .. chosen)
        else
            WowVision.graphHost:_speak(chosen)
        end
        return
    end
    if why == "contextClose" then
        def.onMirror(index, "reread")
        return
    end
    if why == "contextDone" then
        -- what the click did is heard from the entry itself (its label changes live)
        return
    end
    def.onMirror(index, why)
end

-- /wv combatkeys: the state of the secure frame and, per staged key, what the game runs on it now.
function combatKeys.report()
    if keysFrame == nil then
        print("WowVision combat keys: not set up yet")
        return
    end
    local function attr(name)
        return tostring(keysFrame:GetAttribute(name))
    end
    local recent = logLines or {}
    for i = math.max(1, #recent - 14), #recent do
        print(recent[i])
    end
    print(
        "WowVision combat keys: enabled "
            .. attr("enabled")
            .. ", fighting "
            .. attr("fighting")
            .. ", taken "
            .. attr("taken")
            .. ", menu open "
            .. attr("menuopen")
            .. ", opening buttons "
            .. #combatKeys.openingFrames(WowVision.input)
            .. (dirty and ", changes waiting for the end of the fight" or "")
    )
    for i = 1, keysFrame:GetAttribute("menu-n") or 0 do
        local input = keysFrame:GetAttribute("menu-k" .. i)
        print(input .. ": " .. tostring(GetBindingAction(input, true)))
    end
end
