local graph = WowVision.graph
local announcer = graph.announcer

-- The graph host: owns the open screen stacks, the per-tick rebuild loop, the
-- announce-once differ, the live watch, and input routing. Focus changes are
-- announced exactly once no matter what caused them (a keypress, a content
-- rebuild, the game closing a frame).
--
-- Window stacks: each open window owns one stack; ctrl-tab cycles focus
-- between stacks (a host operation, not node edges). Child screens push onto
-- their stack and pop on close.
--
-- Input: while any stack is open the host holds the navigation keymaps
-- (arrows, tab, ctrl-tab, home/end) as Function actions routing into
-- onKey. The focused node's own binding declarations (vtable.bindings, plus
-- defaults for onActivate/onSecondary) engage when reconciled focus lands on
-- it and release when it leaves -- keyed to the focused ControlId, so mere
-- rebuilds never churn secure frames. Override bindings cannot change during
-- combat lockdown: all handles release on PLAYER_REGEN_DISABLED (the last
-- pre-lockdown window) and re-engage on the first update after combat.
-- Nothing engages while a key it would take is physically held: the engine
-- gives a key's release to whoever owns the key at that moment, so an
-- override landing on a held arrow left the player turning in circles
-- (windows open on their own in a party, and combat ends mid-run). The
-- engage is retried every tick until the keys are up (core/ui/input/heldKeys.lua).
--
-- Coexistence caveat: while a graph stack and an old-framework window are open
-- at the same time, both navigators hold the same navigation keys and the
-- later activation wins. Screens are migrated window-by-window, so the overlap
-- window is small; the bridge owns any per-window exceptions.
local GraphHost = WowVision.Class("GraphHost")
graph.GraphHost = GraphHost

-- Escape is deliberately absent: the game closes its own frames (with its own
-- sounds), and hotkeys the game already handles are never overridden. A screen
-- that needs a close key (a child screen the game doesn't know about) must opt
-- in explicitly via its config.
local NAV_KEYMAPS = {
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
}

-- Letter navigation (typeAhead.lua): where the focused stack or screen opts in with letterNavigation (the WowVision
-- menu, context and dropdown menus -- lists that own the keyboard) and in a window whose own switch is on (Letter
-- Navigation in its menu, off by default: Module:addWindowLetterSetting). While engaged the letters do nothing in the
-- game, so they wait for every letter key to be up and release with the navigation keys (combat, all stacks closed).
-- Plain letters only, and the umlauts of a German keyboard as Sku binds them; an edit box with the keyboard gets its
-- letters as before.
local LETTER_KEYS = {}
for code = string.byte("A"), string.byte("Z") do
    tinsert(LETTER_KEYS, string.char(code))
end
local UMLAUT_KEYS = {}
for _, key in ipairs({ "Ä", "Ö", "Ü", "ä", "ö", "ü", "ß" }) do
    tinsert(LETTER_KEYS, key)
    UMLAUT_KEYS[key] = true
end

-- An umlaut can reach the list twice for one press (its key binding and the typed character): the second is dropped.
local UMLAUT_ONCE = 0.05

function GraphHost:initialize()
    self.stacks = {}
    self.focusedIndex = 0
    self._navHandles = {}
    self._letterHandles = {}
    self._typeAheadState = graph.typeAhead.newState()
    self._doublePressState = graph.doublePress.newState()
    self._nodeHandles = {}
    self._focusNodeId = nil
    self._focusNode = nil
    self._bindingsDirty = false
    -- The focused node's bindings are waiting for a held key to be released.
    self._engageDeferred = false
    -- /wv keylog: print when the navigation keys are taken, waited for and
    -- released, with what the held check saw, for chasing stuck keys.
    self.keyLog = false
    self._navWaitLogged = false

    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:SetScript("OnEvent", function()
        -- Last pre-lockdown window: drop every override binding now; the
        -- update loop re-engages after combat.
        self:_releaseNavBindings()
        self:_releaseNodeHandles()
        self._bindingsDirty = true
    end)
end

-- ---- stack lifecycle ----

function GraphHost:open(config)
    local screen = graph.Screen:new(config)
    local stack = { screens = { screen }, config = config }
    tinsert(self.stacks, stack)
    -- Background stacks (bags auto-opening at a vendor) never steal focus
    -- from an already-open stack; they are still reachable by stack cycling.
    if config.background and self.focusedIndex ~= nil and self.focusedIndex >= 1 and #self.stacks > 1 then
        return stack
    end
    self.focusedIndex = #self.stacks
    screen:resetAnnouncement()
    self._bindingsDirty = true
    WowVision.base.speech:uiStop()
    return stack
end

function GraphHost:close(stack)
    for i, open in ipairs(self.stacks) do
        if open == stack then
            table.remove(self.stacks, i)
            if self.focusedIndex > #self.stacks then
                self.focusedIndex = #self.stacks
            end
            local screen = self:focusedScreen()
            if screen ~= nil then
                screen:resetAnnouncement()
            end
            self._bindingsDirty = true
            return true
        end
    end
    return false
end

function GraphHost:push(stack, config)
    -- going one level deeper ends a filter, as in Sku's menu
    self:clearListFilter(stack.screens[#stack.screens], false)
    local screen = graph.Screen:new(config)
    tinsert(stack.screens, screen)
    screen:resetAnnouncement()
    self._bindingsDirty = true
    return screen
end

function GraphHost:pop(stack)
    if #stack.screens <= 1 then
        return nil
    end
    local removed = table.remove(stack.screens)
    local top = stack.screens[#stack.screens]
    top:resetAnnouncement()
    self._bindingsDirty = true
    return removed
end

function GraphHost:focusedStack()
    return self.stacks[self.focusedIndex]
end

function GraphHost:focusedScreen()
    local stack = self:focusedStack()
    if stack == nil then
        return nil
    end
    return stack.screens[#stack.screens]
end

function GraphHost:isOpen()
    return #self.stacks > 0
end

-- ---- per-tick pull: rebuild, announce-once, live watch, binding sync ----

function GraphHost:update()
    if #self.stacks == 0 then
        if #self._navHandles > 0 then
            self:_logKeys("released the navigation keys")
        end
        self:_releaseNavBindings()
        self:_dropNodeFocus()
        return
    end
    if InCombatLockdown() then
        return
    end
    if #self._navHandles == 0 then
        if WowVision.inputActivator:anyInputHeld(NAV_KEYMAPS) then
            if not self._navWaitLogged then
                self:_logKeys("waiting for a held key before taking the navigation keys")
                self._navWaitLogged = true
            end
        else
            self:_engageNavBindings()
            self:_logKeys("took the navigation keys")
            self._navWaitLogged = false
        end
    end
    self:_syncCloseKey()
    self:_syncLetterKeys()

    local stack = self:focusedStack()
    local screen = self:focusedScreen()
    if not screen.keyGraph:rerender() then
        -- The render produced nothing: the screen closed itself.
        if #stack.screens > 1 then
            self:pop(stack)
        else
            self:close(stack)
        end
        return
    end

    local node = screen.keyGraph:currentNode()
    if node ~= nil then
        if screen._lastSpokenKey == nil or screen._lastSpokenKey ~= node.id then
            local from = screen._lastSpokenNode
            self:_speak(announcer.compose(from, node))
            screen._lastSpokenKey = node.id
            screen._lastSpokenNode = node
        end
        self:_watchLive(screen, node)
        -- Scroll adapters re-align their pane each tick if the focused entry
        -- scrolled out from under them (stateless; never touches bindings).
        if node.vtable.onFocusTick ~= nil then
            pcall(node.vtable.onFocusTick)
        end
        self:_checkClickDrift(node)
    end
    self:_watchAlways(screen, node)
    self:_syncNodeFocus(screen)
    -- A new screen landing on an edit box hands it the keyboard, as a tab
    -- arrival would; returning to a screen (pop, stack cycling) does not.
    if screen._landingPending then
        screen._landingPending = nil
        if node ~= nil and node.vtable.onOpenFocus ~= nil then
            pcall(node.vtable.onOpenFocus)
        end
    end
end

-- Secure clicks bind to a FRAME at engage time, but scrolled pools rebind
-- frames to entries. Compare what each function-valued Click target resolved
-- to at engage against what it resolves to now; on drift, mark bindings
-- dirty so _syncNodeFocus re-engages node handles this same tick. Nav
-- bindings are never released here.
function GraphHost:_checkClickDrift(node)
    local resolutions = self._clickResolutions
    if resolutions == nil or self._focusNodeId == nil or self._focusNodeId ~= node.id then
        return
    end
    for _, entry in ipairs(resolutions) do
        local ok, current = pcall(entry.resolve)
        if ok and current ~= entry.frame then
            self._clickResolutions = nil
            self._bindingsDirty = true
            return
        end
    end
end

-- A label the game keeps secret (a hidden name in a dungeon) cannot be
-- compared, but speech takes it as it is.
function GraphHost:_speak(text)
    if WowVision.secrets.hasText(text) then
        WowVision:speak(text)
    end
end

function GraphHost:_logKeys(what)
    if not self.keyLog then
        return
    end
    print("WowVision keys: " .. what .. ". " .. WowVision.inputActivator:describeInputs(NAV_KEYMAPS))
end

-- ---- focused-node lifecycle: onFocus/onUnfocus + per-node bindings ----

function GraphHost:_syncNodeFocus(screen)
    if InCombatLockdown() then
        self._bindingsDirty = true
        return
    end
    local node = screen ~= nil and screen.keyGraph:currentNode() or nil
    local newId = node ~= nil and node.id or nil

    if not self._bindingsDirty and newId ~= nil and self._focusNodeId ~= nil and self._focusNodeId == newId then
        self._focusNode = node
        return
    end
    if not self._bindingsDirty and newId == nil and self._focusNodeId == nil then
        return
    end

    -- A retry: the node is already focused and announced; only its bindings
    -- are still waiting for a held key to come up.
    local retry = self._engageDeferred and newId ~= nil and self._focusNodeId == newId
    if not retry then
        local previous = self._focusNode
        if previous ~= nil and previous.vtable.onUnfocus ~= nil and (newId == nil or self._focusNodeId ~= newId) then
            pcall(previous.vtable.onUnfocus, previous)
        end
        self:_releaseNodeHandles()
        self._focusNodeId = newId
        self._focusNode = node
        -- onFocus runs first: scroll adapters materialize the row frame here,
        -- and binding targets may resolve lazily against it at engage.
        if node ~= nil and node.vtable.onFocus ~= nil then
            pcall(node.vtable.onFocus, node)
        end
    end
    self._bindingsDirty = false
    self._engageDeferred = false
    if node ~= nil then
        local specs = self:_nodeBindingSpecs(node)
        local keymaps = {}
        for _, spec in ipairs(specs) do
            tinsert(keymaps, spec.binding)
        end
        if WowVision.inputActivator:anyInputHeld(keymaps) then
            self._engageDeferred = true
            self._bindingsDirty = true
        else
            self:_engageNodeBindings(node, specs)
        end
    end
    if not retry then
        self:_setTooltipFor(node)
    end
end

-- Point the tooltip reader (SPACE and the shift-arrow line keys) at the
-- focused node's tooltip: an explicit vtable.tooltip config, or the game
-- tooltip its hovered frame produced.
function GraphHost:_setTooltipFor(node)
    local tooltip = WowVision.UIHost.tooltip
    if self._tooltipActive then
        pcall(function()
            tooltip:onUnfocus()
            tooltip:reset()
        end)
        self._tooltipActive = false
    end
    if node == nil then
        return
    end
    local data = node.vtable.tooltip
    local frameRef = node.vtable.tooltipFrame
    local frame = type(frameRef) == "function" and frameRef() or frameRef
    if data == nil and frame ~= nil then
        data = { type = "Game", mode = "immediate" }
    end
    if data == nil then
        return
    end
    local ok, err = pcall(function()
        tooltip:set({ frame = frame }, data)
        tooltip:onFocus()
    end)
    if not ok then
        geterrorhandler()(err)
    end
    self._tooltipActive = ok
end

function GraphHost:_dropNodeFocus()
    if self._focusNode ~= nil and self._focusNode.vtable.onUnfocus ~= nil then
        pcall(self._focusNode.vtable.onUnfocus, self._focusNode)
    end
    self:_setTooltipFor(nil)
    self:_releaseNodeHandles()
    self._focusNodeId = nil
    self._focusNode = nil
    self._engageDeferred = false
end

-- The binding specs a focused node asks for: its own declarations plus the
-- defaults for activate, secondary and tooltip.
function GraphHost:_nodeBindingSpecs(node)
    local specs = {}
    local has = {}
    local screen = self:focusedScreen()
    local filtering = screen ~= nil and screen.listFilter ~= nil
    -- While a list is filtered Backspace takes the filter away, as in Sku's menu, and picking an entry ends it.
    if filtering then
        has.rightClick = true
        tinsert(specs, {
            binding = "rightClick",
            type = "Function",
            interruptSpeech = true,
            func = function()
                self:clearListFilter(screen, true)
            end,
        })
    end
    if node.vtable.bindings ~= nil then
        for _, spec in ipairs(node.vtable.bindings) do
            if not (filtering and spec.binding == "rightClick") then
                tinsert(specs, filtering and spec.binding == "leftClick" and self:_endsFilter(screen, spec) or spec)
                has[spec.binding] = true
            end
        end
    end
    -- The stop's shared bindings (the page keys over a paged list): the node's own win.
    if node.stopBindings ~= nil then
        for _, spec in ipairs(node.stopBindings) do
            if not has[spec.binding] then
                tinsert(specs, spec)
                has[spec.binding] = true
            end
        end
    end
    if node.vtable.onActivate ~= nil and not has.leftClick then
        tinsert(specs, {
            binding = "leftClick",
            type = "Function",
            interruptSpeech = true,
            func = function()
                self:_activateFocused()
            end,
        })
    end
    if node.vtable.onSecondary ~= nil and not has.rightClick then
        tinsert(specs, {
            binding = "rightClick",
            type = "Function",
            interruptSpeech = true,
            func = function()
                self:_secondaryFocused()
            end,
        })
    end
    if (node.vtable.tooltip ~= nil or node.vtable.tooltipFrame ~= nil) and not has.tooltip then
        tinsert(specs, {
            binding = "tooltip",
            type = "Function",
            interruptSpeech = true,
            func = function()
                WowVision.UIHost.tooltip:speak()
            end,
        })
    end
    return specs
end

-- A copy of an activation spec that also ends the screen's filter, after its own action (a secure click stays secure).
function GraphHost:_endsFilter(screen, spec)
    local copy = {}
    for key, value in pairs(spec) do
        copy[key] = value
    end
    local own = spec.postClick
    copy.postClick = function()
        if own ~= nil then
            own()
        end
        self:clearListFilter(screen, false)
    end
    return copy
end

function GraphHost:_engageNodeBindings(node, specs)
    for _, spec in ipairs(specs) do
        tinsert(self._nodeHandles, WowVision.inputActivator:activate(spec))
    end

    -- Record what function-valued Click targets resolved to right now, for
    -- the per-tick drift check.
    local resolutions = nil
    for _, spec in ipairs(specs) do
        if spec.type == "Click" and type(spec.target) == "function" then
            local ok, frame = pcall(spec.target)
            if ok then
                if resolutions == nil then
                    resolutions = {}
                end
                tinsert(resolutions, { resolve = spec.target, frame = frame })
            end
        end
    end
    self._clickResolutions = resolutions
end

function GraphHost:_releaseNodeHandles()
    for _, handle in ipairs(self._nodeHandles) do
        handle:release()
    end
    self._nodeHandles = {}
    self._clickResolutions = nil
end

-- ---- navigation keymaps ----

function GraphHost:_engageNavBindings()
    for _, key in ipairs(NAV_KEYMAPS) do
        tinsert(
            self._navHandles,
            WowVision.inputActivator:activate({
                binding = key,
                type = "Function",
                delay = 0,
                func = function()
                    self:onKey(key)
                end,
            })
        )
    end
end

function GraphHost:_releaseNavBindings()
    for _, handle in ipairs(self._navHandles) do
        handle:release()
    end
    self._navHandles = {}
    self:_releaseLetterKeys()
    if self._closeHandle ~= nil then
        self._closeHandle:release()
        self._closeHandle = nil
    end
    if self._gameCloseHandle ~= nil then
        self._gameCloseHandle:release()
        self._gameCloseHandle = nil
    end
end

-- The close key (Escape) engages only when the focused stack owns something
-- the game cannot close for it: a pushed child screen, or a stack whose
-- config opts in with captureClose (frameless temporary windows). Everywhere
-- else Escape stays with the game.
--
-- A window whose frame shows a view inside itself with the game's own way
-- back (the quest log's details) names that button through closeClick: while
-- it returns one, the close key is a secure click of it, so Escape steps back
-- a view before it closes the window.
function GraphHost:_syncCloseKey()
    local stack = self:focusedStack()
    local config = stack ~= nil and stack.config or nil
    local owns = stack ~= nil and (#stack.screens > 1 or (config ~= nil and config.captureClose == true))
    local target = nil
    if stack ~= nil and not owns and config ~= nil and config.closeClick ~= nil then
        target = config.closeClick()
    end
    local wants = owns or target ~= nil
    -- What the key does changed (the view went back, another button): let go, then take it again.
    if self._closeHandle ~= nil and (not wants or self._closeTarget ~= target) then
        self._closeHandle:release()
        self._closeHandle = nil
    end
    if wants and self._closeHandle == nil and not WowVision.inputActivator:anyInputHeld({ "close" }) then
        if target ~= nil then
            self._closeHandle = WowVision.inputActivator:activate({
                binding = "close",
                type = "Click",
                emulatedKey = "LeftButton",
                target = target,
            })
        else
            self._closeHandle = WowVision.inputActivator:activate({
                binding = "close",
                type = "Function",
                delay = 0,
                func = function()
                    self:onKey("close")
                end,
            })
        end
        self._closeTarget = target
    end
    -- The controller has no Escape key: where Escape stays with the game, the
    -- B button runs the game's own Escape command (gameClose keymap, no
    -- keyboard input), so the game closes its frame with its own sounds.
    local wantsGame = stack ~= nil and not wants
    if wantsGame and self._gameCloseHandle == nil and not WowVision.inputActivator:anyInputHeld({ "gameClose" }) then
        self._gameCloseHandle = WowVision.inputActivator:activate({
            binding = "gameClose",
            type = "Command",
            command = "TOGGLEGAMEMENU",
        })
    elseif not wantsGame and self._gameCloseHandle ~= nil then
        self._gameCloseHandle:release()
        self._gameCloseHandle = nil
    end
end

-- Whether the focused list takes letters: its window's own switch is on, or its stack or screen opts in and the
-- setting for menus (UI module) is on.
function GraphHost:_wantsLetters()
    local stack = self:focusedStack()
    local screen = self:focusedScreen()
    if stack == nil or screen == nil then
        return false
    end
    if stack.config ~= nil and stack.config.windowLetters ~= nil and stack.config.windowLetters() then
        return true
    end
    local ui = WowVision.base ~= nil and WowVision.base.ui or nil
    if ui == nil or ui.settings == nil or ui.settings.letterNavigation == false then
        return false
    end
    return (stack.config ~= nil and stack.config.letterNavigation == true)
        or (screen.config ~= nil and screen.config.letterNavigation == true)
end

function GraphHost:_syncLetterKeys()
    local wants = self:_wantsLetters()
    if wants and #self._letterHandles == 0 then
        -- a letter held (walking on W as the menu opened): its release would be eaten; retried every tick
        if WowVision.inputActivator:inputsHeld(LETTER_KEYS) then
            return
        end
        for _, key in ipairs(LETTER_KEYS) do
            local letter = key
            tinsert(self._letterHandles, WowVision.inputActivator:activateInputs({ letter }, {
                type = "Function",
                delay = 0,
                func = function()
                    self:onLetter(letter)
                end,
            }))
        end
        self:_umlautListener():Show()
        self:_logKeys("took the letter keys")
    elseif not wants and #self._letterHandles > 0 then
        self:_releaseLetterKeys()
    end
end

function GraphHost:_releaseLetterKeys()
    if #self._letterHandles > 0 then
        self:_logKeys("released the letter keys")
    end
    for _, handle in ipairs(self._letterHandles) do
        handle:release()
    end
    self._letterHandles = {}
    if self._umlautFrame ~= nil then
        self._umlautFrame:Hide()
    end
end

-- A key binding on an umlaut does not reach the list on every client and keyboard, so while the letters are taken a
-- frame also listens for the typed character. It lets every key through to the game's bindings; shown only with the
-- letter keys, and created here, out of combat.
function GraphHost:_umlautListener()
    if self._umlautFrame == nil then
        local frame = CreateFrame("Frame")
        frame:Hide()
        frame:EnableKeyboard(true)
        frame:SetPropagateKeyboardInput(true)
        local function typed(_, key)
            if UMLAUT_KEYS[key] and not IsControlKeyDown() and not IsAltKeyDown() and GetCurrentKeyBoardFocus() == nil then
                self:_logKeys("heard the umlaut " .. key)
                self:onLetter(key)
            end
        end
        frame:SetScript("OnChar", typed)
        frame:SetScript("OnKeyDown", typed)
        self._umlautFrame = frame
    end
    return self._umlautFrame
end

-- Whether this press of an umlaut was already handled (see UMLAUT_ONCE).
function GraphHost:_umlautRepeated(letter)
    local umlaut, now = graph.typeAhead.typed(letter), GetTime()
    local repeated = self._lastUmlaut == umlaut and now - self._lastUmlautAt < UMLAUT_ONCE
    self._lastUmlaut, self._lastUmlautAt = umlaut, now
    return repeated
end

-- A letter in a list that takes letters: stop speech first, as for the navigation keys.
function GraphHost:onLetter(letter)
    if UMLAUT_KEYS[letter] and self:_umlautRepeated(letter) then
        return
    end
    graph.doublePress.reset(self._doublePressState)
    local stopped = WowVision.base.speech:uiStop()
    if stopped and (WowVision.consts.UI_DELAY or 0) > 0 then
        C_Timer.After(WowVision.consts.UI_DELAY, function()
            self:_typeLetter(letter)
        end)
    else
        self:_typeLetter(letter)
    end
end

-- One letter goes to the next entry of the focused list starting with it, repeated it cycles. Different letters typed
-- quickly filter the list, as in Sku's menu, and from then on every letter adds to the filter however slowly it comes;
-- a list that cannot be filtered searches for the typed start. The only match being the focused entry reads it again;
-- no match says so, like Sku's menu.
function GraphHost:_typeLetter(letter)
    local screen = self:focusedScreen()
    if screen == nil then
        return
    end
    if screen.listFilter ~= nil then
        self:_filterList(screen, screen.listFilter, screen.listFilter.text .. graph.typeAhead.typed(letter))
        return
    end
    local rowList = screen.config ~= nil and screen.config.rowList == true
    local text, cycle = graph.typeAhead.feed(self._typeAheadState, letter, GetTime())
    local cursor = self:_focusedCursor(screen)
    if cursor ~= nil then
        if cycle or cursor.show == nil then
            self:_cursorJump(cursor, text, cycle)
        else
            self:_filterList(screen, { cursor = cursor }, text)
        end
        return
    end
    if not cycle then
        local scope = screen.keyGraph:filterScope(rowList)
        if scope ~= nil then
            self:_filterList(screen, scope, text)
            return
        end
    end
    local move = screen.keyGraph:moveToText(text, cycle, rowList)
    if move.moved then
        self:_announceMove(screen, move)
    elseif move.found then
        if cycle then
            self:_speakFocusedState(screen)
        end
    else
        self:_speak(WowVision:getLocale()["No results"])
    end
end

-- A list living behind one node (the destinations in F10, the chat lines): the node walks it with bindings of its own,
-- so the graph sees a single entry and the list has to answer for itself. vtable.listCursor:
--   labels()  -> the name of every entry of the whole list
--   index()   -> the position shown now
--   go(i)     moves to entry i of the whole list and reads it
--   show(matches, text)  shows only these entries of the whole list (a list of indices) under a Filter line at
--             position 1; show(nil) shows the whole list again, staying on the entry. Absent: letters only jump.
function GraphHost:_focusedCursor(screen)
    if not screen.keyGraph:rerender() then
        return nil
    end
    local node = screen.keyGraph:currentNode()
    return node ~= nil and node.vtable.listCursor or nil
end

local function cursorLabels(cursor, text)
    local matchText, labels = graph.typeAhead.matcher(text), {}
    for i, label in ipairs(cursor.labels()) do
        labels[i] = matchText(label)
    end
    return labels
end

function GraphHost:_cursorJump(cursor, text, cycle)
    local index = graph.typeAhead.find(cursorLabels(cursor, text), cursor.index(), text, cycle)
    if index == nil then
        self:_speak(WowVision:getLocale()["No results"])
    else
        cursor.go(index)
    end
end

-- Filter the list to the entries containing text and land on the "Filter: text" line above them.
function GraphHost:_filterList(screen, filter, text)
    filter.text = text
    screen.listFilter = filter
    self._bindingsDirty = true
    if filter.cursor ~= nil then
        local matches = {}
        for i, label in ipairs(cursorLabels(filter.cursor, text)) do
            if graph.typeAhead.contains(label, text) then
                tinsert(matches, i)
            end
        end
        filter.matches = #matches
        filter.cursor.show(matches, text)
    else
        screen.state.nextSuggestedMove = graph.LIST_FILTER_ID
    end
    if not screen.keyGraph:rerender() then
        return
    end
    local node = screen.keyGraph:currentNode()
    local spoken = announcer.leafText(node)
    if filter.matches == 0 then
        spoken = spoken .. ". " .. WowVision:getLocale()["No results"]
    end
    self:_speak(spoken)
    screen._lastSpokenKey = node.id
    screen._lastSpokenNode = node
    screen._liveKey = nil
end

-- Back to the whole list, focus staying on the entry it was on (from the Filter line: the list's first entry).
-- announce says so: Backspace and the left arrow; going on to an entry just ends the filter.
function GraphHost:clearListFilter(screen, announce)
    local filter = screen.listFilter
    if filter == nil then
        return
    end
    screen.listFilter = nil
    self._typeAheadState = graph.typeAhead.newState()
    self._bindingsDirty = true
    if filter.cursor ~= nil then
        filter.cursor.show(nil)
    end
    local current = screen.state.curKey
    if current ~= nil and current.key == graph.LIST_FILTER_ID.key then
        screen.state.nextSuggestedMove = filter.firstId
    end
    if announce and screen.keyGraph:rerender() then
        local node = screen.keyGraph:currentNode()
        self:_speak(WowVision:getLocale()["Filter removed"] .. ". " .. (announcer.leafText(node) or ""))
        screen._lastSpokenKey = node.id
        screen._lastSpokenNode = node
        screen._liveKey = nil
    end
end

-- Keymap inputs changed (a rebind): drop every handle and re-engage on the
-- next update so override bindings pick up the new keys.
function GraphHost:refreshBindings()
    self:_releaseNavBindings()
    self:_releaseNodeHandles()
    self._bindingsDirty = true
end

-- Entry point for navigation keypresses. Mirrors UIHost's TTS sequencing: stop
-- current speech first; on clients whose TTS needs it, delay the operation so
-- the stop is processed before the next announcement.
-- The press time is taken here, before the delay, so the delay never stretches a double press.
function GraphHost:onKey(key)
    local at = GetTime()
    local stopped = WowVision.base.speech:uiStop()
    if stopped and (WowVision.consts.UI_DELAY or 0) > 0 then
        C_Timer.After(WowVision.consts.UI_DELAY, function()
            self:_dispatchKey(key, at)
        end)
    else
        self:_dispatchKey(key, at)
    end
end

function GraphHost:_dispatchKey(key, at)
    local screen = self:focusedScreen()
    if screen == nil then
        return
    end
    if key == "up" or key == "down" or key == "left" or key == "right" then
        self:_arrow(screen, key, at)
        return
    end
    graph.doublePress.reset(self._doublePressState)
    if key == "next" or key == "previous" then
        self:_tab(screen, key)
    elseif key == "nextWindow" then
        self:_cycleStack(1)
    elseif key == "previousWindow" then
        self:_cycleStack(-1)
    elseif key == "home" then
        self:_jumpEdge(screen, true)
    elseif key == "end" then
        self:_jumpEdge(screen, false)
    elseif key == "close" then
        self:_close(screen)
    elseif key == "contextMenu" then
        WowVision.graph.contextMenu.open()
    end
end

-- Arrows: in a filtered list left takes the filter away and right into a group
-- ends it; a focused slider adjusts on left/right before any navigation;
-- edge-wired movement next; at an edge, a node's own onRight/onLeft (a Scanner
-- entry opening its level, or going back), then right opens the entry's next
-- level, left/right get tree semantics, and left goes back one level; an Up or
-- Down bump at the first or last entry sounds and reads the entry again (the
-- UI module's edgeSound setting), any other bump stays silent. The same
-- arrow pressed twice quickly skips empty slots (doublePress.lua).
function GraphHost:_arrow(screen, dir, at)
    local kg = screen.keyGraph
    local node = kg:currentNode()
    if node == nil then
        return
    end
    local double = graph.doublePress.press(self._doublePressState, dir, at or GetTime(), screen, node.id.key)

    if screen.listFilter ~= nil then
        if dir == "left" then
            self:clearListFilter(screen, true)
            return
        elseif dir == "right" and node.expandable then
            self:clearListFilter(screen, false)
        end
    end

    if dir == "left" or dir == "right" then
        if self:_adjustFocused(screen, dir == "right" and 1 or -1) then
            return
        end
    end

    local move
    if double and self:_skipsEmptySlots() then
        move = kg:moveSkippingEmpty(dir)
    else
        move = kg:move(dir)
    end
    local landed = kg:currentNode()
    graph.doublePress.settle(self._doublePressState, landed ~= nil and landed.id.key or nil)
    if move.moved then
        self:_announceMove(screen, move)
        return
    end

    if dir == "right" and node.vtable.onRight ~= nil then
        node.vtable.onRight()
        return
    elseif dir == "left" and node.vtable.onLeft ~= nil then
        node.vtable.onLeft()
        return
    end

    if dir == "right" and node.vtable.opensLevel then
        self:_activateFocused()
        return
    end

    if dir == "left" or dir == "right" then
        local result = dir == "right" and kg:treeRight() or kg:treeLeft()
        if result.kind == "expanded" or result.kind == "collapsed" then
            self:_speakFocusedState(screen)
            return
        elseif result.kind == "emptyGroup" then
            self:_speakFocusedState(screen)
            return
        elseif result.kind == "descended" or result.kind == "ascended" then
            self:_announceMove(screen, result.move)
            return
        elseif result.kind == "leaf" then
            if dir == "left" then
                self:_levelBack(screen, node)
            end
            return
        end
        if dir == "left" then
            self:_levelBack(screen, node)
            return
        end
    end

    -- Focus did not move on Up or Down: the first or last entry. As in Sku, a
    -- short sound and the entry read again (Left and Right bumps stay silent:
    -- they are level and tree keys).
    if (dir == "up" or dir == "down") and self:_playsEdgeSound() then
        if PlaySound ~= nil then
            PlaySound(GraphHost.EDGE_SOUND)
        end
        self:_announceMove(screen, { from = node, to = node })
    end
end

-- The game's sound kit Sku plays when Up or Down hits the end of a list.
GraphHost.EDGE_SOUND = 681

-- The UI module's setting; on unless switched off.
function GraphHost:_playsEdgeSound()
    local ui = WowVision.base ~= nil and WowVision.base.ui or nil
    return ui == nil or ui.settings == nil or ui.settings.edgeSound ~= false
end

-- The UI module's setting; on unless switched off.
function GraphHost:_skipsEmptySlots()
    local ui = WowVision.base ~= nil and WowVision.base.ui or nil
    return ui == nil or ui.settings == nil or ui.settings.skipEmptySlots ~= false
end

-- The left arrow: one level back, never out of the menu. Only from a pushed screen; the first level of a context menu
-- stays (it would leave the menu), a yes/no question stays, and in a row left only walks the row.
function GraphHost:_levelBack(screen, node)
    local stack = self:focusedStack()
    if stack == nil or #stack.screens <= 1 or screen.config == nil or screen.config.noLevelBack then
        return
    end
    if node.transitions.left ~= nil or node.transitions.right ~= nil then
        return
    end
    if screen.config._contextMenu and not stack.screens[#stack.screens - 1].config._contextMenu then
        return
    end
    self:pop(stack)
end

function GraphHost:_tab(screen, key)
    self:clearListFilter(screen, false) -- a filter belongs to the list focus is leaving
    local kg = screen.keyGraph
    local move = kg:move(key)
    if move.moved then
        self:_announceMove(screen, move)
        -- Tab-pair arrivals only: a node may react to being tabbed to
        -- (edit boxes take keyboard focus so typing starts immediately;
        -- Tab out is their hooked OnTabPressed).
        local node = kg:currentNode()
        if node ~= nil and node.vtable.onTabFocus ~= nil then
            node.vtable.onTabFocus()
        end
    end
    -- No move (a single-stop screen): silent, same as arrows.
end

-- Home/End: within a tree, the first/last sibling; in a horizontal row (a
-- bar of action buttons, a row of tabs), the row's first/last cell -- the
-- bar is the list the player is in, not the column of bars beneath it;
-- otherwise the top/bottom of the column.
function GraphHost:_jumpEdge(screen, first)
    local kg = screen.keyGraph
    local node = kg:currentNode()
    if node == nil then
        return
    end
    local move
    if graph.KeyGraph.inTree(node) then
        move = kg:moveToSiblingEdge(first)
    elseif screen.config ~= nil and screen.config.rowList == true then
        -- a list of rows (the key bindings): the first or last row, not the ends of this one
        move = kg:moveToRowEdge(first)
    elseif node.transitions.left ~= nil or node.transitions.right ~= nil then
        move = kg:moveToEdge(first and "left" or "right")
    else
        move = kg:moveToEdge(first and "up" or "down")
    end
    if move.moved then
        self:_announceMove(screen, move)
    end
end

function GraphHost:_cycleStack(step)
    if #self.stacks <= 1 then
        return
    end
    self.focusedIndex = ((self.focusedIndex - 1 + step) % #self.stacks) + 1
    local screen = self:focusedScreen()
    if screen ~= nil then
        screen:resetAnnouncement()
    end
    self._bindingsDirty = true
end

function GraphHost:_close(screen)
    local stack = self:focusedStack()
    if #stack.screens > 1 then
        self:pop(stack)
        return
    end
    if stack.config ~= nil and stack.config.onRequestClose ~= nil then
        stack.config.onRequestClose(stack)
    else
        self:close(stack)
    end
end

function GraphHost:_announceMove(screen, move)
    local node = move.to
    if node == nil then
        return
    end
    self:_speak(announcer.compose(move.from, node, move.transitionLabel))
    screen._lastSpokenKey = node.id
    screen._lastSpokenNode = node
end

-- Speak the focused group's post-toggle readout (it includes the new
-- expanded/collapsed state) and rebaseline the differ and live watch so the
-- change isn't spoken twice.
function GraphHost:_speakFocusedState(screen)
    local node = screen.keyGraph:currentNode()
    if node == nil then
        return
    end
    self:_speak(announcer.leafText(node))
    screen._lastSpokenKey = node.id
    screen._lastSpokenNode = node
    screen._liveKey = nil
end

-- Run the focused node's activation; a declared stateText line is the
-- synchronous feedback path, spoken immediately, with the live watch
-- rebaselined so the same change isn't spoken twice.
function GraphHost:_activateFocused()
    graph.doublePress.reset(self._doublePressState)
    local screen = self:focusedScreen()
    if screen == nil then
        return
    end
    -- the Filter line of a list behind one node is no entry to pick
    local filter = screen.listFilter
    if filter ~= nil and filter.cursor ~= nil and filter.cursor.index() == 1 then
        return
    end
    screen.keyGraph:activate()
    self:_speakStateText(screen)
    self:clearListFilter(screen, false)
end

function GraphHost:_secondaryFocused()
    graph.doublePress.reset(self._doublePressState)
    local screen = self:focusedScreen()
    if screen == nil then
        return
    end
    screen.keyGraph:secondary()
    self:_speakStateText(screen)
end

function GraphHost:_adjustFocused(screen, sign)
    if not screen.keyGraph:tryAdjust(sign, false) then
        return false
    end
    WowVision.base.speech:uiStop()
    self:_speakStateText(screen)
    return true
end

function GraphHost:_speakStateText(screen)
    local node = screen.keyGraph:currentNode()
    local stateText = node ~= nil and node.vtable.stateText or nil
    if stateText == nil then
        return
    end
    local ok, text = pcall(stateText)
    if ok and text ~= nil and text ~= "" then
        self:_speak(text)
        screen._liveKey = nil
    end
end

-- After a page key's click (nodes.pageKeys): when the stop's page changed,
-- land on the stop's first entry, as a fresh page is read from its top. The
-- render from before the click still holds the old page. No change (the
-- first or last page, or a page that arrives later): focus stays, and a
-- text that changes under it is spoken by the live watch.
function GraphHost:landAfterPageTurn(stopKey)
    local screen = self:focusedScreen()
    if screen == nil or screen.keyGraph.current == nil then
        return
    end
    local keyGraph = screen.keyGraph
    local function pageOf(render)
        if render.stopPages == nil then
            return nil
        end
        return render.stopPages[stopKey]
    end
    local before = pageOf(keyGraph.current)
    if not keyGraph:rerender() then
        return
    end
    local after = pageOf(keyGraph.current)
    if after == nil or after == before then
        return
    end
    for _, node in ipairs(keyGraph.current.order) do
        if node.stopKey == stopKey and node.focusable ~= false then
            WowVision.base.speech:uiStop()
            keyGraph:focus(node.id)
            -- The same control on a new page (a pooled item button) is news:
            -- announce it, and let the live watch baseline the new page.
            screen._lastSpokenKey = nil
            screen._liveKey = nil
            return
        end
    end
end

WowVision.graphHost = GraphHost:new()

-- Localized wording for the announcer (the graph core itself is
-- locale-agnostic; the host installs the words).
local L = WowVision:getLocale()
announcer.positionText = function(index, count)
    return index .. " " .. L["of"] .. " " .. count
end
announcer.expandedStateText = function(expanded)
    return expanded and L["Expanded"] or L["Collapsed"]
end
