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
-- "game" is the game's own default for a setting: choosing it restores that
-- default, and from then on WowVision leaves the variable alone.
soft.GAME_DEFAULT = "game"
soft.lockModes = { "game", "always", "noHardTarget", "noAttackableHardTarget" }

-- Returns the WithLocked and MatchLocked values for a mode and the current
-- hard target, or nil for an unknown mode (the game's values stay).
--
-- loose: the target is one the game set itself (IsTargetLoose), because
-- SoftTargetForce (on for enemies by default, or for friends) makes the
-- soft target the target. Such a target is no hard target here. The game counts it as
-- locked, though: with WithLocked 0 it dropped the soft enemy at once, the
-- loose target with it, then picked the same enemy again, every frame or
-- two (measured on Forever 2026-11-08: the event 40 times a second, gone
-- with WithLocked 1 or Force 0). So 0 is written only for a target you
-- chose, never as a resting value; with no such target soft targeting may
-- act (2). Tabbing to a mob lets soft targeting act for the frame before
-- the write lands. Attacking a loose target leaves it loose (measured: the
-- whole fight), so these modes never hold back soft targeting for an enemy
-- the game picked: soft targeting keeps working, as with Game Default.
function soft.lockValues(mode, hasTarget, canAttack, dead, loose)
    if mode == soft.GAME_DEFAULT then
        return nil
    end
    local chosen = hasTarget and not loose
    if mode == "always" then
        return 2, 0
    elseif mode == "noHardTarget" then
        return chosen and 0 or 2, 1
    elseif mode == "noAttackableHardTarget" then
        -- 2 also for a target you cannot attack: a corpse you loot, an NPC
        -- you talk to, a player you follow.
        if chosen and canAttack and not dead then
            return 0, 2
        end
        return 2, 2
    end
    return nil
end

-- Writes console variables and checks that they landed. A refused write
-- raises no Lua error, it simply does not take, so every write is read back.
-- Secure variables are refused in combat (and raise ADDON_ACTION_BLOCKED), so
-- in combat they are not tried at all: they wait in `pending` until flush().
local Writer = WowVision.Class("SoftTargetWriter")
soft.Writer = Writer

-- api: getCVar(name), setCVar(name, value), getDefault(name), isSecure(name),
-- inCombat()
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

-- Puts a variable back on the game's own default, with the same read back
-- and hold as any write. Returns what write returns.
function Writer:restore(name)
    local default = self.api.getDefault(name)
    if default == nil then
        self.pending[name] = nil
        return "missing"
    end
    return self:write(name, default)
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
