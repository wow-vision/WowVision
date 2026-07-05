local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

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
function nodes.scrollBoxList(builder, config)
    local scrollBox = config.scrollBox
    if scrollBox == nil then
        error("scrollBoxList requires a scrollBox")
    end
    if config.rowLabel == nil and config.row == nil and config.emit == nil then
        error("scrollBoxList requires rowLabel, row, or emit")
    end

    local size = scrollBox:GetDataProviderSize()
    local provider = scrollBox.GetDataProvider ~= nil and scrollBox:GetDataProvider() or nil
    if size == 0 or provider == nil then
        return builder
    end

    if config.label ~= nil then
        builder:pushContext(config.label)
    end

    for index = 1, size do
        local data = provider:Find(index)
        local capturedIndex = index

        local id
        if config.id ~= nil then
            id = config.id(data, capturedIndex)
        elseif type(data) == "table" then
            id = ControlId.referenced(data, "row:" .. capturedIndex)
        else
            id = ControlId.structural("row:" .. tostring(data) .. ":" .. capturedIndex)
        end

        local onFocus = function()
            scrollBox:ScrollToElementDataIndex(capturedIndex)
        end
        local target = function()
            local rowFrame = resolveRowFrame(scrollBox, data, capturedIndex)
            if rowFrame ~= nil and config.button ~= nil then
                return config.button(rowFrame, data, capturedIndex)
            end
            return rowFrame
        end

        if config.emit ~= nil then
            config.emit(builder, data, capturedIndex, { onFocus = onFocus, target = target, id = id })
        else
            local vtable
            if config.row ~= nil then
                vtable = config.row(data, capturedIndex, { onFocus = onFocus, target = target })
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
