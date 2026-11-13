-- The texts of the WowNav engine in WowVision's languages: WowVisionNavigationText (the resolver's reasons) and the
-- spoken names of targets, built the way WowNav's Localization.lua builds them (data ReadMe section 8): a dyn target
-- has a name key and a place that the client names in its own language (C_Map.GetAreaInfo / GetRealZoneText, the
-- English nameParam as the fallback), plus a suffix when two targets of a zone would sound alike. Categories come as
-- English keys from the data and are named here.

local L = WowVision:getLocale()

local text = {}
WowVision.wownavText = text

-- the resolver's reasons (TargetResolver.lua); keys without an entry read back as the key
local REASONS = {
    res_stale = L["The target position is outdated"],
    res_no_native_map = L["The target is on another map"],
    res_other_map = L["The target is on another map"],
    res_band_invalid = L["There is no such floor"],
    res_ambiguous = L["The target lies over several floors"],
    res_z_conflict = L["The target's height fits no floor of the network"],
    res_level_unknown = L["The target lies over several floors"],
    res_no_point = L["No network point near the target"],
    res_no_path = L["No network path to the target"],
    res_no_route_from_start = L["No network path from here to the target"],
    -- the dock guidance (DockNavigation.lua)
    dock_reached = L["Dock %s reached. Wait here for %s. Board when you hear it arrive."],
    dock_boarding_hint = L[" The beacon shows the boarding direction; I turns you toward it."],
    dock_boarding_next = L[" Next point: %s."],
    height_hint_above = L["Target is above, about %d yards."],
    height_hint_below = L["Target is below, about %d yards."],
    dock_passive_set = L["Destination dock %s noted. Wait for the vehicle, board by ear and get off at the destination stop. Then choose the dock again for the way on foot."],
    vehicle_tram = L["the Deeprun Tram"],
    vehicle_boat = L["the ship"],
    vehicle_zeppelin = L["the zeppelin"],
    vehicle_lift = L["the elevator"],
    vehicle_other = L["the vehicle"],
    stop_boarding_point_reached = L["Boarding point %s reached"],
    dock_no_wait_proof = L["The dock has no valid waiting point proof"],
    boarding_no_direction_proof = L["The boarding point has no valid direction proof on this map"],
    wait_proof_invalid = L["The waiting point proof is invalid; no boarding instruction"],
    stop_boarding_proof_changed = L["The boarding point proof or the map changed; guidance ended"],
    -- target descriptions (his TargetSelection:Describe), walk-in targets (TransitActivation), route ends
    desc_inexact = L[" (inexact +%.1f yards%s)"],
    desc_horizontal_unknown = L[" horizontal, height unknown"],
    desc_vertical = L[" vertical"],
    desc_pick_height = L[" (choose the floor)"],
    desc_level_unknown = L[" (floor unknown)"],
    desc_no_point = L[" (no network point within the radius)"],
    desc_water = L[" (water surface, diving depth %.1f yards)"],
    approx_target = L["Approximate target position."],
    stop_net_ends = L["The network ends %.1f yards%s from the target; search the surroundings yourself. The last stretch is unchecked."],
    stop_water_net_ends = L["The network ends %.1f yards from the water surface position; diving depth %.1f yards. The rest of the way and the diving are yours, the last stretch is unchecked."],
    suffix_horizontal = L[" horizontally"],
    prepoint_reached_go_through = L["Prepoint reached. Walk straight ahead through the entrance or portal; the beacon stays on until the activation area."],
    prepoint_reached_unresolved = L["Prepoint reached. The beacon keeps following the checked way to the activation area."],
    activation_area_entered = L["In the activation area. Keep walking straight ahead; only a map change confirms the transition. The route stays on until then."],
    activation_position_reached = L["Position of the activation area reached. %sA journey is not confirmed here; the route stays on."],
    height_not_confirmed = L["The height is not confirmed. "],
    reason_activation_map_changed = L["Map change after the activation area; route ended. The destination is not confirmed."],
    reason_map_changed_guidance_done = L["Map change; the activation guidance is finished."],
    activation_proof_invalid = L["The entrance has no valid proof."],
    action_boarding = L["Board only when the vehicle is safely there."],
    prepoint_reached_dive = L["Prepoint reached. Dive here: walk straight ahead to the dive point; the beacon stays on until then."],
    activation_area_dive = L["At the dive point. Dive here; the route stays on until the dive is confirmed."],
    -- a portal clicked at (activation mode click) and the Wind Bridge of Zephras Isle, which comes at its own time
    prepoint_reached_click = L["Prepoint reached. Walk on to the portal; the beacon stays on until you are there."],
    activation_area_click = L["At the portal. Target it with soft targeting and interact with it; the route stays on until the transition is confirmed."],
    prepoint_reached_wind_bridge = L["Prepoint reached. Walk on to the waiting point of the Wind Bridge; the beacon stays on until then."],
    activation_area_wind_bridge = L["At the waiting point of the Wind Bridge. Wait until you hear the bridge, then step into the wind current."],
    approximate_position = L["The position is approximate."],
    -- his Z2 warnings (faction outposts)
    outpost_through = L["Warning: there is no way around the enemy outpost, the route leads through it."],
    outpost_target = L["Warning: the target lies in an enemy outpost."],
    stop_outside_zones = L["Route ended outside the network's zones."],
    no_live_coordinates = L["No position of the group member available"],
    target_source_gone = L["The target is no longer available; no new route"],
    -- fishing spots (FishingNavigation.lua): where the water lies, seen from the player
    fishing_arrival = L["%s reached. The water is %s. Cast range about %d to %d yards. Press I to turn to the water."],
    fishing_arrival_no_facing = L["%s reached. Cast range about %d to %d yards. Press I to turn to the water."],
    fishing_sector_1 = L["straight ahead"],
    fishing_sector_2 = L["ahead to the left"],
    fishing_sector_3 = L["to the left"],
    fishing_sector_4 = L["behind to the left"],
    fishing_sector_5 = L["behind you"],
    fishing_sector_6 = L["behind to the right"],
    fishing_sector_7 = L["to the right"],
    fishing_sector_8 = L["ahead to the right"],
}

function WowVisionNavigationText(key, ...)
    local template = REASONS[key]
    if template == nil then
        return tostring(key)
    end
    if select("#", ...) > 0 then
        return string.format(template, ...)
    end
    return template
end

-- his WowVisionNavigationPrint: what DockNavigation.lua says goes to WowVision's speech (text.say, set by the module)
function WowVisionNavigationPrint(message)
    if text.say ~= nil then
        text.say(message)
    end
end

function WowVisionNavigationTargetName(target)
    return text.targetName(target)
end

function text.german()
    return GetLocale ~= nil and GetLocale() == "deDE"
end

-- dyn name templates (nameKey) and suffixes (nameSuffix.key)
local DYN = {
    dungeon_entrance = L["Dungeon entrance: %s"],
    portal = L["Portal to %s"],
    dock_ship = L["Ship dock to %s"],
    dock_zeppelin = L["Zeppelin dock to %s"],
    tram_entrance = L["Deeprun Tram entrance"],
    tram_dock = L["Tram dock toward %s"],
    elevator = L["Elevator: %s"],
    zone_transition = L["Crossing to %s"],
    on_ship = L["On the ship to %s"],
    on_zeppelin = L["On the zeppelin to %s"],
    in_tram = L["In the tram toward %s"],
    boarding_boat = L["On the ship"],
    boarding_zeppelin = L["On the zeppelin"],
    boarding_vehicle = L["At the vehicle"],
    dive_entry = L["Dive here"],
    dive_exit = L["Surface here"],
    fishing_spot_shore = L["Fishing spot on the shore: %s"],
    fishing_spot_structure = L["Fishing spot on pier or quay: %s"],
    cave_center = L["Central point: %s"],
    -- the transitions of Zephras Isle (their places are named in the key)
    rohashi_portal = L["Portal to Rohashi Spires"],
    rohashi_arrival = L["Arrival at Rohashi Spires"],
    valanaar_portal = L["Portal to Valanaar"],
    valanaar_arrival_horde = L["Horde arrival in Valanaar Sanctuary"],
    valanaar_arrival_alliance = L["Alliance arrival in Valanaar Sanctuary"],
    wind_bridge_wait = L["Wind Bridge waiting point"],
    wind_bridge_landing = L["Wind Bridge landing"],
}
-- a dungeon with several entrances: the wing of each (nameWing, nameWingDe in German) after the dungeon
local DYN_WING = {
    dungeon_entrance = L["Dungeon entrance: %s, %s"],
}
local SUFFIX = {
    lower = L[" (lower)"],
    upper = L[" (upper)"],
    z = L[" (height %d)"],
    number = L[" (%d)"],
}

local placeName
-- the place a target names (a dock: where its line goes), in the client's language
function text.placeName(target)
    return placeName(target)
end

function placeName(target)
    if type(target.nameAreaId) == "number" and C_Map ~= nil and C_Map.GetAreaInfo ~= nil then
        local ok, name = pcall(C_Map.GetAreaInfo, target.nameAreaId)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    if type(target.nameMapId) == "number" and GetRealZoneText ~= nil then
        local ok, name = pcall(GetRealZoneText, target.nameMapId)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    if type(target.nameParam) == "string" and target.nameParam ~= "" then
        return target.nameParam
    end
    return nil
end

local function nameSuffix(target)
    local suffix = target.nameSuffix
    if type(suffix) ~= "table" or type(suffix.key) ~= "string" then
        return ""
    end
    local template = SUFFIX[suffix.key]
    if template == nil then
        return ""
    end
    if template:find("%d", 1, true) then
        if type(suffix.value) ~= "number" then
            return ""
        end
        return string.format(template, suffix.value)
    end
    return template
end

-- ---- creatures and objects in the client's language
--
-- The catalogues name a creature or an object in English and German only. Each one also carries its game ID (entry),
-- and Questie's database (QuestieDB: NpcDB and ObjectDB, the globals it publishes) holds the same creatures and
-- objects by ID with their names in the client's language. So on a client that is neither English nor German the
-- name comes from Questie where it knows the ID, and the catalogue's own name is the fallback.
local NPC_KINDS = { npc = true, mob = true, creature = true }
local OBJECT_KINDS = { gameobject = true, herb = true, mining = true, mailbox = true }
local OWN_LOCALES = { enUS = true, enGB = true, deDE = true }

-- Whether the Names in Your Language setting is on; the module (module.lua) replaces this.
function text.localNamesEnabled()
    return true
end

local localNames = { NpcDB = { name = {}, subName = {} }, ObjectDB = { name = {}, subName = {} } }

-- Forgets what Questie answered (a new language, or a Questie that was not ready).
function text.clearLocalNames()
    localNames = { NpcDB = { name = {}, subName = {} }, ObjectDB = { name = {}, subName = {} } }
end

local function isSecret(value)
    return WowVision.secrets ~= nil and WowVision.secrets.isSecret(value) == true
end

-- Questie answers in its own language setting (Auto follows the game, but it can be forced), and until its start-up
-- has run it still says English. Its names are used only while that language is the client's; when Questie cannot be
-- asked, it is taken to agree.
local function questieSpeaksClientLanguage()
    if QuestieLoader == nil or type(QuestieLoader.ImportModule) ~= "function" then
        return true
    end
    local ok, l10n = pcall(QuestieLoader.ImportModule, QuestieLoader, "l10n")
    if not ok or type(l10n) ~= "table" or type(l10n.GetUILocale) ~= "function" then
        return true
    end
    local asked, uiLocale = pcall(l10n.GetUILocale, l10n)
    return not asked or uiLocale == nil or uiLocale == GetLocale()
end

-- Questie's database can exist before Questie has finished loading it, and a lookup then misses. Once Questie says
-- it is ready, everything remembered so far is forgotten, so those names are asked again. Hooked on the first lookup
-- (and again for a new Questie.API table); Questie fires the hook at once when it is already ready.
local hookedQuestieApi = nil
local function forgetWhenQuestieIsReady()
    local questie = rawget(_G, "Questie")
    local api = type(questie) == "table" and questie.API or nil
    if type(api) ~= "table" or api == hookedQuestieApi or type(api.RegisterOnReady) ~= "function" then
        return
    end
    hookedQuestieApi = api
    pcall(api.RegisterOnReady, text.clearLocalNames)
end

-- A text field ("name", "subName") Questie gives an ID, or nil. A miss is remembered, but only when Questie could be
-- asked properly: before its table exists, or before it speaks the client's language, a lookup must still be able to
-- succeed later. A miss while Questie is still loading is forgotten when it is ready (forgetWhenQuestieIsReady).
local function questieField(databaseName, id, field)
    local database = _G[databaseName]
    if type(database) ~= "table" or type(database.Get) ~= "function" then
        return nil
    end
    forgetWhenQuestieIsReady()
    local remembered = localNames[databaseName][field]
    local known = remembered[id]
    if known ~= nil then
        return known or nil
    end
    if not questieSpeaksClientLanguage() then
        return nil
    end
    local ok, value = pcall(database.Get, id, field)
    if ok and type(value) == "string" and not isSecret(value) and value ~= "" then
        remembered[id] = value
        return value
    end
    remembered[id] = false
    return nil
end

-- The catalogue writes the title an NPC carries under its name in parentheses, "Innkeeper Grosk (Innkeeper)". Players
-- search by it ("cook"), so the localized name keeps one: Questie's title for the NPC, in the same place.
local function hasTitle(nameEn)
    return type(nameEn) == "string" and nameEn:find("%b()%s*$") ~= nil
end

-- The name of a creature or an object in the client's language, or nil: a target named by a template (a dungeon
-- entrance, a dock), without an ID, of another kind, or one Questie does not know.
function text.localName(target)
    if type(target) ~= "table" or target.nameKey ~= nil or not text.localNamesEnabled() then
        return nil
    end
    if OWN_LOCALES[GetLocale ~= nil and GetLocale() or "enUS"] then
        return nil
    end
    local entry = target.entry
    if type(entry) ~= "number" or isSecret(entry) then
        return nil
    end
    local databaseName = NPC_KINDS[target.kind] and "NpcDB" or OBJECT_KINDS[target.kind] and "ObjectDB" or nil
    if databaseName == nil then
        return nil
    end
    local name = questieField(databaseName, entry, "name")
    if name ~= nil and databaseName == "NpcDB" and hasTitle(target.nameEn) then
        local title = questieField(databaseName, entry, "subName")
        if title ~= nil then
            name = name .. " (" .. title .. ")"
        end
    end
    return name
end

-- The spoken name of a target (WowNav's WowVisionNavigationTargetName).
function text.targetName(target, german)
    if type(target) ~= "table" then
        return ""
    end
    local key = target.nameKey
    if german == nil then
        german = text.german()
    end
    local wing = german and type(target.nameWingDe) == "string" and target.nameWingDe ~= "" and target.nameWingDe
        or target.nameWing
    local wingTemplate = type(key) == "string" and DYN_WING[key] or nil
    if wingTemplate ~= nil and type(wing) == "string" and wing ~= "" then
        return string.format(wingTemplate, placeName(target) or L["unknown destination"], wing) .. nameSuffix(target)
    end
    local template = type(key) == "string" and DYN[key] or nil
    if template ~= nil then
        if not template:find("%s", 1, true) then
            return template .. nameSuffix(target)
        end
        return string.format(template, placeName(target) or L["unknown destination"]) .. nameSuffix(target)
    end
    local english, deutsch = target.nameEn, target.nameDe
    if not german then
        local localName = text.localName(target)
        if localName ~= nil then
            return localName .. nameSuffix(target)
        end
    end
    if german and type(deutsch) == "string" and deutsch ~= "" then
        return deutsch .. nameSuffix(target)
    end
    if type(english) == "string" and english ~= "" then
        return english .. nameSuffix(target)
    end
    if type(deutsch) == "string" and deutsch ~= "" then
        return deutsch .. nameSuffix(target)
    end
    return tostring(target.id or "")
end

-- category keys of the data (ReadMe section 7)
local CATEGORY = {
    quest_giver = L["quest giver"], trainer = L["trainer"], vendor = L["vendor"],
    flight_master = L["flight master"], innkeeper = L["innkeeper"], banker = L["banker"],
    stable_master = L["stable master"], auctioneer = L["auctioneer"], spirit_healer = L["spirit healer"],
    spirit_guide = L["spirit guide"], npc_or_mob = L["NPC or mob"], chest = L["object"],
    herb_or_ore = L["herb or ore"], object = L["object"], quest_item = L["quest item"],
    interaction_object = L["interaction object"], mailbox = L["mailbox"], anvil = L["anvil"], forge = L["forge"],
    door = L["door"], book = L["book"], chair = L["chair"], sign = L["sign"], fishing_spot = L["fishing spot"],
    switch = L["switch"], trap = L["trap"], spell_focus = L["spell focus"], capture_point = L["capture point"],
    destructible_building = L["destructible building"], guild_bank = L["guild bank"], trapdoor = L["trapdoor"],
    waypoint = L["waypoint"], orientation = L["orientation point"], transport = L["transport"], live = L["live target"],
    zone_transition = L["zone transition"], transit = L["transit"], boat = L["ship"], tram = L["tram"],
    dungeon = L["dungeon"], portal = L["portal"], zeppelin = L["zeppelin"], lift = L["elevator"], dive = L["dive"],
    cave = L["cave"], quest_explore = L["quest exploration"],
}

-- Automatic waypoints are named by their height in whole yards only (his auto_prefix_z: "the player finds re-entry
-- points on the right level"); their type (his AUTO_TYPES) is not said. Every waypoint of the data has its height; one
-- without would be said so, never as height 0.
function text.autoName(z)
    if type(z) ~= "number" or z ~= z or z == math.huge or z == -math.huge then
        return L["Auto, height unknown"]
    end
    return string.format(L["Auto, height %d"], math.floor(z + 0.5))
end

-- What a list row adds to a target's name after its resolution (his TargetSelection:Describe): inexact by how much,
-- a floor to choose, no network point, water surface; "" when there is nothing to add.
function text.describe(result)
    if type(result) ~= "table" then
        return ""
    end
    local out = ""
    local yards = result.delta3D or result.deltaXY or 0
    if result.quality == "approximate" and yards >= 1 then
        out = WowVisionNavigationText("desc_inexact", yards,
            result.zUnknown and WowVisionNavigationText("desc_horizontal_unknown")
                or (result.zOutOfTolerance and WowVisionNavigationText("desc_vertical") or ""))
    elseif result.quality == "ambiguous" then
        out = WowVisionNavigationText(result.levelUnknown and "desc_level_unknown" or "desc_pick_height")
    elseif result.quality == "unroutable" then
        out = WowVisionNavigationText("desc_no_point")
    end
    if result.normalizedWater then
        out = out .. WowVisionNavigationText("desc_water", result.divingDepth or 0)
    end
    return out
end

-- The spoken categories of a target, "trainer, vendor"; nil when it has none worth saying.
function text.categories(target)
    local list = target.category
    if type(list) == "string" then
        list = { list }
    end
    if type(list) ~= "table" then
        return nil
    end
    local out = {}
    for _, key in ipairs(list) do
        local name = CATEGORY[key]
        if name == nil and type(key) == "string" then
            local number = key:match("^object_type_(%d+)$")
            name = number and string.format(L["object type %s"], number) or nil
        end
        if name ~= nil then
            out[#out + 1] = name
        end
    end
    if #out == 0 then
        return nil
    end
    return table.concat(out, ", ")
end
