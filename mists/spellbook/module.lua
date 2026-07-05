local module = WowVision.base.windows:createModule("spellbook")
local L = module.L
module:setLabel(L["Spellbook"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The spellbook: bottom tabs pick the book, then either the spell pages
-- (side tabs, the spell list, page buttons) or the professions summary.
-- module.renderSpellBook and module.renderProfessions live in their files.

local function render(builder, screen)
    local frame = SpellBookFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    local title = frame:GetTitleText():GetText()
    builder:pushContext("spellbook", title)

    local currentTab = frame.currentTab
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, frame.numTabs do
        local button = _G["SpellBookFrameTabButton" .. i]
        if button ~= nil and button:IsShown() then
            local captured = button
            local vtable = nodes.proxyButton({ target = captured })
            tinsert(vtable.announcements, {
                text = function()
                    if SpellBookFrame.currentTab == captured then
                        return L["selected"]
                    end
                    return nil
                end,
                kind = kinds.selected,
            })
            builder:addItem(ControlId.forObject(captured), vtable)
        end
    end
    builder:endRow()
    builder:popContext()

    if currentTab ~= nil and currentTab.bookType == "spell" then
        module.renderSpellBook(builder)
    elseif currentTab ~= nil and currentTab.bookType == "professions" then
        module.renderProfessions(builder)
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "spellbook",
    frameName = "SpellBookFrame",
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
        if button:IsVisible() then
            local captured = button
            builder:addItem(
                ControlId.forObject(captured),
                nodes.proxyButton({
                    target = captured,
                    label = function()
                        return GetSpellInfo(captured.spellID)
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
