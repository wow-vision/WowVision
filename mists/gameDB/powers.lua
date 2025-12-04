local L = WowVision:getLocale()
local db = WowVision.gameDB:get("Power")

local powerInfo = WowVision.info.InfoManager:new()
powerInfo:addFields({
    { key = "key", required = true, once = true },
    { key = "id", required = true },
    { key = "label", required = true },
    { key = "minimum", required = true, default = 0 },
})

local function addPower(info)
    local obj = {}
    powerInfo:set(obj, info)
    db:register(obj.key, obj)
    return obj
end

local function addPowers(powers)
    for _, power in ipairs(powers) do
        addPower(power)
    end
end

addPowers({
    { key = "alternate", id = Enum.PowerType.Alternate, label = L["alternate"] },
    { key = "alternateencounter", id = Enum.PowerType.AlternateEncounter, label = L["alternate encounter"] },
    { key = "alternatemount", id = Enum.PowerType.AlternateMount, label = L["alternate mount"] },
    { key = "alternatequest", id = Enum.PowerType.AlternateQuest, label = L["alternate quest"] },
    { key = "arcanecharges", id = Enum.PowerType.ArcaneCharges, label = L["arcane charges"] },
    { key = "balance", id = Enum.PowerType.Balance, minimum = -100, label = L["balance"] },
    { key = "burningembers", id = Enum.PowerType.BurningEmbers, label = L["burning embers"] },
    { key = "chi", id = Enum.PowerType.Chi, label = L["chi"] },
    { key = "combopoints", id = Enum.PowerType.ComboPoints, label = L["combo points"] },
    { key = "demonicfury", id = Enum.PowerType.DemonicFury, label = L["demonic fury"] },
    { key = "energy", id = Enum.PowerType.Energy, label = L["energy"] },
    { key = "essence", id = Enum.PowerType.Essence, label = L["essence"] },
    { key = "focus", id = Enum.PowerType.Focus, label = L["focus"] },
    { key = "fury", id = Enum.PowerType.Fury, label = L["fury"] },
    { key = "happiness", id = Enum.PowerType.Happiness, label = L["happiness"] },
    { key = "holypower", id = Enum.PowerType.HolyPower, label = L["holy power"] },
    { key = "insanity", id = Enum.PowerType.Insanity, label = L["insanity"] },
    { key = "lunarpower", id = Enum.PowerType.LunarPower, label = L["lunar power"] },
    { key = "maelstrom", id = Enum.PowerType.Maelstrom, label = L["maelstrom"] },
    { key = "mana", id = Enum.PowerType.Mana, label = L["mana"] },
    { key = "pain", id = Enum.PowerType.Pain, label = L["pain"] },
    { key = "rage", id = Enum.PowerType.Rage, label = L["rage"] },
    { key = "runeblood", id = Enum.PowerType.RuneBlood, label = L["blood runes"] },
    { key = "runechromatic", id = Enum.PowerType.RuneChromatic, label = L["death runes"] },
    { key = "runefrost", id = Enum.PowerType.RuneFrost, label = L["frost runes"] },
    { key = "runeunholy", id = Enum.PowerType.RuneUnholy, label = L["unholy runes"] },
    { key = "runes", id = Enum.PowerType.Runes, label = L["runes"] },
    { key = "runicpower", id = Enum.PowerType.RunicPower, label = L["runic power"] },
    { key = "shadoworbs", id = Enum.PowerType.ShadowOrbs, label = L["shadow orbs"] },
    { key = "soulshards", id = Enum.PowerType.SoulShards, label = L["soul shards"] },
})
