local testRunner = WowVision.testing.testRunner
local combatKeys = WowVision.graph.combatKeys

-- The secure snippets of graph/combatKeys.lua run as plain Lua against a stand-in for the game's frame handle: its
-- attributes, the override bindings it owns, and the calls it makes into addon code.
local function newHandle()
    local handle = { attributes = {}, bindings = {}, calls = {} }
    function handle:GetAttribute(name)
        return self.attributes[name]
    end
    function handle:SetAttribute(name, value)
        self.attributes[name] = value
    end
    function handle:SetBindingClick(_, key, target, button)
        assert(target == self, "binds to its own frame")
        self.bindings[key] = button
    end
    function handle:ClearBinding(key)
        self.bindings[key] = nil
    end
    function handle:ClearBindings()
        self.bindings = {}
    end
    function handle:RunAttribute(name, ...)
        return self:run(self.attributes[name], "...", ...)
    end
    function handle:CallMethod(name, ...)
        tinsert(self.calls, { name, ... })
    end
    function handle:run(body, params, ...)
        -- the game runs a snippet as the body of function(self, <params>)
        local snippet = assert(loadstring("return function(self, " .. params .. ")\n" .. body .. "\nend"))()
        return snippet(self, ...)
    end
    handle.attributes._take = combatKeys.TAKE
    handle.attributes._release = combatKeys.RELEASE
    handle.attributes._combat = combatKeys.COMBAT
    return handle
end

local function stage(handle, menu, menuOpen)
    for i, entry in ipairs(menu) do
        handle.attributes["menu-k" .. i] = entry[1]
        handle.attributes["menu-a" .. i] = entry[2]
    end
    handle.attributes["menu-n"] = #menu
    handle.attributes.enabled = 1
    handle.attributes.menuopen = menuOpen and 1 or 0
end

local MENU = { { "UP", "up" }, { "DOWN", "down" }, { "TAB", "next" }, { "ESCAPE", "close" } }

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
        driver:run(combatKeys.ON_STATE, "stateid, newstate", "combat", "1")
        t:assertEqual(keys.bindings.UP, "up")
        driver:run(combatKeys.ON_STATE, "stateid, newstate", "combat", "0")
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
