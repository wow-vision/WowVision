-- The entries on the module's screen: the choice of the fight and of the measure, the buttons that say your line and
-- the top of the list, and the reset, which asks first.
local ns = WowVision.detailsMeter
local L = ns.L
local Game = ns.Game
local Data = ns.Data
local Screen = ns.Screen

local function graph()
    return WowVision ~= nil and WowVision.graph or nil
end

-- The question before an erasing, as a level of its own: the question, Cancel (the first button), Erase everything.
-- Going back (Escape) is saying no.
function ns.renderResetConfirm(builder)
    local g = graph()
    local nodes, ControlId = g.nodes, g.ControlId
    local host = WowVision.graphHost
    builder:pushContext("reset", L["Reset Details data"], nil, false)
    builder:addItem(
        ControlId.structural("prompt"),
        nodes.text({
            label = function()
                return Data.resetQuestion()
            end,
            live = false,
        })
    )
    builder:addItem(
        ControlId.structural("cancel"),
        nodes.button({
            label = L["Cancel, erase nothing"],
            onActivate = function()
                host:pop(host:focusedStack())
                Game.speak(L["Nothing was erased."])
            end,
        })
    )
    builder:addItem(
        ControlId.structural("confirm"),
        nodes.button({
            label = L["Erase everything"],
            onActivate = function()
                host:pop(host:focusedStack())
                Data.reset(Game.speak)
            end,
        })
    )
    builder:popContext()
end

-- The level the entry opens.
function ns.renderMenu(builder)
    local g = graph()
    local nodes, ControlId = g.nodes, g.ControlId
    builder:pushContext("details", L["Details damage meter"])
    builder:addItem(ControlId.structural("fight"), Screen.choiceNode("segment", false))
    builder:addItem(ControlId.structural("measure"), Screen.choiceNode("attribute", false))
    builder:addItem(
        ControlId.structural("say"),
        nodes.button({
            label = L["Say my line"],
            onActivate = function()
                ns.sayMine()
            end,
        })
    )
    builder:addItem(
        ControlId.structural("top"),
        nodes.button({
            label = L["Say the top of the list"],
            onActivate = function()
                ns.sayTop()
            end,
        })
    )
    builder:addItem(
        ControlId.structural("reset"),
        nodes.button({
            label = L["Reset Details data"],
            opensLevel = true,
            onActivate = function()
                if Game.inCombat() then
                    Game.speak(L["Erasing is not possible during a fight. Try again after it."])
                    return
                end
                g.settings.pushScreen("details:reset", ns.renderResetConfirm)
            end,
        })
    )
    builder:popContext()
end

