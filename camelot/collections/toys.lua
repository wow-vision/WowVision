local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The WoW: Forever toy box: search, filter, the collected count, the
-- current page of toys (eighteen fixed buttons, rebound on every page
-- flip), and the page controls.

local TOYS_PER_PAGE = 18

-- The toy button showing this toy, or nil.
local function findToy(itemID)
    local icons = ToyBox.iconsFrame
    for i = 1, TOYS_PER_PAGE do
        local button = icons["spellButton" .. i]
        if button ~= nil and button:IsShown() and button.itemID == itemID then
            return button
        end
    end
    return nil
end

-- A toy's label: its name, then not collected or favorite.
local function toyLabel(button)
    local itemID = button.itemID
    return nodes.joinLabel(
        nodes.shownText(button.name) or tostring(itemID),
        not PlayerHasToy(itemID) and NOT_COLLECTED,
        C_ToyBox.GetIsFavorite(itemID) and FAVORITE
    )
end

-- A toy: left uses it, right opens the favorite menu (owned toys), drag
-- picks it up for an action bar.
local function toyNode(itemID)
    return nodes.proxyFoundButton({
        find = function()
            return findToy(itemID)
        end,
        label = toyLabel,
        tooltip = function(tooltip)
            tooltip:SetToyByItemID(itemID)
        end,
        drag = nodes.pickupAction(function()
            C_ToyBox.PickupToyBoxItem(itemID)
        end, true),
    })
end

local function renderToyBox(builder)
    local box = ToyBox
    module.renderSearchAndFilter(builder, "toy", box.searchBox, box.FilterDropdown)

    local tracker = box.ProgressTracker
    if tracker ~= nil and tracker:IsShown() then
        builder:beginStop("toyProgress")
        builder:addItem(
            ControlId.structural("toyProgress"),
            nodes.text({
                label = function()
                    return nodes.joinLabel(nodes.shownText(tracker.Label), nodes.shownText(tracker.Count))
                end,
            })
        )
    end

    builder:beginStop("toys")
    builder:pushContext("toys", TOY_BOX)
    local emitted = 0
    for i = 1, TOYS_PER_PAGE do
        local button = box.iconsFrame["spellButton" .. i]
        local itemID = button ~= nil and button.itemID or nil
        if button ~= nil and button:IsShown() and itemID ~= nil and itemID > 0 then
            builder:addItem(ControlId.structural("toy:" .. itemID), toyNode(itemID))
            emitted = emitted + 1
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("toysEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    nodes.pagingRow(builder, "toy", box.PagingFrame)
end

module.addTab(3, { frame = "ToyBox", render = renderToyBox })
