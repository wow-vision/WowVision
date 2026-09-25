local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The WoW: Forever pet journal (the classic companion journal): search,
-- the collected/not collected filter, the pet list (a ScrollBox read from
-- the pet journal API), the selected pet's card, and the summon button.

-- A pet list entry's label: its name (a custom name first, then the
-- species), and whether it is collected or a favorite.
local function petLabel(index)
    local _, _, isOwned, customName, _, favorite, _, name = C_PetJournal.GetPetInfoByIndex(index)
    if name == nil then
        return nil
    end
    local label = name
    if customName ~= nil and customName ~= "" then
        label = customName .. " (" .. name .. ")"
    end
    return nodes.joinLabel(label, not isOwned and NOT_COLLECTED, favorite and FAVORITE)
end

local function petRow(data, index, helpers)
    local vtable = {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return petLabel(data.index)
                end,
                kind = kinds.label,
            },
            {
                text = function()
                    local card = PetJournalPetCard
                    if card ~= nil and card.speciesID == data.speciesID and card.petID == data.petID then
                        return L["selected"]
                    end
                    return nil
                end,
                kind = kinds.selected,
            },
        },
        bindings = {
            -- Left shows the pet's card; right opens the pet menu (summon,
            -- favorite) for owned pets, which the dropdown watcher picks up.
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
    }
    -- Only owned pets can be picked up (to an action bar).
    if data.petID ~= nil then
        tinsert(vtable.bindings, {
            binding = "drag",
            type = "Function",
            func = nodes.pickupAction(function()
                C_PetJournal.PickupPet(data.petID)
            end, true),
        })
    end
    return vtable
end

-- The selected pet's card: name (and species under a custom name), where
-- it comes from, and its description.
local function renderPetCard(builder)
    local card = PetJournalPetCard
    if card == nil or not card:IsShown() or card.speciesID == nil then
        return
    end
    local info = card.PetInfo
    builder:beginStop("petCard")
    builder:pushContext("petCard", L["Details"])
    builder:addItem(
        ControlId.structural("petCardName"),
        nodes.text({
            label = function()
                return nodes.joinLabel(nodes.shownText(info.name), nodes.shownText(info.subName))
            end,
        })
    )
    if info.sourceText ~= nil and info.sourceText ~= "" then
        builder:addItem(ControlId.structural("petCardSource"), nodes.text({ label = info.sourceText }))
    end
    if info.description ~= nil and info.description ~= "" then
        builder:addItem(ControlId.structural("petCardDescription"), nodes.text({ label = info.description }))
    end
    builder:popContext()
end

local function renderPetJournal(builder)
    local journal = PetJournal
    module.renderSearchAndFilter(builder, "pet", journal.searchBox, journal.FilterDropdown)

    builder:beginStop("pets")
    nodes.scrollBoxList(builder, {
        scrollBox = journal.ScrollBox,
        key = "pets",
        label = PET_JOURNAL,
        id = function(data, index)
            if data.petID ~= nil then
                return ControlId.structural("pet:" .. data.petID)
            end
            return ControlId.structural("species:" .. tostring(data.speciesID))
        end,
        row = petRow,
    })

    renderPetCard(builder)

    builder:beginStop("summon")
    builder:addItem(ControlId.forObject(PetJournalSummonButton), nodes.proxyButton({ target = PetJournalSummonButton }))
end

module.addTab(2, { frame = "PetJournal", render = renderPetJournal })
