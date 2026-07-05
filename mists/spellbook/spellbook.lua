local module = WowVision.base.windows.spellbook
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local function getSpellLabel(button)
    local regions = { button:GetRegions() }
    local label = {}
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" and region:IsShown() then
            local text = region:GetText()
            if text ~= nil and text ~= "" then
                tinsert(label, text)
            end
        end
    end
    return table.concat(label, " ")
end

-- The spell pages: side tabs (specialization filters), the spell list --
-- live labels, since page flips rebind the same twelve buttons -- and the
-- page buttons.
function module.renderSpellBook(builder)
    if SpellBookSideTabsFrame ~= nil and SpellBookSideTabsFrame:IsShown() then
        builder:beginStop("sideTabs")
        builder:pushContext("sideTabs", L["Side Tabs"])
        builder:startRow()
        for _, button in ipairs({ SpellBookSideTabsFrame:GetChildren() }) do
            local captured = button
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
        builder:endRow()
        builder:popContext()
    end

    if SpellBookSpellIconsFrame ~= nil and SpellBookSpellIconsFrame:IsShown() then
        builder:beginStop("spells")
        builder:pushContext("spells", L["Spells"])
        local buttons = { SpellBookSpellIconsFrame:GetChildren() }
        table.sort(buttons, function(a, b)
            return a:GetID() < b:GetID()
        end)
        local emitted = 0
        for _, button in ipairs(buttons) do
            if button:IsShown() and button:IsEnabled() then
                local captured = button
                local vtable = nodes.proxyButton({
                    target = captured,
                    label = function()
                        return getSpellLabel(captured)
                    end,
                })
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
    end

    if SpellBookPageNavigationFrame ~= nil and SpellBookPageNavigationFrame:IsShown() then
        builder:beginStop("prevPage")
        builder:addItem(
            ControlId.forObject(SpellBookPrevPageButton),
            nodes.proxyButton({ target = SpellBookPrevPageButton, label = L["Previous Page"] })
        )
        builder:beginStop("nextPage")
        builder:addItem(
            ControlId.forObject(SpellBookNextPageButton),
            nodes.proxyButton({ target = SpellBookNextPageButton, label = L["Next Page"] })
        )
    end
end

-- The core abilities tab: spec tabs picking whose list shows, then each
-- ability with its name, guidance text, and required level when not yet
-- learned. Draggable only for your own spec's learned actives, matching the
-- buttons.
function module.renderCoreAbilities(builder)
    local frame = SpellBookCoreAbilitiesFrame
    if frame == nil or not frame:IsShown() then
        return
    end

    if frame.SpecTabs ~= nil then
        builder:beginStop("coreSpecTabs")
        builder:pushContext("coreSpecTabs", L["Tabs"])
        builder:startRow()
        for _, tab in ipairs(frame.SpecTabs) do
            if tab:IsShown() then
                local captured = tab
                builder:addItem(
                    ControlId.forObject(captured),
                    nodes.proxyCheckButton({
                        target = captured,
                        label = function()
                            local _, displayName = C_SpecializationInfo.GetSpecializationInfo(captured:GetID())
                            return displayName
                        end,
                    })
                )
            end
        end
        builder:endRow()
        builder:popContext()
    end

    builder:beginStop("coreAbilities")
    builder:pushContext("coreAbilities", frame.SpecName ~= nil and frame.SpecName:GetText() or "")
    for i, button in ipairs(frame.Abilities or {}) do
        if button:IsShown() then
            local captured = button
            local vtable = nodes.proxyButton({
                target = captured,
                label = function()
                    local parts = {}
                    tinsert(parts, captured.Name:GetText() or "")
                    local level = captured.RequiredLevel:GetText()
                    if level ~= nil and level ~= "" then
                        tinsert(parts, level)
                    end
                    tinsert(parts, captured.InfoText:GetText() or "")
                    return table.concat(parts, ", ")
                end,
            })
            tinsert(vtable.bindings, {
                binding = "drag",
                type = "Function",
                func = function()
                    if captured.draggable then
                        local script = captured:GetScript("OnDragStart")
                        if script ~= nil then
                            script(captured)
                        end
                    end
                end,
            })
            builder:addItem(ControlId.forObject(captured), vtable)
        end
    end
    builder:popContext()
end

local function stripHTML(text)
    if text == nil then
        return ""
    end
    text = text:gsub("<[^>]+>", " ")
    text = text:gsub("|n", " ")
    text = text:gsub("%s+", " ")
    return text
end

-- The what-has-changed tab, read straight from the class-keyed data tables
-- the panel itself renders from.
function module.renderWhatHasChanged(builder)
    local displayName, class = UnitClass("player")
    local titles = WHAT_HAS_CHANGED_TITLE ~= nil and WHAT_HAS_CHANGED_TITLE[class] or nil
    local bodies = WHAT_HAS_CHANGED_DISPLAY ~= nil and WHAT_HAS_CHANGED_DISPLAY[class] or nil
    if bodies == nil then
        return
    end

    builder:beginStop("whatHasChanged")
    builder:pushContext("whatHasChanged", displayName)
    for i, body in ipairs(bodies) do
        local title = titles ~= nil and titles[i] or nil
        local text = stripHTML(body)
        builder:addItem(
            ControlId.structural("changed:" .. i),
            nodes.text({
                label = function()
                    if title ~= nil and title ~= "" then
                        return i .. ". " .. title .. ". " .. text
                    end
                    return i .. ". " .. text
                end,
            })
        )
    end
    builder:popContext()
end
