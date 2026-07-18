local module = WowVision.base.navigation:createModule("falling")
local L = module.L
module:setLabel(L["Fall Detection"])

-- Fall detection (Sku's system, whose escalating sound sequence we ship):
-- while IsFalling(), after a configurable delay, play the numbered fall
-- sounds one per 0.05s -- the rising sequence conveys how long the fall has
-- lasted. An optional announcement speaks once at the first sound. When
-- Ignore Jumps is on, falls beginning within a grace window of a jump press
-- stay silent (ordinary hops), while long drops keep alerting once the
-- grace passes.

local SEQUENCE_STEP = 0.05
local SEQUENCE_MAX = 99
local JUMP_GRACE = 0.8

local settings = module:hasSettings()
settings:add({
    key = "delay",
    type = "Number",
    label = L["Delay (milliseconds)"],
    default = 200,
    min = 0,
    max = 1000,
})
settings:add({
    key = "ignoreJumps",
    type = "Bool",
    label = L["Ignore Jumps"],
    default = true,
})

local alert = module:addAlert({ key = "falling", label = L["Fall Detection"] })
alert:addOutput({
    type = "Sound",
    key = "sound",
    action = "sound",
    label = L["Falling Sound"],
    getPath = function(self, message)
        return string.format("Sound/WowVision/falling/fall_sound-%02d.mp3", message.number)
    end,
})
alert:addOutput({
    type = "TTS",
    key = "tts",
    action = "voice",
    label = L["Falling Announcement"],
    buildMessage = function(self, message)
        return L["Falling"]
    end,
})

settings:addRef("falling", alert.parameters)

local lastJump = 0
hooksecurefunc("JumpOrAscendStart", function()
    lastJump = GetTime()
end)

local fallStart = nil
local soundNumber = 0

module:hasUpdate(function(self)
    if IsFalling() then
        local now = GetTime()
        if fallStart == nil then
            fallStart = now
        end
        -- Jump grace: keep resetting the fall clock while inside the
        -- window, so the delay counts from the moment the grace ends.
        if self.settings.ignoreJumps and (fallStart - lastJump) < JUMP_GRACE and (now - lastJump) < JUMP_GRACE then
            fallStart = now
            soundNumber = 0
            return
        end
        local elapsed = now - fallStart - (self.settings.delay or 0) / 1000
        if elapsed > 0 then
            local target = math.floor(elapsed / SEQUENCE_STEP)
            if target > soundNumber and soundNumber < SEQUENCE_MAX then
                soundNumber = soundNumber + 1
                if soundNumber == 1 then
                    self:fireAlert("falling", { action = "voice" })
                end
                self:fireAlert("falling", { action = "sound", number = soundNumber })
            end
        end
    else
        fallStart = nil
        soundNumber = 0
    end
end)
