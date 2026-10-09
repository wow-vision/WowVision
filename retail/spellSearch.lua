local spellSearch = {}
WowVision.spellSearch = spellSearch

local L = WowVision:getLocale()
local graph = WowVision.graph
local nodes = graph.nodes

-- The modern spell search box of retail and WoW: Forever (on Forever the
-- spellbook and the class talents; no retail window uses it yet). Typing fills a suggestion list under the box; while the box has
-- the keyboard, Up and Down move the list's highlight and Enter picks the
-- highlighted suggestion (else it searches the typed text). Those are the
-- game's own keys, but the highlight is only drawn, so a hook after the
-- list's highlight call speaks it: the suggestion, its position, and on the
-- last one the game's line for the matches that did not fit. It speaks
-- only while WowVision's focus is on the box and the box has the keyboard,
-- so a mouse over the list, or a window WowVision does not run, stays
-- silent.

-- Hooked lists and the box each belongs to; hooksecurefunc stacks, so each
-- list is hooked once.
local boxes = setmetatable({}, { __mode = "k" })

local function focusedOn(editBox)
    if not editBox:HasFocus() then
        return false
    end
    local screen = WowVision.graphHost:focusedScreen()
    local node = screen ~= nil and screen.keyGraph:currentNode() or nil
    return node ~= nil and node.vtable.tooltipFrame == editBox
end

local function highlightedText(container)
    local index = container.highlightedIndex
    if index == nil or index <= 0 then
        return nil
    end
    local scrollBox = container.ScrollBox
    if scrollBox:HasDataProvider() then
        local count = scrollBox:GetDataProviderSize()
        local data = scrollBox:GetDataProvider():Find(index)
        local name = data ~= nil and data.resultInfo ~= nil and data.resultInfo.name or nil
        local overflow = nil
        if index == count and container.OverflowCount:IsShown() then
            overflow = container.OverflowCount.Text:GetText()
        end
        return nodes.joinLabel(name, graph.announcer.positionText(index, count), overflow)
    end
    -- No matches: the list offers the frame's suggested searches instead.
    local text = nil
    local count = 0
    for button in container.suggestedResultButtonsPool:EnumerateActive() do
        count = count + 1
        if button.displayIndex == index then
            text = button.Text:GetText()
        end
    end
    if text == nil then
        return nil
    end
    return nodes.joinLabel(text, graph.announcer.positionText(index, count))
end

local function watch(editBox, container)
    if container == nil then
        return
    end
    if boxes[container] == nil then
        hooksecurefunc(container, "HighlightPreviewResult", function(self)
            local box = boxes[self]
            if box == nil or not focusedOn(box) then
                return
            end
            local text = highlightedText(self)
            if text ~= nil then
                WowVision:speak(text)
            end
        end)
    end
    boxes[container] = editBox
end

-- The search box as an edit box node, its suggestions spoken.
function spellSearch.node(editBox)
    if editBox.GetSearchPreviewContainer ~= nil then
        watch(editBox, editBox:GetSearchPreviewContainer())
    end
    return nodes.proxyEditBox({ editBox = editBox, label = L["Search"] })
end
