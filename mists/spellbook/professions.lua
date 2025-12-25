local module = WowVision.base.windows.spellbook
local L = module.L
local gen = module:hasUI()

gen:Element("spellbook/Professions", function(props)
    local frame = props.frame
    local result = { "Panel", layout = true, shouldAnnounce = false, children = {} }
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        tinsert(result.children, { "spellbook/Professions/Profession", frame = child })
    end
    return result
end)

gen:Element("spellbook/Professions/Profession", function(props)
    local frame = props.frame
    if not frame:IsShown() then
        return nil
    end
    if frame.missingText:IsShown() then
        return { "Text", text = frame.missingText:GetText() }
    end
    local label = frame.professionName:GetText() or ""
    if frame.specialization then
        local specializationLabel = frame.specialization:GetText()
        if specializationLabel then
            label = label .. " (" .. specializationLabel .. ")"
        end
    end
    local rankText = frame.rank:GetText() .. " (" .. frame.statusBar.rankText:GetText() .. ")"
    local result = {
        "List",
        label = label,
        children = {
            { "Text", text = rankText },
            { "spellbook/Professions/ProfessionSpell", frame = frame.SpellButton2 },
            { "spellbook/Professions/ProfessionSpell", frame = frame.SpellButton1 },
            { "ProxyButton", frame = frame.UnlearnButton, label = L["Unlearn"] },
        },
    }
    return result
end)

gen:Element("spellbook/Professions/ProfessionSpell", function(props)
    local frame = props.frame
    local label = frame.spellString:GetText()
    local substring = frame.subSpellString:GetText()
    if substring and substring ~= "" then
        label = label .. "(" .. substring .. ")"
    end
    return { "ProxyCheckButton", frame = frame, label = label }
end)
