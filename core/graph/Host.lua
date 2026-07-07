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

function GraphHost:initialize()
    self.stacks = {}
    self.focusedIndex = 0
    self._navHandles = {}
    self._nodeHandles = {}
    self._focusNodeId = nil
    self._focusNode = nil
    self._bindingsDirty = false

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
        self:_releaseNavBindings()
        self:_dropNodeFocus()
        return
    end
    if InCombatLockdown() then
        return
    end
    if #self._navHandles == 0 then
        self:_engageNavBindings()
    end
    self:_syncCloseKey()

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

function GraphHost:_speak(text)
    if text ~= nil and text ~= "" then
        WowVision:speak(text)
    end
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

    local previous = self._focusNode
    if previous ~= nil and previous.vtable.onUnfocus ~= nil and (newId == nil or self._focusNodeId ~= newId) then
        pcall(previous.vtable.onUnfocus, previous)
    end
    self:_releaseNodeHandles()
    self._focusNodeId = newId
    self._focusNode = node
    self._bindingsDirty = false
    if node ~= nil then
        -- onFocus runs first: scroll adapters materialize the row frame here,
        -- and binding targets may resolve lazily against it at engage.
        if node.vtable.onFocus ~= nil then
            pcall(node.vtable.onFocus, node)
        end
        self:_engageNodeBindings(node)
    end
    self:_setTooltipFor(node)
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
end

function GraphHost:_engageNodeBindings(node)
    local specs = {}
    local has = {}
    if node.vtable.bindings ~= nil then
        for _, spec in ipairs(node.vtable.bindings) do
            tinsert(specs, spec)
            has[spec.binding] = true
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
    if self._closeHandle ~= nil then
        self._closeHandle:release()
        self._closeHandle = nil
    end
end

-- The close key (Escape) engages only when the focused stack owns something
-- the game cannot close for it: a pushed child screen, or a stack whose
-- config opts in with captureClose (frameless temporary windows). Everywhere
-- else Escape stays with the game.
function GraphHost:_syncCloseKey()
    local stack = self:focusedStack()
    local wants = stack ~= nil
        and (#stack.screens > 1 or (stack.config ~= nil and stack.config.captureClose == true))
    if wants and self._closeHandle == nil then
        self._closeHandle = WowVision.inputActivator:activate({
            binding = "close",
            type = "Function",
            delay = 0,
            func = function()
                self:onKey("close")
            end,
        })
    elseif not wants and self._closeHandle ~= nil then
        self._closeHandle:release()
        self._closeHandle = nil
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
function GraphHost:onKey(key)
    local stopped = WowVision.base.speech:uiStop()
    if stopped and (WowVision.consts.UI_DELAY or 0) > 0 then
        C_Timer.After(WowVision.consts.UI_DELAY, function()
            self:_dispatchKey(key)
        end)
    else
        self:_dispatchKey(key)
    end
end

function GraphHost:_dispatchKey(key)
    local screen = self:focusedScreen()
    if screen == nil then
        return
    end
    if key == "up" or key == "down" or key == "left" or key == "right" then
        self:_arrow(screen, key)
    elseif key == "next" or key == "previous" then
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

-- Arrows: a focused slider adjusts on left/right before any navigation;
-- edge-wired movement next; at an edge, left/right get tree semantics; a bump
-- with nothing to do re-reads the current node for orientation.
function GraphHost:_arrow(screen, dir)
    local kg = screen.keyGraph
    local node = kg:currentNode()
    if node == nil then
        return
    end

    if dir == "left" or dir == "right" then
        if self:_adjustFocused(screen, dir == "right" and 1 or -1) then
            return
        end
    end

    local move = kg:move(dir)
    if move.moved then
        self:_announceMove(screen, move)
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
            return
        end
    end

    -- Focus did not move: stay silent. Re-reading the same node on a
    -- boundary bump is noise when arrowing quickly.
end

function GraphHost:_tab(screen, key)
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

function GraphHost:_jumpEdge(screen, first)
    local kg = screen.keyGraph
    local node = kg:currentNode()
    if node == nil then
        return
    end
    local move
    if graph.KeyGraph.inTree(node) then
        move = kg:moveToSiblingEdge(first)
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
    local screen = self:focusedScreen()
    if screen == nil then
        return
    end
    screen.keyGraph:activate()
    self:_speakStateText(screen)
end

function GraphHost:_secondaryFocused()
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
