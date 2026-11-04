-- The distance to the target, as a recorded number. A module of its own for
-- its update, but in the menu only its alert shows, under Hard Target: that
-- alert's Enabled is the one switch. See the migration in core/db.lua.
local module = WowVision.base:createModule("range")
local L = module.L
module:setLabel(L["Range"])
module.hiddenFromMenu = true
local rangeCheck = LibStub("LibRangeCheck-3.0")

local rangeChange = module:addAlert({
    key = "rangeChange",
    label = L["Range Changed"],
})

rangeChange:addOutput({
    type = "Voice",
    key = "voice",
    label = L["Voice Alert"],
    getPath = function(self, message)
        return "Path", "numbers/" .. message.range .. ".mp3"
    end,
})

WowVision.base.targeting.hardTargetSettings:addRef("range", rangeChange.parameters)

-- The target's GUID can be secret (hidden identities on Forever and Retail)
-- and then cannot be compared tick to tick: the target change event stands
-- in as the change signal while it is.
module:registerEvent("event", "PLAYER_TARGET_CHANGED")

function module:onEvent(event)
    if event == "PLAYER_TARGET_CHANGED" then
        self.targetDirty = true
    end
end

function module:onEnable()
    self.target = nil
    self.targetRange = nil
    self.targetDirty = false

    -- LibRangeCheck builds its per-class checker list on first init, which can
    -- run before the player's class/spells are available (producing only the
    -- 8/28 interact fallbacks). Force a rebuild now that we're enabled, and again
    -- whenever the player's spells change (spec/talent/learn), so the spell-based
    -- range checkers are actually populated.
    if not self.rangeInitFrame then
        self.rangeInitFrame = CreateFrame("Frame")
        self.rangeInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.rangeInitFrame:RegisterEvent("SPELLS_CHANGED")
        self.rangeInitFrame:SetScript("OnEvent", function()
            rangeCheck:init(true)
        end)
    end
    rangeCheck:init(true)

    self:hasUpdate(function(self)
        local target = UnitGUID("target")
        if not target then
            self.target = nil
            self.targetRange = nil
            self.targetDirty = false
            return
        end
        if InCombatLockdown() and UnitIsFriend("player", "target") then
            return
        end
        local rangeMin, rangeMax = rangeCheck:GetRange("target")
        if rangeMax == nil then
            self.targetRange = nil
            return
        end
        local secrets = WowVision.secrets
        local targetChanged
        if secrets.isSecret(target) then
            targetChanged = self.targetDirty == true
        else
            targetChanged = secrets.changed(target, self.target)
        end
        self.targetDirty = false
        if targetChanged or rangeMax ~= self.targetRange then
            rangeChange:fire({ range = rangeMax })
            self.target = target
            self.targetRange = rangeMax
        end
    end)
end
