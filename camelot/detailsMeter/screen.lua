-- The WowVision screen of the damage meter: one window with three levels, the ranked list, one player, and the question
-- that comes before an erasing. Escape (or Backspace on the last line) goes back up and, at the top, closes. The lines
-- are worked out by Data from the game's damage meter and read when the focus lands on them; the screen is drawn again
-- every tick, so each time a line is read it is current.
--
-- The list level, in tab stops:
--   Summary   which fight and which figures, then your own line and rank (Enter opens your details), the best of the
--             list when it is not you (Enter opens it), and the group (total, how many, how long)
--   List      one line per player: name, figures, percent; Enter opens the player
--   Display   the fight: its list of choices (Left and Right change it one step), show the current fight, show all
--             fights together, show the last kept fight, the fight before and after in the list; the measure: its
--             list of choices, the measure before and after
--   Actions   follow the Details window or not, and the reset (which asks first)
--   Help      one line on the keys
-- Every button says in its label what Enter does (the ones that go somewhere name where) and, once pressed, says what is
-- shown now.
-- The player level: Player (who, rank, totals, how many spells and targets, then the spells on the next lines),
-- Targets (damage done only), Back.
-- The reset level: the question (what would be erased), Cancel, Erase everything. Nothing is erased until the last.
local ns = WowVision.detailsMeter
local L = ns.L
local Text = ns.Text
local Game = ns.Game
local Data = ns.Data

local Screen = {}
ns.Screen = Screen

-- Where the player is. It is reset each time the screen opens.
local state = {
    level = "list", -- list | player | reset
    player = nil, -- Data.reference of the row opened, with the key of the line to land on when going back
    from = nil, -- the key of the line the reset was asked from
}
Screen.state = state

local function graph()
    return WowVision.graph
end

local function id(key)
    return graph().ControlId.structural(key)
end

-- Puts the player on a line of the level just entered (the screen was built from the level it just left).
local function land(key)
    local screen = Screen.screen
    if screen ~= nil and screen.keyGraph ~= nil and key ~= nil then
        pcall(screen.keyGraph.focus, screen.keyGraph, id(key))
    end
end

-- A line to read. It is read as the focus lands on it and not again while it stays there: its figures change as the
-- fight goes on, and a line spoken again at every change would never stop.
local function textNode(label)
    local vtable = graph().nodes.text({ label = label })
    vtable.announcements[1].live = false
    return vtable
end

-- A button that changes what is shown: its label says what Enter does, and pressing it says what is shown now (fight and
-- measure, then your line). It carries no "selected" mark: that would make Tab land on it instead of on the control
-- that says what is shown.
local function actionNode(label, activate)
    local vtable = graph().nodes.button({
        label = label,
        onActivate = activate,
        stateText = function()
            return Data.readout()
        end,
    })
    vtable.announcements[1].live = false
    return vtable
end

-- A button that goes one step through the fights (what = "segment") or the measures ("attribute"); its label names
-- where it goes: "Next fight in the list: All fights together".
local function stepNode(what, step, template)
    return actionNode(function()
        local choice = Data.neighbor(what, step)
        return Text.fill(L[template], choice ~= nil and choice.label or L["unavailable"])
    end, function()
        Data.cycle(what, step)
    end)
end

-- A button that shows a fight.
local function showNode(label, value)
    return actionNode(label, function()
        Data.choose("segment", value)
    end)
end

-- A line to read that Enter goes into.
local function openNode(label, activate)
    local vtable = graph().nodes.button({ label = label, onActivate = activate, opensLevel = true })
    vtable.announcements[1].live = false
    return vtable
end

-- ----------------------------------------------------- the fight and the measure

-- Set when Left or Right just changed something: the host asks for the state text after Enter as well, and only a
-- change is to be said back.
local adjusted = false

-- The control that chooses the fight (what = "segment") or the measure (what = "attribute"): Enter opens the whole
-- list of choices; with cycles, Left and Right go one step through them (round again) and say what is shown now.
function Screen.choiceNode(what, cycles)
    local config
    if what == "segment" then
        config = {
            label = L["Fight"],
            get = function()
                return Data.segmentKey(Data.selection().segment)
            end,
            set = function(value)
                Data.choose("segment", value)
            end,
            choices = function()
                return Data.segmentChoices()
            end,
            valueText = function()
                return Data.segmentLabel(Data.selection().segment)
            end,
        }
    else
        config = {
            label = L["Measure"],
            get = function()
                return Data.selection().attribute
            end,
            set = function(value)
                Data.choose("attribute", value)
            end,
            choices = function()
                return Data.attributeChoices()
            end,
            valueText = function()
                local attribute = Data.attribute(Data.selection().attribute)
                return attribute ~= nil and Data.attributeName(attribute) or L["unavailable"]
            end,
        }
    end
    local vtable = graph().nodes.choice(config)
    if cycles then
        vtable.onAdjust = function(sign)
            adjusted = true
            Data.cycle(what, sign > 0 and 1 or -1)
        end
        vtable.stateText = function()
            if not adjusted then
                return nil
            end
            adjusted = false
            return Data.readout()
        end
    end
    return vtable
end

-- ------------------------------------------------------------------ the list

local function renderList(builder)
    local nodes = graph().nodes
    local selection = Data.selection()
    local view, reason = Data.view(selection)
    local mine = view ~= nil and Data.mine(view) or nil
    local best = view ~= nil and Data.bestLine(view) and view.rows[1] or nil

    builder:beginStop("summary")
    builder:pushContext("summary", L["Damage meter"], nil, false)
    local overview = function()
        return Data.overview(selection, view, reason)
    end
    if mine ~= nil then
        builder:addItem(
            id("overview"),
            openNode(overview, function()
                Screen.openPlayer(mine, "overview")
            end)
        )
    else
        builder:addItem(id("overview"), textNode(overview))
    end
    if best ~= nil then
        builder:addItem(
            id("best"),
            openNode(function()
                return Data.bestLine(view)
            end, function()
                Screen.openPlayer(best, "best")
            end)
        )
    end
    if view ~= nil then
        builder:addItem(
            id("group"),
            textNode(function()
                return Data.groupLine(selection, view)
            end)
        )
    end
    builder:popContext()

    if view ~= nil then
        builder:beginStop("list")
        builder:pushContext("list:" .. view.attribute.key, Data.attributeName(view.attribute))
        if #view.rows == 0 then
            builder:addItem(id("list:none"), textNode(L["Nobody in this list yet."]))
        end
        for _, row in ipairs(view.rows) do
            local key = Data.rowKey(row)
            builder:addItem(
                id(key),
                openNode(function()
                    return Data.rowLabel(view, row)
                end, function()
                    Screen.openPlayer(row, key)
                end)
            )
        end
        builder:popContext()
    end

    builder:beginStop("display")
    builder:pushContext("display:fight", L["Fight"])
    builder:addItem(id("display:segment"), Screen.choiceNode("segment", true))
    builder:addItem(id("display:current"), showNode(L["Show the current fight"], "current"))
    builder:addItem(id("display:overall"), showNode(L["Show all fights together"], "overall"))
    local last = Data.lastKept()
    if last ~= nil then
        builder:addItem(
            id("display:last"),
            showNode(function()
                return Text.fill(L["Show the last kept fight: %s"], last.label)
            end, last.value)
        )
    end
    builder:addItem(id("display:fight-previous"), stepNode("segment", -1, "Previous fight in the list: %s"))
    builder:addItem(id("display:fight-next"), stepNode("segment", 1, "Next fight in the list: %s"))
    builder:popContext()
    builder:pushContext("display:measure", L["Measure"])
    builder:addItem(id("display:attribute"), Screen.choiceNode("attribute", true))
    builder:addItem(id("display:measure-previous"), stepNode("attribute", -1, "Previous measure in the list: %s"))
    builder:addItem(id("display:measure-next"), stepNode("attribute", 1, "Next measure in the list: %s"))
    builder:popContext()

    builder:beginStop("actions")
    builder:pushContext("actions", L["Actions"])
    builder:addItem(
        id("actions:follow"),
        nodes.toggle({
            label = L["Follow the Details window"],
            get = function()
                return Game.getSetting("follow") ~= false
            end,
            set = function(value)
                Game.setSetting("follow", value == true)
                Data.clearCache()
            end,
        })
    )
    builder:addItem(
        id("actions:reset"),
        nodes.button({
            label = L["Reset Details: erases every fight, after a question"],
            opensLevel = true,
            onActivate = function()
                Screen.openReset("actions:reset")
            end,
        })
    )
    builder:popContext()

    builder:beginStop("help")
    builder:pushContext("help", L["Help"], nil, false)
    builder:addItem(
        id("help:text"),
        textNode(L["Tab goes from the summary to the list, then to the display and to the actions. Enter opens a player or does what the button says. Left and right on Fight and Measure change one step. Escape goes back."])
    )
    builder:popContext()
end

-- --------------------------------------------------------------- one player

-- The key of a spell line: its spell when it can be read (a number of the same spell, when it comes more than once:
-- a pet's cast and the player's), else its place.
local function spellKeys(spells)
    local keys, seen = {}, {}
    for index, entry in ipairs(spells.entries) do
        local base = "spell:" .. index
        if not Text.isSecret(entry.id) and type(entry.id) == "number" then
            base = "spell:" .. entry.id
        end
        seen[base] = (seen[base] or 0) + 1
        keys[index] = base .. "#" .. seen[base]
    end
    return keys
end

local function renderSpells(builder, view, row, spells)
    builder:pushContext("spells", L["Spells"])
    if spells == nil or #spells.entries == 0 then
        builder:addItem(id("spells:none"), textNode(L["No spell known for this player."]))
    else
        local keys = spellKeys(spells)
        for index, entry in ipairs(spells.entries) do
            builder:addItem(
                id(keys[index]),
                textNode(function()
                    return Data.spellLabel(view, row, spells, entry)
                end)
            )
        end
    end
    builder:popContext()
end

local function renderTargets(builder, targets, why)
    builder:beginStop("targets")
    builder:pushContext("targets", L["Targets"])
    if targets == nil then
        builder:addItem(
            id("targets:none"),
            textNode(why == "combat" and L["The targets are known after the fight."] or L["No target known."])
        )
    elseif #targets == 0 then
        builder:addItem(id("targets:none"), textNode(L["No target known."]))
    else
        local sum = 0
        for _, target in ipairs(targets) do
            sum = sum + target.amount
        end
        for index, target in ipairs(targets) do
            builder:addItem(
                id("target:" .. index),
                textNode(function()
                    return Text.line(", ", target.name, Text.number(target.amount), Text.percent(target.amount, sum))
                end)
            )
        end
    end
    builder:popContext()
end

local function renderPlayer(builder)
    local nodes = graph().nodes
    local selection = Data.selection()
    local view = Data.view(selection)
    local row = Data.findRow(view, state.player)

    local spells, targets, why
    local hasTargets = false
    if row ~= nil then
        local key = Data.selectionKey(selection) .. "|" .. Data.rowKey(row)
        spells = Data.cached("spells|" .. key, 1, function()
            return Data.spells(view, row)
        end)
        local attribute = view.attribute.key
        hasTargets = attribute == "DamageDone" or attribute == "Dps"
        if hasTargets then
            targets, why = Data.cached("targets|" .. key .. "|" .. tostring(Game.inCombat()), 30, function()
                return Data.targets(view, row)
            end)
        end
    end

    builder:beginStop("player")
    builder:pushContext("player", L["Player details"], nil, false)
    if row == nil then
        builder:addItem(id("player:gone"), textNode(L["This player is not in the list any more."]))
    else
        builder:addItem(
            id("player:header"),
            textNode(function()
                return Data.playerHeader(view, row)
            end)
        )
        builder:addItem(
            id("player:totals"),
            textNode(function()
                return Data.playerTotals(view, row, Data.playerCounts(spells, hasTargets and targets or nil))
            end)
        )
    end
    builder:popContext()
    if row ~= nil then
        renderSpells(builder, view, row, spells)
        if hasTargets then
            renderTargets(builder, targets, why)
        end
    end

    builder:beginStop("back")
    builder:pushContext("back", L["Navigation"], nil, false)
    builder:addItem(
        id("back"),
        nodes.button({
            label = L["Back to the list"],
            onActivate = function()
                Screen.back()
            end,
        })
    )
    builder:popContext()
end

-- ------------------------------------------------------------------- the reset

local function renderReset(builder)
    local nodes = graph().nodes
    builder:beginStop("reset")
    builder:pushContext("reset", L["Reset Details data"], nil, false)
    builder:addItem(
        id("reset:prompt"),
        textNode(function()
            return Data.resetQuestion()
        end)
    )
    builder:addItem(
        id("reset:cancel"),
        nodes.button({
            label = L["Cancel, erase nothing"],
            onActivate = function()
                Screen.cancelReset()
            end,
        })
    )
    builder:addItem(
        id("reset:confirm"),
        nodes.button({
            label = L["Erase everything"],
            onActivate = function()
                Screen.confirmReset()
            end,
        })
    )
    builder:popContext()
end

-- The question first. Nothing is erased until "Erase everything" is chosen; not at all during a fight.
function Screen.openReset(from)
    if Game.inCombat() then
        Game.speak(L["Erasing is not possible during a fight. Try again after it."])
        return false
    end
    state.level, state.from = "reset", from
    land("reset:prompt")
    return true
end

function Screen.cancelReset()
    local from = state.from
    state.level, state.from = "list", nil
    Game.speak(L["Nothing was erased."])
    land(from or "overview")
end

function Screen.confirmReset()
    state.level, state.from, state.player = "list", nil, nil
    land("overview")
    Data.reset(Game.speak)
end

-- ------------------------------------------------------------------- screen

function Screen.render(builder, screen)
    Screen.screen = screen
    if state.level == "player" then
        renderPlayer(builder)
    elseif state.level == "reset" then
        renderReset(builder)
    else
        renderList(builder)
    end
end

-- Goes into a player: from is the key of the line to come back to.
function Screen.openPlayer(row, from)
    state.player = Data.reference(row)
    state.player.from = from
    state.level = "player"
    land("player:header")
end

function Screen.close()
    state.level, state.player, state.from = "list", nil, nil
    Game.close()
end

-- One level up; at the top, the screen closes. Going back from the question is saying no.
function Screen.back()
    if state.level == "player" then
        local from = state.player ~= nil and state.player.from or nil
        state.level, state.player = "list", nil
        land(from)
    elseif state.level == "reset" then
        Screen.cancelReset()
    else
        Screen.close()
    end
end

function Screen.config()
    return {
        key = Game.WINDOW,
        -- a frameless window: the game cannot close it for us, so Escape is held by the screen
        captureClose = true,
        letterNavigation = true,
        render = function(builder, screen)
            return Screen.render(builder, screen)
        end,
        onRequestClose = Game.guarded(function()
            Screen.back()
        end),
    }
end

local function open()
    if not Game.open(Screen.config()) then
        Game.speak(L["WowVision's windows are not available."])
        return false
    end
    return true
end

-- Opens the screen, or closes it when it is open (the key and the command both toggle).
function Screen.toggle()
    if Game.isOpen() then
        Screen.close()
        return true
    end
    state.level, state.player, state.from = "list", nil, nil
    Data.clearCache()
    return open()
end
