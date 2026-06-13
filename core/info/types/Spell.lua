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

function SpellField:getGenerator(obj)
    local field = self
    local value = self:get(obj)
    local label = self:getLabel() or self.key
    local valueStr = self:getValueString(obj, value)

    return {
        "Button",
        label = label,
        extras = valueStr,
        events = {
            click = function(event, button)
                button.context:addGenerated(field:buildSelector(obj, button))
            end,
        },
    }
end

function SpellField:buildSelector(obj, parentButton)
    local field = self
    local children = {
        {
            "EditBox",
            label = L["Spell Name"],
            autoInputOnFocus = false,
            events = {
                submit = function(event, editBox)
                    local text = editBox:getValue()
                    local spellID = getSpellID(text)
                    if spellID then
                        field:set(obj, spellID)
                        parentButton.context:pop()
                    end
                end,
            },
        },
        {
            "EditBox",
            label = L["Spell ID"],
            autoInputOnFocus = false,
            type = "decimal",
            events = {
                submit = function(event, editBox)
                    local text = editBox:getValue()
                    local id = tonumber(text)
                    if id then
                        field:set(obj, id)
                        parentButton.context:pop()
                    end
                end,
            },
        },
    }

    -- Add spell history entries
    local history = WowVision.spellHistory
    if history then
        local sorted = {}
        for spellID, entry in pairs(history.spells) do
            tinsert(sorted, { spellID = spellID, name = entry.name })
        end
        table.sort(sorted, function(a, b)
            return a.name < b.name
        end)
        for _, spell in ipairs(sorted) do
            tinsert(children, {
                "Button",
                label = spell.name .. " (" .. spell.spellID .. ")",
                events = {
                    click = function(event, button)
                        field:set(obj, spell.spellID)
                        parentButton.context:pop()
                    end,
                },
            })
        end
    end

    return {
        "List",
        label = self:getLabel() or self.key,
        children = children,
    }
end
