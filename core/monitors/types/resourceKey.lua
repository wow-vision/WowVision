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

-- Kept once it is built whole; a failed build is tried again next press.
local percentCurve = nil
local function curve()
    if percentCurve == nil then
        local built = C_CurveUtil.CreateCurve()
        built:SetType(Enum.LuaCurveType.Step)
        for _, point in ipairs(steps.percentCurvePoints()) do
            built:AddPoint(point[1], point[2])
        end
        percentCurve = built
    end
    return percentCurve
end

local function curvePercent(powerType)
    return UnitPowerPercent("player", powerType, false, curve())
end

-- A bar's percent: through the curve where the game has one (Retail,
-- Forever, Mists and TBC; the value may be hidden), else from the plain
-- numbers (Classic Era).
local function barPercent(powerType)
    if UnitPowerPercent ~= nil and C_CurveUtil ~= nil and C_CurveUtil.CreateCurve ~= nil then
        local ok, value = pcall(curvePercent, powerType)
        -- A hidden value throws on any comparison, even with nil; only its
        -- truth can be tested.
        if ok and value then
            return value
        end
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
    -- A hidden value is tested by its truth only: any comparison throws.
    local value
    if counted then
        value = UnitPower("player", powerType)
    else
        value = barPercent(powerType)
    end
    if not value then
        return
    end
    WowVision:speak(steps.readoutText(name, counted, value))
end

module:registerBinding({
    type = "Function",
    key = "monitors/speakMainResource",
    inputs = {},
    label = L["Speak Main Resource"],
    interruptSpeech = true,
    func = speakMainResource,
})
