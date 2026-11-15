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
-- button cannot be pointed at another frame in combat). Those say so (Host:combatAction).
local combatKeys = {}
graph.combatKeys = combatKeys

-- The menu keys taken while a menu is open: the graph host's navigation keymaps, the close key, and the focused
-- entry's keys that addon code answers (the clicks run the entry's own Function binding, the tooltip reads it).
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
-- Attributes: menu-n / menu-k<i> / menu-a<i> the staged inputs and their action names; enabled 1 or 0 (the setting);
-- menuopen 1 when a WowVision window is open (kept current out of combat, read as the fight begins); fighting 1 in a
-- fight with the setting on; taken 1 while the menu keys are bound to the frame.

-- Bind the menu keys to the frame.
combatKeys.TAKE = [[
    if self:GetAttribute("taken") == 1 then
        return
    end
    self:SetAttribute("taken", 1)
    for i = 1, self:GetAttribute("menu-n") or 0 do
        self:SetBindingClick(true, self:GetAttribute("menu-k" .. i), self, self:GetAttribute("menu-a" .. i))
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

-- The fight begins (true) or ends (false). Ending lets every key go.
combatKeys.COMBAT = [[
    local fighting = ...
    self:ClearBindings()
    self:SetAttribute("taken", 0)
    if not fighting or self:GetAttribute("enabled") ~= 1 then
        self:SetAttribute("fighting", 0)
        return
    end
    self:SetAttribute("fighting", 1)
    if self:GetAttribute("menuopen") == 1 then
        self:RunAttribute("_take")
    end
]]

-- A menu key press, the action name as the button: Escape lets the menu keys go; addon code then does what the key
-- does.
combatKeys.CLICK = [[
    if button == "close" then
        self:RunAttribute("_release")
    end
    self:CallMethod("onCombatKey", button)
]]

-- The wrapper on a window-opening binding's button: in a fight, take the menu keys; the button then runs its own
-- action. owner is the secure frame.
combatKeys.OPENING = [[
    if owner:GetAttribute("fighting") == 1 then
        owner:RunAttribute("_take")
    end
]]

-- The state driver's handler: the frame's own COMBAT with the new state.
combatKeys.ON_STATE = [[
    self:GetFrameRef("keys"):RunAttribute("_combat", newstate == "1")
]]

local keysFrame = nil
local stagedOpen = nil
-- The keys or the window-opening buttons changed (a rebind, a module switched on or off, the setting): written on
-- the next update out of combat.
local dirty = true
local wrapped = {}

local function createFrames()
    local keys = CreateFrame("Button", "WowVisionCombatKeys", UIParent, "SecureHandlerClickTemplate")
    keys:RegisterForClicks("AnyDown")
    keys:SetAttribute("_take", combatKeys.TAKE)
    keys:SetAttribute("_release", combatKeys.RELEASE)
    keys:SetAttribute("_combat", combatKeys.COMBAT)
    keys:SetAttribute("_onclick", combatKeys.CLICK)
    keys.onCombatKey = function(_, action)
        combatKeys.onKey(action)
    end

    local driver = CreateFrame("Frame", "WowVisionCombatKeysDriver", UIParent, "SecureHandlerStateTemplate")
    SecureHandlerSetFrameRef(driver, "keys", keys)
    driver:SetAttribute("_onstate-combat", combatKeys.ON_STATE)
    RegisterStateDriver(driver, "combat", "[combat] 1; 0")
    return keys
end

local function enabled()
    local ui = WowVision.base ~= nil and WowVision.base.ui or nil
    return ui == nil or ui.settings == nil or ui.settings.combatMenus ~= false
end
combatKeys.enabled = enabled

local function writeList(frame, prefix, entries, previous)
    for i, entry in ipairs(entries) do
        frame:SetAttribute(prefix .. "-k" .. i, entry.input)
        frame:SetAttribute(prefix .. "-a" .. i, entry.action)
    end
    for i = #entries + 1, previous or 0 do
        frame:SetAttribute(prefix .. "-k" .. i, nil)
        frame:SetAttribute(prefix .. "-a" .. i, nil)
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

-- The player's keys, the setting or the window-opening buttons changed: write them anew on the next update out of
-- combat (tick). Cheap, callable any time, also in combat.
function combatKeys.stage()
    dirty = true
end

local function writeStage()
    dirty = false
    if keysFrame == nil then
        keysFrame = createFrames()
    end
    local menu = combatKeys.entries(WowVision.input, combatKeys.MENU_KEYS)
    writeList(keysFrame, "menu", menu, keysFrame:GetAttribute("menu-n"))
    keysFrame:SetAttribute("enabled", enabled() and 1 or 0)
    wrapOpeningFrames()
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
    local value = open and 1 or 0
    if stagedOpen ~= value then
        stagedOpen = value
        keysFrame:SetAttribute("menuopen", value)
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

local function log(text)
    local host = WowVision.graphHost
    if host ~= nil and host.keyLog then
        print("WowVision combat keys: " .. text)
    end
end

-- A menu key pressed in combat, by action name (from the secure frame).
function combatKeys.onKey(action)
    local L = WowVision:getLocale()
    local host = WowVision.graphHost
    log(action .. ", " .. #host.stacks .. " open")
    if action == "close" then
        local remaining = WowVision.UIHost.windowManager:closeOwnWindows()
        if #remaining == 0 then
            WowVision:notify(L["Menus closed"])
        else
            WowVision:notify(L["Menus closed, still open"] .. ": " .. table.concat(remaining, ", "))
        end
        return
    end
    if not host:isOpen() then
        WowVision:notify(L["No menu open, Escape gives the keys back"])
        return
    end
    if action == "leftClick" or action == "rightClick" or action == "tooltip" then
        host:combatAction(action)
        return
    end
    host:onKey(action)
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
