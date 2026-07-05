local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The HybridScrollFrame adapter: a fixed pool of row buttons over an
-- API-enumerable list (the quest log). The panel's update loop stamps each
-- visible button's ID with its absolute data index, so focusing an index
-- drives the real scrollbar in row-height units (which reruns the panel's
-- update) and the click target is the pooled button whose ID matches.
--
-- config:
--   scrollFrame  the HybridScrollFrame (required)
--   count        function -> number of logical entries (required)
--   emit         function(builder, index, helpers) -- emit the entry's nodes
--                (required). helpers = { onFocus, target, id }.
--   key          stable prefix for default ids (default "hybrid")
--   label        announcement context wrapped around the entries
--   id           function(index) -> ControlId; default structural key:index
--   rowHeight    pixels per row; defaults to the first pooled button's height
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

    local function rowHeight()
        if config.rowHeight ~= nil then
            return config.rowHeight
        end
        local buttons = scrollFrame.buttons
        if buttons ~= nil and buttons[1] ~= nil then
            return buttons[1]:GetHeight()
        end
        return 16
    end

    local function scrollBarOf()
        if scrollFrame.scrollBar ~= nil then
            return scrollFrame.scrollBar
        end
        if scrollFrame.GetName ~= nil and scrollFrame:GetName() ~= nil then
            return _G[scrollFrame:GetName() .. "ScrollBar"]
        end
        return nil
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
            pcall(function()
                local offset = HybridScrollFrame_GetOffset(scrollFrame)
                local visible = scrollFrame.buttons ~= nil and #scrollFrame.buttons or 0
                if capturedIndex <= offset or capturedIndex > offset + visible - 1 then
                    local scrollBar = scrollBarOf()
                    if scrollBar ~= nil then
                        scrollBar:SetValue((capturedIndex - 1) * rowHeight())
                    end
                end
            end)
        end

        local target = function()
            local buttons = scrollFrame.buttons
            if buttons == nil then
                return nil
            end
            for _, button in ipairs(buttons) do
                if button:IsShown() and button:GetID() == capturedIndex then
                    return button
                end
            end
            return nil
        end

        config.emit(builder, capturedIndex, { onFocus = onFocus, target = target, id = id })
    end

    if config.label ~= nil then
        builder:popContext()
    end
    return builder
end
