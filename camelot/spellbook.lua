local module = WowVision.base.windows:createModule("spellbook")
local L = module.L
module:setLabel(L["Spellbook"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The WoW: Forever spellbook. Forever runs the modern PlayerSpellsFrame
-- (the retail spellbook, restyled), not the classic SpellBookFrame the
-- Mists module reads: named category tabs (class, general, pet), a search
-- box, an options menu, and a paged grid of spells built from frame pools.
-- The screen mirrors the current page: category tabs, search, options, the
-- page's spells grouped under their headers, then the page controls.
-- PlayerSpellsFrame also hosts the talent tree, which is not covered yet.

-- A spell row's label: name, subtext (rank, passive), and the unlearned
-- note (available at level N, trainable) when the frame shows one.
local function spellLabel(item)
    local parts = {}
    for _, fontString in ipairs({ item.Name, item.SubName, item.RequiredLevel }) do
        if fontString ~= nil and fontString:IsShown() then
            local text = fontString:GetText()
            if text ~= nil and text ~= "" then
                tinsert(parts, text)
            end
        end
    end
    return table.concat(parts, ", ")
end

-- A spell's identity: its bank and action (spell, flyout, or pet action
-- id). Not the slot index: learning a spell shifts every slot after it.
local function spellAction(item)
    local info = item.spellBookItemInfo
    return info ~= nil and info.actionID or item.slotIndex
end

local function spellKey(item)
    return "spell:" .. tostring(item.spellBank) .. ":" .. tostring(spellAction(item))
end

-- The item frame currently showing the spell with this key, or nil. Item
-- frames are pooled: a page rebuild (spells changed, a filter toggled)
-- hands the spell to a different frame, so clicks resolve the frame at
-- press time, and the host re-engages when the resolution drifts.
-- Runs every tick for the focused row (live label, click drift check), so
-- it compares fields instead of building keys.
local function findItem(book, bank, action)
    for _, frame in book.PagedSpellsFrame:EnumerateFrames() do
        if
            frame.HasValidData ~= nil
            and frame.spellBank == bank
            and frame:IsShown()
            and frame:HasValidData()
            and spellAction(frame) == action
        then
            return frame
        end
    end
    return nil
end

-- A spell row over the item's icon button: real clicks cast (left), toggle
-- pet autocast (right), or open a flyout. No hover scripts: the item's
-- OnEnter rewrites action bar highlight marks and updates the pet bar, and
-- run as the addon that taints the bars in combat. The tooltip is filled
-- straight from the spellbook slot instead.
local function spellNode(book, bank, action)
    local function target()
        local item = findItem(book, bank, action)
        return item ~= nil and item.Button or nil
    end
    return {
        controlType = graph.controlTypes.button,
        contextActions = nodes.proxyContextActions(target),
        announcements = {
            {
                text = function()
                    local item = findItem(book, bank, action)
                    return item ~= nil and spellLabel(item) or nil
                end,
                kind = kinds.label,
            },
        },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = target },
            {
                binding = "drag",
                type = "Function",
                func = function()
                    local button = target()
                    local script = button ~= nil and button:GetScript("OnDragStart") or nil
                    if script ~= nil then
                        script(button)
                    end
                end,
            },
        },
        -- The reader anchors the tooltip to this frame; without one it
        -- reads nothing.
        tooltipFrame = target,
        tooltip = {
            type = "Game",
            mode = "immediate",
            populate = function(tooltip)
                local item = findItem(book, bank, action)
                if item ~= nil then
                    tooltip:SetSpellBookItem(item.slotIndex, item.spellBank)
                end
            end,
        },
    }
end

-- Category tabs (TabSystem buttons): real clicks. The selected tab is
-- disabled by the tab system, so it reads as selected rather than disabled.
-- The tab system releases and re-acquires its pooled tabs on every spell
-- data refresh (SPELLS_CHANGED while open), so a tab is found by name at
-- press time and keyed by name.
local function tabName(tab)
    return tab.tabText or tab.tooltipText
end

local function findTab(tabSystem, name)
    for _, tab in ipairs(tabSystem.tabs) do
        if tab:IsShown() and tabName(tab) == name then
            return tab
        end
    end
    return nil
end

local function renderCategoryTabs(builder, book)
    local tabSystem = book.CategoryTabSystem
    if tabSystem == nil or tabSystem.tabs == nil then
        return
    end
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for _, tab in ipairs(tabSystem.tabs) do
        local name = tabName(tab)
        if tab:IsShown() and name ~= nil then
            local function target()
                return findTab(tabSystem, name)
            end
            builder:addItem(ControlId.structural("tab:" .. name), {
                controlType = graph.controlTypes.button,
                announcements = {
                    { text = name, kind = kinds.label },
                    {
                        text = function()
                            local current = target()
                            if current ~= nil and current.isSelected then
                                return L["selected"]
                            end
                            return nil
                        end,
                        kind = kinds.selected,
                    },
                },
                bindings = {
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = target },
                },
            })
        end
    end
    builder:endRow()
    builder:popContext()
end

-- The current page: headers become contexts over the spells that follow
-- them (both page halves, in display order). Pooled frames carry stale
-- data while released, so only frames holding valid data are read.
local function renderSpells(builder, book)
    local paged = book.PagedSpellsFrame
    if paged == nil then
        return
    end
    builder:beginStop("spells")
    builder:pushContext("spells", L["Spells"])
    local inHeader = false
    local emitted = 0
    for _, frame in paged:EnumerateFrames() do
        if frame:IsShown() then
            if frame.HasValidData ~= nil then
                if frame:HasValidData() and frame.Button ~= nil then
                    builder:addItem(
                        ControlId.structural(spellKey(frame)),
                        spellNode(book, frame.spellBank, spellAction(frame))
                    )
                    emitted = emitted + 1
                end
            elseif frame.Text ~= nil then
                if inHeader then
                    builder:popContext()
                end
                local text = frame.Text:GetText() or ""
                builder:pushContext("header:" .. text, text)
                inHeader = true
            end
        end
    end
    if inHeader then
        builder:popContext()
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("spellsEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()
end

-- Previous page, the page text ("Page 1/3"), next page, as one row.
local function renderPaging(builder, book)
    local controls = book.PagedSpellsFrame ~= nil and book.PagedSpellsFrame.PagingControls or nil
    if controls == nil or not controls:IsShown() then
        return
    end
    builder:beginStop("paging")
    builder:startRow()
    builder:addItem(
        ControlId.forObject(controls.PrevPageButton),
        nodes.proxyButton({ target = controls.PrevPageButton, label = L["Previous Page"] })
    )
    if controls.PageText ~= nil then
        builder:addItem(
            ControlId.structural("pageText"),
            nodes.text({
                label = function()
                    return controls.PageText:GetText() or ""
                end,
            })
        )
    end
    builder:addItem(
        ControlId.forObject(controls.NextPageButton),
        nodes.proxyButton({ target = controls.NextPageButton, label = L["Next Page"] })
    )
    builder:endRow()
end

local function renderSpellBook(builder, book)
    renderCategoryTabs(builder, book)

    if book.SearchBox ~= nil then
        builder:beginStop("search")
        -- No clear button stop, like the other search boxes: emptying the
        -- box and pressing Enter leaves search results the same way.
        builder:addItem(ControlId.structural("search"), nodes.proxyEditBox({ editBox = book.SearchBox, label = L["Search"] }))
    end

    if book.SettingsDropdown ~= nil then
        builder:beginStop("options")
        builder:addItem(
            ControlId.forObject(book.SettingsDropdown),
            nodes.proxyDropdown({ target = book.SettingsDropdown, label = L["Options"] })
        )
    end

    renderSpells(builder, book)
    renderPaging(builder, book)
end

local function render(builder, screen)
    local frame = PlayerSpellsFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("spellbook", L["Spellbook"])
    local book = frame.SpellBookFrame
    if book ~= nil and book:IsShown() then
        renderSpellBook(builder, book)
    else
        builder:beginStop("unimplemented")
        builder:addItem(ControlId.structural("unimplemented"), nodes.text({ label = "Not implemented yet" }))
    end
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "spellbook",
    frameName = "PlayerSpellsFrame",
    graphScreen = { render = render },
})

-- The spell flyout (action bar and spellbook flyout arrows). Not a UIPanel:
-- the game will not close it on Escape, so the screen holds close and hides
-- the frame itself.
local function renderFlyout(builder, screen)
    if SpellFlyout == nil or not SpellFlyout:IsShown() then
        return
    end
    builder:pushContext("flyout", L["Spell Flyout"])
    builder:beginStop("spells")
    for _, button in ipairs({ SpellFlyout:GetChildren() }) do
        if button:IsVisible() and button.spellID ~= nil then
            local captured = button
            builder:addItem(
                ControlId.forObject(captured),
                nodes.proxyButton({
                    target = captured,
                    label = function()
                        return C_Spell.GetSpellName(captured.spellID)
                    end,
                })
            )
        end
    end
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "SpellFlyout",
    frameName = "SpellFlyout",
    graphScreen = {
        render = renderFlyout,
        captureClose = true,
        onRequestClose = function()
            SpellFlyout:Hide()
        end,
    },
})
