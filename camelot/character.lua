local module = WowVision.base.windows:createModule("character")
local L = module.L
module:setLabel(L["Character"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The WoW: Forever character frame: a column of six side tabs (character,
-- reputation, skills, PvP, currency, statistics) swapping subframes into
-- one panel. The character tab is two panes: the paper doll with its
-- equipment slots on the left, and on the right a sidebar of stats,
-- equipment sets, or pet stats, each a ScrollBox list. The other tabs are
-- one ScrollBox list each, most with a detail side pane built from the
-- shared side-pane template (title, subtitle, description, rows, footer
-- controls).
--
-- Every list is driven from its data provider, so labels come from the
-- element data (or are recomputed from it), never from row frames that
-- may be scrolled out of existence.

-- ---- helpers ----

local function fontText(fontString)
    if fontString == nil or fontString.GetText == nil then
        return nil
    end
    local ok, text = pcall(fontString.GetText, fontString)
    if ok and text ~= nil and text ~= "" then
        return text
    end
    return nil
end

local function shown(frame)
    return frame ~= nil and frame.IsShown ~= nil and frame:IsShown()
end

local function selectedPart(isSelected)
    return {
        text = function()
            if isSelected() then
                return L["selected"]
            end
            return nil
        end,
        kind = kinds.selected,
    }
end

local function collapsedPart(isCollapsed)
    return {
        text = function()
            return isCollapsed() and L["Collapsed"] or L["Expanded"]
        end,
        kind = kinds.value,
    }
end

-- A list row: label from data, click through the row's real button.
local function listRow(helpers, label, extraParts, target)
    local announcements = { { text = label, kind = kinds.label } }
    for _, part in ipairs(extraParts or {}) do
        tinsert(announcements, part)
    end
    return {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = target or helpers.target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = target or helpers.target },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    }
end

-- A read-only list row that still scrolls into view when focused.
local function listText(helpers, label)
    return {
        controlType = graph.controlTypes.text,
        announcements = { { text = label, kind = kinds.label, live = "focus" } },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    }
end

-- Sub-header rows toggle through a child button when they have one.
local function collapseTarget(rowFrame)
    if rowFrame ~= nil and rowFrame.ToggleCollapseButton ~= nil then
        return rowFrame.ToggleCollapseButton
    end
    return rowFrame
end

-- ---- the shared side pane ----

local function sidePaneRows(pane)
    local rows = {}
    if pane.Content == nil then
        return rows
    end
    for _, row in ipairs({ pane.Content:GetChildren() }) do
        if row:IsShown() and row.Label ~= nil then
            tinsert(rows, row)
        end
    end
    table.sort(rows, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)
    return rows
end

-- One stop reading a detail pane top to bottom: title and subtitle,
-- description, the pooled rows (label and value, wrapped text, or a
-- category heading), then whatever footer controls the caller names.
local function renderSidePane(builder, pane, key, controls)
    if not shown(pane) then
        return
    end
    builder:beginStop(key)
    builder:pushContext(key, L["Details"])

    if shown(pane.EmptyText) then
        builder:addItem(ControlId.structural(key .. ":empty"), nodes.text({ label = nodes.frameText(pane.EmptyText) }))
    else
        builder:addItem(
            ControlId.structural(key .. ":title"),
            nodes.text({
                label = function()
                    local title = fontText(pane.Title) or ""
                    local subtitle = shown(pane.Subtitle) and fontText(pane.Subtitle) or nil
                    if subtitle ~= nil then
                        return title .. ", " .. subtitle
                    end
                    return title
                end,
                live = "focus",
            })
        )
        if shown(pane.Description) then
            builder:addItem(
                ControlId.structural(key .. ":description"),
                nodes.text({
                    label = function()
                        local fontString = pane.Description.GetFontString ~= nil and pane.Description:GetFontString()
                            or nil
                        return fontText(fontString)
                    end,
                })
            )
        end
        for index, row in ipairs(sidePaneRows(pane)) do
            local captured = row
            builder:addItem(
                ControlId.structural(key .. ":row:" .. index),
                nodes.text({
                    label = function()
                        local label = fontText(captured.Label) or ""
                        local value = captured.Value ~= nil and fontText(captured.Value) or nil
                        if value ~= nil then
                            return label .. " " .. value
                        end
                        return label
                    end,
                })
            )
        end
    end

    for _, control in ipairs(controls or {}) do
        local target = control.target
        if shown(target) then
            local vtable
            if control.check then
                vtable = nodes.proxyCheckButton({ target = target, label = control.label })
            else
                vtable = nodes.proxyButton({ target = target, label = control.label })
            end
            builder:addItem(ControlId.forObject(target), vtable)
        end
    end

    builder:popContext()
end

local function checkboxLabel(checkbox)
    return function()
        return fontText(checkbox.Label) or nodes.frameText(checkbox)()
    end
end

-- ---- character tab: equipment ----

local SLOT_NAMES = {
    [INVSLOT_AMMO] = L["Ammo"],
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

local function equipmentLabel(slot)
    local slotId = slot:GetID()
    local itemLink = GetInventoryItemLink("player", slotId)
    if itemLink then
        return WowVision.items.getLinkLabel(itemLink) or itemLink
    end
    return SLOT_NAMES[slotId] or L["Empty"]
end

local function draggableProxy(button, label)
    local vtable = nodes.proxyButton({ target = button, label = label })
    if vtable == nil then
        return nil
    end
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local script = button:GetScript("OnDragStart")
            if script ~= nil then
                script(button)
            end
        end,
    })
    return vtable
end

-- The slots in the order the frame draws them: the left column, the right
-- column, then the weapon row. The ammo slot only shows with a ranged
-- weapon, and hidden slots emit nothing.
local SLOT_BUTTONS = {
    "CharacterHeadSlot",
    "CharacterNeckSlot",
    "CharacterShoulderSlot",
    "CharacterBackSlot",
    "CharacterChestSlot",
    "CharacterShirtSlot",
    "CharacterTabardSlot",
    "CharacterWristSlot",
    "CharacterHandsSlot",
    "CharacterWaistSlot",
    "CharacterLegsSlot",
    "CharacterFeetSlot",
    "CharacterFinger0Slot",
    "CharacterFinger1Slot",
    "CharacterTrinket0Slot",
    "CharacterTrinket1Slot",
    "CharacterMainHandSlot",
    "CharacterSecondaryHandSlot",
    "CharacterRangedSlot",
    "CharacterAmmoSlot",
}

local function renderEquipment(builder)
    builder:beginStop("equipment")
    builder:pushContext("equipment", L["Equipment"])
    for _, name in ipairs(SLOT_BUTTONS) do
        local slot = _G[name]
        if slot ~= nil then
            local captured = slot
            builder:addItem(
                ControlId.forObject(captured),
                draggableProxy(captured, function()
                    return equipmentLabel(captured)
                end)
            )
        end
    end
    builder:addItem(
        ControlId.structural("level"),
        nodes.text({
            label = function()
                local level = fontText(CharacterLevelText) or ""
                local loyalty = shown(PetLoyaltyText) and fontText(PetLoyaltyText) or nil
                if loyalty ~= nil then
                    return level .. ", " .. loyalty
                end
                return level
            end,
        })
    )
    builder:popContext()
end

-- ---- character tab: stats ----

-- Blizzard computes a stat's text by writing into a stat frame, so a
-- private probe frame with the same Label and Value strings reproduces
-- the row text for elements that have no frame on screen.
local statProbe = nil
local function probe()
    if statProbe == nil then
        statProbe = CreateFrame("Frame", nil, UIParent)
        statProbe:Hide()
        statProbe.Label = statProbe:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        statProbe.Value = statProbe:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    end
    return statProbe
end

local function statText(data)
    if data.labelText ~= nil then
        return data.labelText .. " " .. tostring(data.valueText or "")
    end
    local info = PAPERDOLL_STATINFO ~= nil and data.name ~= nil and PAPERDOLL_STATINFO[data.name] or nil
    if info == nil or info.updateFunc == nil then
        return tostring(data.name or "")
    end
    local frame = probe()
    frame.Label:SetText("")
    frame.Value:SetText("")
    frame.tooltip = nil
    frame.tooltip2 = nil
    pcall(info.updateFunc, frame, data.unit, data.id)
    return (fontText(frame.Label) or tostring(data.name)) .. " " .. (fontText(frame.Value) or "")
end

-- The stats scroll box: category headers open a context each, so moving
-- into a category speaks its name once; the stats inside are read-only
-- rows carrying the game's tooltip.
local function renderStatsPane(builder, pane, key, label)
    if not shown(pane) or pane.ScrollBox == nil then
        return
    end
    builder:beginStop(key)
    builder:pushContext(key, label)
    local categoryOpen = false
    nodes.scrollBoxList(builder, {
        scrollBox = pane.ScrollBox,
        key = key,
        emit = function(builder, data, index, helpers)
            if type(data) ~= "table" then
                return
            end
            if data.isHeader then
                if categoryOpen then
                    builder:popContext()
                end
                builder:pushContext(key .. ":category:" .. index, tostring(data.name or ""))
                categoryOpen = true
                return
            end
            builder:addItem(
                helpers.id,
                listText(helpers, function()
                    return statText(data)
                end)
            )
        end,
    })
    if categoryOpen then
        builder:popContext()
    end
    builder:popContext()
end

-- ---- character tab: equipment sets ----

local function equipmentSetLabel(pane, data)
    local ids = pane.equipmentSetIDs
    local setID = ids ~= nil and type(data) == "table" and ids[data.index] or nil
    if setID == nil then
        return L["Empty"]
    end
    local name, _, _, isEquipped, _, _, _, numLost = C_EquipmentSet.GetEquipmentSetInfo(setID)
    local label = name or tostring(setID)
    if isEquipped then
        label = label .. ", " .. L["Equipped"]
    end
    if (numLost or 0) > 0 then
        label = label .. ", " .. string.format(L["%d items missing"], numLost)
    end
    return label
end

-- The new/edit set popup: a name box, the icon type filter, the icon
-- grid as a number (index into the filtered icons, with the selected
-- icon's texture kept in step), then Okay and Cancel. Blizzard focuses
-- the name box on show; the screen clears that so navigation keys work
-- and Enter on the box hands focus back.
local function renderGearSetPopup(builder, screen)
    local popup = GearManagerPopupFrame
    if not shown(popup) or popup.BorderBox == nil then
        return
    end
    local box = popup.BorderBox
    -- Blizzard focuses the name box on show; take the keyboard back once
    -- so navigation works (the box's own stop refocuses it on Enter).
    if not screen._tookFocus and box.IconSelectorEditBox ~= nil then
        screen._tookFocus = true
        box.IconSelectorEditBox:ClearFocus()
    end
    builder:pushContext("setPopup", EQUIPMENT_MANAGER or L["Equipment Sets"])
    if box.IconSelectorEditBox ~= nil then
        builder:beginStop("name")
        builder:addItem(
            ControlId.structural("setPopup:name"),
            nodes.proxyEditBox({
                editBox = box.IconSelectorEditBox,
                fixAutoFocus = true,
                label = function()
                    return fontText(box.EditBoxHeaderText) or L["Name"]
                end,
            })
        )
    end
    if shown(box.IconTypeDropdown) then
        builder:beginStop("iconType")
        builder:addItem(ControlId.forObject(box.IconTypeDropdown), nodes.proxyDropdown({ target = box.IconTypeDropdown }))
    end
    local selector = popup.IconSelector
    if selector ~= nil and selector.GetSelectedIndex ~= nil then
        builder:beginStop("icon")
        builder:addItem(
            ControlId.structural("setPopup:icon"),
            nodes.number({
                label = L["Icon"],
                get = function()
                    return selector:GetSelectedIndex() or 1
                end,
                set = function(value)
                    if type(value) ~= "number" then
                        error("not a number")
                    end
                    local count = selector:GetNumSelections() or 0
                    if count == 0 then
                        return
                    end
                    value = math.floor(value + 0.5)
                    if value < 1 then
                        value = 1
                    elseif value > count then
                        value = count
                    end
                    selector:SetSelectedIndex(value)
                    if selector.selectedCallback ~= nil then
                        selector.selectedCallback(value, selector:GetSelection(value))
                    end
                    if selector.ScrollToSelectedIndex ~= nil then
                        selector:ScrollToSelectedIndex()
                    end
                end,
                valueText = function()
                    return tostring(selector:GetSelectedIndex() or 0)
                        .. " "
                        .. L["of"]
                        .. " "
                        .. tostring(selector:GetNumSelections() or 0)
                end,
            })
        )
    end
    builder:beginStop("buttons")
    builder:startRow()
    for _, button in ipairs({ box.OkayButton, box.CancelButton }) do
        if shown(button) then
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end
    builder:endRow()
    builder:popContext()
end

-- The new/edit set dialog is its own window: it hangs off the character
-- frame as a separate popup and closes on its own, so it navigates as one.
module:registerWindow({
    type = "FrameWindow",
    name = "gearSetPopup",
    frameName = "GearManagerPopupFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderGearSetPopup },
})

local function selectedSet(pane)
    local setID = pane.selectedSetID
    if setID == nil then
        return nil
    end
    local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
    if name == nil then
        return nil
    end
    return setID, name
end

-- Equipment sets follow the selection-driven layout used elsewhere: the
-- set list is the first stop and New Set the second; selecting a set adds
-- a stop per action on it (Equip, Save, Edit, Delete). Edit and Delete
-- are hover-only buttons inside each row for the mouse, so here they are
-- plain buttons doing what those do.
local function renderEquipmentSets(builder, pane)
    if not shown(pane) or pane.ScrollBox == nil then
        return
    end
    builder:beginStop("equipmentSets")
    nodes.scrollBoxList(builder, {
        scrollBox = pane.ScrollBox,
        key = "equipmentSets",
        label = EQUIPMENT_MANAGER or L["Equipment Sets"],
        emit = function(builder, data, index, helpers)
            local ids = pane.equipmentSetIDs
            local setID = ids ~= nil and type(data) == "table" and ids[data.index] or nil
            builder:addItem(
                helpers.id,
                listRow(helpers, function()
                    return equipmentSetLabel(pane, data)
                end, {
                    selectedPart(function()
                        return setID ~= nil and pane.selectedSetID == setID
                    end),
                })
            )
        end,
    })

    if shown(pane.NewSet) then
        builder:beginStop("newSet")
        builder:addItem(ControlId.forObject(pane.NewSet), nodes.proxyButton({ target = pane.NewSet }))
    end

    local setID, setName = selectedSet(pane)
    if setID == nil then
        return
    end
    if shown(pane.EquipSet) then
        builder:beginStop("equipSet")
        builder:addItem(ControlId.forObject(pane.EquipSet), nodes.proxyButton({ target = pane.EquipSet }))
    end
    if shown(pane.SaveSet) then
        builder:beginStop("saveSet")
        builder:addItem(ControlId.forObject(pane.SaveSet), nodes.proxyButton({ target = pane.SaveSet }))
    end
    builder:beginStop("editSet")
    builder:addItem(
        ControlId.structural("equipmentSets:edit"),
        nodes.button({
            label = EQUIPMENT_SET_EDIT or L["Edit Set"],
            onActivate = function()
                local popup = GearManagerPopupFrame
                if popup == nil then
                    return
                end
                popup.mode = IconSelectorPopupFrameModes.Edit
                popup.setID = setID
                popup.origName = setName
                popup:Show()
            end,
        })
    )
    builder:beginStop("deleteSet")
    builder:addItem(
        ControlId.structural("equipmentSets:delete"),
        nodes.button({
            label = DELETE or L["Delete Set"],
            onActivate = function()
                StaticPopup_Show("CONFIRM_DELETE_EQUIPMENT_SET", setName, nil, setID)
            end,
        })
    )
end

-- ---- character tab: sidebar strip and pane toggle ----

local function renderSidebarTabs(builder)
    if not shown(PaperDollSidebarTabs) then
        return
    end
    builder:beginStop("sidebarTabs")
    builder:pushContext("sidebarTabs", L["Sidebar Tabs"])
    builder:startRow()
    local any = false
    for i = 1, #(PAPERDOLL_SIDEBARS or {}) do
        local tab = _G["PaperDollSidebarTab" .. i]
        local tabIndex = i
        if shown(tab) then
            local info = PAPERDOLL_SIDEBARS[i]
            local vtable = nodes.proxyButton({ target = tab, label = info ~= nil and info.name or nil })
            if vtable ~= nil then
                any = true
                tinsert(
                    vtable.announcements,
                    selectedPart(function()
                        return PaperDollFrame ~= nil and PaperDollFrame.selectedTab == tabIndex
                    end)
                )
                builder:addItem(ControlId.forObject(tab), vtable)
            end
        end
    end
    if not any then
        builder:addItem(ControlId.structural("sidebarTabs:empty"), nodes.text({ label = L["Empty"] }))
    end
    builder:endRow()
    builder:popContext()
end

local function renderPaneToggle(builder)
    local button = CharacterFrame.RightPaneToggleButton
    if not shown(button) then
        return
    end
    builder:beginStop("paneToggle")
    builder:addItem(
        ControlId.forObject(button),
        nodes.proxyButton({
            target = button,
            label = function()
                return button.tooltipText or L["Details"]
            end,
        })
    )
end

local function renderPaperDoll(builder)
    renderEquipment(builder)
    if CharacterFrame:IsRightPaneCollapsed() then
        renderPaneToggle(builder)
        return
    end
    renderStatsPane(builder, CharacterStatsPaneScrollBox, "stats", L["Stats"])
    renderEquipmentSets(builder, PaperDollFrame.EquipmentManagerPane)
    renderStatsPane(builder, CharacterStatsPanePetScrollBox, "petStats", L["Pet"])
    renderSidebarTabs(builder)
    renderPaneToggle(builder)
end

-- ---- reputation ----

local function reputationProgress(current, minimum, maximum)
    if current == nil or minimum == nil or maximum == nil then
        return nil
    end
    return tostring(current - minimum) .. " / " .. tostring(maximum - minimum)
end

-- Standing and progress the way the row's bar shows them.
local function reputationLabel(data)
    local name = tostring(data.name or "")
    if data.isHeader and not data.isHeaderWithRep then
        return name
    end
    local standing, progress = nil, nil
    local friendship = data.factionID ~= nil and C_GossipInfo.GetFriendshipReputation(data.factionID) or nil
    if friendship ~= nil and (friendship.friendshipFactionID or 0) > 0 then
        standing = friendship.reaction
        if friendship.nextThreshold ~= nil then
            progress = reputationProgress(friendship.standing, friendship.reactionThreshold, friendship.nextThreshold)
        end
    elseif C_Reputation.IsMajorFaction ~= nil and data.factionID ~= nil and C_Reputation.IsMajorFaction(data.factionID) then
        local major = C_MajorFactions.GetMajorFactionData(data.factionID)
        standing = string.format(RENOWN_LEVEL_LABEL or "%d", major ~= nil and major.renownLevel or 0)
        if major ~= nil and not C_MajorFactions.HasMaximumRenown(data.factionID) then
            progress = reputationProgress(major.renownReputationEarned, 0, major.renownLevelThreshold)
        end
    else
        standing = _G["FACTION_STANDING_LABEL" .. tostring(data.reaction or 0)]
        if data.reaction ~= MAX_REPUTATION_REACTION then
            progress = reputationProgress(data.currentStanding, data.currentReactionThreshold, data.nextReactionThreshold)
        end
    end
    local label = name
    if standing ~= nil then
        label = label .. " - " .. standing
    end
    if progress ~= nil then
        label = label .. " " .. progress
    end
    return label
end

local function renderReputation(builder)
    local frame = ReputationFrame
    if frame == nil or frame.ScrollBox == nil then
        return
    end
    if shown(frame.filterDropdown) then
        builder:beginStop("repFilter")
        builder:addItem(ControlId.forObject(frame.filterDropdown), nodes.proxyDropdown({ target = frame.filterDropdown }))
    end
    builder:beginStop("factions")
    nodes.scrollBoxList(builder, {
        scrollBox = frame.ScrollBox,
        key = "factions",
        label = L["Reputation"],
        button = collapseTarget,
        emit = function(builder, data, index, helpers)
            if type(data) ~= "table" then
                return
            end
            local parts = {}
            if data.isHeader then
                tinsert(
                    parts,
                    collapsedPart(function()
                        return data.isCollapsed
                    end)
                )
            end
            if not data.isHeader or data.isHeaderWithRep then
                tinsert(
                    parts,
                    selectedPart(function()
                        return C_Reputation.GetSelectedFaction() == data.factionIndex
                    end)
                )
            end
            builder:addItem(
                helpers.id,
                listRow(helpers, function()
                    return reputationLabel(data)
                end, parts)
            )
        end,
    })

    local detail = frame.ReputationDetailFrame
    if detail ~= nil then
        renderSidePane(builder, detail, "repDetail", {
            { target = detail.AtWarCheckbox, check = true, label = checkboxLabel(detail.AtWarCheckbox or {}) },
            {
                target = detail.MakeInactiveCheckbox,
                check = true,
                label = checkboxLabel(detail.MakeInactiveCheckbox or {}),
            },
            {
                target = detail.WatchFactionCheckbox,
                check = true,
                label = checkboxLabel(detail.WatchFactionCheckbox or {}),
            },
            { target = detail.ViewRenownButton },
        })
    end
end

-- ---- skills ----

local function skillLabel(data)
    local name = tostring(data.name or "")
    if data.isHeader then
        return name
    end
    local rank = data.rank or 0
    local modifier = data.modifier or 0
    local text = name .. " " .. tostring(rank)
    if modifier ~= 0 then
        text = text .. " (" .. (modifier > 0 and "+" or "") .. tostring(modifier) .. ")"
    end
    return text .. " / " .. tostring(data.maxRank or 0)
end

local function renderSkills(builder)
    local frame = SkillsFrame
    if frame == nil or frame.ScrollBox == nil then
        return
    end
    builder:beginStop("skills")
    nodes.scrollBoxList(builder, {
        scrollBox = frame.ScrollBox,
        key = "skills",
        label = L["Skills"],
        button = collapseTarget,
        emit = function(builder, data, index, helpers)
            if type(data) ~= "table" then
                return
            end
            local parts = {}
            if data.isHeader then
                tinsert(
                    parts,
                    collapsedPart(function()
                        return data.isCollapsed
                    end)
                )
            else
                tinsert(
                    parts,
                    selectedPart(function()
                        return C_SkillInfo.GetSelectedSkill() == data.skillIndex
                    end)
                )
            end
            builder:addItem(
                helpers.id,
                listRow(helpers, function()
                    return skillLabel(data)
                end, parts)
            )
        end,
    })
    renderSidePane(builder, frame.SkillDetailFrame, "skillDetail")
end

-- ---- PvP ----

local function renderPVP(builder)
    local frame = PVPRankFrame
    if frame == nil then
        return
    end
    builder:beginStop("pvp")
    builder:pushContext("pvp", PVP or L["PvP"])
    local info = frame.MainInfoFrame
    local fields = {
        { key = "season", fontString = frame.SeasonTimerField },
        { key = "currentSeason", fontString = info ~= nil and info.CurrentSeasonField or nil },
        { key = "rank", fontString = info ~= nil and info.CurrentRankField or nil },
        { key = "progress", fontString = info ~= nil and info.CurrentRankProgressField or nil },
    }
    for _, field in ipairs(fields) do
        if shown(field.fontString) then
            builder:addItem(
                ControlId.structural("pvp:" .. field.key),
                nodes.text({ label = nodes.frameText(field.fontString), live = "focus" })
            )
        end
    end
    local reward = info ~= nil and info.RankProgressBarDisplay ~= nil and info.RankProgressBarDisplay.NextRewardLevel or nil
    if shown(reward) then
        builder:addItem(
            ControlId.forObject(reward),
            nodes.proxyButton({ target = reward, label = PVP_RANK_NEXT_REWARD_BUTTON or L["Next Reward"] })
        )
    end
    builder:popContext()
    renderSidePane(builder, frame.DetailFrame, "pvpDetail")
end

-- ---- currency ----

local function currencyLabel(data)
    local name = tostring(data.name or "")
    if data.isHeader then
        return name
    end
    if data.quantity ~= nil then
        return name .. " " .. tostring(data.quantity)
    end
    return name
end

local function renderCurrency(builder)
    local frame = TokenFrame
    if frame == nil or frame.ScrollBox == nil then
        return
    end
    builder:beginStop("currency")
    nodes.scrollBoxList(builder, {
        scrollBox = frame.ScrollBox,
        key = "currency",
        label = CURRENCY or L["Currency"],
        button = collapseTarget,
        emit = function(builder, data, index, helpers)
            if type(data) ~= "table" then
                return
            end
            local parts = {}
            if data.isHeader then
                tinsert(
                    parts,
                    collapsedPart(function()
                        return not data.isHeaderExpanded
                    end)
                )
            else
                tinsert(
                    parts,
                    selectedPart(function()
                        return frame.selectedID ~= nil and frame.selectedID == data.currencyIndex
                    end)
                )
            end
            builder:addItem(
                helpers.id,
                listRow(helpers, function()
                    return currencyLabel(data)
                end, parts)
            )
        end,
    })
    local detail = frame.DetailFrame
    if detail ~= nil then
        renderSidePane(builder, detail, "currencyDetail", {
            { target = detail.InactiveCheckbox, check = true, label = checkboxLabel(detail.InactiveCheckbox or {}) },
            { target = detail.BackpackCheckbox, check = true, label = checkboxLabel(detail.BackpackCheckbox or {}) },
            { target = detail.CurrencyTransferToggleButton },
        })
    end
end

-- ---- statistics ----

local function statisticNodeData(node)
    if type(node) == "table" and node.GetData ~= nil then
        return node:GetData()
    end
    return node
end

-- The value straight from the game (the row data only holds Blizzard's
-- "--" for anything it could not read as a plain number, money included),
-- falling back to what the row shows.
local function statisticValue(data)
    local raw = nil
    if data.statID ~= nil and GetStatistic ~= nil then
        local ok, quantity = pcall(GetStatistic, data.statID)
        if ok then
            raw = quantity
        end
    end
    if raw == nil then
        raw = data.value
    end
    return WowVision.utils.statisticValueText(raw, C_CurrencyInfo.GetCoinText)
end

local function renderStatistics(builder)
    local frame = StatisticsFrame
    if frame == nil or frame.ScrollBox == nil then
        return
    end
    builder:beginStop("statistics")
    nodes.scrollBoxList(builder, {
        scrollBox = frame.ScrollBox,
        key = "statistics",
        label = STATISTICS or L["Statistics"],
        button = collapseTarget,
        emit = function(builder, node, index, helpers)
            local data = statisticNodeData(node)
            if type(data) ~= "table" then
                return
            end
            local parts = {}
            if data.isCategory and type(node) == "table" and node.IsCollapsed ~= nil then
                tinsert(
                    parts,
                    collapsedPart(function()
                        return node:IsCollapsed()
                    end)
                )
            elseif not data.isCategory then
                -- A statistic does nothing on click, so it is a text row:
                -- name, then its value, then the position.
                local row = listText(helpers, tostring(data.name or ""))
                tinsert(row.announcements, {
                    text = function()
                        return statisticValue(data)
                    end,
                    kind = kinds.value,
                    live = "focus",
                })
                builder:addItem(helpers.id, row)
                return
            end
            builder:addItem(
                helpers.id,
                listRow(helpers, tostring(data.name or ""), parts)
            )
        end,
    })
end

-- ---- the window ----

local TAB_NAMES = {
    function()
        return CHARACTER or L["Character"]
    end,
    function()
        return REPUTATION or L["Reputation"]
    end,
    function()
        return SKILLS or L["Skills"]
    end,
    function()
        return PVP or L["PvP"]
    end,
    function()
        return CURRENCY or L["Currency"]
    end,
    function()
        return STATISTICS or L["Statistics"]
    end,
}

-- The side tabs are plain frames with mouse scripts, not buttons, so a
-- secure click cannot reach them; the frame's own click handler runs
-- instead, exactly as its mouse-up script would call it.
local function renderTabs(builder)
    local tabs = CharacterFrame.ModeTabs ~= nil and CharacterFrame.ModeTabs.Tabs or nil
    if tabs == nil then
        return
    end
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    local any = false
    for index, tab in ipairs(tabs) do
        if shown(tab) then
            any = true
            local captured = tab
            local tabIndex = index
            local vtable = nodes.button({
                label = TAB_NAMES[index] or function()
                    return tostring(index)
                end,
                onActivate = function()
                    CharacterFrame:OnModeTabClicked(captured)
                end,
            })
            tinsert(
                vtable.announcements,
                selectedPart(function()
                    return CharacterFrame.selectedTab == tabIndex
                end)
            )
            vtable.tooltipFrame = captured
            builder:addItem(ControlId.forObject(captured), vtable)
        end
    end
    if not any then
        builder:addItem(ControlId.structural("tabs:empty"), nodes.text({ label = L["Empty"] }))
    end
    builder:endRow()
    builder:popContext()
end

local function render(builder, screen)
    local frame = CharacterFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("character", L["Character"])

    -- Body first: opening the panel lands on the tab's content, with the
    -- tabs a stop behind.
    local active = frame.activeSubframe
    if active == "PaperDollFrame" or active == nil then
        renderPaperDoll(builder)
    elseif active == "ReputationFrame" then
        renderReputation(builder)
    elseif active == "SkillsFrame" then
        renderSkills(builder)
    elseif active == "PVPRankFrame" then
        renderPVP(builder)
    elseif active == "TokenFrame" then
        renderCurrency(builder)
    elseif active == "StatisticsFrame" then
        renderStatistics(builder)
    end

    renderTabs(builder)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "character",
    frameName = "CharacterFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
