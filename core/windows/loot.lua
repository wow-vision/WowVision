local module = WowVision.base.windows:createModule("loot")
local L = module.L
module:setLabel(L["Loot"])

-- The button of a roll. WoW: Forever keeps them in a container, other clients on
-- the frame itself. An item with a transmog roll shows that button in Greed's place.
local function rollButton(frame, rollType)
    local buttons = frame.LootButtonContainer or frame
    if rollType == "need" then
        return buttons.NeedButton
    elseif rollType == "pass" then
        return buttons.PassButton
    end
    local transmog = buttons.TransmogButton
    if transmog ~= nil and transmog:IsShown() then
        return transmog
    end
    return buttons.GreedButton
end

local function rollLoot(rollType)
    for i = 1, 6 do
        local frame = _G["GroupLootFrame" .. i]
        if frame and frame:IsVisible() then
            if rollType == "info" then
                WowVision:speak(frame.Name:GetText())
            else
                local button = rollButton(frame, rollType)
                if button:IsEnabled() then
                    button:Click()
                else
                    -- the game's own reason, as its tooltip gives it
                    WowVision:speak(button.reason or L["Disabled"])
                end
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
