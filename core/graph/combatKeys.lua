local graph = WowVision.graph

-- Menus in combat: the keys of WowVision's menus while the game is in combat lockdown.
--
-- Out of combat the graph host binds the menu keys (arrows, Tab, Enter...) to pooled secure buttons while a window is
-- open and lets them go when the last one closes (graph/Host.lua). The game refuses every binding change by addon
-- code in combat, so the host lets them go at combat start and the menus fall silent until the fight ends. Secure
-- code may still change the bindings of its own frame in combat (RestrictedFrames.lua, HANDLE:SetBindingClick and
-- HANDLE:ClearBinding), and it may call back into addon code (HANDLE:CallMethod, run insecure). So in combat one
-- secure frame holds the keys:
--   * a state driver on [combat] (the game's own SecureStateDriver) binds the opening keys (the WowVision menu key)
--     to the frame for the whole fight, and takes the menu keys too when a menu was open as the fight began;
--   * an opening key takes the menu keys; the close key (Escape) lets them go, so with no menu open every key keeps
--     its game function;
--   * every key is handed to addon code by name (onKey below), where the graph does what it does out of combat.
-- The only thing the secure side decides is whether the menu keys are taken. It never needs to know what a key does.
--
-- Every key is the player's own: the WowVision keymaps (the menu keys, and the WowVision menu key), or for a menu
-- key its own combat keymap ("In Combat: Up") where one is set. They are written onto the frame out of combat
-- (stage), on every rebind and setting change; a change made in combat applies when the fight ends.
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

-- The keys that open a menu, held the whole fight: each is a WowVision Function binding whose own func runs.
combatKeys.OPEN_KEYS = {
    "wowvision/menu",
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
function combatKeys.entries(inputManager, keys, taken)
    taken = taken or {}
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

-- ---- the secure frame ----
--
-- Attributes: menu-n / menu-k<i> / menu-a<i> and open-n / open-k<i> / open-a<i> the staged inputs and their action
-- names; enabled 1 or 0 (the setting); menuopen 1 when a WowVision window is open (kept current out of combat, read
-- as the fight begins); taken 1 while the menu keys are bound to the frame.

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

-- The fight begins (true) or ends (false). Ending clears everything the frame bound.
combatKeys.COMBAT = [[
    local fighting = ...
    self:ClearBindings()
    self:SetAttribute("taken", 0)
    if not fighting or self:GetAttribute("enabled") ~= 1 then
        return
    end
    for i = 1, self:GetAttribute("open-n") or 0 do
        self:SetBindingClick(true, self:GetAttribute("open-k" .. i), self, self:GetAttribute("open-a" .. i))
    end
    if self:GetAttribute("menuopen") == 1 then
        self:RunAttribute("_take")
    end
]]

-- A key press, the action name as the button: Escape lets the menu keys go, an opening key takes them; addon code
-- then does what the key does.
combatKeys.CLICK = [[
    if button == "close" then
        self:RunAttribute("_release")
    elseif self:GetAttribute("taken") ~= 1 then
        self:RunAttribute("_take")
    end
    self:CallMethod("onCombatKey", button)
]]

-- The state driver's handler: the frame's own COMBAT with the new state.
combatKeys.ON_STATE = [[
    self:GetFrameRef("keys"):RunAttribute("_combat", newstate == "1")
]]

local keysFrame = nil
local stagedOpen = nil
local stagePending = false

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

-- Write the player's keys and the setting onto the secure frame. Out of combat only; asked in combat, it runs when
-- the fight ends.
function combatKeys.stage()
    if InCombatLockdown() then
        stagePending = true
        return
    end
    stagePending = false
    if keysFrame == nil then
        keysFrame = createFrames()
    end
    local inputManager = WowVision.input
    local taken = {}
    local open = combatKeys.entries(inputManager, combatKeys.OPEN_KEYS, taken)
    local menu = combatKeys.entries(inputManager, combatKeys.MENU_KEYS, taken)
    writeList(keysFrame, "open", open, keysFrame:GetAttribute("open-n"))
    writeList(keysFrame, "menu", menu, keysFrame:GetAttribute("menu-n"))
    keysFrame:SetAttribute("enabled", enabled() and 1 or 0)
end

-- Whether a WowVision window is open, for the next fight's start. Called by the graph host on every update out of
-- combat; written only when it changes.
function combatKeys.setMenuOpen(open)
    if keysFrame == nil or stagePending or InCombatLockdown() then
        return
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

local OPEN_SET = {}
for _, key in ipairs(combatKeys.OPEN_KEYS) do
    OPEN_SET[key] = true
end

-- A key pressed in combat, by action name (from the secure frame).
function combatKeys.onKey(action)
    local L = WowVision:getLocale()
    if OPEN_SET[action] then
        local binding = WowVision.input:getBinding(action)
        if binding ~= nil and binding.func ~= nil then
            WowVision.base.speech:stop()
            binding.func()
        end
        return
    end
    if action == "close" then
        WowVision.UIHost.windowManager:closeOwnWindows()
        WowVision:notify(L["Menus closed"])
        return
    end
    local host = WowVision.graphHost
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

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or stagePending then
        combatKeys.stage()
    end
end)
