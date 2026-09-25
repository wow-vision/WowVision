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

-- A spell's identity: its action (spell, flyout, or pet action id). Not the
-- slot index: learning a spell shifts every slot after it.
local function spellKey(item)
    return "spell:" .. tostring(item.spellBank) .. ":" .. tostring(item.spellBookItemInfo.actionID)
end

-- The item frame currently showing this spell, or nil. Item frames are
-- pooled: a page rebuild (spells changed, a filter toggled) hands the spell
-- to a different frame. Runs every tick for the focused row, so it compares
-- fields instead of building keys.
local function findItem(book, bank, actionID)
    for _, frame in book.PagedSpellsFrame:EnumerateFrames() do
        if
            frame.HasValidData ~= nil
            and frame.spellBank == bank
            and frame:IsShown()
            and frame:HasValidData()
            and frame.spellBookItemInfo.actionID == actionID
        then
            return frame
        end
    end
    return nil
end

-- A spell row over the item's icon button: left casts (or opens a flyout),
-- right toggles pet autocast, drag picks the spell up. The item's own
-- OnEnter rewrites action bar highlight marks and updates the pet bar, so
-- the tooltip is filled straight from the spellbook slot instead.
local function spellNode(book, bank, actionID)
    local function findButton()
        local item = findItem(book, bank, actionID)
        return item ~= nil and item.Button or nil
    end
    return nodes.proxyFoundButton({
        find = findButton,
        label = function(button)
            local item = button:GetParent()
            return nodes.joinLabel(
                nodes.shownText(item.Name),
                nodes.shownText(item.SubName),
                nodes.shownText(item.RequiredLevel)
            )
        end,
        tooltip = function(tooltip, button)
            local item = button:GetParent()
            tooltip:SetSpellBookItem(item.slotIndex, item.spellBank)
        end,
        drag = nodes.pickupAction(function()
            local item = findItem(book, bank, actionID)
            if item ~= nil then
                C_SpellBook.PickupSpellBookItem(item.slotIndex, item.spellBank)
            end
        end, true),
    })
end

-- Category tabs (TabSystem buttons): real clicks. The selected tab is
-- disabled by the tab system, so it reads as selected rather than disabled.
-- The tab system releases and re-acquires its pooled tabs on every spell
-- data refresh (SPELLS_CHANGED while open), so a tab is found by name.
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
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for _, tab in ipairs(tabSystem.tabs) do
        local name = tabName(tab)
        if tab:IsShown() and name ~= nil then
            builder:addItem(
                ControlId.structural("tab:" .. name),
                nodes.proxyFoundButton({
                    find = function()
                        return findTab(tabSystem, name)
                    end,
                    label = tabName,
                    selected = function()
                        local current = findTab(tabSystem, name)
                        return current ~= nil and current.isSelected
                    end,
                    rightClick = false,
                })
            )
        end
    end
    builder:endRow()
    builder:popContext()
end

-- The current page: headers become contexts over the spells that follow
-- them (both page halves, in display order). Pooled frames carry stale
-- data while released, so only frames holding valid data are read.
local function renderSpells(builder, book)
    builder:beginStop("spells")
    builder:pushContext("spells", L["Spells"])
    local inHeader = false
    local emitted = 0
    for _, frame in book.PagedSpellsFrame:EnumerateFrames() do
        if frame:IsShown() then
            if frame.HasValidData ~= nil then
                if frame:HasValidData() then
                    builder:addItem(
                        ControlId.structural(spellKey(frame)),
                        spellNode(book, frame.spellBank, frame.spellBookItemInfo.actionID)
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

local function renderSpellBook(builder, book)
    renderCategoryTabs(builder, book)

    builder:beginStop("search")
    -- No clear button stop, like the other search boxes: emptying the box and
    -- pressing Enter leaves search results the same way.
    builder:addItem(ControlId.structural("search"), nodes.proxyEditBox({ editBox = book.SearchBox, label = L["Search"] }))

    builder:beginStop("options")
    builder:addItem(
        ControlId.forObject(book.SettingsDropdown),
        nodes.proxyDropdown({ target = book.SettingsDropdown, label = L["Options"] })
    )

    renderSpells(builder, book)
    nodes.pagingRow(builder, "spells", book.PagedSpellsFrame.PagingControls)
end

local function render(builder, screen)
    local frame = PlayerSpellsFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("spellbook", L["Spellbook"])
    local book = frame.SpellBookFrame
    if book:IsShown() then
        renderSpellBook(builder, book)
    else
        builder:beginStop("unimplemented")
        builder:addItem(ControlId.structural("unimplemented"), nodes.text({ label = L["Not implemented yet"] }))
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
-- the frame itself. The flyout is a secure frame: it cannot be hidden in
-- combat, and its buttons' OnEnter writes their tooltip refresh field, so
-- the tooltip is filled directly.
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
                    hover = false,
                    label = function()
                        return C_Spell.GetSpellName(captured.spellID)
                    end,
                    tooltip = {
                        type = "Game",
                        mode = "immediate",
                        populate = function(tooltip)
                            tooltip:SetSpellByID(captured.spellID)
                        end,
                    },
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
            if not InCombatLockdown() then
                SpellFlyout:Hide()
            end
        end,
    },
})
