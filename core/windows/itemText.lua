local module = WowVision.base.windows:createModule("ItemText")
local L = module.L
module:setLabel(L["Item Text"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Books, letters, plaques: the item text reader. Content is one stop; page
-- turns rewrite the live text in place. The text arrives async
-- (ITEM_TEXT_READY), so labels resolve nil until the client has it and the
-- live watch speaks it when it lands.

local function contentText(builder, id, label)
    builder:addItem(id, nodes.text({ label = label }))
end

local function render(builder, screen)
    if ItemTextFrame == nil or not ItemTextFrame:IsShown() then
        return
    end
    builder:pushContext("itemText", ItemTextGetItem() or L["Item Text"])

    builder:beginStop("content")
    contentText(builder, ControlId.structural("name"), function()
        return ItemTextGetItem()
    end)
    contentText(builder, ControlId.structural("creator"), function()
        local creator = ItemTextGetCreator()
        if creator ~= nil and creator ~= "" then
            return creator
        end
        return nil
    end)
    contentText(builder, ControlId.structural("page"), function()
        local page = ItemTextGetPage()
        if page ~= nil and page > 0 then
            return L["Page"] .. " " .. page
        end
        return nil
    end)
    contentText(builder, ControlId.structural("body"), function()
        return ItemTextGetText()
    end)

    if ItemTextPrevPageButton ~= nil and ItemTextPrevPageButton:IsShown() then
        builder:beginStop("prevPage")
        builder:addItem(
            ControlId.forObject(ItemTextPrevPageButton),
            nodes.proxyButton({ target = ItemTextPrevPageButton, label = L["Previous Page"] })
        )
    end
    if ItemTextNextPageButton ~= nil and ItemTextNextPageButton:IsShown() then
        builder:beginStop("nextPage")
        builder:addItem(
            ControlId.forObject(ItemTextNextPageButton),
            nodes.proxyButton({ target = ItemTextNextPageButton, label = L["Next Page"] })
        )
    end
    builder:beginStop("close")
    builder:addItem(
        ControlId.forObject(ItemTextFrameCloseButton),
        nodes.proxyButton({ target = ItemTextFrameCloseButton, label = L["Close"] })
    )

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "ItemText",
    frameName = "ItemTextFrame",
    graphScreen = { render = render },
})
