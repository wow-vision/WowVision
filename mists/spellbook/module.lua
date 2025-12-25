local module = WowVision.base.windows:createModule("spellbook")
local L = module.L
module:setLabel(L["Spellbook"])
local gen = module:hasUI()

gen:Element("spellbook", function(props)
    local frame = props.frame
    local tab = SpellBookFrame.currentTab
    local title = frame:GetTitleText():GetText()
    local result = {
        "Panel",
        label = title,
        wrap = true,
        children = {
            { "spellbook/Tabs", frame = frame, tab = tab },
        },
    }
    if tab.bookType == "spell" then
        tinsert(result.children, { "spellbook/SpellBook", frame = frame, title = title })
    elseif tab.bookType == "professions" then
        tinsert(result.children, { "spellbook/Professions", frame = SpellBookProfessionFrame, title = title })
    end
    return result
end)

gen:Element("spellbook/Tabs", function(props)
    local tab = props.tab
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    for i = 1, props.frame.numTabs do
        local button = _G["SpellBookFrameTabButton" .. i]
        if button and button:IsShown() then
            tinsert(result.children, {
                "ProxyButton",
                frame = button,
                selected = button == tab,
            })
        end
    end
    return result
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
