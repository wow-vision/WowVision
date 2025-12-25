local module = WowVision.base.windows.spellbook
local L = module.L
local gen = module:hasUI()

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
