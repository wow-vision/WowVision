local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The button-pool scroll adapter (HybridScrollFrame and kin): a fixed pool of
-- row buttons over an API-enumerable list, like the quest log.
--
-- DEFAULT MODE replicates the old ProxyScrollFrame discipline exactly:
-- focusing an entry ALWAYS scrolls it to a calibrated position (never only
-- when it looks offscreen), which re-stamps the button pool synchronously;
-- the landing is then VERIFIED by finding the button whose index matches,
-- and the scroll rolls back if none does. Buttons rebind as the pool
-- scrolls, so an index-to-button mapping is only ever trusted immediately
-- after scrolling to that index.
--
-- TAINTED MODE (config.tainted = true) is for panels where addon-driven
-- scrolling breaks protected actions: our SetValue runs the frame's update
-- handler inside OUR insecure stack, tainting the pool's stamped fields
-- (button.id and kin) AND the offset field -- which then re-taints even
-- Blizzard's own secure refreshes, persistently. (Symptom: Copy Character
-- Name blocked after scrolling the friends list.) In this mode the adapter
-- NEVER writes the scrollbar; the hardware keys scroll through Blizzard's
-- own arrow buttons instead, whose handlers keep everything secure:
--   - up/down at the visible edge: one secure click of the real arrow
--     ("/click name LeftButton 1" for hybrid arrows, which only scroll on
--     the down press; plain click for Faux-era bars), then focus moves on
--     the same keypress via postClick.
--   - scrollUp/scrollDown (Page Up/Down): a macrotext of enough arrow
--     clicks to cover one viewport, then focus snaps to the nearest
--     newly-visible row.
--   - home/end are eaten: an unscrolled jump would detach focus from the
--     viewport, and a secure jump of arbitrary distance cannot fit one
--     keypress.
--
-- config:
--   scrollFrame  the scroll frame (required; needs a scrollBar and a pool in
--                .buttons, else the scroll child's children)
--   count        function -> number of logical entries (required)
--   emit         function(builder, index, helpers) -- emit the entry's nodes
--                (required). helpers = { onFocus, onFocusTick, target, id,
--                edgeBindings }. Concat edgeBindings (may be nil) into the
--                row vtable's bindings.
--   key          stable prefix for default ids (default "hybrid")
--   label        announcement context wrapped around the entries
--   emptyLabel   what the list says when it has no entries (text or
--                function; default "Empty"), e.g. the game's own line
--   id           function(index) -> ControlId; default structural key:index.
--                TAINTED MODE REQUIRES this to return the SAME id the emit
--                callback gives addItem for that index -- the page-scroll
--                focus snap looks rows up by it
--   rowHeight    pixels per row; defaults to the frame's buttonHeight, else
--                the first pooled button's height
--   buttons      function -> the button pool, for frames whose pool is not
--                discoverable (FauxScrollFrames with named sibling buttons)
--   indexOf      function(button) -> the button's LOGICAL index, for pools
--                whose IDs are pool-relative (TBC-era Faux rows carry slot
--                ids; logical index is id plus the frame's scroll offset)
--   offsetOf     function(index) -> the entry's pixel offset from the top,
--                for variable-height lists (the friends list mixes 34px
--                rows with 16px dividers); overrides the rowHeight math
--   tainted      true -> tainted mode (see above)
function nodes.hybridScrollList(builder, config)
    local scrollFrame = config.scrollFrame
    if scrollFrame == nil then
        error("hybridScrollList requires a scrollFrame")
    end
    if config.count == nil or config.emit == nil then
        error("hybridScrollList requires count and emit")
    end

    local keyPrefix = tostring(config.key or "hybrid")

    -- An empty list is still a place to land.
    local total = config.count()
    if total == nil or total <= 0 then
        if config.label ~= nil then
            builder:pushContext(keyPrefix, config.label)
        end
        builder:addItem(
            ControlId.structural(keyPrefix .. ":empty"),
            nodes.text({ label = config.emptyLabel or WowVision:getLocale()["Empty"] })
        )
        if config.label ~= nil then
            builder:popContext()
        end
        return builder
    end

    local function buttonsOf()
        if config.buttons ~= nil then
            return config.buttons()
        end
        if scrollFrame.buttons ~= nil then
            return scrollFrame.buttons
        end
        local scrollChild = scrollFrame.GetScrollChild ~= nil and scrollFrame:GetScrollChild() or nil
        if scrollChild ~= nil then
            return { scrollChild:GetChildren() }
        end
        return {}
    end

    local function rowHeight()
        if config.rowHeight ~= nil then
            return config.rowHeight
        end
        if scrollFrame.buttonHeight ~= nil then
            return scrollFrame.buttonHeight
        end
        local buttons = buttonsOf()
        if buttons[1] ~= nil then
            return buttons[1]:GetHeight()
        end
        return 16
    end

    local function indexOfButton(button)
        if config.indexOf ~= nil then
            return config.indexOf(button)
        end
        return button.index or button:GetID()
    end

    local function findButton(index)
        for _, button in ipairs(buttonsOf()) do
            if button:IsShown() and indexOfButton(button) == index then
                return button
            end
        end
        return nil
    end

    local function scrollBarOf()
        if scrollFrame.scrollBar ~= nil then
            return scrollFrame.scrollBar
        end
        if scrollFrame.ScrollBar ~= nil then
            return scrollFrame.ScrollBar
        end
        -- FauxScrollFrames name their bar as a global with no key.
        if scrollFrame.GetName ~= nil and scrollFrame:GetName() ~= nil then
            return _G[scrollFrame:GetName() .. "ScrollBar"]
        end
        return nil
    end

    local function idOf(index)
        if config.id ~= nil then
            return config.id(index)
        end
        return ControlId.structural(keyPrefix .. ":" .. index)
    end

    -- Default-mode scroll: always write, verify the landing, roll back a
    -- miss.
    local function scrollToIndex(index)
        local scrollBar = scrollBarOf()
        if scrollBar == nil then
            return
        end
        local scrollChild = scrollFrame.GetScrollChild ~= nil and scrollFrame:GetScrollChild() or nil
        local buttons = buttonsOf()
        if scrollChild == nil or buttons[1] == nil then
            return
        end
        local childTop = scrollChild:GetTop()
        local buttonTop = buttons[1]:GetTop()
        if childTop == nil or buttonTop == nil then
            return
        end
        local original = scrollBar:GetValue()
        -- The pool's pixel baseline within the scroll child. Hybrid pools are
        -- parented to the child and ride it, so the measured gap is constant;
        -- Faux-style static pools sit still while the child slides under
        -- them, so the measured gap shifts by the current scroll value.
        local baseline = childTop - buttonTop
        if buttons[1]:GetParent() ~= scrollChild then
            baseline = baseline + original
        end
        local pixels
        if config.offsetOf ~= nil then
            pixels = config.offsetOf(index)
        else
            pixels = rowHeight() * (index - 1)
        end
        scrollBar:SetValue(baseline + pixels)
        if findButton(index) ~= nil then
            return
        end
        scrollBar:SetValue(original)
    end

    -- ---- tainted-mode secure key machinery ----

    local secure = config.tainted == true
    local scrollBar = scrollBarOf()

    -- Which logical indices are visible right now, for the edge checks.
    local visible = {}
    if secure then
        for _, button in ipairs(buttonsOf()) do
            if button ~= nil and button:IsShown() then
                local ok, buttonIndex = pcall(indexOfButton, button)
                if ok and buttonIndex ~= nil then
                    visible[buttonIndex] = true
                end
            end
        end
    end

    -- Hybrid arrows only scroll on the DOWN press ("/click name btn 1");
    -- Faux-era arrows respond to a plain click.
    local hybridArrows = scrollFrame.buttons ~= nil
    local clickSuffix = hybridArrows and " LeftButton 1" or " LeftButton"
    local function arrowName(which)
        if scrollBar == nil then
            return nil
        end
        local arrow = scrollBar[which]
        if arrow == nil and scrollBar.GetName ~= nil and scrollBar:GetName() ~= nil then
            arrow = _G[scrollBar:GetName() .. which]
        end
        if arrow == nil or arrow.GetName == nil then
            return nil
        end
        return arrow:GetName()
    end
    local function arrowScript(which)
        local name = arrowName(which)
        if name == nil then
            return nil
        end
        return "/click " .. name .. clickSuffix
    end

    -- Pixels one arrow click covers.
    local function stepPixels()
        if scrollFrame.buttons ~= nil then
            return scrollFrame.stepSize or scrollFrame.buttonHeight or rowHeight()
        end
        if scrollBar == nil then
            return rowHeight()
        end
        return scrollBar.scrollStep or (scrollBar:GetHeight() / 2)
    end

    -- After a page scroll, land focus on the nearest newly-visible row:
    -- page down continues forward from the top of the new view, page up
    -- backward from its bottom. Some indices have no node (dividers), so
    -- walk the candidates until one focuses.
    local function focusNearestVisible(topmost)
        local candidates = {}
        for _, button in ipairs(buttonsOf()) do
            if button ~= nil and button:IsShown() then
                local ok, buttonIndex = pcall(indexOfButton, button)
                if ok and buttonIndex ~= nil and buttonIndex >= 1 and buttonIndex <= total then
                    tinsert(candidates, buttonIndex)
                end
            end
        end
        table.sort(candidates, function(a, b)
            if topmost then
                return a < b
            end
            return a > b
        end)
        local screen = WowVision.graphHost:focusedScreen()
        if screen == nil then
            return
        end
        for _, buttonIndex in ipairs(candidates) do
            if screen.keyGraph:focus(idOf(buttonIndex)) then
                return
            end
        end
    end

    -- Page Up/Down: one keypress, enough secure arrow clicks to cover a
    -- viewport (the slider clamps at its ends, so extra clicks are safe).
    -- A down-flagged click leaves the button logically pressed, and a
    -- second down-click on a pressed button is swallowed -- press state
    -- only resets between hardware events. So each hybrid click is a
    -- press-RELEASE pair, making every repetition a full click cycle.
    local function pageSpec(which, keymap, topmost)
        local name = arrowName(which)
        if name == nil then
            return nil
        end
        local unit
        if hybridArrows then
            unit = "/click " .. name .. " LeftButton 1\n/click " .. name .. " LeftButton\n"
        else
            unit = "/click " .. name .. " LeftButton\n"
        end
        local step = stepPixels()
        local viewport = scrollFrame.GetHeight ~= nil and scrollFrame:GetHeight() or 0
        local clicks = 1
        if step ~= nil and step > 0 and viewport > 0 then
            clicks = math.ceil(viewport / step)
        end
        local maxClicks = math.floor(1000 / #unit)
        if clicks > maxClicks then
            clicks = maxClicks
        end
        if clicks < 1 then
            clicks = 1
        end
        return {
            binding = keymap,
            type = "Script",
            script = string.rep(unit, clicks),
            postClick = function()
                WowVision.base.speech:uiStop()
                focusNearestVisible(topmost)
            end,
        }
    end

    local pageUpSpec, pageDownSpec, eatHome, eatEnd
    if secure then
        pageUpSpec = pageSpec("ScrollUpButton", "scrollUp", false)
        pageDownSpec = pageSpec("ScrollDownButton", "scrollDown", true)
        local noop = function() end
        eatHome = { binding = "home", type = "Function", func = noop }
        eatEnd = { binding = "end", type = "Function", func = noop }
    end

    if config.label ~= nil then
        builder:pushContext(keyPrefix, config.label)
    end

    for index = 1, total do
        local capturedIndex = index
        local id = idOf(capturedIndex)

        local onFocus, onFocusTick
        if secure then
            -- Never write the scrollbar; the keys below move the viewport.
            onFocus = function() end
        else
            onFocus = function()
                pcall(scrollToIndex, capturedIndex)
            end
            -- Stateless per-tick re-align: if the entry scrolled out from
            -- under focus, pull it back.
            onFocusTick = function()
                if findButton(capturedIndex) == nil then
                    pcall(scrollToIndex, capturedIndex)
                end
            end
        end

        local target = function()
            return findButton(capturedIndex)
        end

        local edgeBindings = nil
        if secure then
            edgeBindings = {}
            if index > 1 and not visible[index - 1] then
                local script = arrowScript("ScrollUpButton")
                if script ~= nil then
                    tinsert(edgeBindings, {
                        binding = "up",
                        type = "Script",
                        script = script,
                        postClick = function()
                            WowVision.graphHost:onKey("up")
                        end,
                    })
                end
            end
            if index < total and not visible[index + 1] then
                local script = arrowScript("ScrollDownButton")
                if script ~= nil then
                    tinsert(edgeBindings, {
                        binding = "down",
                        type = "Script",
                        script = script,
                        postClick = function()
                            WowVision.graphHost:onKey("down")
                        end,
                    })
                end
            end
            if pageUpSpec ~= nil then
                tinsert(edgeBindings, pageUpSpec)
            end
            if pageDownSpec ~= nil then
                tinsert(edgeBindings, pageDownSpec)
            end
            tinsert(edgeBindings, eatHome)
            tinsert(edgeBindings, eatEnd)
        end

        config.emit(builder, capturedIndex, {
            onFocus = onFocus,
            onFocusTick = onFocusTick,
            target = target,
            id = id,
            edgeBindings = edgeBindings,
        })
    end

    if config.label ~= nil then
        builder:popContext()
    end
    return builder
end
