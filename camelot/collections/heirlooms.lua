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
    local itemID = entry.itemID
    return module.joinLabel({
        module.shownText(entry.name),
        module.shownText(entry.level),
        module.shownText(entry.special),
        not C_Heirloom.PlayerHasHeirloom(itemID) and NOT_COLLECTED or nil,
    })
end

-- The page layout lists, in display order, header markers (strings, one per
-- header frame in order), new-row markers (-1), and item ids.
local function renderPage(builder, journal)
    local layout = journal.heirloomLayoutData ~= nil and journal.heirloomLayoutData[journal.PagingFrame:GetCurrentPage()]
        or nil
    local headers = journal.heirloomHeaderFrames or {}
    local headerIndex = 0
    local inHeader = false
    local emitted = 0
    for _, entry in ipairs(layout or {}) do
        if type(entry) == "string" then
            headerIndex = headerIndex + 1
            local header = headers[headerIndex]
            local text = header ~= nil and header.text ~= nil and header.text:GetText() or entry
            if inHeader then
                builder:popContext()
            end
            builder:pushContext("header:" .. text, text)
            inHeader = true
        elseif type(entry) == "number" and entry > 0 then
            local itemID = entry
            if findHeirloom(itemID) ~= nil then
                builder:addItem(
                    ControlId.structural("heirloom:" .. itemID),
                    -- Either click creates the heirloom in the bags (or
                    -- upgrades it while an upgrade item is on the cursor).
                    module.foundButtonNode({
                        find = function()
                            return findHeirloom(itemID)
                        end,
                        label = heirloomLabel,
                        tooltip = function(tooltip)
                            tooltip:SetHeirloomByItemID(itemID)
                        end,
                        rightClick = false,
                    })
                )
                emitted = emitted + 1
            end
        end
    end
    if inHeader then
        builder:popContext()
    end
    return emitted
end

function module.renderHeirlooms(builder)
    local journal = HeirloomsJournal
    module.renderSearchAndFilter(builder, "heirloom", journal.SearchBox, journal.FilterDropdown)

    if journal.ClassDropdown ~= nil then
        builder:beginStop("heirloomClass")
        builder:addItem(
            ControlId.forObject(journal.ClassDropdown),
            module.namedDropdown(journal.ClassDropdown, CLASS)
        )
    end

    local progress = journal.progressBar
    if progress ~= nil and progress:IsShown() and progress.text ~= nil then
        builder:beginStop("heirloomProgress")
        builder:addItem(
            ControlId.structural("heirloomProgress"),
            nodes.text({
                label = function()
                    return module.joinLabel({ L["Progress"], progress.text:GetText() })
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

    module.renderPaging(builder, "heirloom", journal.PagingFrame)
end
