local module = WowVision.base:createModule("range")
local L = module.L
module:setLabel(L["Range"])
local rangeCheck = LibStub("LibRangeCheck-3.0")
local settings = module:hasSettings()

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

settings:addRef("announce", rangeChange.parameters)

function module:onEnable()
    self.target = nil
    self.targetRange = nil

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
        if target == nil then
            self.target = nil
            self.targetRange = nil
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
        if target ~= self.target or rangeMax ~= self.targetRange then
            rangeChange:fire({ range = rangeMax })
            self.target = target
            self.targetRange = rangeMax
        end
    end)
end
