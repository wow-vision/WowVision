-- The group health monitor's checks: Sku's rule (speak a member when their
-- health moved the role's minimum change and minimum pitch steps since
-- their last announcement) on health the addon cannot read. No WoW API in here: the caller hands in
-- an environment, so tools/groupHealthSim.lua runs the real checks against
-- a simulated engine.
--
-- Speak first, check afterwards. The member's reference (the health of
-- the number the player last heard) is a plain number once known, so the rule is a
-- volume gate: a health event speaks the number at once, silent inside
-- reference -/+ minimum change (widened to the pitch levels within the
-- minimum pitch steps), and the game decides whether it is heard.
-- A silent readback sample (readback.lua) called in the same frame reads
-- the same health and tells afterwards whether the number was a move; then
-- the reference moves to it.
--
-- The reference moves only on a reading of the very health the number
-- went out at, so only on a number that was really gated open there. A
-- lost check:
-- - its number played to its end and no health event came since (health
--   changes only with an event): a silent re-check with the same plan reads
--   that same health and tells exactly whether the number was heard;
-- - a health event came since: the reference stays, and the event's own
--   number is gated by it (it may repeat the lost one);
-- - a stop cut its number while it played (also after its sample had
--   ended): unsure, the next number is said wherever its lane speaks, and
--   its reading sets the reference afresh.
-- A move is never swallowed; the price is a number now and then said twice.
-- (Earlier a re-check waited for the next health event and took the lost
-- number as heard whenever health had moved by then, and the move went
-- unsaid: first party fight in game, 2026-10-14.)
--
-- Per member: out (checks the readback still has), again (a health event
-- came while two were out: check once more when one is back), events (health
-- events so far), recheck (the plan of a lost check to read again silently:
-- no event since, so the same health), unsure (not known what the player
-- last heard: the next number is said in any case).

local GroupHealth = WowVision.groupHealth

-- Who is read first when several wait for the slot line (lower first): a
-- member below their urgent threshold, then tanks, then healers, then the
-- lower health; a member without a reference last.
function GroupHealth.readPriority(member, urgentPercent)
    if member == nil or member.reference == nil then
        return 1000
    end
    local score = member.reference
    if urgentPercent ~= nil and member.reference < urgentPercent then
        score = score - 200
    end
    if member.role == "TANK" then
        score = score - 30
    elseif member.role == "HEALER" then
        score = score - 15
    end
    return score
end

local Checks = WowVision.Class("GroupHealthChecks")
GroupHealth.Checks = Checks

-- env:
-- - members() the watched members by unit; memberFor(unit) a member by
--   any unit token naming them (nil when not watched);
-- - threshold(member) the role's minimum change, whole percent;
--   pitchQuiet(member) (optional) the band of health that sounds less than
--   the role's minimum pitch steps from the member's reference;
--   urgent(member) the role's urgent threshold, percent;
--   holdMs(member) (optional) how long the member's check waits after a
--   health event (0: none);
--   speakBelow(member) (optional) the role's "Speak Below" as a fraction:
--   above it numbers are silent, so moves there leave the reference;
-- - carry(member, quiet) speaks the member's number straight to the engine,
--   silent inside `quiet` ({ low, high } health), and returns how many
--   utterances it made;
-- - for the readback (readback.lua): now, after, speak, through,
--   nextCount, onOwnCut, onFailing, onError and optionally line, frameMs,
--   startOwner;
-- - trace(member, what, detail, extra) (optional): diagnostics, see log.lua.
function Checks:initialize(env)
    self.env = env
    self.readback = GroupHealth.Readback:new({
        line = env.line,
        now = env.now,
        frameMs = env.frameMs,
        startOwner = env.startOwner,
        after = env.after,
        speak = env.speak,
        through = env.through,
        nextCount = env.nextCount,
        onOwnCut = env.onOwnCut,
        onFailing = env.onFailing,
        onError = env.onError,
        plan = function(unit)
            local member = env.memberFor(unit)
            if member == nil then
                return GroupHealth.locatePlan()
            end
            return GroupHealth.planFor(member, env.threshold(member), env.pitchQuiet ~= nil and env.pitchQuiet(member) or nil,
                env.speakBelow ~= nil and env.speakBelow(member) or nil)
        end,
        priority = function(unit)
            local member = env.memberFor(unit)
            return GroupHealth.readPriority(member, member ~= nil and env.urgent(member) or nil)
        end,
        rerequest = function(unit)
            self:check(unit)
        end,
        -- (health events come through Checks:onEvent)
        onReading = function(unit, reading)
            return self:onReading(unit, reading)
        end,
        onDiscard = function(unit, why, sample)
            self:onDiscard(unit, why, sample)
        end,
        onNumberCut = function(unit)
            self:onNumberCut(unit)
        end,
        onPurge = function()
            self:onPurge()
        end,
    })
end

function Checks:trace(member, what, detail, extra)
    if self.env.trace ~= nil then
        self.env.trace(member, what, detail, extra)
    end
end

-- The members in number order: the same order every time (a table by unit
-- token walks in an order that changes from run to run).
function Checks:membersInOrder()
    local list = {}
    for _, member in pairs(self.env.members()) do
        tinsert(list, member)
    end
    table.sort(list, function(a, b)
        return a.number < b.number
    end)
    return list
end

-- One silent sample for every member whose reference is not known yet:
-- someone who joined.
function Checks:readNew()
    for _, member in ipairs(self:membersInOrder()) do
        if not member.dead and member.reference == nil and (member.out or 0) == 0 then
            self.readback:request(member.unit)
        end
    end
end

-- A check of the member goes out: `opts` as readback:request takes them.
function Checks:send(member, opts)
    member.out = (member.out or 0) + 1
    if self.readback:request(member.unit, opts) then
        return true
    end
    -- Two samples of the member out already: the readback asks again
    -- (rerequest) when one is back.
    member.out = member.out - 1
    return false
end

-- A health event of the unit: health may have changed, so a lost check can
-- no longer be read again exactly (Checks:onDiscard).
function Checks:onEvent(unit)
    local member = self.env.memberFor(unit)
    if member == nil then
        return
    end
    member.events = (member.events or 0) + 1
    member.recheck = nil
    -- Held: the check goes out a little later (env.holdMs), with the
    -- health of then; events meanwhile join it.
    local hold = self.env.holdMs ~= nil and self.env.holdMs(member) or 0
    if hold > 0 then
        if not member.held then
            member.held = true
            self.env.after(hold / 1000, function()
                member.held = false
                self:check(member.unit)
            end)
        end
        return
    end
    self:check(unit)
end

-- A health event, or the readback asking for the member again. A member
-- without a reference gets a plain silent sample (the first reading sets
-- it). Otherwise the number goes out now, carried by a sample. While the
-- member's last check is still out, a second one may go out beside it
-- when the slot line is free (nobody else waiting): gated by the same
-- reference it may repeat the first, but a member taking hit after hit is
-- heard at once. Else it waits for the check and goes out with the health
-- of that moment.
function Checks:check(unit)
    local member = self.env.memberFor(unit)
    if member == nil or member.dead then
        return
    end
    if member.reference == nil then
        self.readback:request(member.unit)
        return
    end
    local out = member.out or 0
    -- Said in any case next: a re-check of an older number no longer helps.
    if member.unsure then
        member.recheck = nil
    end
    if member.recheck ~= nil then
        if out >= 2 then
            member.again = true
            return
        end
        local plan = member.recheck
        member.recheck = nil
        local events = member.events
        local opts = {
            plan = plan,
            recheck = true,
            events = events,
            -- Waiting for the line, a health event may come: then it reads
            -- another health, and the event's own check takes over. Or a
            -- stop may cut the number it stands for: then it is said again.
            valid = function()
                return member.events == events and not member.unsure
            end,
        }
        if not self:send(member, opts) then
            member.recheck = plan
        end
        return
    end
    if out >= 2 or (out == 1 and not self.readback:lineFree()) then
        member.again = true
        self:trace(member, "wait", out >= 2 and "two checks out" or "its last check was out and the line busy")
        return
    end
    self:send(member, {
        events = member.events,
        carry = function(plan)
            if self.env.memberFor(member.unit) ~= member or member.dead then
                return 0
            end
            self:trace(member, "sent", plan)
            return self.env.carry(member, GroupHealth.quietFor(plan))
        end,
    })
end

-- A check is back (read or lost).
local function checkBack(member)
    member.out = math.max(0, (member.out or 1) - 1)
end

-- Returns true when the reading found a carried number was a move.
function Checks:onReading(unit, reading)
    local member = self.env.memberFor(unit)
    if member == nil or member.dead then
        return false
    end
    local moved = GroupHealth.judge(member, reading, self.env.threshold(member), self.env.speakBelow ~= nil and self.env.speakBelow(member) or nil)
    if reading.carried then
        checkBack(member)
        if moved then
            self:trace(member, "moved")
        end
    end
    if (member.out or 0) == 0 then
        if member.again then
            member.again = false
            self:check(member.unit)
        end
    end
    return moved
end

-- A sample that carried a number was lost: whether the number was heard is
-- not known, so the reference stays. The readback asks for the member
-- again by itself after a disturbance (readbackRetries, a stop), and that
-- check speaks again what is still a move.
function Checks:onDiscard(unit, why, sample)
    if not sample.carried then
        return
    end
    local member = self.env.memberFor(unit)
    if member == nil then
        return
    end
    checkBack(member)
    if member.reference ~= nil then
        if (why == "stop" and sample.carriedCut) or why == "timeout" or why == "failed" then
            -- Its number was cut while it played (or may have been):
            -- whatever the player heard of it, the next number is said in
            -- any case (GroupHealth.planFor), and its reading tells what
            -- the player heard.
            member.unsure = true
        elseif not member.unsure and why ~= "older than the last reading" and sample.opts ~= nil and sample.opts.events == member.events then
            -- Its number played to its end, and no health event came since,
            -- so the health has not changed: a silent re-check with the
            -- same plan reads the very health it went out at and tells
            -- exactly whether it was heard. (A health event since: the
            -- reference stays and the next number may repeat it.)
            member.recheck = sample.plan
        end
    end
    self:trace(member, "lost", why, sample)
    if not GroupHealth.readbackRetries(why) and why ~= "stop" and member.again then
        member.again = false
        self:check(member.unit)
    end
end

-- A stop cut a number whose check had already ended (the number plays
-- longer than its sample): as with a cut check, the next number is said in
-- any case.
function Checks:onNumberCut(unit)
    local member = self.env.memberFor(unit)
    if member ~= nil and member.reference ~= nil then
        member.unsure = true
        member.recheck = nil
        self:trace(member, "lost", "stop after its reading")
    end
end

-- The readback dropped everything (a member stuck failing): every check is
-- gone, and who has no reference yet is read again.
function Checks:onPurge()
    for _, member in ipairs(self:membersInOrder()) do
        -- Its checks out may have carried heard numbers.
        if (member.out or 0) > 0 and member.reference ~= nil then
            member.unsure = true
        end
        member.out = 0
        member.again = false
    end
    self:readNew()
end
