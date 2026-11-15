local testRunner = WowVision.testing.testRunner
local combatKeys = WowVision.graph.combatKeys

-- The secure snippets of graph/combatKeys.lua run as plain Lua against a stand-in for the game's frame handle: its
-- attributes, the override bindings it owns, and the calls it makes into addon code.
-- A binding is recorded as the button name alone when it clicks the handle itself, else as "<frame>:<button>".
local function newHandle(name)
    local handle = { name = name or "WowVisionCombatKeys", attributes = {}, bindings = {}, calls = {}, refs = {} }
    function handle:GetName()
        return self.name
    end
    function handle:GetAttribute(attribute)
        return self.attributes[attribute]
    end
    function handle:SetAttribute(attribute, value)
        self.attributes[attribute] = value
    end
    function handle:GetFrameRef(label)
        return self.refs[label]
    end
    function handle:SetBindingClick(_, key, target, button)
        if target == self then
            self.bindings[key] = button
        else
            local targetName = type(target) == "string" and target or target:GetName()
            self.bindings[key] = targetName .. ":" .. button
        end
    end
    function handle:ClearBinding(key)
        self.bindings[key] = nil
    end
    function handle:ClearBindings()
        self.bindings = {}
    end
    function handle:RunAttribute(attribute, ...)
        return self:run(self.attributes[attribute], "...", ...)
    end
    function handle:CallMethod(method, ...)
        tinsert(self.calls, { method, ... })
    end
    function handle:run(body, params, ...)
        -- the game runs a snippet as the body of function(self, <params>)
        local snippet = assert(loadstring("return function(self, " .. params .. ")\n" .. body .. "\nend"))()
        return snippet(self, ...)
    end
    handle.attributes._take = combatKeys.TAKE
    handle.attributes._release = combatKeys.RELEASE
    handle.attributes._useKeys = combatKeys.USE_KEYS
    handle.attributes._arm = combatKeys.ARM
    handle.attributes._enter = combatKeys.ENTER
    handle.attributes._leave = combatKeys.LEAVE
    handle.attributes._cycle = combatKeys.CYCLE
    handle.attributes._combat = combatKeys.COMBAT
    handle.refs.use = { name = "WowVisionCombatUse", attributes = {} }
    function handle.refs.use:GetName()
        return self.name
    end
    function handle.refs.use:SetAttribute(attribute, value)
        self.attributes[attribute] = value
    end
    return handle
end

local function stage(handle, menu, menuOpen)
    for i, entry in ipairs(menu) do
        handle.attributes["menu-k" .. i] = entry[1]
        handle.attributes["menu-a" .. i] = entry[2]
    end
    handle.attributes["menu-n"] = #menu
    local rightClick = 0
    for _, entry in ipairs(menu) do
        if entry[2] == "rightClick" then
            rightClick = rightClick + 1
            handle.attributes["rc-k" .. rightClick] = entry[1]
        end
    end
    handle.attributes["rc-n"] = rightClick
    local leftClick = 0
    for _, entry in ipairs(menu) do
        if entry[2] == "leftClick" then
            leftClick = leftClick + 1
            handle.attributes["lc-k" .. leftClick] = entry[1]
        end
    end
    handle.attributes["lc-n"] = leftClick
    handle.attributes.enabled = 1
    handle.attributes.menuopen = menuOpen and 1 or 0
end

local MENU = {
    { "UP", "up" },
    { "DOWN", "down" },
    { "TAB", "next" },
    { "SHIFT-TAB", "previous" },
    { "HOME", "home" },
    { "END", "end" },
    { "CTRL-TAB", "nextWindow" },
    { "ESCAPE", "close" },
    { "ENTER", "leftClick" },
    { "BACKSPACE", "rightClick" },
}

local function click(handle, button)
    handle:run(combatKeys.CLICK, "button, down", button, true)
end

local function fight(handle, fighting)
    handle:run(combatKeys.COMBAT, "...", fighting)
end

-- A key bound to a window-opening binding's own button: the wrapper runs with the secure frame as owner.
local function opening(handle)
    local button = newHandle()
    button:run(combatKeys.OPENING, "button, down, owner", "LeftButton", true, handle)
end

-- A stand-in for the input manager: keymaps by key with their inputs.
local function inputManager(keymaps)
    return {
        getBinding = function(_, key)
            local inputs = keymaps[key]
            if inputs == nil then
                return nil
            end
            return { inputs = inputs }
        end,
    }
end

testRunner:addSuite("CombatKeys", {
    ["the fight binds nothing when no menu is open"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, false)
        fight(handle, true)
        t:assertNil(next(handle.bindings))
        t:assertEqual(handle.attributes.fighting, 1)
    end,

    ["a menu open as the fight begins keeps its keys"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, true)
        fight(handle, true)
        t:assertEqual(handle.bindings.UP, "up")
        t:assertEqual(handle.bindings.TAB, "next")
        t:assertEqual(handle.bindings.ESCAPE, "close")
        t:assertEqual(handle.attributes.taken, 1)
    end,

    ["a window-opening key takes the menu keys in a fight"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, false)
        fight(handle, true)
        opening(handle)
        t:assertEqual(handle.bindings.DOWN, "down")
        t:assertEqual(handle.attributes.taken, 1)
    end,

    ["a window-opening key takes nothing out of a fight"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, false)
        opening(handle)
        t:assertNil(next(handle.bindings))
        fight(handle, true)
        fight(handle, false)
        opening(handle)
        t:assertNil(next(handle.bindings))
    end,

    ["escape lets the menu keys go and is handed on"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, true)
        fight(handle, true)
        click(handle, "close")
        t:assertNil(next(handle.bindings))
        t:assertEqual(handle.attributes.taken, 0)
        t:assertEqual(handle.calls[1][1], "onCombatKey")
        t:assertEqual(handle.calls[1][2], "close")
    end,

    ["a menu key is handed on and changes no binding"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, true)
        fight(handle, true)
        click(handle, "down")
        t:assertEqual(handle.bindings.UP, "up")
        t:assertEqual(handle.calls[1][2], "down")
    end,

    ["the end of the fight clears every key"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, true)
        fight(handle, true)
        fight(handle, false)
        t:assertNil(next(handle.bindings))
        t:assertEqual(handle.attributes.taken, 0)
        t:assertEqual(handle.attributes.fighting, 0)
    end,

    ["switched off, the fight binds nothing and opening keys take nothing"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, true)
        handle.attributes.enabled = 0
        fight(handle, true)
        opening(handle)
        t:assertNil(next(handle.bindings))
    end,

    ["the state driver passes the fight on"] = function(t)
        local driver = newHandle()
        local keys = newHandle()
        stage(keys, MENU, true)
        function driver:GetFrameRef(name)
            return name == "keys" and keys or nil
        end
        -- the game's driver passes a number (SecureStateDriver.lua, resolveDriver)
        driver:run(combatKeys.ON_STATE, "stateid, newstate", "combat", 1)
        t:assertEqual(keys.bindings.UP, "up")
        driver:run(combatKeys.ON_STATE, "stateid, newstate", "combat", 0)
        t:assertNil(next(keys.bindings))
    end,

    ["a combat keymap replaces the menu key's inputs"] = function(t)
        local manager = inputManager({
            up = { "UP" },
            ["combat/up"] = { "CTRL-UP" },
            down = { "DOWN" },
            ["combat/down"] = {},
        })
        t:assertEqual(combatKeys.inputsFor(manager, "up")[1], "CTRL-UP")
        t:assertEqual(combatKeys.inputsFor(manager, "down")[1], "DOWN")
    end,

    ["an input goes to the first key that has it"] = function(t)
        local manager = inputManager({ up = { "UP", "DOWN" }, down = { "DOWN" } })
        local menu = combatKeys.entries(manager, { "up", "down", "missing" })
        t:assertEqual(#menu, 2)
        t:assertEqual(menu[1].input, "UP")
        t:assertEqual(menu[2].input, "DOWN")
        t:assertEqual(menu[2].action, "up")
    end,
})

-- A mirrored list: two bags, the backpack with three slots and a bag with two, as registerMirror stages it.
local BAGS = {
    { value = "0 1", group = 0 },
    { value = "0 2", group = 0 },
    { value = "0 3", group = 0 },
    { value = "1 1", group = 1 },
    { value = "1 2", group = 1 },
}

local function stageBags(handle, open)
    for i, row in ipairs(combatKeys.mirrorAttributes(BAGS)) do
        handle.attributes["bags-v" .. i] = row.value
        handle.attributes["bags-f" .. i] = row.first
        handle.attributes["bags-l" .. i] = row.last
    end
    handle.attributes["bags-n"] = #BAGS
    handle.attributes["bags-open"] = open and 1 or 0
    handle.attributes["ok-n"] = 1
    handle.attributes["ok-k1"] = "B"
    handle.attributes["ok-o1"] = "WowVisionCombatOpen_bags"
    handle.attributes["mirror-n"] = 1
    handle.attributes["mirror-k1"] = "bags"
    -- the slots' own buttons, as the open bags laid them out before the fight
    for i = 1, #BAGS do
        handle.attributes["bags-p" .. i] = open and 1 or 0
    end
end

-- The game's open-bags key in a fight: the opener's wrapper with the secure frame as owner. False: the click is
-- cancelled.
local function openBags(handle)
    local opener = newHandle("WowVisionCombatOpen_bags")
    opener.attributes.mirror = "bags"
    return opener:run(combatKeys.OPENER, "button, down, owner", "LeftButton", true, handle)
end

local function lastMirror(handle)
    for i = #handle.calls, 1, -1 do
        if handle.calls[i][1] == "onMirror" then
            return handle.calls[i]
        end
    end
    return nil
end

local function bagsFight(open)
    local handle = newHandle()
    stage(handle, MENU, false)
    stageBags(handle, open)
    fight(handle, true)
    return handle
end

testRunner:addSuite("CombatMirror", {
    ["a group's first and last entry are staged per entry"] = function(t)
        local rows = combatKeys.mirrorAttributes(BAGS)
        t:assertEqual(rows[2].first, 1)
        t:assertEqual(rows[2].last, 3)
        t:assertEqual(rows[4].first, 4)
        t:assertEqual(rows[5].last, 5)
        t:assertEqual(rows[5].value, "1 2")
    end,

    ["the fight binds the open-bags key to the opener"] = function(t)
        local handle = bagsFight(false)
        t:assertEqual(handle.bindings.B, "WowVisionCombatOpen_bags:LeftButton")
    end,

    ["the open-bags key opens the bags and walks them from the first slot"] = function(t)
        local handle = bagsFight(false)
        t:assertNotEqual(openBags(handle), false, "the click opens the visible bags")
        t:assertEqual(handle.attributes.mode, "bags")
        t:assertEqual(handle.attributes["bags-open"], 1)
        t:assertEqual(handle.bindings.DOWN, "down")
        t:assertEqual(handle.bindings.BACKSPACE, "WowVisionCombatUse:LeftButton")
        t:assertEqual(handle.refs.use.attributes.item, "0 1")
        local call = lastMirror(handle)
        t:assertEqual(call[3], 1)
        t:assertEqual(call[4], "open")
    end,

    ["down and up stay within the bag"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        click(handle, "down")
        click(handle, "down")
        t:assertEqual(handle.attributes.idx, 3)
        click(handle, "down")
        t:assertEqual(handle.attributes.idx, 3, "the bag's last slot is an edge")
        t:assertEqual(lastMirror(handle)[4], "down")
        click(handle, "up")
        t:assertEqual(handle.refs.use.attributes.item, "0 2")
    end,

    ["tab goes from bag to bag and wraps"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        click(handle, "down")
        click(handle, "next")
        t:assertEqual(handle.attributes.idx, 4)
        t:assertEqual(handle.refs.use.attributes.item, "1 1")
        click(handle, "next")
        t:assertEqual(handle.attributes.idx, 1)
        click(handle, "previous")
        t:assertEqual(handle.attributes.idx, 4, "back to the first slot of the last bag")
        click(handle, "end")
        t:assertEqual(handle.attributes.idx, 5)
        click(handle, "home")
        t:assertEqual(handle.attributes.idx, 4)
    end,

    ["walking keys go to addon code only as the new position"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        local before = #handle.calls
        click(handle, "down")
        t:assertEqual(#handle.calls, before + 1)
        t:assertEqual(handle.calls[#handle.calls][1], "onMirror")
    end,

    ["enter is handed over with the position"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        click(handle, "down")
        click(handle, "leftClick")
        local call = lastMirror(handle)
        t:assertEqual(call[3], 2)
        t:assertEqual(call[4], "leftClick")
    end,

    ["the open-bags key again closes the bags and lets the keys go"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        t:assertEqual(openBags(handle), false, "no click: its toggles would reopen the bags")
        t:assertEqual(handle.attributes.mode, "")
        t:assertEqual(handle.attributes["bags-open"], 0)
        t:assertNil(handle.bindings.DOWN)
        t:assertNil(handle.refs.use.attributes.item)
        t:assertEqual(lastMirror(handle)[4], "close")
    end,

    ["bags open but not walked: the key steps in without a click"] = function(t)
        local handle = bagsFight(true)
        t:assertEqual(openBags(handle), false)
        t:assertEqual(handle.attributes.mode, "bags")
        t:assertEqual(handle.attributes["bags-open"], 1)
    end,

    ["escape in the bags closes them and lets the keys go"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        click(handle, "close")
        t:assertEqual(handle.attributes.mode, "")
        t:assertEqual(handle.attributes["bags-open"], 0)
        t:assertNil(handle.bindings.BACKSPACE)
        t:assertEqual(handle.bindings.B, "WowVisionCombatOpen_bags:LeftButton")
        local closed = false
        for _, call in ipairs(handle.calls) do
            closed = closed or (call[1] == "onMirror" and call[4] == "close")
        end
        t:assertTrue(closed, "addon code closes the visible bags")
    end,

    ["ctrl-tab to the other windows: backspace is the frame's again"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        click(handle, "nextWindow")
        t:assertEqual(handle.attributes.mode, "")
        t:assertEqual(handle.bindings.BACKSPACE, "rightClick")
        t:assertNil(handle.refs.use.attributes.item)
        t:assertEqual(handle.calls[#handle.calls][2], "otherWindow")
    end,

    ["ctrl-tab with only the bags open goes to the other windows, the next one back"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        click(handle, "nextWindow")
        t:assertEqual(handle.attributes.mode, "")
        t:assertEqual(handle.calls[#handle.calls][2], "otherWindow")
        click(handle, "nextWindow")
        t:assertEqual(handle.attributes.mode, "bags")
        t:assertEqual(handle.bindings.BACKSPACE, "WowVisionCombatUse:LeftButton")
    end,

    ["a window-opening key leaves the list being walked"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        opening(handle)
        t:assertEqual(handle.attributes.mode, "")
        t:assertEqual(handle.bindings.BACKSPACE, "rightClick")
        t:assertEqual(handle.attributes.taken, 1)
    end,

    ["ctrl-tab goes from the bags to the equipment and back, each where it was left"] = function(t)
        local handle = bagsFight(true)
        handle.attributes["mirror-n"] = 2
        handle.attributes["mirror-k2"] = "equipment"
        handle.attributes["equipment-n"] = 2
        handle.attributes["equipment-v1"] = "1"
        handle.attributes["equipment-v2"] = "13"
        handle.attributes["equipment-f1"], handle.attributes["equipment-l1"] = 1, 2
        handle.attributes["equipment-f2"], handle.attributes["equipment-l2"] = 1, 2
        handle.attributes["equipment-open"] = 1
        openBags(handle)
        click(handle, "down")
        click(handle, "nextWindow")
        t:assertEqual(handle.attributes.mode, "equipment")
        click(handle, "down")
        t:assertEqual(handle.refs.use.attributes.item, "13")
        click(handle, "nextWindow")
        t:assertEqual(handle.attributes.mode, "", "then the other windows")
        click(handle, "nextWindow")
        t:assertEqual(handle.attributes.mode, "bags")
        t:assertEqual(handle.attributes.idx, 2, "the bags where they were left")
        click(handle, "previousWindow")
        t:assertEqual(handle.attributes.mode, "")
        click(handle, "previousWindow")
        t:assertEqual(handle.attributes.mode, "equipment")
        t:assertEqual(handle.attributes.idx, 2)
    end,

    ["a fight that begins on a focused bag slot walks on from it"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, true)
        stageBags(handle, true)
        handle.attributes.startmode = "bags"
        handle.attributes["bags-start"] = 5
        fight(handle, true)
        t:assertEqual(handle.attributes.mode, "bags")
        t:assertEqual(handle.attributes.idx, 5)
        t:assertEqual(handle.refs.use.attributes.item, "1 2")
        t:assertEqual(lastMirror(handle)[4], "resume")
    end,

    ["the keyring's slots arm nothing"] = function(t)
        local handle = bagsFight(false)
        handle.attributes["bags-v1"] = ""
        openBags(handle)
        t:assertNil(handle.refs.use.attributes.item)
    end,

    ["bags open as the fight began: enter is a secure click of the slot's own button"] = function(t)
        local handle = bagsFight(true)
        openBags(handle)
        t:assertEqual(handle.bindings.ENTER, "WowVisionCombatPick_bags1:LeftButton")
        click(handle, "down")
        t:assertEqual(handle.bindings.ENTER, "WowVisionCombatPick_bags2:LeftButton")
        click(handle, "nextWindow")
        t:assertEqual(handle.bindings.ENTER, "leftClick", "out of the list enter is the frame's again")
    end,

    ["bags opened in the fight: enter stays with addon code, which says why"] = function(t)
        local handle = bagsFight(false)
        openBags(handle)
        t:assertEqual(handle.bindings.ENTER, "leftClick")
        click(handle, "leftClick")
        t:assertEqual(lastMirror(handle)[4], "leftClick")
    end,

    ["closed and opened again in the fight: the old buttons are not trusted"] = function(t)
        local handle = bagsFight(true)
        openBags(handle)
        openBags(handle)
        openBags(handle)
        t:assertEqual(handle.attributes.mode, "bags")
        t:assertEqual(handle.bindings.ENTER, "leftClick")
    end,

    ["a trusted layout: bags opened in the fight pick up too"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, false)
        stageBags(handle, false)
        handle.attributes["bags-trusted"] = 1
        for i = 1, #BAGS do
            handle.attributes["bags-p" .. i] = 1
        end
        fight(handle, true)
        openBags(handle)
        t:assertEqual(handle.bindings.ENTER, "WowVisionCombatPick_bags1:LeftButton")
        openBags(handle)
        openBags(handle)
        t:assertEqual(handle.bindings.ENTER, "WowVisionCombatPick_bags1:LeftButton", "reopened in the fight")
    end,

    ["shift-f10 opens the slot's two entries: enter runs the chosen one"] = function(t)
        local handle = bagsFight(true)
        openBags(handle)
        click(handle, "down")
        click(handle, "contextMenu")
        t:assertEqual(handle.attributes.ctx, 1)
        t:assertEqual(lastMirror(handle)[4], "contextOpen")
        t:assertEqual(lastMirror(handle)[3], 2, "the menu belongs to the focused slot")
        t:assertEqual(handle.bindings.ENTER, "WowVisionCombatPick_bags2:LeftButton", "first entry: the left click")
        click(handle, "down")
        t:assertEqual(handle.bindings.ENTER, "WowVisionCombatUse:LeftButton", "second entry: the right click")
        t:assertEqual(handle.refs.use.attributes.item, "0 2")
        t:assertEqual(handle.attributes.idx, 2, "the slot stays")
        local call = lastMirror(handle)
        t:assertEqual(call[3], 2)
        t:assertEqual(call[4], "contextMove")
    end,

    ["escape closes only the context menu"] = function(t)
        local handle = bagsFight(true)
        openBags(handle)
        click(handle, "contextMenu")
        click(handle, "down")
        click(handle, "close")
        t:assertEqual(handle.attributes.ctx, 0)
        t:assertEqual(handle.attributes.mode, "bags")
        t:assertEqual(handle.bindings.ENTER, "WowVisionCombatPick_bags1:LeftButton")
        t:assertEqual(lastMirror(handle)[4], "contextClose")
        click(handle, "close")
        t:assertEqual(handle.attributes.mode, "", "a second escape leaves the bags")
    end,

    ["running an entry closes the context menu"] = function(t)
        local handle = bagsFight(true)
        openBags(handle)
        click(handle, "contextMenu")
        click(handle, "down")
        local use = newHandle("WowVisionCombatUse")
        use:run(combatKeys.CONTEXT_DONE, "button, down, owner", "LeftButton", true, handle)
        t:assertEqual(handle.attributes.ctx, 0)
        t:assertEqual(handle.bindings.ENTER, "WowVisionCombatPick_bags1:LeftButton")
        t:assertEqual(lastMirror(handle)[4], "contextDone")
    end,

    ["the context menu's other keys stay in it"] = function(t)
        local handle = bagsFight(true)
        openBags(handle)
        click(handle, "contextMenu")
        click(handle, "next")
        t:assertEqual(handle.attributes.idx, 1)
        t:assertEqual(handle.attributes.ctx, 1)
    end,

    ["out of a fight the opener does what the button does"] = function(t)
        local handle = newHandle()
        stage(handle, MENU, false)
        stageBags(handle, false)
        t:assertNil(openBags(handle))
        t:assertNil(handle.attributes.mode)
    end,
})
