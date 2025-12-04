local module = WowVision.base.windows:createModule("talents")
local L = module.L
module:setLabel(L["Talents"])
local gen = module:hasUI()

gen:Element("talents", {
    alwaysRun = true, -- Children reference frames that may not exist initially
}, function(props)
    local result = {
        "Panel",
        label = L["Talents"],
        wrap = true,
        children = {
            { "talents/Tabs", key = "tabs", frame = props.frame },
            { "talents/Specialization", key = "spec", frame = PlayerTalentFrameSpecialization },
            { "talents/Talents", key = "talents", frame = PlayerTalentFrameTalents },
            { "talents/glyphs", key = "glyphs", frame = GlyphFrame },
        },
    }
    return result
end)

gen:Element("talents/Tabs", {
    dynamicValues = function(props)
        return { props.frame.numTabs, props.frame.selectedTab }
    end,
}, function(props)
    local result = { "List", direction = "horizontal", label = L["Tabs"], children = {} }
    for i = 1, props.frame.numTabs do
        local tab = _G["PlayerTalentFrameTab" .. i]
        tinsert(result.children, {
            "ProxyButton",
            key = "tab_" .. i,
            frame = tab,
            selected = props.frame.selectedTab == i,
        })
    end
    return result
end)

gen:Element("talents/Specialization", {
    dynamicValues = function(props)
        return { props.frame:IsShown() }
    end,
}, function(props)
    if not props.frame:IsShown() then
        return nil
    end
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "talents/SpecializationList", key = "list", frame = props.frame },
            { "talents/SpecializationDescription", key = "desc", frame = props.frame.spellsScroll },
            { "ProxyButton", key = "learn", frame = props.frame.learnButton },
        },
    }
    return result
end)

gen:Element("talents/SpecializationList", {
    dynamicValues = function(props)
        local f = props.frame
        local values = {}
        for i = 1, 4 do
            local button = f["specButton" .. i]
            if button then
                tinsert(values, button.selected)
                tinsert(values, button.specName:GetText())
            end
        end
        return values
    end,
}, function(props)
    local result = { "List", label = L["Specializations"], children = {} }
    for i = 1, 4 do
        local button = props.frame["specButton" .. i]
        if button then
            tinsert(result.children, {
                "ProxyButton",
                key = "spec_" .. i,
                frame = button,
                label = button.specName:GetText(),
                selected = button.selected,
            })
        end
    end
    return result
end)

gen:Element("talents/SpecializationDescription", {
    dynamicValues = function(props)
        if not props.frame:IsVisible() then
            return { false }
        end
        local frame = props.frame.child
        local values = { true, frame.roleName:GetText(), frame.description:GetText() }
        for i = 1, 5 do
            local button = frame["abilityButton" .. i]
            if button then
                tinsert(values, button.name:GetText())
            end
        end
        return values
    end,
}, function(props)
    if not props.frame:IsVisible() then
        return nil
    end
    local frame = props.frame.child
    local result = {
        "List",
        label = L["Specialization Info"],
        children = {
            { "Text", key = "role", text = frame.roleName:GetText() },
            { "Text", key = "desc", text = frame.description:GetText() },
        },
    }
    for i = 1, 5 do
        local button = frame["abilityButton" .. i]
        if button then
            tinsert(result.children, {
                "ProxyButton",
                key = "ability_" .. i,
                frame = button,
                label = button.name:GetText(),
            })
        end
    end
    return result
end)

gen:Element("talents/Talents", {
    dynamicValues = function(props)
        return { props.frame:IsShown() }
    end,
}, function(props)
    if not props.frame:IsShown() then
        return nil
    end

    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "talents/TalentsList", key = "list", frame = props.frame },
            { "ProxyButton", key = "learn", frame = props.frame.learnButton },
            { "talents/TalentsClearButton", key = "clear", frame = props.frame.clearInfo },
        },
    }

    return result
end)

gen:Element("talents/TalentsList", {
    dynamicValues = function()
        return {}
    end, -- Static tier structure
}, function(props)
    local result = { "List", label = L["Talents"], children = {} }
    for i = 1, MAX_NUM_TALENT_TIERS do
        local tier = props.frame["tier" .. i]
        if tier then
            tinsert(result.children, { "talents/TalentsTier", key = "tier_" .. i, frame = tier })
        end
    end
    return result
end)

gen:Element("talents/TalentsTier", {
    dynamicValues = function(props)
        local f = props.frame
        return {
            f.level:GetText(),
            f.talent1 and f.talent1.name:GetText(),
            f.talent2 and f.talent2.name:GetText(),
            f.talent3 and f.talent3.name:GetText(),
        }
    end,
}, function(props)
    local result = { "List", label = props.frame.level:GetText(), direction = "horizontal", children = {} }
    for i = 1, 3 do
        local button = props.frame["talent" .. i]
        if button then
            tinsert(result.children, {
                "ProxyButton",
                key = "talent_" .. i,
                frame = button,
                label = button.name:GetText(),
            })
        end
    end
    return result
end)

local function getClearLabel(button)
    local info = C_Spell.GetSpellInfo(button.spellID)
    local label = info.name .. "(" .. button.name:GetText() .. ")"
    return label
end

gen:Element("talents/TalentsClearButton", {
    dynamicValues = function(props)
        return { props.frame.spellID, props.frame.name:GetText() }
    end,
}, function(props)
    return { "ProxyButton", frame = props.frame, label = getClearLabel(props.frame) }
end)

module:registerWindow({
    name = "talents",
    auto = true,
    generated = true,
    rootElement = "talents",
    frameName = "PlayerTalentFrame",
    conflictingAddons = { "Sku" },
})
