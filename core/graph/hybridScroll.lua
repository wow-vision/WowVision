local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The button-pool scroll adapter (HybridScrollFrame and kin): a fixed pool of
-- row buttons over an API-enumerable list, like the quest log. Replicates the
-- old ProxyScrollFrame discipline exactly: focusing an entry ALWAYS scrolls
-- it to a calibrated position (never only when it looks offscreen), which
-- re-stamps the button pool synchronously; the landing is then VERIFIED by
-- finding the button whose index matches, and the scroll rolls back if none
-- does. Buttons rebind as the pool scrolls, so an index-to-button mapping is
-- only ever trusted immediately after scrolling to that index.
--
-- config:
--   scrollFrame  the scroll frame (required; needs a scrollBar and a pool in
--                .buttons, else the scroll child's children)
--   count        function -> number of logical entries (required)
--   emit         function(builder, index, helpers) -- emit the entry's nodes
--                (required). helpers = { onFocus, target, id }.
--   key          stable prefix for default ids (default "hybrid")
--   label        announcement context wrapped around the entries
--   id           function(index) -> ControlId; default structural key:index
--   rowHeight    pixels per row; defaults to the frame's buttonHeight, else
--                the first pooled button's height
--   buttons      function -> the button pool, for frames whose pool is not
--                discoverable (FauxScrollFrames with named sibling buttons)
--   indexOf      function(button) -> the button's LOGICAL index, for pools
--                whose IDs are pool-relative (TBC-era Faux rows carry slot
--                ids; logical index is id plus the frame's scroll offset)
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
            nodes.text({ label = WowVision:getLocale()["Empty"] })
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
        scrollBar:SetValue(baseline + rowHeight() * (index - 1))
        if findButton(index) ~= nil then
            return
        end
        scrollBar:SetValue(original)
    end

    if config.label ~= nil then
        builder:pushContext(keyPrefix, config.label)
    end

    for index = 1, total do
        local capturedIndex = index

        local id
        if config.id ~= nil then
            id = config.id(capturedIndex)
        else
            id = ControlId.structural(keyPrefix .. ":" .. capturedIndex)
        end

        local onFocus = function()
            pcall(scrollToIndex, capturedIndex)
        end

        -- Stateless per-tick re-align: if the entry scrolled out from under
        -- focus, pull it back. The host's click-drift watch handles
        -- re-engaging bindings when the frame mapping shifts.
        local onFocusTick = function()
            if findButton(capturedIndex) == nil then
                pcall(scrollToIndex, capturedIndex)
            end
        end

        local target = function()
            return findButton(capturedIndex)
        end

        config.emit(builder, capturedIndex, {
            onFocus = onFocus,
            onFocusTick = onFocusTick,
            target = target,
            id = id,
        })
    end

    if config.label ~= nil then
        builder:popContext()
    end
    return builder
end
