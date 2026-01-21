local module = WowVision.base.windows:createModule("spellbook")
local L = module.L
module:setLabel(L["Spellbook"])

local gen = module:hasUI()

WowVision.tbc = WowVision.tbc or {}
WowVision.tbc.spellbook = {
    module = module,
    gen = gen,
    L = L,
}

gen:Element("spellbook", function(props)
    local result = {
        "Panel",
        label = L["Spellbook"],
        wrap = true,
        children = {},
    }

    -- Bottom tabs (Spellbook, Pet, etc.)
    tinsert(result.children, { "spellbook/Tabs" })

    -- Side tabs (spell schools/professions)
    tinsert(result.children, { "spellbook/SkillLineTabs", frame = SpellBookSideTabsFrame })

    -- Spell buttons grid
    tinsert(result.children, { "spellbook/Spells" })

    -- Page navigation
    tinsert(result.children, { "spellbook/PageNav" })

    -- Show all ranks checkbox
    if ShowAllSpellRanksCheckbox and ShowAllSpellRanksCheckbox:IsShown() then
        tinsert(result.children, {
            "ProxyCheckButton",
            frame = ShowAllSpellRanksCheckbox,
            label = ShowAllSpellRanksCheckboxText:GetText(),
        })
    end

    -- Close button
    if SpellBookCloseButton then
        tinsert(result.children, {
            "ProxyButton",
            frame = SpellBookCloseButton,
            label = CLOSE or "Close",
        })
    end

    return result
end)

gen:Element("spellbook/SkillLineTabs", function(props)
    local frame = props.frame
    if not frame:IsShown() then
        return nil
    end
    local result = {
        "List",
        label = L["Side Tabs"],
        children = {},
    }

    for i = 1, 8 do
        local tab = _G["SpellBookSkillLineTab" .. i]
        if tab and tab:IsShown() then
            tinsert(result.children, {
                "ProxyButton",
                key = "skillline_" .. i,
                frame = tab,
                label = tab.tooltip or "",
                selected = tab:GetChecked(),
            })
        end
    end

    if #result.children == 0 then
        return nil
    end

    return result
end)

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

gen:Element("spellbook/Spells", function(props)
    local result = {
        "List",
        label = L["Spells"],
        children = {},
    }

    local buttons = getSpellButtons()
    for _, button in ipairs(buttons) do
        local label = getSpellLabel(button)
        if label and label ~= "" then
            tinsert(result.children, {
                "ProxyButton",
                key = "spell_" .. button:GetID(),
                frame = button,
                label = label,
                tooltip = {
                    type = "Game",
                    mode = "immediate",
                },
            })
        end
    end

    if #result.children == 0 then
        return nil
    end

    return result
end)

gen:Element("spellbook/PageNav", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "ProxyButton", frame = SpellBookPrevPageButton, label = L["Previous Page"] },
            { "ProxyButton", frame = SpellBookNextPageButton, label = L["Next Page"] },
        },
    }
end)

gen:Element("spellbook/Tabs", function(props)
    local result = {
        "List",
        label = L["Tabs"],
        direction = "horizontal",
        children = {},
    }

    for i = 1, 3 do
        local tab = _G["SpellBookFrameTabButton" .. i]
        if tab and tab:IsShown() then
            local selected = PanelTemplates_GetSelectedTab(SpellBookFrame) == i
            tinsert(result.children, {
                "ProxyButton",
                key = "tab_" .. i,
                frame = tab,
                selected = selected,
            })
        end
    end

    if #result.children == 0 then
        return nil
    end

    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "spellbook",
    generated = true,
    rootElement = "spellbook",
    frameName = "SpellBookFrame",
    conflictingAddons = { "Sku" },
})
