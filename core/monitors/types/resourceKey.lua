local module = WowVision.base.monitors
local L = module.L
local steps = WowVision.resourceSteps
local powersDB = WowVision.gameDB:get("Power")

-- Speak Main Resource: one key (none by default) that says the resource the
-- game shows for the player now: "energy 80%" in cat form, "mana 43%" in
-- caster form, "rage 20%", or the count of a counted resource. It works
-- while the game hides the value (Retail and WoW: Forever hide the player's
-- mana and energy from addons, even out of combat): the value is only
-- joined into the spoken text, never compared, and a bar's percent comes
-- from the game's own curve. The bar is on screen for every sighted player.

-- TRACE (temporary, while the key is tried in game): what each press does,
-- in the chat.
local function trace(text)
    print("WowVision main resource: " .. text)
end

local percentCurve = nil
local function curve()
    if percentCurve == nil then
        percentCurve = C_CurveUtil.CreateCurve()
        percentCurve:SetType(Enum.LuaCurveType.Step)
        for _, point in ipairs(steps.percentCurvePoints()) do
            percentCurve:AddPoint(point[1], point[2])
        end
    end
    return percentCurve
end

-- A bar's percent: through the curve where the game has one (the value may
-- be hidden), else from the plain numbers (classic clients).
local function barPercent(powerType)
    if UnitPowerPercent ~= nil and C_CurveUtil ~= nil and C_CurveUtil.CreateCurve ~= nil then
        local ok, value = pcall(UnitPowerPercent, "player", powerType, false, curve())
        -- A hidden value throws on any comparison, even with nil; only its
        -- truth can be tested.
        if ok and value then
            return value
        end
        trace("percent function: " .. (ok and "no value" or tostring(value)))
    end
    local current = UnitPower("player", powerType)
    local maximum = UnitPowerMax("player", powerType)
    if WowVision.secrets.isSecret(current) or WowVision.secrets.isSecret(maximum) then
        return nil
    end
    return steps.percent(current, maximum)
end

local function speakMainResource()
    local powerType, token = UnitPowerType("player")
    if powerType == nil then
        return
    end
    local key = type(token) == "string" and strlower(token):gsub("_", "") or nil
    local entry = key ~= nil and powersDB:get(key) or nil
    local name = entry ~= nil and entry.label or (token ~= nil and _G[token]) or ""
    local counted = steps.isCounted(key)
    local value
    if counted then
        value = UnitPower("player", powerType)
    else
        value = barPercent(powerType)
    end
    if not value then
        trace("no value for " .. tostring(token))
        return
    end
    trace("speaking " .. tostring(token) .. (WowVision.secrets.isSecret(value) and " (hidden value)" or ""))
    WowVision:speak(steps.readoutText(name, counted, value))
end

module:registerBinding({
    type = "Function",
    key = "monitors/speakMainResource",
    inputs = {},
    label = L["Speak Main Resource"],
    interruptSpeech = true,
    func = function()
        trace("key pressed")
        local ok, err = pcall(speakMainResource)
        if not ok then
            trace("error: " .. tostring(err))
        end
    end,
})
