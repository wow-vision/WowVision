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
