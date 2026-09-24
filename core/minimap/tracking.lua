local module = WowVision.base.minimap
local Engine = WowVision.minimapScan.engine
local scanner = WowVision.base.scanner
local L = module.L

-- The scanner's last category, Tracking: what the minimap tracks and how
-- the world map filters, as checkboxes. A sighted player sets these from
-- the minimap's tracking menu and the world map's filter menu; with the
-- minimap scanner reading tracked dots, filtering matters as much here.
--
-- Not meant as the final place: a world map window could hold the map
-- filters, and a hotkey could open the tracking list directly. F9 is where
-- the scanner's results already are, so it goes here for now.

local function available()
    return C_Minimap ~= nil
        and C_Minimap.GetNumTrackingTypes ~= nil
        and C_Minimap.GetTrackingInfo ~= nil
        and C_Minimap.GetTrackingFilter ~= nil
end

-- The game's own menu lists its OPTIONAL_FILTERS plus tracking spells;
-- the rest are modern-era types this client names but has no use for
-- (the Warband banker, archaeology dig sites). Added on top: the types the
-- minimap scanner sorts by that the menu hides (vendors, points of
-- interest), so everything it can find can be switched here.
local SCANNER_FILTERS = { "VenderFood", "VendorAmmo", "VendorReagent", "VendorPoison", "POI" }

local function shownFilters()
    local shown = {}
    local constants = MinimapConstants or {}
    for id, on in pairs(constants.OPTIONAL_FILTERS or {}) do
        shown[id] = on == true or nil
    end
    local filters = Enum.MinimapTrackingFilter or {}
    for _, name in ipairs(SCANNER_FILTERS) do
        if filters[name] ~= nil then
            shown[filters[name]] = true
        end
    end
    return shown
end

-- Through the game's helper where it exists: some filters (low level
-- quests) mirror an options panel setting it keeps in step.
local function setTracking(index, on)
    if MinimapUtil ~= nil and MinimapUtil.SetTrackingFilterByFilterIndex ~= nil then
        MinimapUtil.SetTrackingFilterByFilterIndex(index, on)
    else
        C_Minimap.SetTracking(index, on)
    end
end

local function minimapNodes()
    local out = {}
    local shown = shownFilters()
    for _, t in ipairs(Engine.trackingTypes()) do
        local id = nil
        if t.isSpell then
            id = "spell" .. tostring(t.spellID)
        elseif shown[t.filterID] then
            id = t.filterID
        end
        if id ~= nil then
            local captured = t.index
            tinsert(out, {
                key = "track:" .. tostring(id),
                label = t.name,
                toggle = {
                    get = function()
                        local current = C_Minimap.GetTrackingInfo(captured)
                        return current ~= nil and current.active == true
                    end,
                    set = function(on)
                        setTracking(captured, on)
                    end,
                },
            })
        end
    end
    return out
end

-- The world map's filter menu, in its order: each entry a CVar, a
-- minimap tracking filter, or both (low level quests is both, the same
-- switch as on the minimap). Labels and descriptions are the game's own
-- strings; entries this client lacks are left out.
local MAP_FILTERS = {
    { text = "SHOW_QUEST_OBJECTIVES_ON_MAP_TEXT", cvar = "questPOI", tip = "QUEST_OBJECTIVES_FILTER_DESCRIPTION" },
    { text = "SHOW_QUEST_LEVELS", cvar = "showQuestLevel", tip = "QUEST_LEVEL_FILTER_DESCRIPTION" },
    {
        text = "MAP_QUEST_DIFFICULTY_TEXT",
        cvar = "showQuestDifficultyColor",
        tip = "QUEST_DIFFICULTY_FILTER_DESCRIPTION",
    },
    {
        text = "SHOW_INSTANCE_ENTRANCES_ON_MAP_TEXT",
        cvar = "showDungeonEntrancesOnMap",
        tip = "INSTANCE_ENTRANCES_FILTER_DESCRIPTION",
    },
    { text = "MINIMAP_TRACKING_TRIVIAL_QUESTS", filter = "TrivialQuests", tip = "TRIVIAL_QUESTS_FILTER_DESCRIPTION" },
    { text = "CONTENT_TRACKING_MAP_TOGGLE", cvar = "contentTrackingFilter", tip = "TRACKED_ITEMS_FILTER_DESCRIPTION" },
}

local function cvarExists(name)
    return GetCVar(name) ~= nil
end

local function filterIndex(filterId)
    for _, t in ipairs(Engine.trackingTypes()) do
        if t.filterID == filterId then
            return t.index
        end
    end
    return nil
end

local function mapFilterNodes()
    local out = {}
    for _, entry in ipairs(MAP_FILTERS) do
        local label = _G[entry.text]
        local filterId = entry.filter ~= nil and Enum.MinimapTrackingFilter ~= nil
                and Enum.MinimapTrackingFilter[entry.filter]
            or nil
        local usable = (entry.cvar == nil or cvarExists(entry.cvar)) and (entry.filter == nil or filterId ~= nil)
        if type(label) == "string" and usable then
            local tip = _G[entry.tip]
            tinsert(out, {
                key = "map:" .. (entry.cvar or entry.filter),
                label = label,
                details = type(tip) == "string" and { tip } or nil,
                toggle = {
                    -- As the game reads it: on unless the CVar or the
                    -- tracking filter says otherwise.
                    get = function()
                        if entry.cvar ~= nil and not GetCVarBool(entry.cvar) then
                            return false
                        end
                        if filterId ~= nil and C_Minimap.IsFilteredOut ~= nil and C_Minimap.IsFilteredOut(filterId) then
                            return false
                        end
                        return true
                    end,
                    set = function(on)
                        if entry.cvar ~= nil then
                            SetCVar(entry.cvar, on and "1" or "0")
                        end
                        if filterId ~= nil then
                            local index = filterIndex(filterId)
                            if index ~= nil then
                                setTracking(index, on)
                            end
                        end
                    end,
                },
            })
        end
    end
    return out
end

scanner:registerProvider({
    key = "tracking",
    label = L["Tracking"],
    order = 1000,
    optional = true,
    expanded = false,
    build = function()
        if not available() then
            return {}
        end
        return {
            { key = "minimap", label = L["Minimap Tracking"], children = minimapNodes },
            { key = "worldMap", label = L["Map Filter"], children = mapFilterNodes },
        }
    end,
})
