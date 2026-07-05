local module = WowVision.base.windows:createModule("talents")
local L = module.L
module:setLabel(L["Talents"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The MoP talent window: tabs, the specialization page (spec choices plus
-- the selected spec's role, description, and abilities), and the talents page
-- (tiers as rows of three choices). All static frames; no scroll piloting.

local function selectedPart(isSelected)
    return {
        text = function()
            if isSelected() then
                return L["selected"]
            end
            return nil
        end,
        kind = kinds.selected,
        live = "focus",
    }
end

local function fontStringText(owner, key)
    return function()
        local region = owner[key]
        if region ~= nil and region.GetText ~= nil then
            return region:GetText()
        end
        return nil
    end
end

local function renderTabs(builder, frame)
    builder:beginStop("tabs")
    builder:pushContext(L["Tabs"])
    builder:startRow()
    for i = 1, frame.numTabs or 0 do
        local tab = _G["PlayerTalentFrameTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            tinsert(
                vtable.announcements,
                selectedPart(function()
                    return frame.selectedTab == tabIndex
                end)
            )
            builder:addItem(ControlId.forObject(tab), vtable)
        end
    end
    builder:endRow()
    builder:popContext()
end

local function renderSpecialization(builder, page)
    builder:beginStop("specs")
    builder:pushContext(L["Specializations"])
    for i = 1, 4 do
        local button = page["specButton" .. i]
        if button ~= nil and button:IsShown() then
            local captured = button
            local vtable = nodes.proxyButton({
                target = captured,
                label = fontStringText(captured, "specName"),
            })
            tinsert(
                vtable.announcements,
                selectedPart(function()
                    return captured.selected
                end)
            )
            builder:addItem(ControlId.forObject(captured), vtable)
        end
    end
    builder:popContext()

    local scroll = page.spellsScroll
    if scroll ~= nil and scroll:IsVisible() and scroll.child ~= nil then
        local child = scroll.child
        builder:beginStop("specInfo")
        builder:pushContext(L["Specialization Info"])
        builder:addItem(ControlId.structural("role"), nodes.text({ label = fontStringText(child, "roleName") }))
        builder:addItem(ControlId.structural("specDesc"), nodes.text({ label = fontStringText(child, "description") }))
        for i = 1, 5 do
            local ability = child["abilityButton" .. i]
            if ability ~= nil and ability:IsShown() then
                builder:addItem(
                    ControlId.forObject(ability),
                    nodes.proxyButton({
                        target = ability,
                        label = fontStringText(ability, "name"),
                    })
                )
            end
        end
        builder:popContext()
    end

    if page.learnButton ~= nil and page.learnButton:IsShown() then
        builder:beginStop("specLearn")
        builder:addItem(ControlId.forObject(page.learnButton), nodes.proxyButton({ target = page.learnButton }))
    end
end

-- A talent choice: proxy click plus the old drag support, announcing when it
-- is the tier's chosen talent.
local function talentNode(button)
    local vtable = nodes.proxyButton({
        target = button,
        label = fontStringText(button, "name"),
    })
    tinsert(
        vtable.announcements,
        selectedPart(function()
            return button.knownSelection ~= nil and button.knownSelection:IsShown()
        end)
    )
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local script = button:GetScript("OnDragStart")
            if script ~= nil then
                script(button)
            end
        end,
    })
    return vtable
end

local function renderTalents(builder, page)
    builder:beginStop("talents")
    builder:pushContext(L["Talents"])
    for tierIndex = 1, MAX_NUM_TALENT_TIERS or 6 do
        local tier = page["tier" .. tierIndex]
        if tier ~= nil then
            local levelText = tier.level ~= nil and tier.level:GetText() or tostring(tierIndex)
            builder:pushContext(levelText)
            builder:startRow()
            for column = 1, 3 do
                local button = tier["talent" .. column]
                if button ~= nil then
                    builder:addItem(ControlId.forObject(button), talentNode(button))
                end
            end
            builder:endRow()
            builder:popContext()
        end
    end
    builder:popContext()

    builder:beginStop("talentActions")
    builder:startRow()
    if page.learnButton ~= nil and page.learnButton:IsShown() then
        builder:addItem(ControlId.forObject(page.learnButton), nodes.proxyButton({ target = page.learnButton }))
    end
    local clear = page.clearInfo
    if clear ~= nil and clear:IsShown() then
        builder:addItem(
            ControlId.forObject(clear),
            nodes.proxyButton({
                target = clear,
                label = function()
                    local ok, label = pcall(function()
                        local info = C_Spell.GetSpellInfo(clear.spellID)
                        return info.name .. " (" .. clear.name:GetText() .. ")"
                    end)
                    if ok then
                        return label
                    end
                    return nil
                end,
            })
        )
    end
    builder:endRow()
end

local function render(builder, screen)
    local frame = PlayerTalentFrame
    if frame == nil or not frame:IsShown() then
        return
    end

    renderTabs(builder, frame)

    local spec = PlayerTalentFrameSpecialization
    if spec ~= nil and spec:IsShown() then
        renderSpecialization(builder, spec)
    end

    local talents = PlayerTalentFrameTalents
    if talents ~= nil and talents:IsShown() then
        renderTalents(builder, talents)
    end

    if GlyphFrame ~= nil and GlyphFrame:IsShown() then
        builder:beginStop("glyphs")
        builder:addItem(ControlId.structural("glyphs"), nodes.text({ label = "Glyphs not yet implemented" }))
    end
end

module:registerWindow({
    type = "FrameWindow",
    name = "talents",
    frameName = "PlayerTalentFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
