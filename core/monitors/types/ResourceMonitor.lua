local L = WowVision:getLocale()
local monitors = WowVision.monitors
local steps = WowVision.resourceSteps
local powersDB = WowVision.gameDB:get("Power")

-- Resource monitor: sounds and speech for the player's own resources, any
-- of them (combo points, mana, energy, rage, ...). The monitor holds the
-- resource, the step size and the speech settings; every step is a rule of
-- its own with one plain alert (a sound and a speech switch). Picking the
-- resource, the step size or a default builds the steps anew with those
-- defaults; after that each step is edited like any rule. The steps follow
-- Blizzard's Combat Audio Alerts (resourceSteps.lua).

-- ---------------------------------------------------------------------------
-- The speech output of a step: on or off. What it says and in which voice,
-- speed and volume is the monitor's, for all its steps.
-- ---------------------------------------------------------------------------
local ResourceSpeech = WowVision.alerts:createOutput("ResourceSpeech")

function ResourceSpeech:onFire(message)
    if message.speak ~= nil then
        message.speak(message.text)
    end
end

-- ---------------------------------------------------------------------------
-- A step: a count (counted resources) or a percent threshold (bars). Its
-- value and label come from the monitor's setup, so its menu is its alert's
-- menu and nothing else.
-- ---------------------------------------------------------------------------
local ResourceStepRule = monitors.ruleRegistry:createType({ key = "ResourceStep" })

ResourceStepRule:addFields({
    { key = "value", type = "Number", default = 0, persist = true, showInUI = false },
    {
        key = "alert",
        type = "Alert",
        persist = true,
        label = L["Alert"],
        sortPriority = 3,
        alert = { key = "alert", label = L["Alert"] },
        outputs = {
            { type = "Sound", key = "sound", label = L["Sound Alert"] },
            { type = "ResourceSpeech", key = "tts", label = L["TTS Alert"] },
        },
    },
})

function ResourceStepRule:getAlert()
    return self.class:getField("alert"):getAlert(self)
end

-- The defaults a new step starts with (before it is stored): its sound and
-- which outputs are on.
function ResourceStepRule:setDefaults(soundPath, soundOn, speechOn)
    for _, output in ipairs(self:getAlert().outputs) do
        if output.key == "sound" then
            output.path = soundPath
            output.enabled = soundOn
            output.defaultEnabled = soundOn
        elseif output.key == "tts" then
            output.enabled = speechOn
            output.defaultEnabled = speechOn
        end
    end
end

function ResourceStepRule:fire(message)
    if self.enabled then
        self:getAlert():fire(message)
    end
end

-- The step's menu (core/graph/settings.lua renderObjectInto): the alert's
-- own menu, its Enabled switch and the sound and speech outputs, without
-- a level of its own ("Alert") in between.
function ResourceStepRule:renderGraphSettings(builder)
    local parameters = self:getAlert().parameters
    local label = parameters.label
    parameters.label = nil
    WowVision.graph.settings.renderInto(builder, parameters)
    parameters.label = label
end

function ResourceStepRule:getLabel()
    if self.label ~= nil and self.label ~= "" then
        return self.label
    end
    return tostring(self.value)
end

-- ---------------------------------------------------------------------------
-- The monitor
-- ---------------------------------------------------------------------------
local ResourceMonitor = monitors:createType("Resource")
ResourceMonitor.label = L["Resource"]
monitors.ResourceMonitor = ResourceMonitor

-- Whether the player has a resource now: its maximum is above 0 (the check
-- the Power object type makes). A hidden maximum cannot be compared and
-- counts as had.
local function playerHas(power)
    if UnitPowerMax == nil then
        return true
    end
    local maximum = UnitPowerMax("player", power.id)
    if WowVision.secrets.isSecret(maximum) then
        return true
    end
    return maximum ~= nil and maximum > 0
end

-- The resources to pick from: the ones the player has right now, out of
-- every resource the client knows (Forever knows all of Retail's), plus the
-- one already picked so a saved choice still reads.
local function powerChoices(monitor)
    local picked = monitor ~= nil and monitor.powerType or nil
    local result = {}
    for _, power in ipairs(powersDB.items) do
        if power.key == picked or playerHas(power) then
            tinsert(result, { value = power.key, label = power.label })
        end
    end
    return result
end

-- A new monitor starts on the player's main resource.
local function mainPowerKey()
    if UnitPowerType ~= nil then
        local _, token = UnitPowerType("player")
        if type(token) == "string" then
            local key = strlower(token):gsub("_", "")
            if powersDB:get(key) ~= nil then
                return key
            end
        end
    end
    return "mana"
end

local SIZE_CHOICES = {}
for _, size in ipairs(steps.SIZES) do
    tinsert(SIZE_CHOICES, { value = size, label = string.format(L["Every %d%%"], size) })
end

local SERIES_LABELS = {
    glass = L["Glass"],
    brass = L["Brass"],
    waterdrop = L["Water Drop"],
    stuck = L["Stuck"],
    notes = L["Rising Notes"],
}
local SERIES_CHOICES = {}
for _, key in ipairs(steps.SERIES_ORDER) do
    tinsert(SERIES_CHOICES, { value = key, label = SERIES_LABELS[key] })
end

local FORMAT_LABELS = {
    full = L["Name and Percent (Mana 40%)"],
    noPercent = L["Name and Number (Mana 40)"],
    tenths = L["Name and Tenths (Mana 4)"],
    noName = L["Percent Only (40%)"],
    number = L["Number Only (40)"],
    numberTenths = L["Tenths Only (4)"],
}
local FORMAT_CHOICES = {}
for _, key in ipairs(steps.FORMATS) do
    tinsert(FORMAT_CHOICES, { value = key, label = FORMAT_LABELS[key] })
end

local function speechSettings()
    local base = WowVision.base
    local speech = base ~= nil and base.speech or nil
    return speech ~= nil and speech.settings or nil
end

ResourceMonitor:addFields({
    { key = "powerType", type = "Choice", persist = true, label = L["Resource"], sortPriority = 2, choices = powerChoices, default = mainPowerKey },
    { key = "stepSize", type = "Choice", default = 20, persist = true, label = L["Steps (Bars)"], sortPriority = 2, choices = SIZE_CHOICES },
    { key = "soundSeries", type = "Choice", default = "glass", persist = true, label = L["Step Sounds"], sortPriority = 2, choices = SERIES_CHOICES },
    { key = "soundOn", type = "Bool", default = true, persist = true, label = L["Sound on Every Step"], sortPriority = 2 },
    { key = "speechOn", type = "Bool", default = true, persist = true, label = L["Speech on Every Step"], sortPriority = 2 },
    { key = "speechFormat", type = "Choice", default = "noPercent", persist = true, label = L["Speech Format"], sortPriority = 2, choices = FORMAT_CHOICES },
    {
        key = "speechVoice",
        type = "TtsVoice",
        persist = true,
        label = L["Voice"],
        sortPriority = 2,
        default = WowVision.classes.SPEECH_VOICE,
        followVoice = function()
            local settings = speechSettings()
            return settings ~= nil and settings.voiceID or 0
        end,
    },
    { key = "speechRate", type = "Number", default = 0, min = -10, max = 10, persist = true, label = L["Speech Rate"], sortPriority = 2 },
    { key = "speechVolume", type = "Number", default = 100, min = 0, max = 100, persist = true, label = L["Speech Volume"], sortPriority = 2 },
    { key = "speechGap", type = "Number", default = 0, min = 0, max = 5, step = 0.5, persist = true, label = L["Minimum Time Between Messages (seconds)"], sortPriority = 2 },
    -- What the steps were last built for; a change of the resource, step
    -- size or a default builds them anew.
    { key = "builtFor", type = "String", persist = true, showInUI = false },
})

ResourceMonitor:updateFields({
    {
        key = "rules",
        label = L["Steps"],
        -- The setup builds the steps; there is nothing to add by hand.
        availableTypes = function()
            return {}
        end,
    },
})

function ResourceMonitor:initialize(config)
    self._last = nil
    self._hidden = {}
    monitors.Monitor.initialize(self, config)
end

function ResourceMonitor:getLabel()
    if self.label ~= nil and self.label ~= "" then
        return self.label
    end
    local power = powersDB:get(self.powerType)
    return L["Resource"] .. ": " .. (power ~= nil and power.label or tostring(self.powerType))
end

function ResourceMonitor:isCounted()
    return steps.isCounted(self.powerType)
end

-- What the steps depend on, as one string.
function ResourceMonitor:buildKey()
    local size = self:isCounted() and "count" or tostring(self.stepSize)
    return table.concat({
        tostring(self.powerType),
        size,
        tostring(self.soundSeries),
        tostring(self.soundOn),
        tostring(self.speechOn),
    }, "|")
end

-- The label a built step gets: "40%" on a bar, "3" for a count.
local function stepLabel(counted, value)
    if counted then
        return tostring(value)
    end
    return value .. "%"
end

local function addStep(self, value, counted, soundPath)
    local rule = monitors.ruleRegistry:createTemporaryComponent({
        type = "ResourceStep",
        value = value,
        label = stepLabel(counted, value),
    })
    rule:setDefaults(soundPath, self.soundOn, self.speechOn)
    self.class:getField("rules"):addElement(self, rule)
end

-- Replace the steps by fresh ones for the resource (maximum: its current
-- maximum, used by counted resources).
function ResourceMonitor:buildSteps(maximum)
    local rulesField = self.class:getField("rules")
    while #(self.rules or {}) > 0 do
        rulesField:removeElement(self, #self.rules)
    end
    local counted = self:isCounted()
    local values = steps.build(counted, maximum, self.stepSize or 20)
    local sounds = steps.sounds(counted, values, self.soundSeries)
    for _, value in ipairs(values) do
        addStep(self, value, counted, sounds[value])
    end
    self.builtFor = self:buildKey()
    self._last = nil
end

-- A counted resource that grew (a talent adds combo points) gets the
-- missing steps; the steps it has stay as they are.
function ResourceMonitor:growSteps(maximum)
    local highest = -1
    for _, rule in ipairs(self.rules or {}) do
        if rule.value > highest then
            highest = rule.value
        end
    end
    if highest >= maximum then
        return
    end
    local values = steps.build(true, maximum)
    local sounds = steps.sounds(true, values, self.soundSeries)
    for value = highest + 1, maximum do
        addStep(self, value, true, sounds[value])
    end
end

-- Hidden values: the resource stays silent while the game hides it. Every
-- time a resource turns hidden or readable again the chat says so, with
-- what is hidden and the state around it (where, combat, the power the
-- game shows, the form, the game's own check, a WowVision menu open), so
-- a log shows what the hiding goes with.
local function hiddenDetails(power, currentHidden, maximumHidden)
    local parts = {}
    local which = {}
    if currentHidden then
        tinsert(which, "current")
    end
    if maximumHidden then
        tinsert(which, "maximum")
    end
    tinsert(parts, table.concat(which, " and "))
    local where = "world"
    if IsInInstance ~= nil then
        local inInstance, instanceType = IsInInstance()
        if inInstance then
            where = tostring(instanceType)
        end
    end
    tinsert(parts, where)
    tinsert(parts, InCombatLockdown ~= nil and InCombatLockdown() and "in combat" or "out of combat")
    if UnitPowerType ~= nil then
        local _, token = UnitPowerType("player")
        tinsert(parts, "shown power " .. tostring(token))
    end
    if GetShapeshiftFormID ~= nil then
        tinsert(parts, "form " .. tostring(GetShapeshiftFormID()))
    end
    if C_Secrets ~= nil and C_Secrets.ShouldUnitPowerBeSecret ~= nil then
        tinsert(parts, "game check " .. tostring(C_Secrets.ShouldUnitPowerBeSecret("player", power.id)))
    end
    local host = WowVision.graphHost
    if host ~= nil and host.focusedStack ~= nil then
        local ok, stack = pcall(host.focusedStack, host)
        tinsert(parts, "menu " .. ((ok and stack ~= nil) and "open" or "closed"))
    end
    return table.concat(parts, ", ")
end

function ResourceMonitor:noteHidden(power, currentHidden, maximumHidden)
    local hidden = currentHidden or maximumHidden
    if (self._hidden[power.key] or false) == hidden then
        return
    end
    self._hidden[power.key] = hidden
    if hidden then
        print("WowVision resource: " .. power.key .. " hidden (" .. hiddenDetails(power, currentHidden, maximumHidden) .. ")")
    else
        print("WowVision resource: " .. power.key .. " readable again")
    end
end

-- Read the resource: current and maximum, or nil while it is hidden or
-- the player does not have it.
function ResourceMonitor:read(power)
    local current = UnitPower("player", power.id)
    local maximum = UnitPowerMax("player", power.id)
    local currentHidden = WowVision.secrets.isSecret(current)
    local maximumHidden = WowVision.secrets.isSecret(maximum)
    self:noteHidden(power, currentHidden, maximumHidden)
    if currentHidden or maximumHidden then
        return nil
    end
    if maximum == nil or maximum <= 0 then
        return nil
    end
    return current, maximum
end

-- Speech, in the monitor's voice, speed and volume, spoken by the game like
-- Blizzard's own alerts. With a minimum time between messages, a message
-- that comes too soon waits, and only the newest one waiting is spoken.
function ResourceMonitor:say(text)
    local voice = self.speechVoice
    if voice == nil or voice == WowVision.classes.SPEECH_VOICE then
        local settings = speechSettings()
        voice = settings ~= nil and settings.voiceID or 0
    end
    self._lastSpoke = GetTime()
    C_VoiceChat.SpeakText(voice, WowVision.ttsCacheBust.bust(text), self.speechRate or 0, self.speechVolume or 100, false)
end

function ResourceMonitor:speak(text)
    local gap = self.speechGap or 0
    if gap > 0 and self._lastSpoke ~= nil and GetTime() - self._lastSpoke < gap then
        self._waitingSpeech = text
        return
    end
    self._waitingSpeech = nil
    self:say(text)
end

function ResourceMonitor:speakWaiting()
    local text = self._waitingSpeech
    if text == nil then
        return
    end
    if GetTime() - (self._lastSpoke or 0) >= (self.speechGap or 0) then
        self._waitingSpeech = nil
        self:say(text)
    end
end

function ResourceMonitor:message(power, counted, value)
    local monitor = self
    return {
        text = steps.text(self.speechFormat, counted, power.label, value),
        value = value,
        speak = function(text)
            monitor:speak(text)
        end,
    }
end

function ResourceMonitor:update()
    if not self.enabled then
        return
    end
    self:speakWaiting()
    local power = powersDB:get(self.powerType)
    if power == nil then
        return
    end
    local current, maximum = self:read(power)
    if current == nil then
        -- Hidden or gone: start over in silence when it is back.
        self._last = nil
        return
    end
    local counted = self:isCounted()
    if self.builtFor ~= self:buildKey() then
        self:buildSteps(maximum)
    elseif counted then
        self:growSteps(maximum)
    end
    local value = counted and current or steps.percent(current, maximum)
    local last = self._last
    self._last = value
    -- The first read settles in silence, like every monitor.
    if last == nil or last == value then
        return
    end
    local values = {}
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled then
            tinsert(values, rule.value)
        end
    end
    local stepValue = steps.crossed(counted, last, value, values)
    if stepValue == nil then
        return
    end
    local message = self:message(power, counted, stepValue)
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled and rule.value == stepValue then
            rule:fire(message)
        end
    end
end
