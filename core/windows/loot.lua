local module = WowVision.base.windows:createModule("loot")
local L = module.L
module:setLabel(L["Loot"])

local function rollLoot(rollType)
    for i = 1, 6 do
        local frame = _G["GroupLootFrame" .. i]
        if frame and frame:IsVisible() then
            if rollType == "need" then
                frame.NeedButton:Click()
            elseif rollType == "greed" then
                frame.GreedButton:Click()
            elseif rollType == "pass" then
                frame.PassButton:Click()
            elseif rollType == "info" then
                WowVision:speak(frame.Name:GetText())
            end
            return
        end
    end
    WowVision:speak(L["No loot."])
end

module:registerBinding({
    type = "Function",
    key = "loot/readItem",
    inputs = { "ALT-CTRL-Y" },
    label = L["Roll Tooltip"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        rollLoot("info")
    end,
})

module:registerBinding({
    type = "Function",
    key = "loot/rollNeed",
    inputs = { "ALT-CTRL-U" },
    label = L["Roll Need"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        rollLoot("need")
    end,
})

module:registerBinding({
    type = "Function",
    key = "loot/rollGreed",
    inputs = { "ALT-CTRL-I" },
    label = L["Roll Greed"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        rollLoot("greed")
    end,
})

module:registerBinding({
    type = "Function",
    key = "loot/rollPass",
    inputs = { "ALT-CTRL-O" },
    label = L["Roll Pass"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        rollLoot("pass")
    end,
})

if BonusRollFrame then
    module:registerBinding({
        type = "Click",
        key = "loot/rollBonus",
        inputs = { "ALT-CTRL-P" },
        label = L["Roll Bonus"],
        emulatedKey = "LeftButton",
        targetFrame = BonusRollFrame.PromptFrame.RollButton,
    })
end
