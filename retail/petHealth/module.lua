local PetHealth = WowVision.petHealth

local module = WowVision.base:createModule("petHealth")
local L = module.L
module:setLabel(L["Pet Health"])
local settings = module:hasSettings()

-- The health of your pet (the group health monitor watches players only). A
-- key says it, "Pet 45 percent", and, if the player turns Announce Health
-- Changes on, a change is said by itself in a fight, at most every few
-- seconds and only while WowVision has nothing else to say, with a last word
-- when the fight ends; the pet's death is said once, at once. The percentage
-- is hidden from addons (logic.lua): it is never looked at, only joined into
-- the words.

-- Settings ----------------------------------------------------------------------

-- Off: it speaks on its own.
settings:add({
    key = "automatic",
    type = "Bool",
    label = L["Announce Health Changes"],
    default = false,
})
settings:add({
    key = "outOfCombat",
    type = "Bool",
    label = L["Also Out of Combat"],
    default = false,
})
settings:add({
    key = "interval",
    type = "Number",
    label = L["At Most Every (seconds)"],
    default = 3,
    min = 1,
    max = 30,
})

local stepChoices = {}
for _, step in ipairs(PetHealth.STEPS) do
    tinsert(stepChoices, { value = step, label = step .. " " .. L["percent"] })
end
settings:add({
    key = "step",
    type = "Choice",
    label = L["Round Up To"],
    default = 5,
    choices = stepChoices,
})

-- The game ----------------------------------------------------------------------

local isSecret = WowVision.secrets.isSecret

-- A yes or no the game may refuse or hide: nil then.
local function answer(func, ...)
    local ok, value = pcall(func, ...)
    if not ok or isSecret(value) then
        return nil
    end
    return value and true or false
end

-- One curve object per step, kept once it is built whole.
local curves = {}

local function curveFor(step)
    local curve = curves[step]
    if curve == nil then
        curve = C_CurveUtil.CreateCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        for _, point in ipairs(PetHealth.curvePoints(step)) do
            curve:AddPoint(point[1], point[2])
        end
        curves[step] = curve
    end
    return curve
end

-- The pet's health in percent as the curve gives it, a hidden value; nil when
-- the game does not give it.
local function petPercent(step)
    local ok, curve = pcall(curveFor, step)
    if not ok then
        return nil
    end
    local read, value = pcall(UnitHealthPercent, "pet", true, curve)
    -- A hidden value cannot be compared: only its truth is tested.
    if read and value then
        return value
    end
    return nil
end

-- Speaking ----------------------------------------------------------------------

-- Says the pet's health. automatic: said by itself, so nothing is said when
-- there is nothing to tell.
function module:sayHealth(automatic)
    local function explain(text)
        if not automatic then
            WowVision:speak(text)
        end
    end
    if answer(UnitExists, "pet") == false then
        explain(L["No pet"])
        return
    end
    if answer(UnitIsDeadOrGhost, "pet") == true then
        explain(L["Pet dead"])
        return
    end
    local value = petPercent(self.settings.step)
    if not value then
        explain(L["Pet health unavailable here"])
        return
    end
    WowVision:speak(PetHealth.readout(L["Pet"], value, L["percent"]))
end

-- Wiring ------------------------------------------------------------------------

module.state = PetHealth.newState()

module:registerEvent("unit", "UNIT_HEALTH", "pet")
module:registerEvent("event", "PLAYER_REGEN_ENABLED")

function module:onEvent(event)
    if event == "UNIT_HEALTH" then
        local dead = answer(UnitIsDeadOrGhost, "pet") == true
        if PetHealth.onHealth(self.state, dead) and self.settings.automatic then
            WowVision:speak(L["Pet dead"])
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.settings.automatic and PetHealth.combatEnded(self.state, GetTime()) then
            self:sayHealth(true)
        end
    end
end

-- How often a due announcement is looked for.
local CHECK = 0.25

function module:check()
    local now = GetTime()
    if self.nextCheck ~= nil and now < self.nextCheck then
        return
    end
    self.nextCheck = now + CHECK
    if not self.settings.automatic then
        return
    end
    if not self.settings.outOfCombat and not InCombatLockdown() then
        return
    end
    if PetHealth.due(self.state, now, self.settings.interval, WowVision.base.speech:idle()) then
        self:sayHealth(true)
    end
end

function module:onEnable()
    self.state = PetHealth.newState()
    self.nextCheck = nil
    self:hasUpdate(function(self)
        self:check()
    end)
end

module:registerBinding({
    type = "Function",
    key = "petHealth/speak",
    label = L["Speak Pet Health"],
    inputs = { "ALT-SHIFT-H" },
    interruptSpeech = true,
    func = function()
        module:sayHealth(false)
    end,
})
