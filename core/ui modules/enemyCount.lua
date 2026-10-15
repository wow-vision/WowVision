-- Enemy count rules, kept free of frames so they run in the headless tests.
-- See the combat module for when they run.
--
-- The count comes from enemy nameplates only: what a sighted player sees as
-- plates of enemies in the fight. Nothing is remembered between counts.
-- Every recount starts from the plates that exist right now, so a plate
-- token that moves to another enemy, a missed event or a mob that leashes
-- cannot make the number drift. No unit identity is needed either: one
-- enemy has at most one plate. That matters on Forever and Retail, where an
-- enemy's GUID and name are secret while its plate's threat state is not
-- (UnitThreatSituation between a group member and a nameplate, measured on
-- Forever 1.60.1: 500 answers, none secret).
local enemyCount = {}
WowVision.enemyCount = enemyCount

-- "group": enemies that you, your pet or a group member are fighting.
-- "player": enemies attacking you (you hold their aggro).
enemyCount.modes = { "group", "player" }

local ELITE = { elite = true, rareelite = true, worldboss = true }

-- api, a table of the game calls the count needs:
--   plates()                    the nameplate unit tokens that exist
--   group()                     player, pet, and the group's units
--   exists(unit), reaction(unit), isDead(unit), inCombat(unit),
--   classification(unit)
--   threat(member, unit)        UnitThreatSituation
--   isSecret(value)

-- Hostile by reaction (4 or lower: hated to neutral). Unlike "can attack",
-- the reaction holds while an enemy is immune or not attackable mid-fight,
-- which bosses and adds often are while still in the fight.
local function isHostile(api, unit)
    local reaction = api.reaction(unit)
    if reaction == nil or api.isSecret(reaction) then
        return false
    end
    return reaction <= 4
end

-- Whether a group member is on the enemy's threat list. A secret answer is
-- not nil, so it still means "on the list".
local function groupFights(api, unit, group)
    for _, member in ipairs(group) do
        if api.exists(member) and api.threat(member, unit) ~= nil then
            return true
        end
    end
    return false
end

-- Whether you hold the enemy's aggro (threat status 2 or 3). A secret
-- status cannot be compared; it counts, the way a secret "on the list" does.
local function attacksPlayer(api, unit)
    local status = api.threat("player", unit)
    if status == nil then
        return false
    end
    if api.isSecret(status) then
        return true
    end
    return status >= 2
end

-- The number of enemies for a mode. `skip` is a plate token to leave out:
-- the plate the game is removing right now still exists during its event.
function enemyCount.count(api, mode, eliteOnly, skip)
    local group = mode == "group" and api.group() or nil
    local count = 0
    for _, unit in ipairs(api.plates()) do
        -- An enemy out of combat has an empty threat list: skipping it first
        -- spares the walk over a raid's members for every idle plate.
        if unit ~= skip and isHostile(api, unit) and not api.isDead(unit) and api.inCombat(unit) then
            local counts
            if mode == "player" then
                counts = attacksPlayer(api, unit)
            else
                counts = groupFights(api, unit, group)
            end
            if counts and eliteOnly then
                counts = ELITE[api.classification(unit)] == true
            end
            if counts then
                count = count + 1
            end
        end
    end
    return count
end

-- Holds a new count back until it stayed the same for `hold` seconds, so a
-- plate that blinks out and back is not spoken twice. Feed it every recount;
-- it returns the number to say, once.
local Settler = WowVision.Class("EnemyCountSettler")
enemyCount.Settler = Settler

function Settler:initialize(hold)
    self.hold = hold
    self.said = 0
    self.pending = nil
    self.since = nil
end

function Settler:update(count, now)
    if count == self.said then
        self.pending = nil
        return nil
    end
    if count ~= self.pending then
        self.pending = count
        self.since = now
        return nil
    end
    if now - self.since >= self.hold then
        self.said = count
        self.pending = nil
        return count
    end
    return nil
end
