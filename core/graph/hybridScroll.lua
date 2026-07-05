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
function nodes.hybridScrollList(builder, config)
    local scrollFrame = config.scrollFrame
    if scrollFrame == nil then
        error("hybridScrollList requires a scrollFrame")
    end
    if config.count == nil or config.emit == nil then
        error("hybridScrollList requires count and emit")
    end

    local total = config.count()
    if total == nil or total <= 0 then
        return builder
    end
    local keyPrefix = tostring(config.key or "hybrid")

    local function buttonsOf()
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

    local function scrollToIndex(index)
        local scrollBar = scrollFrame.scrollBar or scrollFrame.ScrollBar
        if scrollBar == nil then
            return
        end
        local scrollChild = scrollFrame.GetScrollChild ~= nil and scrollFrame:GetScrollChild() or nil
        local buttons = buttonsOf()
        if scrollChild == nil or buttons[1] == nil then
            return
        end
        -- The pool's pixel baseline within the scroll child; constant, since
        -- both tops move together as the child scrolls.
        local childTop = scrollChild:GetTop()
        local buttonTop = buttons[1]:GetTop()
        if childTop == nil or buttonTop == nil then
            return
        end
        local original = scrollBar:GetValue()
        scrollBar:SetValue((childTop - buttonTop) + rowHeight() * (index - 1))
        if findButton(index) ~= nil then
            return
        end
        scrollBar:SetValue(original)
    end

    if config.label ~= nil then
        builder:pushContext(config.label)
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

        local target = function()
            return findButton(capturedIndex)
        end

        config.emit(builder, capturedIndex, { onFocus = onFocus, target = target, id = id })
    end

    if config.label ~= nil then
        builder:popContext()
    end
    return builder
end
