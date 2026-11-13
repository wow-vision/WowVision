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

-- "group": enemies that you, your pet or a group member are fighting; in a
-- group, while one of you is in combat, also any enemy in combat that nobody
-- outside it has tapped.
-- "player": enemies attacking you (you hold their aggro).
enemyCount.modes = { "group", "player" }

local ELITE = { elite = true, rareelite = true, worldboss = true }

-- api, a table of the game calls the count needs:
--   plates()                    the nameplate unit tokens that exist
--   group()                     player, pet, and the group's units
--   exists(unit), reaction(unit), isDead(unit), inCombat(unit),
--   classification(unit)
--   threat(member, unit)        UnitThreatSituation
--   tapDenied(unit)             UnitIsTapDenied
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

-- Whether you are in a group and you, your pet or a member is in combat.
-- The combat flag of group units stayed readable in a WoW: Forever dungeon
-- (2026-11-13: it started 99 of 101 logged fights).
-- group is api.group(): outside a group only you and your pet
-- (utils.groupUnits), so more than two units means a group.
local function groupBusy(api, group)
    if #group <= 2 then
        return false
    end
    for _, member in ipairs(group) do
        if api.exists(member) then
            local inCombat = api.inCombat(member)
            if not api.isSecret(inCombat) and inCombat == true then
                return true
            end
        end
    end
    return false
end

-- What one count knows about your group (group mode only): `members` the
-- group's units, `busy` groupBusy, read on the first plate that asks and
-- kept for the rest of the count, so idle plates cost no walk over a raid.
local function groupView(api, mode)
    if mode ~= "group" then
        return nil
    end
    return { members = api.group(), busy = nil }
end

local function isBusy(api, view)
    if view.busy == nil then
        view.busy = groupBusy(api, view.members)
    end
    return view.busy
end

-- In a group: whether the enemy is in combat and nobody outside the group
-- has tapped it, which makes the fight the group's. Needed because the
-- client gets an enemy's threat list only once you are on it yourself:
-- in a WoW: Forever dungeon (2026-11-12, 44 fights) groupFights found
-- nothing until you were in combat, 1.5 to 22 seconds after the group.
-- Both are shown on the plate (in combat; a grey bar when tapped by
-- others). A secret answer to either is unknown and counts as no
-- (utils.groupTapped, sign 3 of the Target in Combat sound's rule).
-- Only while someone in the group is in combat (isBusy): an enemy that
-- attacks someone outside the group is not tapped until that player hits
-- it, and was counted without this for a second or two (dungeon
-- 2026-11-13: twice "1" with nobody in the group in combat).
local function groupHolds(api, unit, view)
    if not isBusy(api, view) then
        return false
    end
    return WowVision.utils.groupTapped(api.inCombat(unit), api.tapDenied(unit), api.isSecret)
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
local function counts(api, mode, view, eliteOnly, unit)
    -- An enemy out of combat has an empty threat list: skipping it first
    -- spares the walk over a raid's members for every idle plate.
    if not (isHostile(api, unit) and not api.isDead(unit) and api.inCombat(unit)) then
        return false
    end
    local fights
    if mode == "player" then
        fights = attacksPlayer(api, unit)
    else
        fights = groupHolds(api, unit, view) or groupFights(api, unit, view.members)
    end
    if fights and eliteOnly then
        fights = ELITE[api.classification(unit)] == true
    end
    return fights
end

-- The number of enemies for a mode. `skip` is a plate token to leave out:
-- the plate the game is removing right now still exists during its event.
function enemyCount.count(api, mode, eliteOnly, skip)
    local view = groupView(api, mode)
    local count = 0
    for _, unit in ipairs(api.plates()) do
        if unit ~= skip and counts(api, mode, view, eliteOnly, unit) then
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
    local view = groupView(api, mode)
    local free, controlled = {}, {}
    for _, unit in ipairs(api.plates()) do
        if unit ~= skip and counts(api, mode, view, eliteOnly, unit) then
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

-- This many controls said together become a count: an area spell (Frost
-- Nova, a fear) would otherwise be a long list of the same name.
enemyCount.GROUP_AT = 3

-- The one name all texts share, when every one is readable and the same.
-- Secret names cannot be compared, so they never group by name.
local function sharedName(texts, count, isSecret)
    local first = texts[1]
    if first == nil or isSecret(first) then
        return nil
    end
    for i = 2, count do
        local text = texts[i]
        if text == nil or isSecret(text) or text ~= first then
            return nil
        end
    end
    return first
end

-- The words of a message: "1, Polymorph", "3 Frost Nova", "2 controlled".
-- options:
--   names     say the crowd control names; false says `noText` for all
--   noText    the word where no name is said ("controlled")
--   join      joins the parts and carries secret texts (secrets.join)
--   isSecret  secrets.isSecret
function enemyCount.controlWords(message, options)
    local noText = options.noText
    local parts = {}
    if message.count ~= nil then
        table.insert(parts, tostring(message.count))
    end
    local count = message.textCount or 0
    if count > 0 then
        if not options.names then
            table.insert(parts, count == 1 and noText or (count .. " " .. noText))
        elseif count >= enemyCount.GROUP_AT then
            table.insert(parts, count .. " " .. (sharedName(message.texts, count, options.isSecret) or noText))
        else
            for i = 1, count do
                local text = message.texts[i]
                if text == nil then
                    text = noText
                end
                table.insert(parts, text)
            end
        end
    end
    if #parts == 0 then
        return nil
    end
    return options.join(parts, ", ")
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

-- Lost lines ----------------------------------------------------------------
-- A number waiting in WowVision's speech queue is thrown away when any
-- speech stop empties the queue: an alert that interrupts (a target change,
-- an error message) or a key that does. The settler takes it as said, so
-- the number heard before stood. In a WoW: Forever dungeon (2026-11-13, 101
-- fights in 84 minutes) 29 of 567 lines were lost, every one while other
-- speech played, and the old number stood up to 63 s. A lost number is said
-- again once, when no newer number came within RESAY_AFTER seconds of it:
-- 13 times in that run.
--
-- A stop replaces the queue table with a new one (tbc/, mists/, retail/
-- speech.lua) and never takes a line out of the old one, so a line still in
-- the old table after the swap was never sent. One the queue sent is no
-- longer in it.
enemyCount.RESAY_AFTER = 5

local LostLine = WowVision.Class("EnemyCountLostLine")
enemyCount.LostLine = LostLine

function LostLine:initialize()
    self.item = nil
end

local function holds(queue, item)
    for _, entry in ipairs(queue) do
        if entry == item then
            return true
        end
    end
    return false
end

-- A number fired: `queue` the speech queue it was put in, `item` its line
-- there (nil when it was sent at once or not queued: nothing to watch),
-- `message` what to fire again.
function LostLine:fired(queue, item, message, now)
    self.queue, self.item, self.message, self.at = queue, item, message, now
end

-- The number watched no longer stands (the count moved on without a new
-- number, as crowd control texts alone do): nothing to say again.
function LostLine:forget()
    self.item = nil
end

-- Run on the count's checks with the speech queue as it is now. Returns the
-- message to fire again, once, or nil.
function LostLine:check(queue, now)
    local item = self.item
    if item == nil then
        return nil
    end
    if queue == self.queue then
        if not holds(queue, item) then
            -- sent
            self.item = nil
        end
        return nil
    end
    if not holds(self.queue, item) then
        -- sent before the stop
        self.item = nil
        return nil
    end
    if now - self.at < enemyCount.RESAY_AFTER then
        return nil
    end
    self.item = nil
    return self.message
end

-- Announcer -----------------------------------------------------------------
-- The speech side of the count (core/ui modules/combat.lua): fires a number,
-- watches its line in the speech queue (LostLine) and says a lost one again.
-- config:
--   fire(message)        fires the Enemy Count alert, every output
--   fireSpeech(message)  fires its speech (TTS) output alone: only a speech
--                        line waits in the queue and can be thrown away; a
--                        voice pack number or a sound plays at once
--   queue()              WowVision's speech queue table, nil without one (Vanilla)
--   now()                the time
--   enabled()            whether the Enemy Count alert is on
--   mode()               the crowd control mode (enemyCountControlMode)
-- Only a line that waits in the queue is watched. A line sent at once (the
-- queue was idle) or one cut while it already plays is not said again: the
-- queue no longer holds it, and nothing tells it apart from one heard.
local Announcer = WowVision.Class("EnemyCountAnnouncer")
enemyCount.Announcer = Announcer

function Announcer:initialize(config)
    self.config = config
    self.lost = LostLine:new()
end

-- Fires a count. A message without a number (crowd control texts alone)
-- means the free count changed without being said, so the last number is no
-- longer worth saying again.
function Announcer:say(message)
    local config = self.config
    local queue = config.queue()
    local before = type(queue) == "table" and #queue or nil
    config.fire(message)
    if message.count == nil then
        self.lost:forget()
        return
    end
    if before == nil then
        return
    end
    local item = nil
    if config.queue() == queue and #queue > before then
        item = queue[#queue]
    end
    self.lost:fired(queue, item, message, config.now())
    self.mode = config.mode()
end

-- With crowd control on, a quiet change (a controlled enemy gone, nothing to
-- say): the free count is the same, so a lost number still stands. Its
-- crowd control texts may not, so only the number is said again.
function Announcer:quietChange()
    local lost = self.lost
    if lost.item ~= nil and lost.message ~= nil and lost.message.texts ~= nil then
        lost.message = { count = lost.message.count }
    end
end

-- Says a lost number again, once, while it is still the count's: not while
-- a newer number waits to settle in `active` (it is said soon), and with
-- `plain` (no crowd control) only when the settler still holds that number.
--
-- While the alert is off nothing is counted, and after a crowd control mode
-- switch the numbers mean something else, so a lost number from before
-- either is forgotten, never said late.
function Announcer:resay(active, plain)
    local config = self.config
    if not config.enabled() or config.mode() ~= self.mode then
        self.lost:forget()
        return
    end
    local queue = config.queue()
    if type(queue) ~= "table" then
        return
    end
    if active.pending ~= nil then
        return
    end
    local message = self.lost:check(queue, config.now())
    if message ~= nil and plain and active.said ~= message.count then
        message = nil
    end
    if message ~= nil then
        -- A copy marked as said again, for whoever looks at the alert.
        local again = { again = true }
        for key, value in pairs(message) do
            again[key] = value
        end
        config.fireSpeech(again)
    end
end

-- The once-a-second check: the recount first, then a lost number. A count
-- that moved on quietly (an enemy died or left without an event) is seen
-- first, so a number already known to be outdated is never said again;
-- the new one follows on its own.
function Announcer:tick(recount, active, plain)
    recount()
    self:resay(active, plain)
end
