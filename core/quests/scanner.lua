local quests = WowVision.base.quests
local scanner = WowVision.base.scanner
local L = quests.L

-- The scanner's Quests and NPCs categories, built from the quest adapter
-- when the scanner opens. Subcategories resolve lazily (their children
-- are functions), so opening the scanner costs only what is expanded.
--
-- Quests
--   Nearby        available quests, nearest giver first; Enter beacons the
--                 giver; a giver with several spawns expands to them
--   In Progress   the log; Enter beacons the first unfinished objective's
--                 nearest target (the turn-in when complete), likewise
--                 expanding to that target's spawns
-- NPCs
--   Quest Givers  givers of nearby quests, with their quests beneath
--   Vendors ... Spirit Healers, Class Trainers, Mailboxes, Rares
--                 the zone's NPCs by role within the scan radius

local Adapter = WowVision.quests.Adapter

local function unknown()
    return L["Unknown"]
end

-- One node per spawn of a target: "Valley of the Four Winds, Halfhill
-- Market, 80 yards, ahead". Spawns Questie believes are in the player's
-- phase come first, nearest first; the rest follow marked "phased out",
-- still there to pick when Questie's guess is wrong; other continents
-- last.
local function spawnNodes(target)
    local spawns = {}
    for _, spawn in ipairs(target.spawns) do
        tinsert(spawns, spawn)
    end
    table.sort(spawns, Adapter.spawnBefore)
    local out = {}
    for _, spawn in ipairs(spawns) do
        tinsert(out, {
            key = "spawn:" .. tostring(spawn.mapId) .. ":" .. tostring(spawn.x) .. ":" .. tostring(spawn.y),
            label = quests:placeName(spawn) or unknown(),
            detail = spawn.phased and L["phased out"] or nil,
            x = spawn.wx,
            y = spawn.wy,
        })
    end
    return out
end

-- A scanner node for a resolved target. Enter beacons its nearest spawn;
-- a target with several spawns expands to one node per spawn so the
-- player can pick the right one (Ella at the farm or Ella at the market).
local function targetNode(target, seen)
    local label = target.name or unknown()
    if target.item ~= nil and target.item.name ~= nil then
        label = target.item.name .. " " .. L["from"] .. " " .. label
    end
    local key = target.kind .. ":" .. tostring(target.id) .. ":" .. tostring(target.source or "")
    if seen ~= nil then
        local count = (seen[key] or 0) + 1
        seen[key] = count
        if count > 1 then
            key = key .. ":" .. count
        end
    end
    local node = { key = key, label = label, onArrive = target.onArrive }
    if target.nearest ~= nil then
        node.x, node.y = target.nearest.wx, target.nearest.wy
    end
    local detail = {}
    if target.subName ~= nil and target.subName ~= "" then
        tinsert(detail, target.subName)
    end
    if target.seen then
        tinsert(detail, L["seen"])
    end
    if target.indoors then
        tinsert(detail, L["indoors"])
    end
    if #target.spawns > 1 then
        tinsert(detail, tostring(#target.spawns) .. " " .. L["spawns"])
        node.children = function()
            return spawnNodes(target)
        end
    elseif target.nearest ~= nil then
        local place = quests:placeName(target.nearest)
        if place ~= nil then
            tinsert(detail, place)
        end
    end
    if #detail > 0 then
        node.detail = table.concat(detail, ", ")
    end
    return node
end

local function targetNodes(targets)
    local out = {}
    local seen = {}
    for _, target in ipairs(targets or {}) do
        tinsert(out, targetNode(target, seen))
    end
    return out
end

local function firstTarget(targets)
    local first = targets ~= nil and targets[1] or nil
    if first ~= nil and first.nearest ~= nil then
        return first
    end
    return nil
end

-- Point a quest node at a target: Enter beacons the nearest spawn, and a
-- target with several spawns (NPCs move around) expands to one node per
-- spawn so the player can pick another.
local function pointAt(node, target)
    if target == nil or target.nearest == nil then
        return node
    end
    node.x, node.y = target.nearest.wx, target.nearest.wy
    node.onArrive = target.onArrive
    if #target.spawns > 1 then
        node.detail = (node.detail ~= nil and (node.detail .. ", ") or "")
            .. tostring(#target.spawns) .. " " .. L["spawns"]
        node.children = function()
            return spawnNodes(target)
        end
    end
    return node
end

local function questDetails(questId)
    return function()
        local quest = quests:quest(questId)
        local lines = {}
        if quest ~= nil and type(quest.objectivesText) == "table" then
            for _, line in ipairs(quest.objectivesText) do
                tinsert(lines, line)
            end
        end
        return lines
    end
end

-- Quest nodes point at the one place that matters now; Enter beacons it,
-- and when that place is an NPC with several spawns the node expands to
-- them.

-- A nearby quest points at its giver. A giver only seen with the quest
-- icon (no quest data) is the NPC itself, tagged "seen"; the minimap
-- scanner adds whether it offers a quest or takes one in.
local SEEN_STATUS = {
    available = L["quest available"],
    turnIn = L["turn in"],
}

local function nearbyQuestNode(entry)
    if entry.seenGiver then
        local detail = { L["seen"] }
        if SEEN_STATUS[entry.status] ~= nil then
            tinsert(detail, SEEN_STATUS[entry.status])
        end
        if entry.flag == "trivial" then
            tinsert(detail, L["low level"])
        end
        if entry.indoors then
            tinsert(detail, L["indoors"])
        end
        return pointAt({
            key = "seenGiver:" .. tostring(entry.starter.id),
            label = entry.name or unknown(),
            detail = table.concat(detail, ", "),
        }, entry.starter)
    end
    local detail = L["Level"] .. " " .. tostring(entry.level)
    if entry.daily then
        detail = detail .. ", " .. L["Daily"]
    elseif entry.repeatable then
        detail = detail .. ", " .. L["Repeatable"]
    end
    return pointAt({
        key = "quest:" .. entry.questId,
        label = entry.name or unknown(),
        detail = detail,
        details = questDetails(entry.questId),
    }, entry.starter)
end

-- A quest in progress points at the nearest target of its first
-- unfinished objective, or the turn-in once complete.
local function inProgressNode(entry)
    local node = {
        key = "quest:" .. entry.questId,
        label = entry.title or unknown(),
        details = questDetails(entry.questId),
    }
    local unfinished = 0
    for _, objective in ipairs(entry.objectives) do
        if not objective.finished then
            unfinished = unfinished + 1
        end
    end
    if entry.complete then
        node.detail = L["Complete"]
    elseif entry.failed then
        node.detail = L["Failed"]
    elseif #entry.objectives > 0 then
        node.detail = string.format("%d %s %d", #entry.objectives - unfinished, L["of"], #entry.objectives)
    end
    if entry.known then
        local target = nil
        if entry.complete or unfinished == 0 then
            target = firstTarget(quests:targets(entry.questId, Adapter.phases.finish))
        else
            for index, objective in ipairs(entry.objectives) do
                if not objective.finished then
                    target = firstTarget(quests:objectiveTargets(entry.questId, index))
                    if target ~= nil then
                        break
                    end
                end
            end
        end
        pointAt(node, target)
    end
    return node
end

local function loadingNode()
    return { key = "loading", label = L["Loading"] }
end

scanner:registerProvider({
    key = "quests",
    label = L["Quests"],
    order = 10,
    build = function(ctx)
        if not quests:hasSource() then
            return { { key = "missing", label = L["No quest data source"] } }
        end
        if not quests:isReady() then
            return { loadingNode() }
        end
        return {
            {
                key = "nearby",
                label = L["Nearby"],
                children = function()
                    if not quests:nearbyReady() then
                        return { loadingNode() }
                    end
                    local out = {}
                    for _, entry in ipairs(quests:nearbyQuests({ maxCount = ctx.maxEntries })) do
                        tinsert(out, nearbyQuestNode(entry))
                    end
                    return out
                end,
            },
            {
                key = "inProgress",
                label = L["In Progress"],
                children = function()
                    local out = {}
                    for _, entry in ipairs(quests:inProgress()) do
                        tinsert(out, inProgressNode(entry))
                    end
                    return out
                end,
            },
        }
    end,
})

local roleLabels = {
    vendor = L["Vendors"],
    repair = L["Repair"],
    trainer = L["Trainers"],
    flightMaster = L["Flight Masters"],
    innkeeper = L["Innkeepers"],
    banker = L["Bankers"],
    auctioneer = L["Auctioneers"],
    stableMaster = L["Stable Masters"],
    battlemaster = L["Battlemasters"],
    spiritHealer = L["Spirit Healers"],
}

-- NPCs seen this session (see seen.lua), as targets of one role.
local function seenTargets(roleKey, radius)
    return WowVision.quests.seen:npcs(roleKey, radius)
end

-- Database targets plus seen ones, nearest first. A seen NPC whose name
-- the database already lists is left out: the database wins.
local function withSeen(targets, roleKey, ctx)
    local seen = seenTargets(roleKey, ctx.radius)
    if #seen == 0 then
        return targets
    end
    local out, names = {}, {}
    for _, target in ipairs(targets) do
        if target.name ~= nil then
            names[target.name] = true
        end
        tinsert(out, target)
    end
    for _, target in ipairs(seen) do
        if not names[target.name] then
            tinsert(out, target)
        end
    end
    table.sort(out, function(a, b)
        if a.distance == nil then
            return false
        end
        if b.distance == nil then
            return true
        end
        return a.distance < b.distance
    end)
    while #out > ctx.maxEntries do
        tremove(out)
    end
    return out
end

-- Givers of nearby quests, one node per giver with its quests beneath.
local function questGiverNodes(ctx)
    local byGiver = {}
    local order = {}
    for _, entry in ipairs(quests:nearbyQuests({ maxCount = ctx.maxEntries })) do
        local starter = entry.starter
        local key = starter.kind .. ":" .. tostring(starter.id)
        local giver = byGiver[key]
        if giver == nil then
            giver = targetNode(starter, nil)
            giver.key = key
            giver.quests = {}
            byGiver[key] = giver
            tinsert(order, giver)
        end
        tinsert(giver.quests, entry)
    end
    for index, giver in ipairs(order) do
        local entries = giver.quests
        giver.quests = nil
        if entries[1].seenGiver then
            -- No quests known beneath a seen giver: the NPC is the node.
            order[index] = nearbyQuestNode(entries[1])
        else
            giver.detail = tostring(#entries) .. " " .. L["quests"]
            giver.children = function()
                local out = {}
                for _, entry in ipairs(entries) do
                    tinsert(out, nearbyQuestNode(entry))
                end
                return out
            end
        end
    end
    return order
end

scanner:registerProvider({
    key = "npcs",
    label = L["NPCs"],
    order = 20,
    build = function(ctx)
        if not quests:hasSource() then
            return { { key = "missing", label = L["No quest data source"] } }
        end
        if not quests:isReady() then
            return { loadingNode() }
        end
        local opts = { radius = ctx.radius, maxCount = ctx.maxEntries }
        local categories = {
            {
                key = "questGivers",
                label = L["Quest Givers"],
                children = function()
                    return questGiverNodes(ctx)
                end,
            },
        }
        -- The native source knows quest points only; its NPC categories
        -- come from the minimap scanner alone and show once it saw some.
        local hasIndex = quests:hasNpcIndex()
        -- Role buckets share one pass over the zone index; resolved on
        -- the first role expanded, then reused by the others.
        local buckets = nil
        local function bucket(key)
            if buckets == nil then
                buckets = quests:npcsByRole(opts)
            end
            return buckets[key] or {}
        end
        local roles = {}
        for _, role in ipairs(Adapter.roles) do
            local roleKey = role.key
            tinsert(roles, {
                key = roleKey,
                label = roleLabels[roleKey] or roleKey,
                needsIndex = true,
                index = function()
                    return bucket(roleKey)
                end,
            })
        end
        tinsert(roles, {
            key = "classTrainers",
            label = L["Class Trainers"],
            index = function()
                return quests:placeTargets("npc", quests:townsfolk("Class Trainer"), opts)
            end,
        })
        tinsert(roles, {
            key = "mailboxes",
            label = L["Mailboxes"],
            index = function()
                return quests:placeTargets("object", quests:townsfolk("Mailbox"), opts)
            end,
        })
        tinsert(roles, { key = "other", label = L["Other NPCs"] })
        tinsert(roles, {
            key = "rares",
            label = L["Rares"],
            needsIndex = true,
            index = function()
                return bucket("rare")
            end,
        })
        for _, role in ipairs(roles) do
            local fromIndex = hasIndex and role.index ~= nil
            if fromIndex or #seenTargets(role.key, ctx.radius) > 0 then
                tinsert(categories, {
                    key = role.key,
                    label = role.label,
                    children = function()
                        if fromIndex and role.needsIndex and not quests:indexReady() then
                            return { loadingNode() }
                        end
                        local targets = fromIndex and role.index() or {}
                        return targetNodes(withSeen(targets, role.key, ctx))
                    end,
                })
            end
        end
        return categories
    end,
})
