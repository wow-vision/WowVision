-- Headless only (tools/headless-tests.lua loads module.lua against a stand-in
-- module and hands it over here): who the monitor watches follows its
-- settings at once.
local testRunner = WowVision.testing.testRunner
local module = WowVision.groupHealth._moduleTestHarness

-- The game as a group of `size` with the player first: a party (player plus
-- party1..) or a raid in groups of five (raid1 is the player).
local function withGroup(kind, size, inCombat, test)
    local names = {
        "IsInRaid",
        "IsInGroup",
        "InCombatLockdown",
        "UnitExists",
        "UnitGUID",
        "UnitIsUnit",
        "UnitIsDeadOrGhost",
        "UnitGroupRolesAssigned",
        "GetRaidRosterInfo",
    }
    local saved = {}
    for _, name in ipairs(names) do
        saved[name] = _G[name]
    end
    local function exists(unit)
        local index = tonumber(unit:match("^party(%d)$"))
        if index ~= nil then
            return kind == "party" and index < size
        end
        index = tonumber(unit:match("^raid(%d+)$"))
        if index ~= nil then
            return kind == "raid" and index <= size
        end
        return unit == "player"
    end
    IsInRaid = function()
        return kind == "raid"
    end
    IsInGroup = function()
        return true
    end
    InCombatLockdown = function()
        return inCombat
    end
    UnitExists = exists
    UnitGUID = function(unit)
        if unit == "raid1" then
            unit = "player"
        end
        return exists(unit) and ("guid-" .. unit) or nil
    end
    UnitIsUnit = function(a, b)
        return a == b or (a == "raid1" and b == "player")
    end
    UnitIsDeadOrGhost = function()
        return false
    end
    UnitGroupRolesAssigned = function()
        return "DAMAGER"
    end
    GetRaidRosterInfo = function(index)
        if kind ~= "raid" or index > size then
            return nil
        end
        return "member" .. index, 0, math.ceil(index / 5)
    end
    local savedSettings = {
        includeSelf = module.settings.includeSelf,
        watchParty = module.settings.watchParty,
        watchRaid = module.settings.watchRaid,
    }
    local savedDispel = {}
    for key, value in pairs(module.settings.dispellable) do
        savedDispel[key] = value
    end
    local ok, err = pcall(test)
    for key, value in pairs(savedSettings) do
        module.settings[key] = value
    end
    for key, value in pairs(savedDispel) do
        module.settings.dispellable[key] = value
    end
    for key in pairs(module.settings.raidGroups) do
        module.settings.raidGroups[key] = true
    end
    module.enabled = false
    module.members, module.aliases, module.raidMode, module.rosterDirty = {}, {}, nil, false
    module.dispelMembers, module.dispelAliases, module.dispelRaidMode, module.dispelDirty = {}, {}, nil, {}
    for _, name in ipairs(names) do
        _G[name] = saved[name]
    end
    if not ok then
        error(err, 0)
    end
end

local function count(members)
    local n = 0
    for _ in pairs(members) do
        n = n + 1
    end
    return n
end

-- A raid group switch as the settings screen sets it: through the
-- category's own sub-field, on the category's table.
local function setRaidGroup(group, value)
    local category = module.settings.class:getField("raidGroups")
    for _, subField in ipairs(category:getSubFields()) do
        if subField.key == "group" .. group then
            subField:set(module.settings.raidGroups, value)
        end
    end
end

-- A dispel switch as the settings screen sets it.
local function setDispel(key, value)
    local category = module.settings.class:getField("dispellable")
    for _, subField in ipairs(category:getSubFields()) do
        if subField.key == key then
            subField:set(module.settings.dispellable, value)
        end
    end
end

testRunner:addSuite("GroupHealthModule", {
    ["Watch Party turned on in a group watches the party at once"] = function(t)
        withGroup("party", 5, false, function()
            module.settings.watchParty = false
            module.enabled = true
            module:rebuild()
            t:assertEqual(count(module.members), 1)
            module.settings.watchParty = true
            t:assertEqual(count(module.members), 5)
            t:assertEqual(module.members.party4.number, 5)
        end)
    end,

    ["Include Yourself turned off drops the player at once"] = function(t)
        withGroup("party", 3, false, function()
            module.enabled = true
            module:rebuild()
            t:assertNotNil(module.members.player)
            module.settings.includeSelf = false
            t:assertNil(module.members.player)
            t:assertEqual(count(module.members), 2)
        end)
    end,

    ["a raid group switched off leaves the watch at once"] = function(t)
        withGroup("raid", 10, false, function()
            module.enabled = true
            module:rebuild()
            t:assertEqual(count(module.members), 10)
            setRaidGroup(2, false)
            t:assertEqual(count(module.members), 5)
            t:assertNil(module.members.raid6)
        end)
    end,

    ["in a raid fight a switch waits for the fight's end, so numbers never move"] = function(t)
        withGroup("raid", 10, true, function()
            module.enabled = true
            module.raidMode = true
            module.members = { raid1 = { unit = "raid1", number = 1 } }
            setRaidGroup(2, false)
            t:assertEqual(count(module.members), 1)
            t:assertTrue(module.rosterDirty)
        end)
    end,

    ["the dispel list watches the party by its own switch, on by default"] = function(t)
        withGroup("party", 5, false, function()
            module.settings.watchParty = false
            module.enabled = true
            module:rebuild()
            t:assertEqual(count(module.dispelMembers), 0)
            setDispel("enabled", true)
            t:assertEqual(count(module.members), 1)
            t:assertEqual(count(module.dispelMembers), 5)
            t:assertEqual(module.dispelMembers.party4.number, 5)
            setDispel("watchParty", false)
            t:assertEqual(count(module.dispelMembers), 1)
            t:assertEqual(count(module.members), 1)
        end)
    end,

    ["the dispel list takes Include Yourself from the monitor"] = function(t)
        withGroup("party", 3, false, function()
            module.enabled = true
            setDispel("enabled", true)
            t:assertNotNil(module.dispelMembers.player)
            module.settings.includeSelf = false
            t:assertNil(module.dispelMembers.player)
            t:assertEqual(count(module.dispelMembers), 2)
        end)
    end,

    ["the dispel list watches a raid only by its own switch, in the monitor's raid groups"] = function(t)
        withGroup("raid", 10, false, function()
            module.enabled = true
            setDispel("enabled", true)
            t:assertNil(module.dispelMembers.raid2)
            t:assertEqual(count(module.members), 10)
            setDispel("watchRaid", true)
            t:assertEqual(count(module.dispelMembers), 10)
            setRaidGroup(2, false)
            t:assertEqual(count(module.dispelMembers), 5)
            t:assertNil(module.dispelMembers.raid6)
            module.settings.watchRaid = false
            t:assertEqual(count(module.dispelMembers), 5)
        end)
    end,

    ["in a raid fight the dispel list waits for the fight's end too"] = function(t)
        withGroup("raid", 10, true, function()
            module.enabled = true
            module.settings.dispellable.enabled = true
            module.settings.dispellable.watchRaid = true
            module.dispelRaidMode = true
            module.dispelMembers = { raid1 = { unit = "raid1", number = 1 } }
            setRaidGroup(2, false)
            t:assertEqual(count(module.dispelMembers), 1)
            t:assertTrue(module.rosterDirty)
        end)
    end,

    ["while the monitor is off, a change builds no list"] = function(t)
        withGroup("party", 5, false, function()
            module.settings.watchParty = false
            module.settings.watchParty = true
            t:assertEqual(count(module.members), 0)
        end)
    end,
})
