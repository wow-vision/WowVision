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
    local petID, _, isOwned, customName, _, favorite, _, name = C_PetJournal.GetPetInfoByIndex(index)
    if name == nil then
        return nil
    end
    local label = name
    if customName ~= nil and customName ~= "" then
        label = customName .. " (" .. name .. ")"
    end
    return module.joinLabel({
        label,
        not isOwned and NOT_COLLECTED or nil,
        favorite and FAVORITE or nil,
    })
end

local function petRow(data, index, helpers)
    return {
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
                    if card == nil or card.speciesID ~= data.speciesID then
                        return nil
                    end
                    if card.petID == data.petID then
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
            {
                binding = "drag",
                type = "Function",
                func = function()
                    local row = helpers.target()
                    local script = row ~= nil and row:GetScript("OnDragStart") or nil
                    if script ~= nil then
                        script(row)
                    end
                end,
            },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
    }
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
                return module.joinLabel({ module.shownText(info.name), module.shownText(info.subName) })
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

function module.renderPetJournal(builder)
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

    if PetJournalSummonButton ~= nil and PetJournalSummonButton:IsShown() then
        builder:beginStop("summon")
        builder:addItem(
            ControlId.forObject(PetJournalSummonButton),
            nodes.proxyButton({ target = PetJournalSummonButton })
        )
    end
end
