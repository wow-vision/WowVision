-- The group health monitor's log (/wv ghlog): what the monitor did, for
-- tests in game. Off by default and quiet while on (in chat it was too much
-- in a fight); /wv ghlog show opens the last lines. The log and the
-- readback's counts also go into WowVisionDump, saved at the next /reload.
-- Health itself is secret and never logged: only what the monitor did and
-- when.
--
-- The monitor reports through module:trace(member, what, detail, extra):
-- - event: a health event, detail the unit token it came with;
-- - wait: a check held back, detail why;
-- - sent: a number went out with a check, detail the check's plan (where
--   the number is silent);
-- - moved: a check found the number was a move;
-- - lost: a check was lost (detail: why, extra: the sample): read again
--   silently while the health is unchanged, else the next number is said
--   (again); a sample thrown away with its slot tells what started in it;
-- - respeak: a death cut by a stop goes out again;
-- - play: a queue entry plays (detail: the entry).

local module = WowVision.base.groupHealth

-- A line per number sent too: a fight of a few minutes in a party fills
-- several hundred.
local LOG_MAX = 1500
local GroupHealth = WowVision.groupHealth
module.log = {}

-- Per member: when the health event came that the next number answers, and
-- why it waited. Weak keys: members dropped by a roster update go away.
local pending = setmetatable({}, { __mode = "k" })

local function chat(text)
    for line in tostring(text):gmatch("[^\n]+") do
        print("WowVision group health: " .. line)
    end
end

-- The clock time, and the game's own time to the hundredth (the clock's
-- seconds and the game time's fractions do not line up).
local function logTime()
    return date("%H:%M:%S") .. string.format(" (%.2f)", GetTime())
end

-- The log and the readback's counts into WowVisionDump.
function module:keepLog()
    WowVisionDump = WowVisionDump or {}
    WowVisionDump.groupHealthLog = {
        lines = self.log,
        -- Since the log went on: the counts below cover the same time.
        seconds = self.logSince ~= nil and GetTime() - self.logSince or nil,
        healthEvents = self.healthEvents,
        readback = self.checks ~= nil and self.checks.readback.stats or nil,
        respoken = self.respoken,
        stopSources = self.stopSources,
        stopKinds = self.stopKinds,
        stopsLeftOut = self.stopsLeftOut,
        stopStacks = self.stopStacks,
        -- Slots thrown away, by why (readback.lua's slot.why).
        slotsLost = self.slotsLost,
    }
end

local function append(parts)
    tinsert(module.log, table.concat(parts, ", "))
    while #module.log > LOG_MAX do
        tremove(module.log, 1)
    end
    module:keepLog()
end

local function memberParts(member)
    return { logTime(), "number " .. tostring(member.number), string.lower(member.role) }
end

local trace = {}

-- Only events under another token than the member's own: in a raid the
-- same person may come as raidN and as partyN or player (one check each).
function trace.event(member, unit)
    module.healthEvents = (module.healthEvents or 0) + 1
    local state = pending[member] or {}
    pending[member] = state
    state.eventAt = state.eventAt or GetTime()
    if unit ~= member.unit then
        local parts = memberParts(member)
        tinsert(parts, "health event as " .. tostring(unit) .. " (" .. member.unit .. ")")
        append(parts)
    end
end

function trace.wait(member, why)
    local state = pending[member] or {}
    pending[member] = state
    state.waited = state.waited or why
end

-- Where a plan's number is silent, in whole percent: inside "moved less"
-- (the reference -/+ the minimum change, widened to the pitch steps), and
-- above "Speak Below" in any case. An unsure plan has no "moved less".
local function silentWords(plan)
    if plan == nil then
        return nil
    end
    if plan.unsure then
        return "said wherever below Speak Below (the last number heard is not known)"
    end
    local quiet = GroupHealth.quietFor(plan)
    if quiet == nil then
        return nil
    end
    local low = math.max(0, math.floor(quiet[1] * 100 + 0.5))
    local high = math.min(100, math.floor(quiet[2] * 100 + 0.5))
    return string.format("silent from %d to %d percent", low, high)
end

function trace.sent(member, plan)
    local state = pending[member] or {}
    pending[member] = {
        sentAfter = state.eventAt ~= nil and GetTime() - state.eventAt or nil,
        waitedFor = state.waited,
    }
    local parts = memberParts(member)
    tinsert(parts, "number sent")
    local words = silentWords(plan)
    if words ~= nil then
        tinsert(parts, words)
    end
    append(parts)
end

function trace.moved(member)
    local parts = memberParts(member)
    tinsert(parts, "moved, reference now " .. tostring(member.reference))
    -- Heard below "Speak Below", or at full health ("<number> full").
    local heard = member.reference < module:roleSetting(member.role, "startThreshold")
        or (member.reference >= 100 and module.settings.announceFull)
    tinsert(parts, heard and "heard" or "silent (above Speak Below)")
    local state = pending[member]
    if state ~= nil and state.sentAfter ~= nil then
        tinsert(parts, string.format("sent %.2f s after the health event", state.sentAfter))
        if state.sentAfter > 0.05 and state.waitedFor ~= nil then
            tinsert(parts, "waited: " .. state.waitedFor)
        end
    end
    append(parts)
end

function trace.lost(member, detail, sample)
    local parts = memberParts(member)
    tinsert(parts, "check lost: " .. detail)
    -- Thrown away with its slot: why, and what started in it.
    local slot = sample ~= nil and sample.slot or nil
    if detail == "ambiguous" and slot ~= nil then
        tinsert(parts, GroupHealth.describeSlot(slot))
        -- Counted once per slot (a slot carries up to three members).
        if not slot.counted then
            slot.counted = true
            local why = slot.why or "thrown away"
            module.slotsLost = module.slotsLost or {}
            module.slotsLost[why] = (module.slotsLost[why] or 0) + 1
        end
    end
    append(parts)
end

function trace.respeak(member)
    module.respoken = (module.respoken or 0) + 1
    local parts = memberParts(member)
    tinsert(parts, "said again after a stop of all speech cut it")
    append(parts)
end

function trace.play(member, entry)
    local parts = memberParts(member)
    tinsert(parts, entry.lane)
    local queued = GetTime() - entry.queuedAt
    if queued > 0.05 then
        tinsert(parts, string.format("waited %.1f s in the queue", queued))
    end
    append(parts)
end

function module:trace(member, what, detail, extra)
    if self.logging and trace[what] ~= nil then
        trace[what](member, detail, extra)
    end
end

-- The function a stack line names, when it has a name (not a place).
local function stackFunction(line)
    return line:match("in function '([^'/]+)'") or line:match("in function `([^'/]+)'")
end

-- Where a stack line points: an addon file (Blizzard's own included) with
-- its line, or a code string (a key binding's body, a /run), else nil
-- (game code without Lua, "[C]").
local function stackPlace(line)
    local file, lineNumber = line:match("AddOns[/\\]([^%]%[\"\n:]-%.%a+)[%]\"]*:(%d+)")
    if file ~= nil then
        return file .. ":" .. lineNumber
    end
    local code = line:match('%[string "([^"\n]*)"%]')
    if code ~= nil then
        return 'code "' .. code:sub(1, 60) .. '"'
    end
    return nil
end

-- What a stop through WowVision's speech module cut, taken just before it
-- (its own hook clears the state): whether WowVision itself was speaking
-- (an utterance of its queue playing, or waiting), and how many checks of
-- ours and numbers that may still play were out. A stop while WowVision
-- was silent cut only other speech: ours, Blizzard's alerts. Only a look,
-- the stop itself goes on unchanged.
local speech = WowVision.base.speech
local stopWithoutLook = speech.stop
function speech:stop(...)
    if module.logging then
        local readback = module.checks ~= nil and module.checks.readback or nil
        module.stopLook = {
            speaking = self.speaking == true or #self.queue > 0,
            checks = readback ~= nil and #readback.inflight or 0,
        }
    end
    local result = stopWithoutLook(self, ...)
    -- Still here: the hook below never ran, the stop was left out (only
    -- silent samples playing).
    if module.logging and module.stopLook ~= nil then
        local look = module.stopLook
        module.stopLook = nil
        local source = module:stopSource(debugstack(2, 20, 0) or "")
        module.stopsLeftOut = module.stopsLeftOut or {}
        module.stopsLeftOut[source] = (module.stopsLeftOut[source] or 0) + 1
        append({ logTime(), string.format("stop left out (only silent checks playing) from %s%s, %d checks kept", source, InCombatLockdown() and ", in combat" or "", look.checks) })
    end
    return result
end

-- Who stopped all speech, while the log is on: the first place in the call
-- stack past the hooks and the speech module (only the messenger), with
-- whether Ctrl was held (Blizzard's Ctrl stop, the "Stop Text to Speech"
-- binding). Counted per source; each source's first stack is kept whole,
-- and every stop gets a log line, to set beside lost checks.
-- The first place in a stack past the hooks and the speech module, and
-- whether Ctrl is held.
-- With the function there; for an alert (core/alerts), also who fired it
-- (the soft target and the Target Change alerts share outputs.lua).
function module:stopSource(stack)
    local source = nil
    for line in stack:gmatch("[^\n]+") do
        local place = stackPlace(line)
        if place ~= nil and not place:find("groupHealth", 1, true) and not place:find("retail/speech.lua", 1, true) then
            local fn = stackFunction(line)
            if source == nil then
                source = place .. (fn ~= nil and " (" .. fn .. ")" or "")
                if not place:find("core/alerts/", 1, true) then
                    break
                end
            elseif not place:find("core/alerts/", 1, true) then
                source = source .. ", alert from " .. (fn ~= nil and fn .. " in " or "") .. place
                break
            end
        end
    end
    if source == nil then
        source = "the game (no Lua on the stack)"
    end
    if IsControlKeyDown() then
        source = source .. ", Ctrl held"
    end
    return source
end

hooksecurefunc(C_VoiceChat, "StopSpeakingText", function()
    if not module.logging then
        return
    end
    local stack = debugstack(2, 20, 0) or ""
    local source = module:stopSource(stack)
    module.stopSources = module.stopSources or {}
    module.stopSources[source] = (module.stopSources[source] or 0) + 1
    module.stopStacks = module.stopStacks or {}
    if module.stopStacks[source] == nil then
        module.stopStacks[source] = stack:sub(1, 1500)
    end
    -- Per source: stops while WowVision spoke, while it was silent (only
    -- other speech cut), not through its speech module; checks cut by each.
    local look = module.stopLook
    module.stopLook = nil
    local kind = look == nil and "other" or (look.speaking and "speaking" or "silent")
    module.stopKinds = module.stopKinds or {}
    local kinds = module.stopKinds[source] or { speaking = 0, silent = 0, other = 0, checksCutSpeaking = 0, checksCutSilent = 0, inCombat = 0 }
    if InCombatLockdown() then
        kinds.inCombat = kinds.inCombat + 1
    end
    module.stopKinds[source] = kinds
    kinds[kind] = kinds[kind] + 1
    if look ~= nil then
        local key = look.speaking and "checksCutSpeaking" or "checksCutSilent"
        kinds[key] = kinds[key] + look.checks
    end
    local what = (InCombatLockdown() and ", in combat" or "")
        .. (look == nil and "" or string.format(", WowVision %s, %d checks out", look.speaking and "speaking" or "silent", look.checks))
    append({ logTime(), "stop of all speech by " .. source .. what })
end)

local function counts(list)
    local parts = {}
    for why, n in pairs(list) do
        tinsert(parts, why .. " " .. n)
    end
    table.sort(parts)
    return #parts > 0 and table.concat(parts, ", ") or "none"
end

local function show()
    local lines = {}
    for _, line in ipairs(module.log) do
        tinsert(lines, line)
    end
    -- The readback's counts, so its health shows next to the plays.
    if module.checks ~= nil then
        local stats = module.checks.readback.stats
        tinsert(lines, string.format(
            "Readback: %d health events, %d samples, %d readings used, thrown away: %s; slots thrown away: %s; most at once %d; purges: %s; own speech cut %d, said again %d; other speech started %d times, %d of them not called through WowVision (Blizzard's Combat Audio Alerts and the like), %d too soon after our calls to be ours (left out)",
            module.healthEvents or 0, stats.samples, stats.readings, counts(stats.discarded), counts(module.slotsLost or {}), stats.maxInflight, counts(stats.purges), stats.ownCut, module.respoken or 0, stats.otherStarts, stats.unseenStarts, stats.earlyStarts or 0
        ))
    end
    if #lines == 0 then
        return false
    end
    chat(lines[#lines])
    WowVision.testing.showResults(table.concat(lines, "\n"))
    return true
end

module:registerCommand({
    name = "ghlog",
    description = "Group health monitor log: 'on' records what the monitor does, 'off' stops, 'show' lists the last lines, 'clear' empties it",
    func = function(args)
        local word = (args or ""):lower():match("^%s*(%S+)")
        local text
        if word == "on" then
            module.logging = true
            -- The counts start afresh with the log.
            module.logSince = GetTime()
            module.healthEvents = 0
            module.respoken = 0
            module.stopSources = nil
            module.stopKinds = nil
            module.stopsLeftOut = nil
            module.slotsLost = nil
            if module.checks ~= nil then
                module.checks.readback:resetStats()
            end
            text = "Group health log on"
        elseif word == "off" then
            module.logging = false
            text = "Group health log off"
        elseif word == "clear" then
            module.log = {}
            module:keepLog()
            text = "Group health log cleared"
        elseif show() then
            return
        else
            text = "Group health log is empty"
        end
        chat(text)
        WowVision:speak(text)
    end,
})
