local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Shared pieces for the WoW: Forever collection tabs.

-- A dropdown reading its name and its current pick.
function module.namedDropdown(dropdown, name)
    local current = nodes.frameText(dropdown)
    return nodes.proxyDropdown({
        target = dropdown,
        label = function()
            return nodes.joinLabel(name, current())
        end,
    })
end

-- A search box and a filter dropdown, each its own stop (an edit box
-- cannot share a stop with anything after it).
function module.renderSearchAndFilter(builder, key, searchBox, filterDropdown)
    if searchBox ~= nil then
        builder:beginStop(key .. "Search")
        builder:addItem(
            ControlId.structural(key .. "Search"),
            nodes.proxyEditBox({ editBox = searchBox, label = L["Search"] })
        )
    end
    if filterDropdown ~= nil then
        builder:beginStop(key .. "Filter")
        builder:addItem(
            ControlId.forObject(filterDropdown),
            nodes.proxyDropdown({ target = filterDropdown, label = L["Filter"] })
        )
    end
end
