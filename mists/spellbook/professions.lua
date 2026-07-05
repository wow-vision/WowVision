local module = WowVision.base.windows.spellbook
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local function professionSpellNode(frame)
    local vtable = nodes.proxyCheckButton({
        target = frame,
        label = function()
            local label = frame.spellString:GetText() or ""
            local substring = frame.subSpellString:GetText()
            if substring ~= nil and substring ~= "" then
                label = label .. "(" .. substring .. ")"
            end
            return label
        end,
    })
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local script = frame:GetScript("OnDragStart")
            if script ~= nil then
                script(frame)
            end
        end,
    })
    return vtable
end

-- The professions summary: each profession is a stop under its name holding
-- rank, its two spell buttons, and unlearn; unlearned slots read their
-- missing text.
function module.renderProfessions(builder)
    local frame = SpellBookProfessionFrame
    if frame == nil then
        return
    end
    for index, child in ipairs({ frame:GetChildren() }) do
        if child:IsShown() then
            builder:beginStop("profession:" .. index)
            if child.missingText ~= nil and child.missingText:IsShown() then
                builder:addItem(
                    ControlId.structural("missing:" .. index),
                    nodes.text({
                        label = function()
                            return child.missingText:GetText()
                        end,
                    })
                )
            else
                local label = child.professionName:GetText() or ""
                if child.specialization ~= nil then
                    local specialization = child.specialization:GetText()
                    if specialization ~= nil then
                        label = label .. " (" .. specialization .. ")"
                    end
                end
                builder:pushContext("profession:" .. index, label)
                builder:addItem(
                    ControlId.structural("rank:" .. index),
                    nodes.text({
                        label = function()
                            return (child.rank:GetText() or "")
                                .. " ("
                                .. (child.statusBar.rankText:GetText() or "")
                                .. ")"
                        end,
                    })
                )
                if child.SpellButton2 ~= nil then
                    builder:addItem(ControlId.forObject(child.SpellButton2), professionSpellNode(child.SpellButton2))
                end
                if child.SpellButton1 ~= nil then
                    builder:addItem(ControlId.forObject(child.SpellButton1), professionSpellNode(child.SpellButton1))
                end
                if child.UnlearnButton ~= nil and child.UnlearnButton:IsShown() then
                    builder:addItem(
                        ControlId.forObject(child.UnlearnButton),
                        nodes.proxyButton({ target = child.UnlearnButton, label = L["Unlearn"] })
                    )
                end
                builder:popContext()
            end
        end
    end
end
