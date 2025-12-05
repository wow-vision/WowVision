local module = WowVision.base.windows:createModule("spellbook")
local L = module.L
module:setLabel(L["Spellbook"])
local gen = module:hasUI()

gen:Element("spellbook", function(props)
    local frame = SpellBookFrame
    local result = {
        "Panel",
        label = frame.TitleText:GetText(),
        wrap = true,
        children = {
            { "spellbook/Tabs", frame = frame },
        },
    }
    local tab = SpellBookFrame.currentTab
    if tab == SpellBookFrameTabButton1 then
        tinsert(result.children, { "spellbook/SpellBook", frame = frame })
    end
    return result
end)

gen:Element("spellbook/Tabs", function(props)
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    for i = 1, props.frame.numTabs do
        local button = _G["SpellBookFrameTabButton" .. i]
        if button and button:IsShown() then
            tinsert(result.children, {
                "ProxyButton",
                frame = button,
                selected = button == props.frame.currentTab,
            })
        end
    end
    return result
end)

gen:Element("spellbook/SpellBook", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "spellbook/SideTabs", frame = SpellBookSideTabsFrame },
            { "spellbook/SpellIcons", frame = SpellBookSpellIconsFrame },
            { "spellbook/SpellBookPageNavigation", frame = SpellBookPageNavigationFrame },
        },
    }
end)

gen:Element("spellbook/SideTabs", function(props)
    if not props.frame or not props.frame:IsShown() then
        return nil
    end
    local result = { "List", label = L["Side Tabs"], direction = "horizontal", children = {} }
    local children = { props.frame:GetChildren() }
    for _, v in ipairs(children) do
        tinsert(result.children, { "ProxyCheckButton", frame = v, label = v.tooltip })
    end
    return result
end)

local function getSpellLabel(button)
    local regions = { button:GetRegions() }
    local label = {}
    for _, v in ipairs(regions) do
        if v:GetObjectType() == "FontString" and v:IsShown() then
            local text = v:GetText()
            if text ~= nil and text ~= "" then
                tinsert(label, text)
            end
        end
    end
    return table.concat(label, " ")
end

gen:Element("spellbook/SpellIcons", function(props)
    if not props.frame or not props.frame:IsShown() then
        return nil
    end
    local result = { "List", label = L["Spells"], children = {} }
    local children = { props.frame:GetChildren() }
    table.sort(children, function(a, b)
        return a:GetID() < b:GetID()
    end)
    for i, v in ipairs(children) do
        if v:IsShown() and v:IsEnabled() then
            tinsert(result.children, {
                "ProxyButton",
                frame = v,
                label = getSpellLabel(v),
            })
        end
    end
    return result
end)

gen:Element("spellbook/SpellBookPageNavigation", function(props)
    if not props.frame or not props.frame:IsShown() then
        return nil
    end
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

module:registerWindow({
    type = "FrameWindow",
    name = "spellbook",
    generated = true,
    rootElement = "spellbook",
    frameName = "SpellBookFrame",
})

gen:Element("SpellFlyout", function(props)
    local result = { "Panel", label = L["Spell Flyout"], wrap = true, children = {} }
    local children = { SpellFlyout:GetChildren() }
    for _, v in ipairs(children) do
        if v:IsVisible() then
            tinsert(result.children, { "ProxyButton", frame = v, label = GetSpellInfo(v.spellID) })
        end
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "SpellFlyout",
    generated = true,
    rootElement = "SpellFlyout",
    frameName = "SpellFlyout",
    hookEscape = true,
    onClose = function()
        SpellFlyout:Hide()
    end,
})
