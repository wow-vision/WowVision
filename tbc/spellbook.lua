local module = WowVision.base.windows:createModule("spellbook")
local L = module.L
module:setLabel(L["Spellbook"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC spellbook: bottom tabs, side skill-line tabs, the spell page
-- (SpellButton1-12, sorted top-to-bottom then left-to-right, live labels
-- since page flips rebind the buttons), page navigation, the show-all-ranks
-- checkbox, and close.

local function getSpellButtons()
    local buttons = {}
    for i = 1, 12 do
        local button = _G["SpellButton" .. i]
        if button and button:IsShown() and button:IsEnabled() then
            tinsert(buttons, button)
        end
    end
    -- Sort top to bottom, left to right
    table.sort(buttons, function(a, b)
        local aTop, bTop = a:GetTop() or 0, b:GetTop() or 0
        local aLeft, bLeft = a:GetLeft() or 0, b:GetLeft() or 0
        if math.abs(aTop - bTop) > 5 then
            return aTop > bTop
        end
        return aLeft < bLeft
    end)
    return buttons
end

local function getSpellLabel(button)
    local name = button.SpellName and button.SpellName:GetText() or ""
    local subName = button.SpellSubName and button.SpellSubName:GetText() or ""
    if subName ~= "" then
        return name .. " " .. subName
    end
    return name
end

local function render(builder, screen)
    if SpellBookFrame == nil or not SpellBookFrame:IsShown() then
        return
    end
    builder:pushContext("spellbook", L["Spellbook"])

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, 3 do
        local tab = _G["SpellBookFrameTabButton" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        if PanelTemplates_GetSelectedTab(SpellBookFrame) == tabIndex then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                })
                builder:addItem(ControlId.forObject(tab), vtable)
            end
        end
    end
    builder:endRow()
    builder:popContext()

    if SpellBookSideTabsFrame ~= nil and SpellBookSideTabsFrame:IsShown() then
        builder:beginStop("sideTabs")
        builder:pushContext("sideTabs", L["Side Tabs"])
        builder:startRow()
        for i = 1, 8 do
            local tab = _G["SpellBookSkillLineTab" .. i]
            if tab ~= nil and tab:IsShown() then
                local captured = tab
                builder:addItem(
                    ControlId.forObject(captured),
                    nodes.proxyCheckButton({
                        target = captured,
                        label = function()
                            return captured.tooltip
                        end,
                    })
                )
            end
        end
        builder:endRow()
        builder:popContext()
    end

    builder:beginStop("spells")
    builder:pushContext("spells", L["Spells"])
    local emitted = 0
    for _, button in ipairs(getSpellButtons()) do
        local captured = button
        local vtable = nodes.proxyButton({
            target = captured,
            label = function()
                return getSpellLabel(captured)
            end,
        })
        if vtable ~= nil then
            tinsert(vtable.bindings, {
                binding = "drag",
                type = "Function",
                func = function()
                    local script = captured:GetScript("OnDragStart")
                    if script ~= nil then
                        script(captured)
                    end
                end,
            })
            builder:addItem(ControlId.forObject(captured), vtable)
            emitted = emitted + 1
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("spellsEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    if SpellBookPrevPageButton ~= nil and SpellBookPrevPageButton:IsShown() then
        builder:beginStop("prevPage")
        builder:addItem(
            ControlId.forObject(SpellBookPrevPageButton),
            nodes.proxyButton({ target = SpellBookPrevPageButton, label = L["Previous Page"] })
        )
    end
    if SpellBookNextPageButton ~= nil and SpellBookNextPageButton:IsShown() then
        builder:beginStop("nextPage")
        builder:addItem(
            ControlId.forObject(SpellBookNextPageButton),
            nodes.proxyButton({ target = SpellBookNextPageButton, label = L["Next Page"] })
        )
    end

    if ShowAllSpellRanksCheckbox ~= nil and ShowAllSpellRanksCheckbox:IsShown() then
        builder:beginStop("showAllRanks")
        builder:addItem(
            ControlId.forObject(ShowAllSpellRanksCheckbox),
            nodes.proxyCheckButton({
                target = ShowAllSpellRanksCheckbox,
                label = function()
                    return ShowAllSpellRanksCheckboxText ~= nil and ShowAllSpellRanksCheckboxText:GetText() or nil
                end,
            })
        )
    end

    if SpellBookCloseButton ~= nil then
        builder:beginStop("close")
        builder:addItem(
            ControlId.forObject(SpellBookCloseButton),
            nodes.proxyButton({ target = SpellBookCloseButton, label = CLOSE or L["Close"] })
        )
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "spellbook",
    frameName = "SpellBookFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
