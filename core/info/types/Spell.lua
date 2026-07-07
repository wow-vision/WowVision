local info = WowVision.info
local L = WowVision:getLocale()

local SpellField, parent = info:CreateFieldClass("Spell", "Number")

-- Look up spell name from ID, with version compatibility
local function getSpellName(spellID)
    if not spellID then
        return nil
    end
    if GetSpellInfo then
        local name = GetSpellInfo(spellID)
        return name
    elseif C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name
        end
    end
    return nil
end

-- Look up spell ID from name, with version compatibility
local function getSpellID(spellName)
    if not spellName or spellName == "" then
        return nil
    end
    if GetSpellInfo then
        local name, _, _, _, _, _, spellID = GetSpellInfo(spellName)
        if name then
            return spellID
        end
    elseif C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellName)
        if spellInfo then
            return spellInfo.spellID
        end
    end
    return nil
end

function SpellField:validate(value)
    if value == nil then
        return nil
    end
    local number = tonumber(value)
    if number then
        return number
    end
    -- Try to look up by name
    local spellID = getSpellID(value)
    return spellID
end

function SpellField:getValueString(obj, value)
    if not value then
        return nil
    end
    local name = getSpellName(value)
    if name then
        return name .. " (" .. value .. ")"
    end
    return tostring(value)
end
