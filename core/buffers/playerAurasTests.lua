-- The player auras module (playerAuras.lua): the key that says every buff and debuff, the list window, the command.
-- The harness in tools/headless-tests.lua loads playerAuras.lua against a stand-in buffers module that keeps what the
-- file registers, and hands over the fake game of the Aura buffer suites (the player's auras, the game's refusal to
-- list them in combat, the tooltip lines). The Aura buffer, the graph framework and the secrets helpers are the real
-- ones.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._playerAurasTestHarness
local module = harness.module
local world = harness.world
local graph = WowVision.graph
local AuraBuffer = WowVision.buffers.AuraBuffer

local WINDOW = "playerAuras"

local function aura(name, fields)
    local data = { name = name, applications = 0, duration = 0 }
    for key, value in pairs(fields or {}) do
        data[key] = value
    end
    return data
end

-- The usual player: two buffs and a debuff, each with the lines the game's tooltip gives (name, description, time
-- left).
local function usual()
    return {
        HELPFUL = {
            aura("Power Word: Fortitude", { duration = 3600, remaining = "59 minutes remaining" }),
            aura("Renew", { applications = 2, duration = 15, remaining = "12 seconds remaining" }),
        },
        HARMFUL = {
            aura("Deadly Poison", { duration = 30, dispelName = "Poison", remaining = "8 seconds remaining" }),
        },
    }
end

local function bindingFor(key)
    for _, info in ipairs(module.bindings) do
        if info.key == key then
            return info
        end
    end
    return nil
end

local function commandFor(name)
    for _, config in ipairs(module.commands) do
        if config.name == name then
            return config
        end
    end
    return nil
end

local function windowConfig()
    return module.windows[WINDOW].graphScreen
end

-- A secret string as the game hands them to addons: it can be joined with ".." and nothing else.
local SECRET = {}
local function secretString(text)
    return setmetatable({ text = text, secret = SECRET }, {
        __concat = function(a, b)
            local left = type(a) == "table" and a.text or a
            local right = type(b) == "table" and b.text or b
            return left .. right
        end,
        __eq = function()
            error("a secret string cannot be compared")
        end,
        __len = function()
            error("a secret string cannot be measured")
        end,
    })
end

-- Runs fn(game) with the player's auras set up in the fake game and the window host and the speech recorded, every
-- piece put back after. options: auras (the lists), restricted (the game refuses the read by index), noPlayer,
-- noAuraCalls (a client without the aura reads).
local function withGame(options, fn)
    options = options or {}
    local savedPlayer, savedUnit, savedRestricted = world.auras.player, world.units.player, world.restricted.player
    local savedTooltips, savedDispel = {}, {}
    for name, lines in pairs(world.tooltips) do
        savedTooltips[name] = lines
    end
    for name, value in pairs(world.dispel) do
        savedDispel[name] = value
    end
    local savedHost, savedSpeak = WowVision.UIHost, WowVision.speak
    local savedAuraCalls = C_UnitAuras
    local savedUnsubscribe = AuraBuffer.unsubscribe
    local registry = WowVision.buffers.registry
    local savedCreate = registry.createTemporaryComponent

    local game = { spoken = {}, opened = {}, closed = {}, created = {}, released = 0 }
    local lists = options.auras or usual()
    world.auras.player = lists
    world.units.player = not options.noPlayer
    world.restricted.player = options.restricted == true
    for _, kind in ipairs({ "HELPFUL", "HARMFUL" }) do
        for _, data in ipairs(lists[kind]) do
            local lines = { data.name, "About " .. data.name }
            if data.duration > 0 then
                lines[#lines + 1] = data.remaining
            end
            world.tooltips[data.name] = lines
            world.dispel[data.name] = data.dispelName
        end
    end
    WowVision.UIHost = {
        openWindow = function(_, name)
            game.opened[#game.opened + 1] = name
        end,
        closeWindow = function(_, name)
            game.closed[#game.closed + 1] = name
        end,
    }
    WowVision.speak = function(_, text)
        game.spoken[#game.spoken + 1] = text
    end
    if options.noAuraCalls then
        C_UnitAuras = nil
    end
    AuraBuffer.unsubscribe = function(self)
        game.released = game.released + 1
        return savedUnsubscribe(self)
    end
    registry.createTemporaryComponent = function(self, config)
        local buffer = savedCreate(self, config)
        if options.emptyBuffers then
            buffer.items = {} -- a buffer that has neither an aura nor a message
        end
        game.created[#game.created + 1] = buffer
        return buffer
    end
    function game:set(kind, list)
        lists[kind] = list
    end
    -- the game says the player's auras changed: the buffers follow
    function game:changed()
        for _, buffer in ipairs(self.created) do
            buffer:rebuild()
        end
    end

    local ok, err = pcall(fn, game)
    -- a list a test left open is closed, so the next test starts with none held
    windowConfig().onRequestClose({})

    registry.createTemporaryComponent = savedCreate
    AuraBuffer.unsubscribe = savedUnsubscribe
    C_UnitAuras = savedAuraCalls
    WowVision.UIHost, WowVision.speak = savedHost, savedSpeak
    world.auras.player, world.units.player, world.restricted.player = savedPlayer, savedUnit, savedRestricted
    for name in pairs(world.tooltips) do
        world.tooltips[name] = savedTooltips[name]
    end
    for name in pairs(world.dispel) do
        world.dispel[name] = savedDispel[name]
    end
    if not ok then
        error(err, 0)
    end
end

local function press(key)
    bindingFor(key).func()
end

-- The window's screen, drawn by the real graph engine: its nodes in order.
local function nodesOf(render)
    local state = graph.newState()
    local keyGraph = graph.KeyGraph:new(function()
        local builder = graph.Builder:new(state.expanded)
        render(builder, {})
        return builder:build()
    end, state)
    keyGraph:rerender()
    local order = keyGraph.current ~= nil and keyGraph.current.order or {}
    return order, keyGraph
end

local function labelOf(node)
    local text = node.vtable.announcements[1].text
    if type(text) == "function" then
        return text()
    end
    return text
end

local function labels(order, stopKey)
    local out = {}
    for _, node in ipairs(order) do
        if stopKey == nil or node.stopKey == stopKey then
            out[#out + 1] = labelOf(node)
        end
    end
    return out
end

local EVERYTHING = "Player Buffs: 2. Power Word: Fortitude, 59 minutes remaining. Renew, 2 stacks, 12 seconds remaining. "
    .. "Player Debuffs: 1. Deadly Poison, 8 seconds remaining, Poison"

testRunner:addSuite("PlayerAuras", {
    ["it is a module of the buffers, with its own window, keys and command"] = function(t)
        t:assertEqual(module.label, "Player Auras")
        t:assertNotNil(module.windows[WINDOW])
        t:assertEqual(module.windows[WINDOW].type, "ManualWindow")
        t:assertEqual(#module.bindings, 2)
        t:assertEqual(#module.commands, 1)
        t:assertEqual(commandFor("auras").scope, "WowVision")
    end,

    ["Alt+Ctrl+B says every buff and debuff, Alt+Shift+B opens the list"] = function(t)
        local say, open = bindingFor("auras/say"), bindingFor("auras/open")
        t:assertEqual(say.inputs[1], "ALT-CTRL-B")
        t:assertEqual(say.type, "Function")
        t:assertEqual(say.label, "Speak Player Auras")
        t:assertTrue(say.interruptSpeech)
        t:assertEqual(open.inputs[1], "ALT-SHIFT-B")
        t:assertEqual(open.label, "Player Auras")
        t:assertTrue(open.interruptSpeech)
        t:assertTrue(open.opensWindow, "in a fight it takes the menu keys like the other keys that open a window")
    end,

    ["the say key reads every buff, then every debuff, each group with its number"] = function(t)
        withGame(nil, function(game)
            press("auras/say")
            t:assertEqual(#game.spoken, 1)
            t:assertEqual(game.spoken[1], EVERYTHING)
        end)
    end,

    ["a group with nothing in it says what the buffer says about it"] = function(t)
        withGame({ auras = { HELPFUL = {}, HARMFUL = { aura("Deadly Poison", { duration = 30, dispelName = "Poison", remaining = "8 seconds remaining" }) } } }, function(game)
            press("auras/say")
            t:assertEqual(game.spoken[1], "Player Buffs, none. Player Debuffs: 1. Deadly Poison, 8 seconds remaining, Poison")
        end)
        withGame({ auras = { HELPFUL = { aura("Mark of the Wild") }, HARMFUL = {} } }, function(game)
            press("auras/say")
            t:assertEqual(game.spoken[1], "Player Buffs: 1. Mark of the Wild. Player Debuffs, none")
        end)
        withGame({ auras = { HELPFUL = {}, HARMFUL = {} } }, function(game)
            press("auras/say")
            t:assertEqual(game.spoken[1], "Player Buffs, none. Player Debuffs, none")
        end)
    end,

    ["a buffer with neither an aura nor a message gives its number, 0"] = function(t)
        withGame({ emptyBuffers = true }, function(game)
            press("auras/say")
            t:assertEqual(game.spoken[1], "Player Buffs: 0. Player Debuffs: 0")
            press("auras/open")
            local order = nodesOf(windowConfig().render)
            t:assertEqual(#order, 2)
            t:assertEqual(labelOf(order[1]), "Player Buffs: 0")
            t:assertEqual(labelOf(order[2]), "Player Debuffs: 0")
        end)
    end,

    ["with no player yet the buffer's own words are said"] = function(t)
        withGame({ noPlayer = true }, function(game)
            press("auras/say")
            t:assertEqual(game.spoken[1], "Player Buffs, no player. Player Debuffs, no player")
        end)
    end,

    ["/wv auras count says only the numbers"] = function(t)
        withGame(nil, function(game)
            commandFor("auras").func("count")
            t:assertEqual(game.spoken[1], "Player Buffs: 2. Player Debuffs: 1.")
        end)
        withGame({ auras = { HELPFUL = {}, HARMFUL = {} } }, function(game)
            commandFor("auras").func("count")
            t:assertEqual(game.spoken[1], "Player Buffs: 0. Player Debuffs: 0.")
        end)
    end,

    ["each press asks the game afresh"] = function(t)
        withGame(nil, function(game)
            press("auras/say")
            game:set("HELPFUL", { aura("Only One") })
            press("auras/say")
            t:assertEqual(game.spoken[2], "Player Buffs: 1. Only One. Player Debuffs: 1. Deadly Poison, 8 seconds remaining, Poison")
        end)
    end,

    ["the buffers are private: one per group, never registered, let go of after the read"] = function(t)
        withGame(nil, function(game)
            local registered = #WowVision.buffers.registry:getComponents()
            press("auras/say")
            t:assertEqual(#game.created, 2)
            t:assertEqual(game.created[1].sources[1], "player:HELPFUL")
            t:assertEqual(game.created[2].sources[1], "player:HARMFUL")
            t:assertEqual(#game.created[1].sources, 1)
            t:assertEqual(game.created[1].speakRemaining, true)
            t:assertEqual(game.created[1].speakDescription, false, "the description is for Space")
            t:assertEqual(#WowVision.buffers.registry:getComponents(), registered, "nothing saved or registered")
            t:assertEqual(game.released, 2, "no more listening to the game's aura events")
            for _, buffer in ipairs(game.created) do
                for _, item in ipairs(buffer.items) do
                    t:assertEqual(item.unit, "player")
                end
            end
        end)
    end,

    ["where the game refuses the read by index, the tooltip's lines say it"] = function(t)
        withGame({ restricted = true }, function(game)
            press("auras/say")
            local text = game.spoken[1]
            t:assertTrue(text:find("Player Buffs: 2. Power Word: Fortitude", 1, true) ~= nil, text)
            t:assertTrue(text:find("Player Debuffs: 1. Deadly Poison", 1, true) ~= nil, text)
            t:assertTrue(text:find("Poison", 1, true) ~= nil, text)
        end)
    end,

    ["secret lines are only joined: never measured, compared, matched or formatted"] = function(t)
        local savedLine = AuraBuffer.AuraItem.getFocusString
        withGame(nil, function(game)
            AuraBuffer.AuraItem.getFocusString = function(self)
                return secretString("Secret " .. self.filter .. " " .. self.index)
            end
            local ok, err = pcall(function()
                press("auras/say")
                commandFor("auras").func("count")
                -- the list reads the same lines
                press("auras/open")
                local order = nodesOf(windowConfig().render)
                t:assertEqual(#order, 3)
                local lines = labels(order)
                t:assertEqual(#lines, 3)
                t:assertEqual(lines[1] .. "", "Secret HELPFUL 1")
                t:assertEqual(lines[3] .. "", "Secret HARMFUL 1")
            end)
            AuraBuffer.AuraItem.getFocusString = savedLine
            if not ok then
                error(err, 0)
            end
            t:assertEqual(game.spoken[1], "Player Buffs: 2. Secret HELPFUL 1. Secret HELPFUL 2. Player Debuffs: 1. Secret HARMFUL 1")
            t:assertEqual(game.spoken[2], "Player Buffs: 2. Player Debuffs: 1.")
        end)
    end,

    ["a line that cannot be read says unavailable"] = function(t)
        local savedLine = AuraBuffer.AuraItem.getFocusString
        withGame(nil, function(game)
            AuraBuffer.AuraItem.getFocusString = function(self)
                if self.index == 1 then
                    error("gone")
                end
                return nil
            end
            local ok, err = pcall(press, "auras/say")
            AuraBuffer.AuraItem.getFocusString = savedLine
            if not ok then
                error(err, 0)
            end
            t:assertEqual(game.spoken[1], "Player Buffs: 2. unavailable. unavailable. Player Debuffs: 1. unavailable")
        end)
    end,

    ["a client without the aura reads says so and opens nothing"] = function(t)
        withGame({ noAuraCalls = true }, function(game)
            press("auras/say")
            commandFor("auras").func("count")
            press("auras/open")
            commandFor("auras").func("")
            t:assertEqual(#game.spoken, 4)
            for _, text in ipairs(game.spoken) do
                t:assertEqual(text, "Auras are not available.")
            end
            t:assertEqual(#game.opened, 0)
        end)
    end,

    ["the list opens the window with fresh buffers and keeps them while it is open"] = function(t)
        withGame(nil, function(game)
            press("auras/open")
            t:assertEqual(#game.opened, 1)
            t:assertEqual(game.opened[1], WINDOW)
            t:assertEqual(#game.created, 2)
            t:assertEqual(game.released, 0, "held while the window is open")
            -- the key again with the list open: fresh buffers, the old ones let go of
            press("auras/open")
            t:assertEqual(#game.created, 4)
            t:assertEqual(game.released, 2)
        end)
    end,

    ["every way of closing the window lets the buffers go, and an empty screen closes itself"] = function(t)
        withGame(nil, function(game)
            local config = windowConfig()
            t:assertTrue(config.captureClose, "frameless: the screen holds Escape")
            press("auras/open")
            t:assertEqual(#nodesOf(config.render), 3)
            config.onRequestClose({}, "escape")
            t:assertEqual(game.released, 2)
            t:assertEqual(#game.closed, 1)
            t:assertEqual(game.closed[1], WINDOW)
            t:assertEqual(#nodesOf(config.render), 0, "adding no nodes closes the screen")
            -- asked again, with nothing held: nothing more to let go of
            config.onRequestClose({})
            t:assertEqual(game.released, 2)
        end)
    end,

    ["the screen has two stops, the buffs then the debuffs, a line per aura"] = function(t)
        withGame(nil, function()
            press("auras/open")
            local order, keyGraph = nodesOf(windowConfig().render)
            t:assertEqual(table.concat(keyGraph:_stopOrder(), ","), "auras:buffs,auras:debuffs")
            t:assertEqual(#order, 3)
            local buffs = labels(order, "auras:buffs")
            t:assertEqual(#buffs, 2)
            t:assertEqual(buffs[1], "Power Word: Fortitude, 59 minutes remaining")
            t:assertEqual(buffs[2], "Renew, 2 stacks, 12 seconds remaining")
            t:assertEqual(labels(order, "auras:debuffs")[1], "Deadly Poison, 8 seconds remaining, Poison")
            -- the groups are announced by the buffer's own names when the focus enters them
            local parent = order[1].parent
            t:assertEqual(parent.vtable.announcements[1].text, "Player Buffs")
            t:assertEqual(order[3].parent.vtable.announcements[1].text, "Player Debuffs")
        end)
    end,

    ["Space reads the aura's tooltip, and its time left is not watched"] = function(t)
        withGame(nil, function()
            press("auras/open")
            local order = nodesOf(windowConfig().render)
            local first, second, debuff = order[1].vtable, order[2].vtable, order[3].vtable
            t:assertEqual(first.tooltip.type, "Aura")
            t:assertEqual(first.tooltip.unit, "player")
            t:assertEqual(first.tooltip.index, 1)
            t:assertEqual(first.tooltip.filter, "HELPFUL")
            t:assertEqual(second.tooltip.index, 2)
            t:assertEqual(debuff.tooltip.index, 1)
            t:assertEqual(debuff.tooltip.filter, "HARMFUL")
            t:assertEqual(first.announcements[1].live, false, "it would be said again every second")
        end)
    end,

    ["a group with nothing in it still has its stop, and says so"] = function(t)
        withGame({ auras = { HELPFUL = {}, HARMFUL = { aura("Deadly Poison", { duration = 30, dispelName = "Poison", remaining = "8 seconds remaining" }) } } }, function()
            press("auras/open")
            local order, keyGraph = nodesOf(windowConfig().render)
            t:assertEqual(table.concat(keyGraph:_stopOrder(), ","), "auras:buffs,auras:debuffs")
            t:assertEqual(labels(order, "auras:buffs")[1], "Player Buffs, none")
            t:assertNil(order[1].vtable.tooltip, "nothing to read a tooltip of")
        end)
    end,

    ["the list follows the game, and its ids stay the same between drawings"] = function(t)
        withGame(nil, function(game)
            press("auras/open")
            local render = windowConfig().render
            local before = nodesOf(render)
            local ids = {}
            for _, node in ipairs(before) do
                ids[#ids + 1] = tostring(node.id.key)
            end
            t:assertEqual(ids[1], "auras:buffs:1")
            t:assertEqual(ids[3], "auras:debuffs:1")
            local again = {}
            for _, node in ipairs(nodesOf(render)) do
                again[#again + 1] = tostring(node.id.key)
            end
            t:assertEqual(table.concat(again, ","), table.concat(ids, ","))

            game:set("HELPFUL", { aura("A"), aura("B"), aura("C"), aura("D") })
            t:assertEqual(#nodesOf(render), 3, "the buffers have not been told yet")
            game:changed()
            t:assertEqual(#nodesOf(render), 5)
            game:set("HARMFUL", {})
            game:changed()
            local order = nodesOf(render)
            t:assertEqual(#order, 5)
            t:assertEqual(labelOf(order[5]), "Player Debuffs, none")
        end)
    end,

    -- The game does not send its aura event in some instanced content: the open list must not depend on it.
    ["the open list re-reads on a timer, without the game's aura event"] = function(t)
        withGame(nil, function(game)
            local savedGetTime = GetTime
            local clock = 100
            GetTime = function()
                return clock
            end
            local ok, err = pcall(function()
                press("auras/open")
                local render = windowConfig().render
                t:assertEqual(#nodesOf(render), 3)
                game:set("HELPFUL", { aura("A"), aura("B"), aura("C"), aura("D") })
                clock = clock + 0.2
                t:assertEqual(#nodesOf(render), 3, "inside the interval nothing is read again")
                clock = clock + 0.4
                t:assertEqual(#nodesOf(render), 5, "no event came: the timer found the change")
                game:set("HARMFUL", {})
                clock = clock + 0.6
                local order = nodesOf(render)
                t:assertEqual(labelOf(order[5]), "Player Debuffs, none")
            end)
            GetTime = savedGetTime
            if not ok then
                error(err, 0)
            end
        end)
    end,

    ["/wv auras opens the list, say and count speak, capitals and spaces do not matter"] = function(t)
        withGame(nil, function(game)
            local run = commandFor("auras").func
            run("")
            run(nil)
            run("  whatever")
            t:assertEqual(#game.opened, 3, "no word, or one it does not know: the list")
            t:assertEqual(#game.spoken, 0)
            run("say")
            run("  SAY  ")
            t:assertEqual(game.spoken[1], EVERYTHING)
            t:assertEqual(game.spoken[2], EVERYTHING)
            run("Count")
            t:assertEqual(game.spoken[3], "Player Buffs: 2. Player Debuffs: 1.")
            t:assertEqual(#game.opened, 3)
        end)
    end,
})
