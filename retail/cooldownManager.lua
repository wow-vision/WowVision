local module = WowVision.base.windows:createModule("cooldownManager")
local L = module.L
module:setLabel(L["Cooldown Manager"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The cooldown manager settings window (/cdm, CooldownViewerSettings): where
-- the player decides which spells and auras the cooldown manager shows, in
-- which bar, in what order, and with which alerts.
--
-- Layout, in tab order:
--   1. The side tabs (Spells, Auras, Group Buffs) as a vertical list.
--   2. The search box, then the gear menu (Show Unlearned, reset, options).
--   3. The tab's content: on Spells and Auras a plain scroll frame of
--      collapsible categories, each a header button over a pool of item
--      frames; on Group Buffs the Shown and Hidden sections.
--   4. The layout dropdown and Revert Changes.
-- The alert editor beside the window is its own window (below).
--
-- Items are Frames, not Buttons, so secure clicks cannot reach them; their
-- OnMouseUp handlers run directly, as do the side tabs' custom mouse up
-- handlers. Enter picks an item up the way a left click does, and Enter on
-- another item drops it there through the same calls the mouse release
-- makes. Backspace opens the item's own context menu (alerts, moves).

local function speak(text)
    WowVision:speak(text)
end

-- TAINT. The on-screen cooldown viewers rebuild from the settings data every
-- time a layout changes (CooldownViewerSettings.OnDataChanged), and they
-- keep aura state in tables that refuse tainted access. A change made from
-- addon code -- a drop, a category move, anything picked in an item's menu
-- -- rebuilds them under WowVision's taint, and the next aura event in
-- combat fails ("attempted to index a table that cannot be accessed while
-- tainted"). Nothing launders that short of a reload: the layout itself is
-- saved to the client (C_CooldownViewer.SetLayoutData) and reads back clean.
-- So every such change is recorded, the first one says so, a Reload
-- Interface button joins the bottom row, and closing the window repeats the
-- reminder.
local changes = { made = false, announced = false }

local function markChanged()
    changes.made = true
    if not changes.announced then
        changes.announced = true
        speak(L["Changes made here apply after the interface reloads. A Reload Interface button is at the end of the window."])
    end
end

local function reloadInterface()
    if C_UI ~= nil and C_UI.Reload ~= nil then
        C_UI.Reload()
    else
        ReloadUI()
    end
end

-- Frames of a pool in screen order, top to bottom then left to right.
local function sortedByPosition(frames)
    table.sort(frames, function(a, b)
        local at, bt = a:GetTop(), b:GetTop()
        if at == nil or bt == nil then
            return false
        end
        if math.abs(at - bt) > 1 then
            return at > bt
        end
        return (a:GetLeft() or 0) < (b:GetLeft() or 0)
    end)
    return frames
end

local function activeFrames(pool)
    local frames = {}
    if pool ~= nil then
        for frame in pool:EnumerateActive() do
            tinsert(frames, frame)
        end
    end
    return frames
end

local function alertCountText(count)
    if count == 1 then
        return L["1 alert"]
    elseif count ~= nil and count > 1 then
        return format(L["%d alerts"], count)
    end
    return nil
end

local function stateText(parts)
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ", ")
end

-- Tabs -----------------------------------------------------------------

-- The side tabs switch on mouse up through a custom handler, not OnClick,
-- so a secure click cannot reach them; the handler's one call is made
-- directly. A greyed-out tab (Group Buffs with too few buffs) reads
-- Disabled and does nothing.
local function renderTabs(builder, frame)
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    for _, tab in ipairs(frame.TabButtons or {}) do
        if tab:IsShown() then
            local captured = tab
            builder:addItem(ControlId.structural("tab:" .. tostring(captured.displayMode)), {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return captured.normalTooltipText or captured.tooltipText
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            return frame.displayMode == captured.displayMode and L["selected"] or nil
                        end,
                        kind = kinds.selected,
                    },
                    {
                        text = function()
                            return captured.isTabDisabled and L["Disabled"] or nil
                        end,
                        kind = kinds.enabled,
                    },
                },
                onActivate = function()
                    if captured.isTabDisabled then
                        return
                    end
                    frame:SetDisplayMode(captured.displayMode)
                end,
            })
        end
    end
    builder:popContext()
end

-- Top bar --------------------------------------------------------------

-- The search box (an edit box cannot share a stop with anything after it)
-- and the gear dropdown.
local function renderTopBar(builder, frame)
    if frame.SearchBox ~= nil then
        builder:beginStop("search")
        builder:addItem(
            ControlId.structural("search"),
            nodes.proxyEditBox({ editBox = frame.SearchBox, label = L["Search"] })
        )
    end
    if frame.SettingsDropdown ~= nil then
        builder:beginStop("settingsMenu")
        builder:addItem(
            ControlId.forObject(frame.SettingsDropdown),
            nodes.proxyDropdown({ target = frame.SettingsDropdown, label = L["Settings"] })
        )
    end
end

-- Spell and aura items -------------------------------------------------

local function itemKey(item)
    if item:IsEmptyCategory() then
        local category = item:GetEmptyCategory()
        return "empty:" .. tostring(category and category:GetCategory())
    end
    return "item:" .. tostring(item:GetCooldownID())
end

local function itemAlertCount(frame, item)
    local manager = frame:GetLayoutManager()
    if manager == nil or item:IsEmptyCategory() then
        return 0
    end
    local ok, count = pcall(manager.GetNumAlerts, manager, item:GetCooldownID(), Enum.CDMLayoutMode.AccessOnly)
    return ok and count or 0
end

local function cancelPickup(frame)
    frame:CancelOrderChange()
    speak(L["Pickup cancelled"])
end

-- Enter: pick the item up, or drop the picked-up item here. A drop on
-- another item lands after it when moving forward and before it when
-- moving back (the mouse decides by cursor side); a drop on a category's
-- empty slot moves the item into that category. Enter on the picked-up
-- item itself cancels.
local function activateItem(frame, item)
    if frame:IsReordering() then
        local source = frame:GetReorderSourceItem()
        if source == item then
            cancelPickup(frame)
            return
        end
        frame:SetReorderTarget(item)
        frame:SetReorderTargetItem(item)
        local after = not item:IsEmptyCategory() and item:GetOrderIndex() > source:GetOrderIndex()
        frame.reorderOffset = after and 1 or 0
        frame:EndOrderChange()
        speak(L["Moved"])
        markChanged()
        return
    end
    if item:IsEmptyCategory() then
        return
    end
    local script = item:GetScript("OnMouseUp")
    if script ~= nil then
        script(item, "LeftButton", true)
        speak(L["Picked up"])
    end
end

-- Backspace: the item's context menu (its alerts, Add New Alert, Move to
-- another category), or cancel a pickup in progress, as a right click does.
local function secondaryItem(frame, item)
    if frame:IsReordering() then
        cancelPickup(frame)
        return
    end
    if item:IsEmptyCategory() then
        return
    end
    if item.DisplayContextMenu ~= nil then
        -- The menu's picks (alerts, moves) all write layout data.
        markChanged()
        item:DisplayContextMenu()
    end
end

local function itemNode(frame, item, scrollFrame)
    local vtable = {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    if item:IsEmptyCategory() then
                        return L["Empty"]
                    end
                    return item:GetNameText()
                end,
                kind = kinds.label,
                live = "focus",
            },
            {
                text = function()
                    if item:IsEmptyCategory() then
                        return nil
                    end
                    local parts = {}
                    if not item:IsKnown() then
                        tinsert(parts, L["Unlearned"])
                    end
                    local alerts = alertCountText(itemAlertCount(frame, item))
                    if alerts ~= nil then
                        tinsert(parts, alerts)
                    end
                    if frame:IsReordering() and frame:GetReorderSourceItem() == item then
                        tinsert(parts, L["Picked up"])
                    end
                    return stateText(parts)
                end,
                kind = kinds.value,
                live = "focus",
            },
        },
        onActivate = function()
            activateItem(frame, item)
        end,
        onSecondary = function()
            secondaryItem(frame, item)
        end,
    }
    if not item:IsEmptyCategory() and item.RefreshTooltipInternal ~= nil then
        -- The item's own hover script writes spell load state onto the
        -- frame; the tooltip is filled by the same routine without it.
        vtable.tooltipFrame = item
        vtable.tooltip = {
            type = "Game",
            mode = "immediate",
            populate = function()
                item:RefreshTooltipInternal()
            end,
        }
    end
    nodes.attachScrollFrame(vtable, scrollFrame, item)
    return vtable
end

-- A category: its header (a real button; a click folds and unfolds it),
-- then its items while expanded, in order.
local function renderCategory(builder, frame, category, scrollFrame)
    local categoryObject = category:GetCategoryObject()
    local key = tostring(categoryObject and categoryObject:GetCategory())
    local header = nodes.proxyButton({
        target = category.Header,
        label = function()
            return categoryObject and categoryObject:GetTitle() or nil
        end,
    })
    if header == nil then
        return
    end
    tinsert(header.announcements, {
        text = function()
            return category:IsCollapsed() and L["Collapsed"] or L["Expanded"]
        end,
        kind = kinds.value,
        live = "focus",
    })
    nodes.attachScrollFrame(header, scrollFrame, category.Header)
    builder:addItem(ControlId.structural("category:" .. key), header)

    if category:IsCollapsed() then
        return
    end
    local items = activeFrames(category.itemPool)
    table.sort(items, function(a, b)
        return (a:GetOrderIndex() or 0) < (b:GetOrderIndex() or 0)
    end)
    builder:pushContext("category:" .. key, categoryObject and categoryObject:GetTitle() or key)
    for _, item in ipairs(items) do
        builder:addItem(ControlId.structural(itemKey(item)), itemNode(frame, item, scrollFrame))
    end
    builder:popContext()
end

local function renderCategories(builder, frame)
    local categories = sortedByPosition(activeFrames(frame.categoryPool))
    if #categories == 0 then
        return
    end
    builder:beginStop("content")
    for _, category in ipairs(categories) do
        renderCategory(builder, frame, category, frame.CooldownScroll)
    end
end

-- Group buffs ------------------------------------------------------------

-- Enter picks a group buff up or drops it: a drop in the other section
-- moves it there (the mouse decides by which section it is over); a drop
-- in the same section, or on the picked-up buff, just puts it down.
local function activateGroupBuff(filter, item)
    local source = filter.dragItem
    if source ~= nil then
        local target = item:GetSection()
        if source ~= item and target ~= source:GetSection() then
            filter:MoveGroupBuffItem(source:GetGroupBuffItem(), source:GetSection(), target)
            filter:CancelGroupBuffItemDrag()
            speak(L["Moved"])
            markChanged()
        else
            filter:CancelGroupBuffItemDrag()
            speak(L["Pickup cancelled"])
        end
        return
    end
    local script = item:GetScript("OnMouseUp")
    if script ~= nil then
        script(item, "LeftButton", true)
        speak(L["Picked up"])
    end
end

local function secondaryGroupBuff(filter, item)
    if filter.dragItem ~= nil then
        filter:CancelGroupBuffItemDrag()
        speak(L["Pickup cancelled"])
        return
    end
    markChanged()
    filter:DisplayContextMenu(item)
end

local function groupBuffNode(filter, item, scrollFrame)
    local vtable = {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    local info = item:GetGroupBuffItem()
                    return info and info.name or nil
                end,
                kind = kinds.label,
                live = "focus",
            },
            {
                text = function()
                    local parts = {}
                    local info = item:GetGroupBuffItem()
                    if info ~= nil and not info.isKnown then
                        tinsert(parts, L["Unlearned"])
                    end
                    if item:GetVisualAlert() ~= nil then
                        tinsert(parts, L["1 alert"])
                    end
                    if filter.dragItem == item then
                        tinsert(parts, L["Picked up"])
                    end
                    return stateText(parts)
                end,
                kind = kinds.value,
                live = "focus",
            },
        },
        onActivate = function()
            activateGroupBuff(filter, item)
        end,
        onSecondary = function()
            secondaryGroupBuff(filter, item)
        end,
        tooltipFrame = item,
        tooltip = {
            type = "Game",
            mode = "immediate",
            populate = function(tooltip)
                local info = item:GetGroupBuffItem()
                if info ~= nil then
                    tooltip:SetSpellByID(info.spellID)
                end
            end,
        },
    }
    nodes.attachScrollFrame(vtable, scrollFrame, item)
    return vtable
end

local function renderGroupBuffSection(builder, filter, section, key)
    if section == nil then
        return
    end
    local title = nodes.frameText(section.Header)
    local header = nodes.proxyButton({ target = section.Header, label = title })
    if header == nil then
        return
    end
    tinsert(header.announcements, {
        text = function()
            return section.isCollapsed and L["Collapsed"] or L["Expanded"]
        end,
        kind = kinds.value,
        live = "focus",
    })
    nodes.attachScrollFrame(header, filter.Scroll, section.Header)
    builder:addItem(ControlId.structural("groupBuffs:" .. key), header)
    if section.isCollapsed then
        return
    end
    local items = sortedByPosition(activeFrames(section.itemPool))
    builder:pushContext("groupBuffs:" .. key, title)
    for _, item in ipairs(items) do
        local info = item:GetGroupBuffItem()
        builder:addItem(
            ControlId.structural("groupBuff:" .. tostring(info and info.spellID)),
            groupBuffNode(filter, item, filter.Scroll)
        )
    end
    builder:popContext()
end

local function renderGroupBuffs(builder, frame)
    local filter = frame.GroupBuffFilter
    if filter == nil or not filter:IsShown() then
        return
    end
    builder:beginStop("content")
    renderGroupBuffSection(builder, filter, filter.shownSection, "shown")
    renderGroupBuffSection(builder, filter, filter.hiddenSection, "hidden")
end

-- Bottom bar -------------------------------------------------------------

local function renderBottomBar(builder, frame)
    builder:beginStop("layout")
    builder:startRow()
    if frame.LayoutDropdown ~= nil then
        local current = nodes.frameText(frame.LayoutDropdown)
        builder:addItem(
            ControlId.forObject(frame.LayoutDropdown),
            nodes.proxyDropdown({
                target = frame.LayoutDropdown,
                label = function()
                    return nodes.joinLabel(L["Layout"], current())
                end,
            })
        )
    end
    if frame.UndoButton ~= nil then
        -- The button's text carries an icon markup; the bare string reads
        -- clean.
        builder:addItem(
            ControlId.forObject(frame.UndoButton),
            nodes.proxyButton({
                target = frame.UndoButton,
                label = COOLDOWN_VIEWER_SETTINGS_BUTTON_REVERT_CHANGES,
            })
        )
    end
    if changes.made then
        builder:addItem(
            ControlId.structural("reload"),
            nodes.button({ label = L["Reload Interface"], onActivate = reloadInterface })
        )
    end
    builder:endRow()
end

local function render(builder, screen)
    local frame = CooldownViewerSettings
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("cooldownManager", L["Cooldown Manager"])
    renderTabs(builder, frame)
    renderTopBar(builder, frame)
    if frame.displayMode == "groupBuffs" then
        renderGroupBuffs(builder, frame)
    else
        renderCategories(builder, frame)
    end
    renderBottomBar(builder, frame)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "cooldownManager",
    frameName = "CooldownViewerSettings",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})

-- Closing the window with keyboard changes behind it repeats the reminder.
function module:onFullEnable()
    local frame = CooldownViewerSettings
    if frame == nil or self._hideHooked then
        return
    end
    self._hideHooked = true
    frame:HookScript("OnHide", function()
        if changes.made then
            speak(L["Cooldown manager changes apply after you reload the interface. Type /reload when ready."])
        end
    end)
end

-- Alert editor ---------------------------------------------------------

-- The alert editor opens beside the window for Add New Alert and for
-- editing an existing alert: the spell, then one dropdown per choice
-- (type, event, sound or visual for cooldowns; the visual for a group
-- buff), then the Add or Edit button. Each dropdown is labelled by the
-- heading the game draws over it.
local function renderAlertEditor(editor, dropdowns)
    return function(builder, screen)
        if editor == nil or not editor:IsShown() then
            return
        end
        builder:pushContext("alertEditor", L["Alert Editor"])
        builder:beginStop("alertSubject")
        builder:addItem(
            ControlId.structural("alertSubject"),
            nodes.text({
                label = function()
                    return nodes.joinLabel(nodes.frameText(editor.Title)(), nodes.frameText(editor.Name)())
                end,
            })
        )
        for _, entry in ipairs(dropdowns) do
            local dropdown = editor[entry.dropdown]
            local heading = editor[entry.label]
            if dropdown ~= nil and dropdown:IsShown() then
                builder:beginStop(entry.dropdown)
                local current = nodes.frameText(dropdown)
                local headingText = heading ~= nil and nodes.frameText(heading) or function()
                    return nil
                end
                builder:addItem(
                    ControlId.forObject(dropdown),
                    nodes.proxyDropdown({
                        target = dropdown,
                        label = function()
                            return nodes.joinLabel(headingText(), current())
                        end,
                    })
                )
            end
        end
        builder:beginStop("alertButtons")
        builder:startRow()
        builder:addItem(ControlId.forObject(editor.AddButton), nodes.proxyButton({ target = editor.AddButton }))
        builder:addItem(
            ControlId.forObject(editor.CloseButton),
            nodes.proxyButton({ target = editor.CloseButton, label = L["Close"] })
        )
        builder:endRow()
        builder:popContext()
    end
end

module:registerWindow({
    type = "FrameWindow",
    name = "cooldownAlertEditor",
    frameName = "CooldownViewerSettingsEditAlert",
    conflictingAddons = { "Sku" },
    graphScreen = {
        render = function(builder, screen)
            return renderAlertEditor(CooldownViewerSettingsEditAlert, {
                { dropdown = "TypeDropdown", label = "PrimaryLabel" },
                { dropdown = "EventDropdown", label = "EventLabel" },
                { dropdown = "PayloadDropdown", label = "PayloadLabel" },
            })(builder, screen)
        end,
    },
})

module:registerWindow({
    type = "FrameWindow",
    name = "groupBuffAlertEditor",
    frameName = "GroupBuffFilterEditVisualAlert",
    conflictingAddons = { "Sku" },
    graphScreen = {
        render = function(builder, screen)
            return renderAlertEditor(GroupBuffFilterEditVisualAlert, {
                { dropdown = "VisualDropdown", label = "PrimaryLabel" },
            })(builder, screen)
        end,
    },
})
