local L = WowVision:getLocale()
local monitors = WowVision.monitors
local steps = WowVision.resourceSteps
local powersDB = WowVision.gameDB:get("Power")

-- Resource monitor: sounds and speech for the player's own resources
-- (combo points, holy power, mana, energy, rage, ...). The monitor holds the
-- resource, the step size and the speech settings; every step is stored as
-- a rule with one plain alert (a sound and a speech switch), shown in the
-- monitor's Steps submenu as an ordinary alert button. Picking the
-- resource, the step size or a default builds the steps anew with those
-- defaults; after that each step's alert is edited like any alert. The
-- steps follow Blizzard's Combat Audio Alerts (resourceSteps.lua).
--
-- Retail and WoW: Forever hide the player's mana and energy from addons,
-- even out of combat: a hidden value cannot be compared, so those are left
-- out of the monitor's list. The Speak Main Resource key (resourceKey.lua)
-- still speaks them.

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
-- value and label come from the monitor's setup; the monitor's Steps
-- submenu shows only its alert.
-- ---------------------------------------------------------------------------
local ResourceStepRule = monitors.ruleRegistry:createType({ key = "ResourceStep" })

ResourceStepRule:addFields({
    { key = "value", type = "Number", default = 0, persist = true, showInUI = false },
    {
        key = "alert",
        type = "Alert",
        persist = true,
        label = L["Alert"],
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
    self:getAlert():fire(message)
end

-- Whether the step can be heard: its alert is on with at least one output
-- on. A silent step does not take a crossing from the steps around it.
function ResourceStepRule:isAudible()
    if not self.enabled then
        return false
    end
    local alert = self:getAlert()
    if not alert.enabled then
        return false
    end
    for _, output in ipairs(alert.outputs) do
        if output.enabled then
            return true
        end
    end
    return false
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

-- Whether the monitor can follow a resource of the player's now: the game
-- does not hide its value (Retail and WoW: Forever hide mana and energy,
-- C_Secrets says so; measured on Forever 2026-11-15) and its maximum is
-- above 0 (the check the Power object type makes). A hidden maximum alone
-- cannot be compared and counts as had. Speak Main Resource
-- (resourceKey.lua) reads the hidden ones.
local function playerHas(power)
    if C_Secrets ~= nil and C_Secrets.ShouldUnitPowerBeSecret ~= nil then
        local ok, hidden = pcall(C_Secrets.ShouldUnitPowerBeSecret, "player", power.id)
        if ok and hidden == true then
            return false
        end
    end
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

-- A new monitor starts on the player's main resource when the monitor can
-- follow it, else on the first one it can (on Retail and Forever the main
-- resource is often a hidden bar: combo points or holy power then).
local function mainPowerKey()
    if UnitPowerType ~= nil then
        local _, token = UnitPowerType("player")
        if type(token) == "string" then
            local key = strlower(token):gsub("_", "")
            local power = powersDB:get(key)
            if power ~= nil and playerHas(power) then
                return key
            end
        end
    end
    local choices = powerChoices(nil)
    if choices[1] ~= nil then
        return choices[1].value
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
        -- The steps show as alert buttons in the Steps submenu
        -- (renderGraphSettings below), not as a rule list.
        showInUI = false,
        -- The setup builds the steps; there is nothing to add by hand.
        availableTypes = function()
            return {}
        end,
    },
})

-- The fields the steps are built from: a change of one builds them anew.
local BUILD_FIELDS = { "powerType", "stepSize", "soundSeries", "soundOn", "speechOn" }

function ResourceMonitor:initialize(config)
    monitors.Monitor.initialize(self, config)
    for _, key in ipairs(BUILD_FIELDS) do
        self.class:getField(key).events.valueChange:subscribe(self, function(self, event, target)
            if target == self then
                self._buildKey = nil
            end
        end)
    end
end

-- The monitor's menu (core/graph/settings.lua renderObjectInto): its
-- settings, then the Steps submenu.
function ResourceMonitor:renderGraphSettings(builder)
    local graph = WowVision.graph
    local settings = graph.settings
    for _, field in ipairs(self.class:getFields()) do
        if field.showInUI ~= false then
            builder:addItem(graph.ControlId.structural("field:" .. field.key), settings.controlFor(field, self))
        end
    end
    local monitor = self
    builder:addItem(
        graph.ControlId.structural("steps"),
        graph.nodes.button({
            label = function()
                return L["Steps"] .. " (" .. #(monitor.rules or {}) .. ")"
            end,
            opensLevel = true,
            onActivate = function()
                settings.pushScreen("steps:" .. tostring(monitor), function(screen)
                    monitor:renderStepAlerts(screen)
                end)
            end,
        })
    )
end

-- The Steps submenu: one button per step, each opening the step's alert
-- like any alert button in the addon (Enabled, Sound Alert, TTS Alert).
function ResourceMonitor:renderStepAlerts(builder)
    local graph = WowVision.graph
    local settings = graph.settings
    builder:pushContext("steps", L["Steps"])
    -- Built on the next read of the resource; until then (monitor off,
    -- resource not readable now) the list would be empty or stale.
    if self.builtFor ~= self:buildKey() then
        builder:addItem(graph.ControlId.structural("notBuilt"), graph.nodes.button({ label = L["No steps yet"] }))
        builder:popContext()
        return
    end
    for _, rule in ipairs(self.rules or {}) do
        local step = rule
        builder:addItem(
            graph.ControlId.forObject(step),
            graph.nodes.button({
                label = step:getLabel(),
                opensLevel = true,
                onActivate = function()
                    local parameters = step:getAlert().parameters
                    parameters.label = step:getLabel()
                    settings.pushScreen("alert:" .. tostring(step), function(screen)
                        settings.renderInto(screen, parameters)
                    end)
                end,
            })
        )
    end
    builder:popContext()
end

function ResourceMonitor:isCounted()
    return steps.isCounted(self.powerType)
end

-- What the steps depend on, as one string; kept until one of its fields
-- changes (update compares it every frame).
function ResourceMonitor:buildKey()
    if self._buildKey == nil then
        local size = self:isCounted() and "count" or tostring(self.stepSize)
        self._buildKey = table.concat({
            tostring(self.powerType),
            size,
            tostring(self.soundSeries),
            tostring(self.soundOn),
            tostring(self.speechOn),
        }, "|")
    end
    return self._buildKey
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

-- Read the resource: current and maximum, or nil while the game hides it
-- (the list leaves hidden ones out, but a saved pick or a game change can
-- still meet one) or the player does not have it.
function ResourceMonitor:read(power)
    local current = UnitPower("player", power.id)
    local maximum = UnitPowerMax("player", power.id)
    if WowVision.secrets.isSecret(current) or WowVision.secrets.isSecret(maximum) then
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
        -- Switched back on, it settles in silence on what it finds.
        self._last = nil
        self._waitingSpeech = nil
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
        if rule:isAudible() then
            tinsert(values, rule.value)
        end
    end
    local stepValue = steps.crossed(counted, last, value, values)
    if stepValue == nil then
        return
    end
    local message = self:message(power, counted, stepValue)
    for _, rule in ipairs(self.rules or {}) do
        if rule.value == stepValue and rule:isAudible() then
            rule:fire(message)
        end
    end
end
