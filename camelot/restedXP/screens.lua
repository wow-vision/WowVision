-- The screens: what Shift+F2 opens (the step now, the arrow, the guide, RestedXP's menu and settings) and the screen
-- a menu of RestedXP's gets when it is shown. They are WowVision graph screens: a render function that declares the
-- controls from RestedXP's live data each time, and WowVision speaks them and routes the keys. See WowVision's
-- docs/src/developer/graph-ui.md.
local ns = WowVision.restedXP
local L = ns.L
local Text = ns.Text
local Source = ns.Source
local Menu = ns.Menu
local Options = ns.Options
local Guidance = ns.Guidance
local Import = ns.Import
local Perf = ns.Perf
local Game = ns.Game

local Screens = {}
ns.Screens = Screens

local MAIN = "restedxp"
local MENU = "restedxp-menu"
local OPTIONS = "restedxp-settings"
local IMPORT = "restedxp-import"
Screens.MAIN = MAIN
Screens.MENU = MENU
Screens.OPTIONS = OPTIONS
Screens.IMPORT = IMPORT

local UPCOMING = 5

-- Reported once each: a failing render is already reported by WowVision, this is for the actions.
local reported = {}
local function report(err)
    err = tostring(err)
    if reported[err] then
        return
    end
    reported[err] = true
    geterrorhandler()("WowVision_RestedXP: " .. err)
end
Screens.report = report

local function graph()
    return WowVision.graph
end

local function id(key)
    return graph().ControlId.structural(key)
end

local function groupVtable(label)
    local g = graph()
    return {
        controlType = g.controlTypes.group,
        announcements = { { text = label, kind = g.kinds.label } },
    }
end

-- An entry that cannot be used now reads as unavailable, and Enter and the arrows do nothing but say so.
local function guardDisabled(vtable, isDisabled)
    local g = graph()
    tinsert(vtable.announcements, {
        text = function()
            if isDisabled() then
                return L["unavailable"]
            end
            return nil
        end,
        kind = g.kinds.enabled,
    })
    local activate = vtable.onActivate
    if activate ~= nil then
        vtable.onActivate = function(...)
            if isDisabled() then
                Game.speak(L["unavailable"])
                return
            end
            return activate(...)
        end
    end
    local adjust = vtable.onAdjust
    if adjust ~= nil then
        vtable.onAdjust = function(...)
            if isDisabled() then
                return
            end
            return adjust(...)
        end
    end
    return vtable
end

-- ------------------------------------------------------- what is said live

function Screens.arrowSpeech(rxp)
    local ok, arrow = pcall(Source.arrow, rxp, Game.hbd(), Game.facing())
    if not ok then
        return L["The game hides the position."]
    end
    return Text.arrow(arrow)
end

local function guideSpeech(rxp)
    local info = Source.guide(rxp)
    if info == nil then
        return L["No guide chosen. Open the menu to choose one."]
    end
    local parts = {}
    if info.name ~= nil then
        tinsert(parts, info.name)
    end
    tinsert(parts, string.format(L["Step %d of %d"], info.step, info.steps))
    return table.concat(parts, ". ")
end
Screens.guideSpeech = guideSpeech

-- ------------------------------------------------------------ the steps

local function renderSteps(builder, rxp)
    local nodes = graph().nodes
    builder:beginStop("steps")
    builder:pushContext("steps", L["Guide"])
    builder:addItem(
        id("guide"),
        nodes.text({
            label = function()
                return guideSpeech(rxp)
            end,
            live = "focus",
        })
    )
    local steps = Source.activeSteps(rxp)
    if #steps == 0 then
        if Source.hasGuide(rxp) then
            builder:addItem(id("nosteps"), nodes.text({ label = L["No step to show right now."] }))
        end
    end
    for position, entry in ipairs(steps) do
        local key = entry.index ~= nil and tostring(entry.index) or ("tip" .. position)
        builder:pushContext("step:" .. key, entry.title or L["Ongoing step"])
        for _, line in ipairs(entry.lines) do
            local lineId = id("line:" .. key .. ":" .. line.number)
            if line.info then
                builder:addItem(lineId, nodes.text({ label = line.text, live = "focus" }))
            elseif line.optional or Source.isLocked(line) then
                builder:addItem(
                    lineId,
                    nodes.text({
                        label = function()
                            if Source.isDone(line) then
                                return line.text .. ", " .. L["done"]
                            end
                            return line.text
                        end,
                        live = "focus",
                    })
                )
            else
                builder:addItem(
                    lineId,
                    nodes.toggle({
                        label = line.text,
                        get = function()
                            return Source.isDone(line)
                        end,
                        set = function(wanted)
                            if not Source.setLine(rxp, line, wanted) then
                                Game.speak(L["That box cannot be changed."])
                            end
                        end,
                        valueText = function()
                            return Source.isDone(line) and L["done"] or L["to do"]
                        end,
                    })
                )
            end
        end
        builder:popContext()
    end
    builder:popContext()
end

-- ------------------------------------------------------------- the arrow

local function startGuidance(rxp, mode)
    local arrow = Source.arrow(rxp, Game.hbd(), Game.facing())
    local ok, why = Guidance.start(Game.maps(), arrow, mode)
    if not ok then
        Game.speak(why)
    end
end

local function renderArrow(builder, rxp)
    local nodes = graph().nodes
    builder:beginStop("arrow")
    builder:pushContext("arrow", L["Arrow"])
    builder:addItem(
        id("arrow:where"),
        nodes.text({
            label = function()
                return Screens.arrowSpeech(rxp)
            end,
            live = "focus",
        })
    )
    builder:addItem(
        id("arrow:beacon"),
        nodes.button({
            label = L["Sound beacon toward the destination"],
            selected = function()
                return Guidance.following == "beacon"
            end,
            onActivate = function()
                startGuidance(rxp, "beacon")
            end,
        })
    )
    builder:addItem(
        id("arrow:route"),
        nodes.button({
            label = L["WowVision route to the destination"],
            selected = function()
                return Guidance.following == "route"
            end,
            onActivate = function()
                startGuidance(rxp, "route")
            end,
        })
    )
    local maps = Game.maps()
    if Guidance.following ~= nil or (maps ~= nil and maps.isGuiding ~= nil and maps:isGuiding()) then
        builder:addItem(
            id("arrow:stop"),
            nodes.button({
                label = L["Stop guiding"],
                onActivate = function()
                    if not Guidance.stop(Game.maps()) then
                        Game.speak(L["Guidance stopped."])
                    end
                end,
            })
        )
    end
    builder:addItem(
        id("arrow:recalculate"),
        nodes.toggle({
            label = L["Recalculate the guidance when the arrow changes destination"],
            get = function()
                return Game.getSetting("recalculate") ~= false
            end,
            set = function(value)
                Game.setSetting("recalculate", value)
            end,
        })
    )
    builder:addItem(
        id("arrow:smallMoves"),
        nodes.toggle({
            label = string.format(L["Ignore small moves of the arrow (under %s)"], Text.yards(Guidance.smallMove)),
            get = function()
                return Game.getSetting("ignoreSmallMoves") == true
            end,
            set = function(value)
                Game.setSetting("ignoreSmallMoves", value)
            end,
        })
    )
    builder:popContext()
end

-- --------------------------------------------------------- the guide's steps

local function renderNavigation(builder, rxp)
    local nodes = graph().nodes
    local info = Source.guide(rxp)
    if info == nil then
        return
    end
    builder:beginStop("navigation")
    builder:pushContext("navigation", L["Move in the guide"])
    builder:addItem(
        id("nav:skip"),
        nodes.button({
            label = L["Skip the step now shown"],
            onActivate = function()
                if Source.skipActive(rxp) == 0 then
                    Game.speak(L["Nothing to skip."])
                end
            end,
        })
    )
    builder:addItem(
        id("nav:previous"),
        nodes.button({
            label = L["Previous step"],
            onActivate = function()
                local now = Source.guide(rxp)
                if now ~= nil then
                    Source.goToStep(rxp, now.step - 1)
                end
            end,
        })
    )
    builder:addItem(
        id("nav:next"),
        nodes.button({
            label = L["Next step"],
            onActivate = function()
                local now = Source.guide(rxp)
                if now ~= nil then
                    Source.goToStep(rxp, now.step + 1)
                end
            end,
        })
    )
    builder:addItem(
        id("nav:goto"),
        nodes.number({
            label = L["Go to step number"],
            get = function()
                local now = Source.guide(rxp)
                return now ~= nil and now.step or nil
            end,
            set = function(value)
                Source.goToStep(rxp, value)
            end,
            step = 1,
            largeStep = 10,
            valueText = function()
                local now = Source.guide(rxp)
                if now == nil then
                    return nil
                end
                return string.format(L["Step %d of %d"], now.step, now.steps)
            end,
        })
    )
    local upcoming = id("nav:upcoming")
    builder:beginGroup(upcoming, groupVtable(L["Steps to come"]))
    if builder:isExpanded(upcoming) then
        local entries = Source.upcoming(rxp, UPCOMING, Game.playerLevel())
        if #entries == 0 then
            builder:addItem(id("nav:upcoming:none"), nodes.text({ label = L["No step to come."] }))
        end
        for _, entry in ipairs(entries) do
            builder:addItem(
                id("nav:upcoming:" .. entry.index),
                nodes.text({ label = Source.stepSpeech(entry) })
            )
        end
    end
    builder:endGroup()
    builder:popContext()
end

-- ------------------------------------------------- active items and targets

local function renderButtons(builder)
    local nodes = graph().nodes
    local ControlId = graph().ControlId
    local sections = {
        { key = "items", label = L["Items to use"], list = Source.activeItems() },
        { key = "enemies", label = L["Enemies to target"], list = Source.activeTargets("Enemy") },
        { key = "friends", label = L["Friendly characters to target"], list = Source.activeTargets("Friendly") },
    }
    for _, section in ipairs(sections) do
        if #section.list > 0 then
            builder:beginStop(section.key)
            builder:pushContext(section.key, section.label)
            for _, entry in ipairs(section.list) do
                builder:addItem(
                    ControlId.forObject(entry.frame),
                    nodes.proxyButton({ target = entry.frame, label = entry.label })
                )
            end
            builder:popContext()
        end
    end
end

-- -------------------------------------------------------------- the menus

-- The texts RestedXP shows for some English entries of its menu, in the game's language: the English and the
-- translation, as a set.
local function menuTexts(rxp, englishList)
    local texts = {}
    local function add(text)
        text = Text.plain(text)
        if text ~= nil then
            texts[text] = true
        end
    end
    for _, english in ipairs(englishList) do
        add(english)
        if type(rxp.locale) == "table" and type(rxp.locale.Get) == "function" then
            local ok, localized = pcall(rxp.locale.Get, english)
            if ok then
                add(localized)
            end
        end
    end
    return texts
end

-- Entries of RestedXP's menu that open one of its own windows (a report, a wizard, a feedback form), which cannot
-- be used from here, or that this screen replaces (the settings, the close entry).
local function skippedTexts(rxp)
    local skipped = menuTexts(rxp, { "Leveling report", "Open Feedback Form", "Run Guide Configurator" })
    local close = Text.plain(rawget(_G, "CLOSE") or "Close")
    if close ~= nil then
        skipped[close] = true
    end
    return skipped
end

-- RestedXP's "Import guide" entry opens its import window, which cannot be used from here: the entry opens the
-- import screen instead.
local function importTexts(rxp)
    return menuTexts(rxp, { "Import guide" })
end

local function importItem()
    return {
        kind = "button",
        text = L["Import a guide"],
        disabled = false,
        info = {
            func = function()
                Game.defer(Screens.openImport)
            end,
        },
    }
end

local function optionsText()
    return Text.plain((rawget(_G, "GAMEOPTIONS_MENU") or "Options") .. "...")
end

-- Declares the items of a menu (see Menu.items). Submenus are groups built only while open; a button runs the item
-- then closes the window with `close`, unless the item keeps the menu open.
local function renderMenuItems(builder, items, prefix, actions)
    local nodes = graph().nodes
    for index, item in ipairs(items) do
        local key = prefix .. "/" .. index .. ":" .. item.text
        if item.kind == "title" then
            builder:addItem(id(key), nodes.text({ label = item.text }))
        elseif item.kind == "submenu" then
            local groupId = id(key)
            builder:beginGroup(groupId, groupVtable(item.text))
            if builder:isExpanded(groupId) then
                renderMenuItems(builder, item.children(), key, actions)
            end
            builder:endGroup()
        elseif item.disabled or not Menu.canActivate(item) then
            builder:addItem(id(key), nodes.text({ label = item.text .. ", " .. L["unavailable"] }))
        elseif item.kind == "toggle" then
            builder:addItem(
                id(key),
                nodes.toggle({
                    label = item.text,
                    get = item.checked,
                    set = function()
                        actions.run(item)
                    end,
                })
            )
        else
            builder:addItem(
                id(key),
                nodes.button({
                    label = item.text,
                    onActivate = function()
                        actions.run(item)
                    end,
                })
            )
        end
    end
end

-- The actions of a menu screen: running an item closes the window first (in a later moment, never from inside the
-- key that is using it), then runs it, then hides RestedXP's own drop-down if it is showing.
local function menuActions(rxp, windowName)
    local actions = {}
    function actions.run(item)
        if Menu.keepsOpen(item) then
            local ok, err = Menu.activate(item)
            if not ok and err then
                report(err)
            end
            return
        end
        Game.defer(function()
            Game.close(windowName)
            local ok, err = Menu.activate(item)
            if not ok and err then
                report(err)
                Game.speak(L["That entry failed."])
            end
            if type(rxp.CloseMenu) == "function" then
                pcall(rxp.CloseMenu, rxp)
            end
        end)
    end
    return actions
end

-- The items of RestedXP's right-click menu for the main screen: without what cannot be used from here.
local function mainMenuItems(rxp)
    local skipped = skippedTexts(rxp)
    local imports = importTexts(rxp)
    local options = optionsText()
    local result = {}
    for _, item in ipairs(Menu.items(Perf.time("menu build", Source.menu, rxp))) do
        if imports[item.text] then
            result[#result + 1] = importItem()
        elseif not skipped[item.text] and item.text ~= options then
            result[#result + 1] = item
        end
    end
    return result
end

local function renderMenu(builder, rxp, screen)
    builder:beginStop("menu")
    builder:pushContext("menu", L["RestedXP menu"])
    if screen.rxpMenu == nil then
        screen.rxpMenu = mainMenuItems(rxp)
    end
    renderMenuItems(builder, screen.rxpMenu, "menu", menuActions(rxp, MAIN))
    builder:popContext()
end

-- ------------------------------------------------------------- the settings

-- Bumped by every change of a setting: what was read about the options before it is read again.
local optionsVersion = 0

-- The visible options of a group, as Options.entries reads them. A screen is rebuilt every frame; the order, the
-- names and which options are hidden are not read again for a quarter of a second (the values and what is
-- greyed out are always read live by the controls themselves), nor after a change.
local ENTRIES_SECONDS = 0.25

local function optionEntries(screen, ctx, path)
    local now = Game.now()
    if now == nil or type(screen) ~= "table" then
        return Options.entries(ctx, path)
    end
    local cache = screen.rxpEntries
    if cache == nil then
        cache = {}
        screen.rxpEntries = cache
    end
    local key = table.concat(path, "/")
    local hit = cache[key]
    if hit ~= nil and hit.version == optionsVersion and now - hit.time < ENTRIES_SECONDS then
        return hit.entries
    end
    local entries = Options.entries(ctx, path)
    cache[key] = { time = now, version = optionsVersion, entries = entries }
    return entries
end

local function commit(entry, ...)
    local nodes = graph().nodes
    local ok, message = entry.check(...)
    if not ok then
        Game.speak(message)
        return false
    end
    local args = { ... }
    local count = select("#", ...)
    local function run()
        local done, err = entry.commit(unpack(args, 1, count))
        optionsVersion = optionsVersion + 1
        if not done then
            report(err)
            Game.speak(L["That setting could not be changed."])
            return
        end
        local rxp = Game.rxp()
        if rxp ~= nil then
            Game.notifyOptionsChanged(rxp.title)
        end
    end
    local confirm = entry.confirmText(...)
    if confirm ~= nil then
        nodes.pushConfirm({ prompt = confirm, confirmLabel = L["Yes"], cancelLabel = L["No"], onConfirm = run })
    else
        run()
    end
    return true
end

local function hexOf(r, g, b)
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
        return nil
    end
    return string.format("#%02X%02X%02X", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
Screens.hexOf = hexOf

local function parseHex(text)
    local hex = tostring(text):match("^%s*#?(%x%x%x%x%x%x)%s*$")
    if hex == nil then
        return nil
    end
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end
Screens.parseHex = parseHex

local function optionVtable(entry)
    local nodes = graph().nodes
    local kind = entry.type
    if kind == "toggle" then
        return nodes.toggle({
            label = entry.label,
            get = function()
                return entry.get() and true or false
            end,
            set = function(value)
                commit(entry, value)
            end,
        })
    elseif kind == "range" then
        local min, max, step, bigStep, isPercent = entry.range()
        local scale = isPercent and 100 or 1
        local stepSize = step or (min ~= nil and max ~= nil and (max - min) / 20) or 1
        local function clamp(value)
            value = tonumber(value)
            if value == nil then
                return nil
            end
            if min ~= nil then
                if step ~= nil then
                    value = math.floor((value - min) / step + 0.5) * step + min
                end
                value = math.max(value, min)
            end
            if max ~= nil then
                value = math.min(value, max)
            end
            return value
        end
        -- a value as it is typed and said: three decimals at most, none for a whole number
        local function tidy(value)
            value = math.floor(value * 1000 + 0.5) / 1000
            local whole = math.floor(value)
            if whole == value then
                return whole
            end
            return value
        end
        return nodes.number({
            label = entry.label,
            get = function()
                local value = entry.get()
                return type(value) == "number" and tidy(value * scale) or nil
            end,
            set = function(value)
                local clamped = clamp(value / scale)
                if clamped ~= nil then
                    commit(entry, clamped)
                end
            end,
            step = stepSize * scale,
            largeStep = (bigStep or stepSize * 5) * scale,
            valueText = function()
                local value = entry.get()
                if type(value) ~= "number" then
                    return nil
                end
                if isPercent then
                    return string.format(L["%d percent"], math.floor(value * 100 + 0.5))
                end
                return tostring(tidy(value))
            end,
        })
    elseif kind == "select" then
        return nodes.choice({
            label = entry.label,
            get = function()
                return entry.get()
            end,
            set = function(value)
                commit(entry, value)
            end,
            choices = function()
                return entry.choices()
            end,
        })
    elseif kind == "input" or kind == "keybinding" then
        return nodes.textInput({
            label = entry.label,
            autoInput = false,
            get = function()
                local value = entry.get()
                return value ~= nil and tostring(value) or ""
            end,
            set = function(text)
                commit(entry, text)
            end,
        })
    elseif kind == "color" then
        return nodes.textInput({
            label = entry.label,
            autoInput = false,
            get = function()
                local r, g, b = entry.get()
                return hexOf(r, g, b) or ""
            end,
            set = function(text)
                local r, g, b = parseHex(text)
                if r == nil then
                    Game.speak(L["A colour is written as six hexadecimal digits, like FF8800."])
                    return
                end
                local _, _, _, a = entry.get()
                commit(entry, r, g, b, a or 1)
            end,
        })
    elseif kind == "execute" then
        return nodes.button({
            label = entry.label,
            onActivate = function()
                commit(entry)
            end,
        })
    end
    return nil
end

local renderOptionsGroup

-- One option. Groups and lists of boxes open as tree sections, built only while open.
local function renderOption(builder, ctx, entry, screen)
    local nodes = graph().nodes
    local key = "opt:" .. table.concat(entry.path, "/")
    local optionId = id(key)
    if entry.type == "group" then
        builder:beginGroup(optionId, groupVtable(entry.label()))
        if builder:isExpanded(optionId) then
            renderOptionsGroup(builder, ctx, entry.path, screen)
        end
        builder:endGroup()
    elseif entry.type == "header" then
        builder:addItem(optionId, nodes.text({ label = entry.label() }))
    elseif entry.type == "description" then
        builder:addItem(optionId, nodes.text({ label = entry.label, live = "focus" }))
    elseif entry.type == "multiselect" then
        builder:beginGroup(optionId, groupVtable(entry.label()))
        if builder:isExpanded(optionId) then
            for _, choice in ipairs(entry.choices()) do
                builder:addItem(
                    id(key .. "/" .. tostring(choice.value)),
                    nodes.toggle({
                        label = choice.label,
                        get = function()
                            return entry.get(choice.value) and true or false
                        end,
                        set = function(value)
                            commit(entry, choice.value, value)
                        end,
                    })
                )
            end
        end
        builder:endGroup()
    else
        local vtable = optionVtable(entry)
        if vtable == nil then
            builder:addItem(optionId, nodes.text({ label = entry.label }))
        else
            builder:addItem(optionId, guardDisabled(vtable, entry.disabled))
        end
    end
end

function renderOptionsGroup(builder, ctx, path, screen)
    for _, entry in ipairs(optionEntries(screen, ctx, path)) do
        renderOption(builder, ctx, entry, screen)
    end
end

local function renderSettings(builder, rxp, screen)
    local nodes = graph().nodes
    local ctx = Perf.time("options table", Options.find, rxp.title)
    if ctx == nil then
        return
    end
    builder:beginStop("settings")
    builder:pushContext("settings", L["RestedXP settings"])
    renderOptionsGroup(builder, ctx, {}, screen)
    builder:popContext()
end

-- RestedXP's page of the game's options window (Options, AddOns, RestedXP Guides): the same settings as the main
-- screen, shown beside WowVision's own window for the options. The page itself is a frame of widgets nothing can
-- read; the screen goes away when the page does.
function Screens.renderOptions(builder, screen)
    local rxp = Game.rxp()
    if rxp == nil or not Game.optionsShown() then
        return
    end
    local ctx = Perf.time("options table", Options.find, rxp.title)
    if ctx == nil then
        return
    end
    builder:pushContext("options", L["RestedXP settings"])
    renderOptionsGroup(builder, ctx, {}, screen)
    builder:popContext()
end

function Screens.optionsConfig()
    return {
        key = OPTIONS,
        letterNavigation = true,
        render = function(builder, screen)
            return Perf.time("options screen", Screens.renderOptions, builder, screen)
        end,
    }
end

-- Registers that screen as a window WowVision opens and closes with the page.
function Screens.registerOptionsWindow()
    return Game.registerWindow(OPTIONS, function()
        return Perf.time("window poll", Game.optionsShown)
    end, Screens.optionsConfig())
end

-- This addon's own settings.
local function renderOwn(builder)
    local nodes = graph().nodes
    builder:beginStop("own")
    builder:pushContext("own", L["Spoken help"])
    builder:addItem(
        id("own:steps"),
        nodes.toggle({
            label = L["Say each new step"],
            get = function()
                return Game.getSetting("announceSteps") ~= false
            end,
            set = function(value)
                Game.setSetting("announceSteps", value)
            end,
        })
    )
    builder:addItem(
        id("own:destination"),
        nodes.toggle({
            label = L["Say where the arrow points when it changes"],
            get = function()
                return Game.getSetting("announceDestination") == true
            end,
            set = function(value)
                Game.setSetting("announceDestination", value)
            end,
        })
    )
    builder:popContext()
end

-- ------------------------------------------------------------- the windows

function Screens.renderMain(builder, screen)
    local nodes = graph().nodes
    local rxp = Game.rxp()
    if rxp == nil then
        builder:addItem(id("missing"), nodes.text({ label = L["RestedXP is not loaded."] }))
        return
    end
    builder:pushContext("restedxp", L["RestedXP"])
    renderSteps(builder, rxp)
    renderArrow(builder, rxp)
    renderNavigation(builder, rxp)
    renderButtons(builder)
    renderMenu(builder, rxp, screen)
    renderSettings(builder, rxp, screen)
    renderOwn(builder)
    builder:popContext()
end

function Screens.mainConfig()
    return {
        key = MAIN,
        captureClose = true,
        letterNavigation = true,
        render = function(builder, screen)
            return Perf.time("main screen", Screens.renderMain, builder, screen)
        end,
        onRequestClose = function()
            Game.close(MAIN)
        end,
    }
end

-- The screen for a menu RestedXP shows: list is the menu table given to its ShowMenu.
function Screens.menuConfig(list)
    return {
        key = MENU,
        captureClose = true,
        letterNavigation = true,
        render = function(builder, screen)
            return Perf.time("menu screen", Screens.renderMenuList, builder, screen, list)
        end,
        onRequestClose = function()
            Game.close(MENU)
            local rxp = Game.rxp()
            if rxp ~= nil and type(rxp.CloseMenu) == "function" then
                pcall(rxp.CloseMenu, rxp)
            end
        end,
    }
end

-- Declares a menu RestedXP shows (see Screens.menuConfig).
function Screens.renderMenuList(builder, screen, list)
    local rxp = Game.rxp()
    if rxp == nil then
        return
    end
    if screen.rxpMenu == nil then
        local skipped = skippedTexts(rxp)
        local imports = importTexts(rxp)
        local options = optionsText()
        screen.rxpMenu = {}
        for _, item in ipairs(Menu.items(list)) do
            if imports[item.text] then
                item = importItem()
            elseif item.text == options then
                -- RestedXP's settings window cannot be used from here: the settings are in the main screen
                item = {
                    kind = "button",
                    text = L["RestedXP settings"],
                    disabled = false,
                    info = {
                        func = function()
                            Game.defer(Screens.toggleMain)
                        end,
                    },
                }
            end
            if not skipped[item.text] then
                screen.rxpMenu[#screen.rxpMenu + 1] = item
            end
        end
    end
    builder:pushContext("menu", L["RestedXP menu"])
    renderMenuItems(builder, screen.rxpMenu, "menu", menuActions(rxp, MENU))
    builder:popContext()
end

-- ------------------------------------------------------------- the import

local function confirmThen(prompt, onConfirm)
    graph().nodes.pushConfirm({
        prompt = prompt,
        confirmLabel = L["Yes"],
        cancelLabel = L["No"],
        onConfirm = onConfirm,
    })
end

-- The paste box takes the keyboard; the player pastes with Ctrl+V.
local function pasteGuide()
    local ok, why = Import.beginPaste(Game.rxp())
    if ok then
        Game.speak(L["Press Ctrl+V to paste the guide string, or Escape to cancel."])
    else
        Game.speak(Import.why(why) or L["That entry failed."])
    end
end

-- RestedXP reports how the import goes, out loud through the hook; what is said here is only why nothing started.
local function importPasted()
    local rxp = Game.rxp()
    if rxp == nil then
        return
    end
    local ok, why, detail = Import.run(rxp)
    if ok or why == "failed" then
        return
    end
    if why == "error" then
        report(detail)
        Game.speak(L["That entry failed."])
        return
    end
    Game.speak(Import.why(why) or L["That entry failed."])
end

local function removeGuide(guide)
    confirmThen(string.format(L["Remove %s?"], guide.name), function()
        local rxp = Game.rxp()
        if rxp ~= nil and Import.remove(rxp, guide.key) then
            Game.speak(L["The guide was removed."])
        else
            Game.speak(L["That guide could not be removed."])
        end
    end)
end

local function purgeGuides()
    confirmThen(
        L["This removes ALL imported guides from RestedXP's saved data, as its Purge button does, and forgets the quests you skipped or put first. Are you sure?"],
        function()
            local rxp = Game.rxp()
            if rxp ~= nil and Import.purge(rxp) then
                Game.speak(L["All imported guides were removed."])
            else
                Game.speak(L["The guides could not be removed."])
            end
        end
    )
end

-- The guides already imported: a section that opens, each guide a button that asks before removing it.
local function renderImportedGuides(builder, rxp)
    local nodes = graph().nodes
    local groupId = id("import:guides")
    builder:beginGroup(groupId, groupVtable(L["Imported guides"]))
    if builder:isExpanded(groupId) then
        local list = Import.guides(rxp)
        if #list == 0 then
            builder:addItem(id("import:none"), nodes.text({ label = L["No imported guides."] }))
        end
        for _, guide in ipairs(list) do
            builder:addItem(
                id("import:guide:" .. guide.key),
                nodes.button({
                    label = guide.label,
                    onActivate = function()
                        removeGuide(guide)
                    end,
                })
            )
        end
    end
    builder:endGroup()
end

-- Where the import stands is read live; the last message RestedXP gave stays here for whoever missed it.
function Screens.renderImport(builder)
    local nodes = graph().nodes
    local rxp = Game.rxp()
    if rxp == nil then
        builder:addItem(id("missing"), nodes.text({ label = L["RestedXP is not loaded."] }))
        return
    end
    if Import.importer(rxp) == nil then
        builder:addItem(id("no-importer"), nodes.text({ label = L["RestedXP has no guide importer."] }))
        return
    end
    builder:pushContext("import", L["Import a guide"])

    builder:beginStop("paste")
    builder:pushContext("paste", L["Paste and import"])
    builder:addItem(
        id("import:status"),
        nodes.text({
            label = function()
                local current = Game.rxp()
                return current ~= nil and Import.statusText(current) or ""
            end,
        })
    )
    local state = Import.state(rxp)
    if state ~= nil and state.last ~= nil then
        builder:addItem(
            id("import:last"),
            nodes.text({
                label = function()
                    local current = Game.rxp()
                    local now = current ~= nil and Import.state(current) or nil
                    if now == nil or now.last == nil then
                        return ""
                    end
                    return string.format(L["Last message: %s"], now.last)
                end,
            })
        )
    end
    builder:addItem(
        id("import:paste"),
        nodes.button({ label = L["Paste a guide string"], onActivate = pasteGuide })
    )
    builder:addItem(
        id("import:run"),
        nodes.button({ label = L["Import the pasted guides"], onActivate = importPasted })
    )
    builder:popContext()

    builder:beginStop("manage")
    builder:pushContext("manage", L["Manage imported guides"])
    renderImportedGuides(builder, rxp)
    builder:addItem(
        id("import:purge"),
        nodes.button({ label = L["Remove all imported guides"], onActivate = purgeGuides })
    )
    builder:addItem(
        id("import:reload"),
        nodes.button({
            label = L["Reload the interface"],
            onActivate = function()
                confirmThen(L["Reload the interface now?"], Game.reload)
            end,
        })
    )
    builder:popContext()

    builder:popContext()
end

-- RestedXP's window is shown only so that its paste box can be used: it goes away with this screen.
function Screens.closeImport()
    Game.close(IMPORT)
    local rxp = Game.rxp()
    if rxp ~= nil then
        Import.hide(rxp)
    end
end

function Screens.importConfig()
    return {
        key = IMPORT,
        captureClose = true,
        letterNavigation = true,
        render = function(builder, screen)
            return Perf.time("import screen", Screens.renderImport, builder, screen)
        end,
        onRequestClose = Screens.closeImport,
    }
end

-- The import screen: opened by the "Import a guide" entry of RestedXP's menu.
function Screens.openImport()
    if Game.inCombat() then
        Game.speak(L["Not available in combat."])
        return
    end
    local rxp = Game.rxp()
    if rxp == nil then
        Game.speak(L["RestedXP is not loaded."])
        return
    end
    if Import.importer(rxp) == nil then
        Game.speak(L["RestedXP has no guide importer."])
        return
    end
    if Game.isOpen(IMPORT) then
        Game.close(IMPORT)
    end
    if not Game.open(IMPORT, Screens.importConfig()) then
        Game.speak(L["WowVision's windows are not available."])
    end
end

-- Shift+F2: opens the main screen, or closes it when it is open.
function Screens.toggleMain()
    if Game.isOpen(MAIN) then
        Game.close(MAIN)
        return
    end
    if Game.inCombat() then
        Game.speak(L["Not available in combat."])
        return
    end
    if not Game.open(MAIN, Screens.mainConfig()) then
        Game.speak(L["WowVision's windows are not available."])
    end
end

-- A menu of RestedXP's is being shown: open the screen for it (the drop-down stays, for anyone who sees it).
function Screens.openMenu(list)
    if Game.isOpen(MAIN) or Game.inCombat() then
        return
    end
    if Game.isOpen(MENU) then
        Game.close(MENU)
    end
    Game.open(MENU, Screens.menuConfig(list))
end
