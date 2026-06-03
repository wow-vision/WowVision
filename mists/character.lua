local module = WowVision.base.windows:createModule("character")
local L = module.L
module:setLabel(L["Character"])
local gen = module:hasUI()

-- Slot ID to localized name mapping for empty slots
local SLOT_NAMES = {
    [INVSLOT_HEAD] = L["Head"],
    [INVSLOT_NECK] = L["Neck"],
    [INVSLOT_SHOULDER] = L["Shoulders"],
    [INVSLOT_BACK] = L["Back"],
    [INVSLOT_CHEST] = L["Chest"],
    [INVSLOT_BODY] = L["Shirt"],
    [INVSLOT_TABARD] = L["Tabard"],
    [INVSLOT_WRIST] = L["Wrist"],
    [INVSLOT_HAND] = L["Hands"],
    [INVSLOT_WAIST] = L["Waist"],
    [INVSLOT_LEGS] = L["Legs"],
    [INVSLOT_FEET] = L["Feet"],
    [INVSLOT_FINGER1] = L["Finger"],
    [INVSLOT_FINGER2] = L["Finger"],
    [INVSLOT_TRINKET1] = L["Trinket"],
    [INVSLOT_TRINKET2] = L["Trinket"],
    [INVSLOT_MAINHAND] = L["Main Hand"],
    [INVSLOT_OFFHAND] = L["Off Hand"],
    [INVSLOT_RANGED] = L["Ranged"],
}

gen:Element("character", {
    regenerateOn = {
        events = { "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED" },
        values = function(props)
            return { selectedTab = CharacterFrame.selectedTab }
        end,
    },
}, function(props)
    local result = { "Panel", label = "Character Frame", wrap = true, children = {} }
    local tab = CharacterFrame.selectedTab
    if tab == 1 then
        tinsert(result.children, { "character/PaperDoll", frame = PaperDollFrame })
    elseif tab == 3 then
        tinsert(result.children, { "character/Reputation", frame = ReputationFrame })
        tinsert(result.children, { "character/ReputationDetail" })
    elseif tab == 4 then
        tinsert(result.children, { "character/Currency", frame = TokenFrame })
    else
        tinsert(result.children, { "Text", text = "Not yet implemented" })
    end
    tinsert(result.children, { "character/Tabs" })
    return result
end)

gen:Element("character/Tabs", {
    regenerateOn = {
        values = function(props)
            return { selectedTab = CharacterFrame.selectedTab }
        end,
    },
}, function(props)
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    for i = 1, 4 do
        local tab = _G["CharacterFrameTab" .. i]
        if tab then
            tinsert(result.children, {
                "ProxyButton",
                key = "tab_" .. i,
                frame = tab,
                selected = CharacterFrame.selectedTab == i,
            })
        end
    end
    return result
end)

gen:Element("character/PaperDoll", {
    regenerateOn = {
        events = { "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED" },
    },
}, function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "character/Equipment", frame = PaperDollItemsFrame },
            { "character/Stats" },
        },
    }
end)

local function getEquipmentLabel(frame)
    local slotId = frame:GetID()
    local itemLink = GetInventoryItemLink("player", slotId)
    if itemLink then
        local itemName = GetItemInfo(itemLink)
        -- GetItemInfo may return nil if item isn't cached yet, fallback to link
        return itemName or itemLink
    end
    -- Empty slot - return localized slot name
    return SLOT_NAMES[slotId] or L["Empty"]
end

gen:Element("character/Equipment", {
    regenerateOn = {
        events = { "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED" },
    },
}, function(props)
    local result = { "List", label = L["Equipment"], children = {} }
    local children = { props.frame:GetChildren() }
    for i, v in ipairs(children) do
        local slotId = v:GetID()
        tinsert(result.children, {
            "ItemButton",
            key = "slot_" .. slotId,
            frame = v,
            label = getEquipmentLabel(v),
            tooltip = {
                type = "Game",
                mode = "immediate",
            },
        })
    end
    return result
end)

gen:Element("character/Stats", {
    regenerateOn = {
        events = {
            "PLAYER_EQUIPMENT_CHANGED",
            "UNIT_INVENTORY_CHANGED",
            "COMBAT_RATING_UPDATE",
            "UNIT_STATS",
            "UNIT_AURA",
            "UNIT_DAMAGE",
            "UNIT_ATTACK_SPEED",
            "UNIT_ATTACK_POWER",
            "UNIT_RANGED_ATTACK_POWER",
            "PLAYER_DAMAGE_DONE_MODS",
        },
    },
}, function(props)
    local result = { "List", label = L["Stats"], children = {} }
    for i, k in ipairs(PAPERDOLL_STATCATEGORY_DEFAULTORDER) do
        local v = PAPERDOLL_STATCATEGORIES[k]
        local categoryFrame = _G["CharacterStatsPaneCategory" .. v.id]
        tinsert(result.children, { "character/StatsCategory", key = "category_" .. v.id, frame = categoryFrame })
    end
    return result
end)

-- No regenerateOn needed - this is always a child of character/Stats
-- which handles the event-driven regeneration
gen:Element("character/StatsCategory", function(props)
    local label = props.frame.NameText:GetText()
    if not label or label == "" then
        return nil
    end
    local result = { "List", direction = "horizontal", label = label, children = {} }
    local children = { props.frame:GetChildren() }
    for i = 2, #children do
        local stat = children[i]
        if stat:IsShown() then
            tinsert(result.children, {
                "ProxyButton",
                key = "stat_" .. i,
                frame = stat,
                label = tostring(stat.Label:GetText()) .. " " .. tostring(stat.Value:GetText()),
                tooltip = {
                    type = "Game",
                    mode = "immediate",
                },
            })
        end
    end
    return result
end)

local function getTokenNumEntries(self, element)
    return GetCurrencyListSize()
end

local function getTokenElement(self, button)
    local index = button.index
    local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maxQuantity, maxEarnable, quantityEarned, isTradeable, itemID =
        GetCurrencyListInfo(index)
    local label = name
    local header = nil
    if isHeader then
        if isExpanded then
            header = "expanded"
        else
            header = "collapsed"
        end
    elseif count ~= nil then
        label = label .. " " .. count
    end
    return { "ProxyButton", frame = button, label = label, header = header }
end

gen:Element("character/Currency", {
    regenerateOn = {
        events = { "CURRENCY_DISPLAY_UPDATE" },
    },
}, function(props)
    local frame = TokenFrameContainer
    local result = {
        "List",
        label = CharacterFrameTab4:GetText(),
        children = {
            {
                "ProxyScrollFrame",
                frame = frame,
                getNumEntries = getTokenNumEntries,
                getElement = getTokenElement,
            },
        },
    }
    return result
end)

------------------------------------------------------------
-- Reputation tab (tab 3). Mists uses the Cata ReputationFrame: ReputationBar[i]
-- rows, ReputationHeader[i] header buttons, a ReputationListScrollFrame
-- FauxScrollFrame, and a ReputationDetailFrame side panel.
------------------------------------------------------------

local NUM_FACTIONS_DISPLAYED = NUM_FACTIONS_DISPLAYED or 15

-- ReputationBar frames report GetID() == 0; derive the display index from the
-- frame name ("ReputationBar3" -> 3) at use time, so we don't depend on the
-- frames existing at addon-load time.
local function repBarIndex(frame)
    local n = frame and frame.GetName and frame:GetName()
    return n and tonumber(n:match("^ReputationBar(%d+)$"))
end

local function buildReputationElement(self, frame)
    local i = repBarIndex(frame)
    if not i then
        return nil
    end
    local bar = frame
    local header = _G["ReputationHeader" .. i]
    local isHeader = header and header:IsShown()
    local isBar = bar and bar:IsShown()
    if not isHeader and not isBar then
        return nil
    end

    local name
    if isHeader and header.Text then
        name = header.Text:GetText() or ""
    else
        local nameText = _G["ReputationBar" .. i .. "FactionName"]
        name = nameText and nameText:GetText() or ""
    end
    if not name or name == "" then
        return nil
    end

    local label = name
    local standingFrame = _G["ReputationBar" .. i .. "FactionStanding"]
    local standingText = standingFrame and standingFrame:GetText() or ""
    if standingText and standingText ~= "" then
        label = label .. " - " .. standingText
    end
    if bar.tooltip and bar.tooltip ~= "" then
        label = label .. bar.tooltip
    end

    if isHeader then
        return {
            "ProxyButton",
            frame = header,
            label = label,
            header = header.isCollapsed and "collapsed" or "expanded",
        }
    end
    -- Regular rows are StatusBars (OnMouseUp, not OnClick), so use a Button that
    -- calls ReputationBar_OnClick directly.
    return {
        "Button",
        label = label,
        events = {
            click = function()
                ReputationBar_OnClick(bar)
            end,
        },
    }
end

local function getNumFactions()
    return GetNumFactions()
end

local function getReputationIndex(self, frame)
    local offset = FauxScrollFrame_GetOffset(ReputationListScrollFrame) or 0
    return (repBarIndex(frame) or 0) + offset
end

local function getReputationRows()
    local rows = {}
    for i = 1, NUM_FACTIONS_DISPLAYED do
        local frame = _G["ReputationBar" .. i]
        if frame then
            tinsert(rows, frame)
        end
    end
    return rows
end

gen:Element("character/Reputation", {
    regenerateOn = {
        events = { "UPDATE_FACTION" },
    },
}, function(props)
    if ReputationListScrollFrame and ReputationListScrollFrame:IsShown() then
        return {
            "ProxyFauxScrollFrame",
            frame = ReputationListScrollFrame,
            buttonHeight = REPUTATIONFRAME_FACTIONHEIGHT,
            updateFunction = ReputationFrame_Update,
            getNumEntries = getNumFactions,
            getElement = buildReputationElement,
            getElementIndex = getReputationIndex,
            getButtons = getReputationRows,
        }
    end

    -- Scroll frame hidden (few factions): render rows directly.
    local children = {}
    for i = 1, NUM_FACTIONS_DISPLAYED do
        local frame = _G["ReputationBar" .. i]
        if frame then
            local element = buildReputationElement(nil, frame)
            if element then
                tinsert(children, element)
            end
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Reputation"], children = children }
end)

gen:Element("character/ReputationDetail", function(props)
    local frame = ReputationDetailFrame
    if not frame or not frame:IsShown() then
        return nil
    end

    local children = {}
    local factionName = ReputationDetailFactionName and ReputationDetailFactionName:GetText() or ""
    local description = ReputationDetailFactionDescription and ReputationDetailFactionDescription:GetText() or ""
    if description and description ~= "" then
        tinsert(children, { "Text", text = description })
    end
    if ReputationDetailAtWarCheckbox and ReputationDetailAtWarCheckbox:IsShown() then
        tinsert(children, { "ProxyCheckButton", frame = ReputationDetailAtWarCheckbox, label = L["At War"] })
    end
    if ReputationDetailInactiveCheckbox and ReputationDetailInactiveCheckbox:IsShown() then
        tinsert(children, { "ProxyCheckButton", frame = ReputationDetailInactiveCheckbox, label = MOVE_TO_INACTIVE or "Move to Inactive" })
    end
    if ReputationDetailMainScreenCheckbox and ReputationDetailMainScreenCheckbox:IsShown() then
        tinsert(children, { "ProxyCheckButton", frame = ReputationDetailMainScreenCheckbox, label = L["Watched"] })
    end
    if ReputationDetailCloseButton then
        tinsert(children, { "ProxyButton", frame = ReputationDetailCloseButton, label = CLOSE or "Close" })
    end

    return { "List", label = factionName, children = children }
end)

module:registerWindow({
    type = "FrameWindow",
    name = "character",
    generated = true,
    rootElement = "character",
    frameName = "CharacterFrame",
    conflictingAddons = { "Sku" },
})
