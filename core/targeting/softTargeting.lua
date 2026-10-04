-- Soft targeting rules and the console variable writer, kept free of frames
-- so they run in the headless tests. See the targeting module for when they run.
local soft = {}

-- Whether soft targeting may act while a hard target is locked. Two console
-- variables carry it (neither is in Blizzard's settings screens):
--   SoftTargetWithLocked  "Allows soft target selection while player has a
--                          locked target. 2 = always do soft targeting"
--   SoftTargetMatchLocked "Match appropriate soft target to locked target.
--                          1 = hard locked target only, 2 = for targets you attack"
-- Measured in game (TBC 2.5.6, corpse and live mob in range, interact pressed
-- with the mob targeted): WithLocked 0 acts on the mob and ignores the corpse,
-- 1 and 2 both loot the corpse. Only 0 suppresses, and there is no
-- "attackable only" value, so that mode switches WithLocked as the target
-- changes. Neither variable is secure (C_CVar.GetCVarInfo on Forever 1.60.1),
-- so the switch also works in combat.
soft.lockModes = { "always", "noHardTarget", "noAttackableHardTarget" }

-- Returns the WithLocked and MatchLocked values for a mode and the current
-- hard target, or nil for an unknown mode (the game's values stay).
function soft.lockValues(mode, hasTarget, canAttack, dead)
    if mode == "always" then
        return 2, 0
    elseif mode == "noHardTarget" then
        return 0, 1
    elseif mode == "noAttackableHardTarget" then
        -- 0 is the resting state, also with no target at all: WithLocked only
        -- acts while a target is locked, and resting at 0 means a mob you tab
        -- to suppresses soft targeting at once. 2 only for a target you cannot
        -- attack: a corpse you loot, an NPC you talk to, a player you follow.
        if hasTarget and (not canAttack or dead) then
            return 2, 2
        end
        return 0, 2
    end
    return nil
end

-- Writes console variables and checks that they landed. A refused write
-- raises no Lua error, it simply does not take, so every write is read back.
-- Secure variables are refused in combat (and raise ADDON_ACTION_BLOCKED), so
-- in combat they are not tried at all: they wait in `pending` until flush().
local Writer = WowVision.Class("SoftTargetWriter")
soft.Writer = Writer

-- api: getCVar(name), setCVar(name, value), isSecure(name), inCombat()
function Writer:initialize(api)
    self.api = api
    self.pending = {}
end

-- The game normalises numbers ("15" reads back as "15.000000").
local function sameValue(a, b)
    if a == b then
        return true
    end
    local numberA, numberB = tonumber(a), tonumber(b)
    return numberA ~= nil and numberA == numberB
end
soft.sameValue = sameValue

-- Returns "set", "same", "pending" or "missing" (no such variable here).
function Writer:write(name, value)
    value = tostring(value)
    local current = self.api.getCVar(name)
    if current == nil then
        self.pending[name] = nil
        return "missing"
    end
    if sameValue(current, value) then
        self.pending[name] = nil
        return "same"
    end
    if self.api.inCombat() and self.api.isSecure(name) then
        self.pending[name] = value
        return "pending"
    end
    pcall(self.api.setCVar, name, value)
    if sameValue(self.api.getCVar(name), value) then
        self.pending[name] = nil
        return "set"
    end
    self.pending[name] = value
    return "pending"
end

-- Tries every waiting write again, in name order.
function Writer:flush()
    local names = {}
    for name in pairs(self.pending) do
        tinsert(names, name)
    end
    table.sort(names)
    for _, name in ipairs(names) do
        self:write(name, self.pending[name])
    end
end

WowVision.softTargeting = soft
