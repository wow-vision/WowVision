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

-- Whether the enemy on a plate counts for a mode.
local function counts(api, mode, group, eliteOnly, unit)
    -- An enemy out of combat has an empty threat list: skipping it first
    -- spares the walk over a raid's members for every idle plate.
    if not (isHostile(api, unit) and not api.isDead(unit) and api.inCombat(unit)) then
        return false
    end
    local fights
    if mode == "player" then
        fights = attacksPlayer(api, unit)
    else
        fights = groupFights(api, unit, group)
    end
    if fights and eliteOnly then
        fights = ELITE[api.classification(unit)] == true
    end
    return fights
end

-- The number of enemies for a mode. `skip` is a plate token to leave out:
-- the plate the game is removing right now still exists during its event.
function enemyCount.count(api, mode, eliteOnly, skip)
    local group = mode == "group" and api.group() or nil
    local count = 0
    for _, unit in ipairs(api.plates()) do
        if unit ~= skip and counts(api, mode, group, eliteOnly, unit) then
            count = count + 1
        end
    end
    return count
end

-- Crowd control -----------------------------------------------------------
-- With the crowd control setting on, the count says only the enemies still
-- free to fight, and crowd control is said apart: its shown text when it
-- lands, a sound when it ends. The shown text is the loss-of-control text
-- for players ("Stunned"; the game keeps none for NPCs) and the crowd
-- control aura's name for NPCs ("Polymorph"). Both are secret on WoW:
-- Forever in combat. Secret text can be stored, joined and spoken, never
-- compared, so two of the same kind cannot be grouped, and the tracker below
-- keys everything on plate tokens and plain counts.
--
-- More api calls for it:
--   controlCount(unit)          loss-of-control effects on the unit (number,
--                               maybe secret), nil when unknown
--   controlAuras(unit)          crowd control auras its plate shows
--                               (readable number), nil when unknown
--   controlText(unit)           the shown text, maybe secret, nil when none

-- Whether the enemy is crowd controlled, from whichever count is readable.
-- A secret count cannot be compared, so it decides nothing.
function enemyCount.isControlled(api, unit)
    local count = api.controlCount(unit)
    if count ~= nil and not api.isSecret(count) and count > 0 then
        return true
    end
    local auras = api.controlAuras(unit)
    return auras ~= nil and not api.isSecret(auras) and auras > 0
end

-- The fighting enemies split in two lists of plate tokens: free and
-- crowd controlled.
function enemyCount.scan(api, mode, eliteOnly, skip)
    local group = mode == "group" and api.group() or nil
    local free, controlled = {}, {}
    for _, unit in ipairs(api.plates()) do
        if unit ~= skip and counts(api, mode, group, eliteOnly, unit) then
            if enemyCount.isControlled(api, unit) then
                table.insert(controlled, unit)
            else
                table.insert(free, unit)
            end
        end
    end
    return free, controlled
end

-- What the settler holds still: the free count and which plates are
-- controlled. A control that breaks while another enemy dies leaves the
-- count the same but changes the plates, so it is still said.
function enemyCount.controlKey(free, controlled)
    local tokens = {}
    for i, unit in ipairs(controlled) do
        tokens[i] = unit
    end
    table.sort(tokens)
    return #free .. "|" .. table.concat(tokens, ",")
end

-- The key of no fight at all: what a settler for control keys starts on.
enemyCount.CONTROL_IDLE = "0|"

-- Turns each settled change into what to say:
--   count     the free count to say, or nil
--   texts     shown texts to say after it (nil in a list entry: no text
--             could be read)
--   ended     a control ended on an enemy still in the fight
-- The rules: the number is always the free enemies. A control that lands
-- says its text alone (the number drops by one, which needs no saying); one
-- that ends plays the sound and says the new number; when only controlled
-- enemies are left, "0" is followed by their texts so it is not taken for
-- the fight's end; a controlled enemy that dies says nothing by itself.
local ControlTracker = WowVision.Class("EnemyControlTracker")
enemyCount.ControlTracker = ControlTracker

function ControlTracker:initialize()
    self.freeCount = 0
    self.free = {}
    -- plate token -> its shown text as read when the control landed (false
    -- when none could be read), kept for the "0" line.
    self.controlled = {}
end

-- A plate token the game removed may come back on another enemy.
function ControlTracker:forget(unit)
    self.controlled[unit] = nil
    self.free[unit] = nil
end

local function textsOf(controlled, units)
    local texts = {}
    for i, unit in ipairs(units) do
        local text = controlled[unit]
        if text == false then
            text = nil
        end
        texts[i] = text
    end
    return texts, #units
end

function ControlTracker:change(free, controlled, readText)
    local was = self.controlled
    local wasFree = self.free
    local now = {}
    local landed, landedFromFree = {}, 0
    for _, unit in ipairs(controlled) do
        if was[unit] ~= nil then
            now[unit] = was[unit]
        else
            local text = readText(unit)
            if text == nil then
                text = false
            end
            now[unit] = text
            table.insert(landed, unit)
            if wasFree[unit] then
                landedFromFree = landedFromFree + 1
            end
        end
    end
    local ended = false
    local freeSet = {}
    for _, unit in ipairs(free) do
        freeSet[unit] = true
        if was[unit] ~= nil then
            ended = true
        end
    end
    local freeCount = #free
    local message = { ended = ended }
    local sorted = {}
    for i, unit in ipairs(controlled) do
        sorted[i] = unit
    end
    table.sort(sorted)
    table.sort(landed)
    if freeCount == 0 and #controlled > 0 and (freeCount ~= self.freeCount or ended) then
        message.count = 0
        message.texts, message.textCount = textsOf(now, sorted)
    elseif ended then
        message.count = freeCount
        if #landed > 0 then
            message.texts, message.textCount = textsOf(now, landed)
        end
    elseif #landed > 0 then
        message.texts, message.textCount = textsOf(now, landed)
        -- The number is said too when it moved by more than the landings.
        if freeCount ~= self.freeCount - landedFromFree then
            message.count = freeCount
        end
    elseif freeCount ~= self.freeCount then
        message.count = freeCount
    end
    self.freeCount = freeCount
    self.free = freeSet
    self.controlled = now
    if message.count == nil and message.texts == nil and not ended then
        return nil
    end
    return message
end

-- The words of a message: "1, Polymorphed". `join` carries secret texts
-- (secrets.join); `noText` stands in where no text could be read.
function enemyCount.controlWords(message, noText, join)
    local parts = {}
    if message.count ~= nil then
        table.insert(parts, tostring(message.count))
    end
    for i = 1, message.textCount or 0 do
        local text = message.texts[i]
        if text == nil then
            text = noText
        end
        table.insert(parts, text)
    end
    if #parts == 0 then
        return nil
    end
    return join(parts, ", ")
end

-- Holds a new count back until it stayed the same for `hold` seconds, so a
-- plate that blinks out and back is not spoken twice. Feed it every recount;
-- it returns the number to say, once.
local Settler = WowVision.Class("EnemyCountSettler")
enemyCount.Settler = Settler

-- `said` is what counts as already said at the start: 0 for plain counts,
-- CONTROL_IDLE for control keys.
function Settler:initialize(hold, said)
    self.hold = hold
    self.said = said or 0
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
