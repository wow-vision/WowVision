local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local L = WowVision:getLocale()

-- The ScrollBox adapter: pilots a Blizzard virtualized scroll widget. The
-- full logical list comes from the widget's data provider, so every row is a
-- node regardless of visibility; focusing a row scrolls it into view, which
-- materializes its real button; the click bindings resolve that button
-- lazily at engage time and secure-click it. Blizzard security is why the
-- real buttons must be clicked (the auction house especially) -- actions
-- never route around the widget.
--
-- Labels must come from the ROW DATA, not the row frame: a row's label is
-- spoken the moment focus moves to it, before the focus lifecycle has
-- scrolled it into view, so offscreen frames cannot be read in time.

-- Debug ledger for /wv gnode: default row id -> what the provider said the
-- row was. Overwritten every rebuild.
graph.scrollBoxDebug = {}

-- The row frame currently backing a data index, or nil while offscreen.
local function resolveRowFrame(scrollBox, data, index)
    if scrollBox.FindFrame ~= nil then
        local found = scrollBox:FindFrame(data)
        if found ~= nil then
            return found
        end
    end
    if scrollBox.ScrollTarget ~= nil then
        for _, child in ipairs({ scrollBox.ScrollTarget:GetChildren() }) do
            if child.GetElementDataIndex ~= nil and child:GetElementDataIndex() == index then
                return child
            end
            if child.GetElementData ~= nil and child:GetElementData() == data then
                return child
            end
        end
    end
    return nil
end

-- Emit one node per data element of a ScrollBox.
-- config:
--   scrollBox   the widget (required)
--   rowLabel    function(data, index) -> spoken label (required; see above)
--   label       announcement context wrapped around the rows
--   key         stable prefix scoping the default row ids -- REQUIRED to be
--               distinct when one screen holds several scroll lists, or their
--               rows collide. Defaults to the label, else "list".
--   id          function(data, index) -> ControlId; defaults to the element
--               data as the reference (focus follows a row through re-sorts)
--   button      function(rowFrame, data, index) -> the clickable frame within
--               the row; defaults to the row frame itself
--   row         function(data, index, helpers) -> vtable, replacing the
--               default row vtable entirely. helpers = { onFocus, target }
--               (the scroll hook and the lazy click target) for composing.
--   emit        function(builder, data, index, helpers) -- full control:
--               emit zero or more nodes for this element (multi-control rows,
--               skipped spacers). helpers adds id (the default ControlId).
--   templates   registry of emitters keyed by the element's frameTemplate --
--               the shape template-driven panels (the settings lists) use.
--               Missing templates fall to config.defaultTemplate, else to a
--               spoken not-implemented row; emitter errors report and skip
--               the row instead of killing the render.
function nodes.scrollBoxList(builder, config)
    local scrollBox = config.scrollBox
    if scrollBox == nil then
        error("scrollBoxList requires a scrollBox")
    end
    if config.rowLabel == nil and config.row == nil and config.emit == nil and config.templates == nil then
        error("scrollBoxList requires rowLabel, row, emit, or templates")
    end

    local size = scrollBox:GetDataProviderSize()
    local provider = scrollBox.GetDataProvider ~= nil and scrollBox:GetDataProvider() or nil
    local keyPrefix = tostring(config.key or config.label or "list")

    -- An empty list is still a place to land.
    if size == 0 or provider == nil then
        if config.label ~= nil then
            builder:pushContext(keyPrefix, config.label)
        end
        builder:addItem(ControlId.structural(keyPrefix .. ":empty"), nodes.text({ label = L["Empty"] }))
        if config.label ~= nil then
            builder:popContext()
        end
        return builder
    end

    if config.label ~= nil then
        builder:pushContext(keyPrefix, config.label)
    end

    for index = 1, size do
        local data = provider:Find(index)
        local capturedIndex = index

        local id
        if config.id ~= nil then
            id = config.id(data, capturedIndex)
        elseif type(data) == "table" then
            id = ControlId.referenced(data, keyPrefix .. ":" .. capturedIndex)
        else
            id = ControlId.structural(keyPrefix .. ":" .. tostring(data) .. ":" .. capturedIndex)
        end

        local target = function()
            local rowFrame = resolveRowFrame(scrollBox, data, capturedIndex)
            if rowFrame ~= nil and config.button ~= nil then
                return config.button(rowFrame, data, capturedIndex)
            end
            return rowFrame
        end
        -- Scroll first so the row materializes, then hover it: the game shows
        -- its tooltip and highlight for the reader.
        local onFocus = nodes.attachHover({
            onFocus = function()
                scrollBox:ScrollToElementDataIndex(capturedIndex)
            end,
        }, target)
        local onUnfocus = onFocus.onUnfocus
        onFocus = onFocus.onFocus

        -- Stateless per-tick re-align: if the row scrolled out from under
        -- focus, pull it back. The host's click-drift watch handles
        -- re-engaging bindings when the frame mapping shifts.
        local onFocusTick = function()
            if target() == nil then
                scrollBox:ScrollToElementDataIndex(capturedIndex)
            end
        end

        -- Provider elements may be plain values (index-range providers hand
        -- out numbers), so only tables carry template and name info.
        local isTable = type(data) == "table"
        graph.scrollBoxDebug[tostring(id.key)] = {
            template = tostring(isTable and data.frameTemplate or "?"),
            name = tostring(
                isTable and (data.name or (type(data.data) == "table" and data.data.name or nil)) or tostring(data)
            ),
        }

        local helpers = {
            onFocus = onFocus,
            onFocusTick = onFocusTick,
            onUnfocus = onUnfocus,
            target = target,
            id = id,
        }
        if config.templates ~= nil then
            local emitter = config.templates[isTable and data.frameTemplate or nil] or config.defaultTemplate
            if emitter ~= nil then
                local ok, err = pcall(emitter, builder, data, capturedIndex, helpers)
                if not ok then
                    geterrorhandler()(err)
                end
            else
                builder:addItem(id, {
                    controlType = graph.controlTypes.text,
                    announcements = {
                        {
                            text = "Row template " .. tostring(data ~= nil and data.frameTemplate) .. " not implemented",
                        },
                    },
                })
            end
        elseif config.emit ~= nil then
            config.emit(builder, data, capturedIndex, helpers)
        else
            local vtable
            if config.row ~= nil then
                vtable = config.row(data, capturedIndex, helpers)
            else
                vtable = {
                    controlType = graph.controlTypes.button,
                    announcements = {
                        {
                            text = function()
                                return config.rowLabel(data, capturedIndex)
                            end,
                            kind = kinds.label,
                        },
                    },
                    bindings = {
                        { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = target },
                        { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = target },
                    },
                    onFocus = onFocus,
                    onFocusTick = onFocusTick,
                    onUnfocus = onUnfocus,
                    tooltipFrame = target,
                }
            end
            builder:addItem(id, vtable)
        end
    end

    if config.label ~= nil then
        builder:popContext()
    end
    return builder
end
