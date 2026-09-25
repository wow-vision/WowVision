local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The WoW: Forever toy box: search, filter, the collected count, the
-- current page of toys (eighteen fixed buttons, rebound on every page
-- flip), and the page controls.

local TOYS_PER_PAGE = 18

local function toyButtons()
    return ToyBox.iconsFrame
end

-- The toy button showing this toy, or nil.
local function findToy(itemID)
    local icons = toyButtons()
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
    return module.joinLabel({
        module.shownText(button.name) or tostring(itemID),
        not PlayerHasToy(itemID) and NOT_COLLECTED or nil,
        C_ToyBox.GetIsFavorite(itemID) and FAVORITE or nil,
    })
end

function module.renderToyBox(builder)
    local box = ToyBox
    module.renderSearchAndFilter(builder, "toy", box.searchBox, box.FilterDropdown)

    local tracker = box.ProgressTracker
    if tracker ~= nil and tracker:IsShown() then
        builder:beginStop("toyProgress")
        builder:addItem(
            ControlId.structural("toyProgress"),
            nodes.text({
                label = function()
                    return module.joinLabel({ module.shownText(tracker.Label), module.shownText(tracker.Count) })
                end,
            })
        )
    end

    builder:beginStop("toys")
    builder:pushContext("toys", TOY_BOX)
    local icons = toyButtons()
    local emitted = 0
    for i = 1, TOYS_PER_PAGE do
        local button = icons["spellButton" .. i]
        local itemID = button ~= nil and button.itemID or nil
        if button ~= nil and button:IsShown() and itemID ~= nil and itemID > 0 then
            builder:addItem(
                ControlId.structural("toy:" .. itemID),
                -- Left uses the toy, right opens the favorite menu (owned
                -- toys), drag picks it up.
                module.foundButtonNode({
                    find = function()
                        return findToy(itemID)
                    end,
                    label = toyLabel,
                    tooltip = function(tooltip)
                        tooltip:SetToyByItemID(itemID)
                    end,
                })
            )
            emitted = emitted + 1
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("toysEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    module.renderPaging(builder, "toy", box.PagingFrame)
end
