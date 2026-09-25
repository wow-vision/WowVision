local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The WoW: Forever heirloom journal: search, filter, class filter, the
-- collected progress, the current page (slot headers over their heirlooms,
-- in the page's own layout order), and the page controls. The tab only
-- shows while the game offers heirlooms.

-- The entry button showing this heirloom, or nil.
local function findHeirloom(itemID)
    for _, entry in ipairs(HeirloomsJournal.heirloomEntryFrames or {}) do
        if entry:IsShown() and entry.itemID == itemID then
            return entry
        end
    end
    return nil
end

-- An heirloom's label: its name, the level it scales to (collected only),
-- the PvP tag, and not collected.
local function heirloomLabel(entry)
    return nodes.joinLabel(
        nodes.shownText(entry.name),
        nodes.shownText(entry.level),
        nodes.shownText(entry.special),
        not C_Heirloom.PlayerHasHeirloom(entry.itemID) and NOT_COLLECTED
    )
end

-- An heirloom: either click creates it in the bags (or upgrades it while an
-- upgrade item is on the cursor). No drag: the buttons have none.
local function heirloomNode(itemID)
    return nodes.proxyFoundButton({
        find = function()
            return findHeirloom(itemID)
        end,
        label = heirloomLabel,
        tooltip = function(tooltip)
            tooltip:SetHeirloomByItemID(itemID)
        end,
        rightClick = false,
    })
end

-- The page layout lists, in display order, header texts (strings), new-row
-- markers (-1), and item ids; the header frames show those same strings.
local function renderPage(builder, journal)
    local layout = journal.heirloomLayoutData ~= nil and journal.heirloomLayoutData[journal.PagingFrame:GetCurrentPage()]
        or nil
    local inHeader = false
    local emitted = 0
    for _, entry in ipairs(layout or {}) do
        if type(entry) == "string" then
            if inHeader then
                builder:popContext()
            end
            builder:pushContext("header:" .. entry, entry)
            inHeader = true
        elseif type(entry) == "number" and entry > 0 then
            builder:addItem(ControlId.structural("heirloom:" .. entry), heirloomNode(entry))
            emitted = emitted + 1
        end
    end
    if inHeader then
        builder:popContext()
    end
    return emitted
end

local function renderHeirlooms(builder)
    local journal = HeirloomsJournal
    module.renderSearchAndFilter(builder, "heirloom", journal.SearchBox, journal.FilterDropdown)

    builder:beginStop("heirloomClass")
    builder:addItem(ControlId.forObject(journal.ClassDropdown), module.namedDropdown(journal.ClassDropdown, CLASS))

    local progress = journal.progressBar
    if progress:IsShown() then
        builder:beginStop("heirloomProgress")
        builder:addItem(
            ControlId.structural("heirloomProgress"),
            nodes.text({
                label = function()
                    return nodes.joinLabel(L["Progress"], progress.text:GetText())
                end,
            })
        )
    end

    builder:beginStop("heirlooms")
    builder:pushContext("heirlooms", HEIRLOOMS)
    if renderPage(builder, journal) == 0 then
        builder:addItem(ControlId.structural("heirloomsEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    nodes.pagingRow(builder, "heirloom", journal.PagingFrame)
end

module.addTab(4, { frame = "HeirloomsJournal", render = renderHeirlooms })
