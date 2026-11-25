-- The WowVision screen: two tab stops. "Information": what the fishing window says, one line each, current at every
-- tick (a line is read when the focus lands on it; the status line also follows its changes). "Actions": start
-- fishing (when the window is closed), put on the fishing gear or put the normal gear back, close the window.
-- Escape closes this screen only; the fishing window keeps its own state.
local ns = WowVision.foreverFishing
local L = ns.L
local Game = ns.Game
local Fishing = ns.Fishing

local Screen = {}
ns.Screen = Screen

local function graph()
    return WowVision.graph
end

local function id(key)
    return graph().ControlId.structural(key)
end

-- The key that opens this screen, as the player has it now (its binding may have been moved).
function Screen.keyName()
    local input = WowVision ~= nil and WowVision.input or nil
    local binding = input ~= nil and type(input.getBinding) == "function" and input:getBinding(ns.BINDING_KEY) or nil
    local first = binding ~= nil and binding.inputs ~= nil and binding.inputs[1] or nil
    return Fishing.keyName(first or ns.DEFAULT_KEY)
end

local function say(text)
    Game.speak(text)
end

-- The screen is drawn again every tick and each line asks for the state: it is read from the game at most four times
-- a second (the window's texts change slowly), and again at once after an action.
local cache = { at = nil, info = nil }
local function current(force)
    local now = GetTime ~= nil and GetTime() or 0
    if force or cache.info == nil or cache.at == nil or now - cache.at >= 0.25 or now < cache.at then
        cache.info = Fishing.read(Game)
        cache.at = now
    end
    return cache.info
end
Screen.current = current

local function forget()
    cache.info = nil
end

local function startAction()
    Fishing.start(Game, say, Screen.keyName())
    forget()
end

local function gearAction()
    Fishing.gear(Game, say)
    forget()
end

local function closeAction()
    local closed = Fishing.close(Game, say)
    forget()
    if closed then
        Game.closeScreen()
    end
end

function Screen.render(builder)
    local nodes = graph().nodes
    local info = current()

    builder:beginStop("fishing:information")
    builder:pushContext("fishing:information", L["Information"])
    for index, line in ipairs(Fishing.lines(info)) do
        local text = line.text
        builder:addItem(
            id("fishing:line:" .. line.key),
            nodes.text({
                label = function()
                    -- the line is read again from the game each time it is asked for
                    for _, candidate in ipairs(Fishing.lines(current())) do
                        if candidate.key == line.key then
                            return candidate.text
                        end
                    end
                    return text
                end,
                live = line.key == "status" and "focus" or nil,
            })
        )
        if index > 40 then
            break
        end
    end
    builder:popContext()

    builder:beginStop("fishing:actions")
    builder:pushContext("fishing:actions", L["Actions"])
    if not info.available then
        -- nothing to do without Forever Fishing: the information line already says so
        builder:popContext()
        return
    end
    if not info.open then
        builder:addItem(
            id("fishing:start"),
            nodes.button({
                label = L["Start fishing"],
                onActivate = Game.guarded(startAction),
            })
        )
    else
        builder:addItem(
            id("fishing:gear"),
            nodes.button({
                label = L["Put on the fishing gear or put my gear back"],
                onActivate = Game.guarded(gearAction),
            })
        )
        local closeLabel = (info.autoRestore ~= false and info.autoEquip ~= false) and L["Close the fishing window and put my gear back"]
            or L["Close the fishing window"]
        builder:addItem(
            id("fishing:close"),
            nodes.button({
                label = closeLabel,
                onActivate = Game.guarded(closeAction),
            })
        )
    end
    builder:popContext()
end

function Screen.config()
    return {
        key = Game.WINDOW,
        -- a frameless window: the game cannot close it for us, so Escape is held by the screen (WowVision's host
        -- only takes the close key for such a stack when it asks)
        captureClose = true,
        render = function(builder)
            return Screen.render(builder)
        end,
        onRequestClose = Game.guarded(function()
            Game.closeScreen()
        end),
    }
end

-- Opens the screen, or closes it when it is open (the key and the command both toggle).
function Screen.toggle()
    if Game.isScreenOpen() then
        Game.closeScreen()
        return true
    end
    -- the game is asked afresh as the screen opens
    forget()
    if not Game.openScreen(Screen.config()) then
        Game.speak(L["WowVision's windows are not available."])
        return false
    end
    return true
end
