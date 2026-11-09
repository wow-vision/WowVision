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

-- The whole tooltip of the item up for a roll (name, quality, item level,
-- stats, requirements), read from its link on a private tooltip frame. If
-- the game gives no link or no lines, the name on the roll frame.
local rollTooltip = WowVision.Tooltip:new("lootRoll")

local function rollText(frame)
    local link = nil
    if frame.rollID ~= nil and GetLootRollItemLink ~= nil then
        local ok, result = pcall(GetLootRollItemLink, frame.rollID)
        if ok then
            link = result
        end
    end
    if link ~= nil and not WowVision.isSecret(link) then
        rollTooltip:set(nil, { type = "Hyperlink", link = link })
        local text = rollTooltip:getText()
        rollTooltip:reset()
        if WowVision.secrets.hasText(text) then
            return text
        end
    end
    return frame.Name:GetText()
end

local function rollLoot(rollType)
    for i = 1, 6 do
        local frame = _G["GroupLootFrame" .. i]
        if frame and frame:IsVisible() then
            if rollType == "info" then
                WowVision:speak(rollText(frame))
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
    WowVision:notify(L["No loot."])
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
