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
