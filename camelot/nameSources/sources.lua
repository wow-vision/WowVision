-- The outside sources: dictionaries asked by an English name, each one a place where the game's language already has
-- the word. Built from what is installed when the calculation runs (env says what the game and the other addons
-- offer, so the tests can hand in stand-ins).
--
-- The kinds a lookup is asked for: "Npc" (a creature's name), "Title" (the line under a creature's name, such as
-- Innkeeper) and "Object" (a world object's name). Sources, in the order they are asked:
--   registered  whatever other addons declared with WowVision.nameSources.addSource
--   gathering   WowVision's own lists of herbs, ores and chests, English and the game's language side by side
--   questie     Questie's translations of its own words (Mailbox, Innkeeper, Stable Master ...)
--   zones       the names of areas: a sign called "Cathedral Square" is an area the game itself names
local ns = WowVision.nameSources

local Sources = {}
ns.Sources = Sources

local function isText(value)
    return type(value) == "string" and value ~= ""
end

-- env: locale; registered = array of { key =, fn = }; gathering = WowVision.minimapScan.gatheringNames;
-- questieTranslations = Questie's l10n.translations; zoneLookup = Questie's l10n.zoneLookup;
-- getAreaInfo(areaId) -> the area's name in the game's language.
function Sources.build(env)
    local locale = env.locale
    local self = { flags = {}, registered = env.registered or {} }

    -- WowVision's lists: the same position in the English list and in the list of the game's language
    local gathering = nil
    if type(env.gathering) == "table" then
        gathering = {}
        for _, section in pairs(env.gathering) do
            if type(section) == "table" and type(section.enUS) == "table" and type(section[locale]) == "table"
                and #section.enUS == #section[locale] then
                for index, english in ipairs(section.enUS) do
                    local translated = section[locale][index]
                    if isText(english) and isText(translated) and english ~= translated and gathering[english] == nil then
                        gathering[english] = translated
                    end
                end
            end
        end
        if next(gathering) == nil then
            gathering = nil
        end
    end
    self.flags.gathering = gathering ~= nil

    -- Questie's own words: { [English] = { [locale] = text | true | false } }; sentences with a place for a number or a
    -- word are not names
    local questie = nil
    if type(env.questieTranslations) == "table" then
        questie = {}
        for english, byLocale in pairs(env.questieTranslations) do
            if type(english) == "string" and not english:find("%", 1, true) and type(byLocale) == "table" then
                local translated = byLocale[locale]
                if isText(translated) and translated ~= english then
                    questie[english] = translated
                end
            end
        end
        if next(questie) == nil then
            questie = nil
        end
    end
    self.flags.questie = questie ~= nil

    -- areas: English name -> the ids that carry it
    local zoneIds = nil
    if type(env.zoneLookup) == "table" and type(env.getAreaInfo) == "function" then
        zoneIds = {}
        for _, byId in pairs(env.zoneLookup) do
            if type(byId) == "table" then
                for areaId, name in pairs(byId) do
                    if type(areaId) == "number" and isText(name) then
                        local list = zoneIds[name]
                        if list == nil then
                            list = {}
                            zoneIds[name] = list
                        end
                        list[#list + 1] = areaId
                    end
                end
            end
        end
        if next(zoneIds) == nil then
            zoneIds = nil
        end
    end
    self.flags.zones = zoneIds ~= nil

    local zoneMemo = {}
    local function zoneName(english)
        local known = zoneMemo[english]
        if known ~= nil then
            return known or nil
        end
        local result = false
        local ids = zoneIds and zoneIds[english]
        if ids ~= nil then
            local found, count = nil, 0
            for _, areaId in ipairs(ids) do
                local ok, name = pcall(env.getAreaInfo, areaId)
                if ok and isText(name) and name ~= found then
                    -- an area the game names the same way everywhere has one answer; two answers is a name we cannot choose
                    found, count = name, count + 1
                end
            end
            if count == 1 and found ~= english then
                result = found
            end
        end
        zoneMemo[english] = result
        return result or nil
    end

    -- the text and the key of the source that gave it
    function self.lookup(kind, english)
        if not isText(english) then
            return nil
        end
        for _, source in ipairs(self.registered) do
            local ok, text = pcall(source.fn, kind, english, locale)
            if ok and isText(text) and text ~= english then
                return text, "registered:" .. tostring(source.key)
            end
        end
        if kind == "Object" and gathering ~= nil and gathering[english] ~= nil then
            return gathering[english], "gathering"
        end
        if (kind == "Object" or kind == "Title") and questie ~= nil and questie[english] ~= nil then
            return questie[english], "questie"
        end
        if kind == "Object" then
            local area = zoneName(english)
            if area ~= nil then
                return area, "zones"
            end
        end
        return nil
    end

    return self
end

-- What the stamp of a cache says about the sources: which ones were there, which addons registered one.
function Sources.signature(sources)
    local parts = {}
    for _, key in ipairs({ "gathering", "questie", "zones" }) do
        parts[#parts + 1] = key .. "=" .. (sources.flags[key] and "1" or "0")
    end
    local registered = {}
    for _, source in ipairs(sources.registered) do
        registered[#registered + 1] = tostring(source.key)
    end
    table.sort(registered)
    parts[#parts + 1] = "reg=" .. table.concat(registered, ",")
    return table.concat(parts, ";")
end

-- Spoken names of the source keys (the locale strings), for the status.
function Sources.label(key, L)
    if key == "same-name" then
        return L["the same name already translated elsewhere"]
    elseif key == "gathering" then
        return L["the herbs, ores and chests WowVision knows"]
    elseif key == "questie" then
        return L["Questie's translations"]
    elseif key == "zones" then
        return L["the game's area names"]
    elseif key == "item" then
        return L["the names of inventory items"]
    end
    local registered = tostring(key):match("^registered:(.*)$")
    return registered or tostring(key)
end
