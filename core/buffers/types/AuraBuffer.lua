local L = WowVision:getLocale()
local secrets = WowVision.secrets

-- The buffs and debuffs on a unit as a buffer: every one the game knows
-- about, not only those drawn on screen, for the player, the target, the
-- focus or the pet, in any combination (the Sources setting, in order).
--
-- Under Retail's secrets (in combat, in instances) the aura list is closed
-- to addons: reading an aura by index throws "Auras cannot be accessed when
-- secret while tainted", and every value of an aura that does come through
-- is secret: it cannot be compared, measured or formatted in Lua, but it
-- can be concatenated and spoken. So the buffer never does arithmetic on an
-- aura, and it has two ways to read one:
--
-- - The index read (C_UnitAuras.GetAuraDataByIndex), where allowed: name,
--   dispel type, stacks, and the time left and description from the aura's
--   tooltip; the stacks are gated through the game's string utilities,
--   which take secret numbers (C_StringUtil.TruncateWhenZero, WrapString).
-- - A tooltip of our own filled by index (GameTooltip:SetUnitAura), which
--   the game allows under restriction (measured 2026-10-24): the line count
--   is plain, the text secret. An aura exists while the tooltip has lines;
--   its first line is the name, with the dispel type on its right side,
--   then the description, and last the time left when the aura has a
--   duration. The stacks of the player's own auras come from Blizzard's
--   BuffFrame and DebuffFrame buttons, which are plain frames (see
--   stackText); a unit's other auras have no readable stack count.
--
-- Items stand for positions, not auras: a secret name cannot key a table.
-- The list rebuilds (once per frame at most) when the game says a source
-- unit's auras changed or the unit itself changed, and the focus stays on
-- its position. Each item reads the aura afresh when spoken.
local AuraBuffer = WowVision.buffers:createType("Aura")

-- More auras than any unit carries; the loop stops at the first empty index.
local MAX_INDEX = 80

local SOURCES = {
    { value = "player:HARMFUL", unit = "player", filter = "HARMFUL", label = L["Player Debuffs"], missing = L["no player"] },
    { value = "player:HELPFUL", unit = "player", filter = "HELPFUL", label = L["Player Buffs"], missing = L["no player"] },
    { value = "target:HARMFUL", unit = "target", filter = "HARMFUL", label = L["Target Debuffs"], missing = L["no target"] },
    { value = "target:HELPFUL", unit = "target", filter = "HELPFUL", label = L["Target Buffs"], missing = L["no target"] },
    { value = "focus:HARMFUL", unit = "focus", filter = "HARMFUL", label = L["Focus Debuffs"], missing = L["no focus"] },
    { value = "focus:HELPFUL", unit = "focus", filter = "HELPFUL", label = L["Focus Buffs"], missing = L["no focus"] },
    { value = "pet:HARMFUL", unit = "pet", filter = "HARMFUL", label = L["Pet Debuffs"], missing = L["no pet"] },
    { value = "pet:HELPFUL", unit = "pet", filter = "HELPFUL", label = L["Pet Buffs"], missing = L["no pet"] },
}
local SOURCE_BY_VALUE = {}
local SOURCE_CHOICES = {}
for _, source in ipairs(SOURCES) do
    SOURCE_BY_VALUE[source.value] = source
    tinsert(SOURCE_CHOICES, { value = source.value, label = source.label })
end
AuraBuffer.SOURCES = SOURCES

AuraBuffer:addFields({
    {
        key = "sources",
        type = "Array",
        label = L["Sources"],
        persist = true,
        sortPriority = 2,
        elementField = { type = "Choice", label = L["Source"], choices = SOURCE_CHOICES },
        default = function()
            return { "player:HARMFUL", "player:HELPFUL" }
        end,
    },
    -- Replaced by the Cast by Me filter (PLAYER): kept, hidden, so a buffer
    -- saved with it on still lists only the player's auras until that
    -- filter is set (see AuraBuffer:filterFor).
    {
        key = "onlyMine",
        type = "Bool",
        label = L["Only My Auras"],
        persist = true,
        showInUI = false,
        default = false,
    },
    -- What an aura says after its name, stacks and dispel type.
    {
        key = "speakRemaining",
        type = "Bool",
        label = L["Speak Time Remaining"],
        persist = true,
        default = true,
    },
    {
        key = "speakDescription",
        type = "Bool",
        label = L["Speak Description"],
        persist = true,
        default = true,
    },
})

-- Filters: the game's aura filter strings (AuraUtil.AuraFilters), passed
-- with the source's HELPFUL or HARMFUL to both the index read and the
-- tooltip fill, so they work under Retail's restriction too. Each is a
-- choice of Any (not passed), Only (the filter) or Not (negated: "!" on
-- clients with AuraUtil.AuraFilterNegationPrefix, Retail and WoW: Forever;
-- on the older clients only Cancelable has a negative, NOT_CANCELABLE).
-- Only the filters the client knows are offered.
local FILTERS = {
    { token = "PLAYER", label = L["Cast by Me"] },
    { token = "RAID", label = L["Castable or Dispellable by Me"] },
    { token = "CANCELABLE", label = L["Cancelable"], negative = "NOT_CANCELABLE" },
    { token = "CROWD_CONTROL", label = L["Crowd Control"] },
    { token = "RAID_PLAYER_DISPELLABLE", label = L["Dispellable by My Group"] },
    { token = "DISPELLABLE", label = L["Dispellable"] },
    { token = "EXTERNAL_DEFENSIVE", label = L["External Defensive"] },
    { token = "BIG_DEFENSIVE", label = L["Big Defensive"] },
    { token = "RAID_IN_COMBAT", label = L["Shown on Raid Frames in Combat"] },
    { token = "IMPORTANT", label = L["Important"] },
}

-- The filter tokens this client knows, and how it negates one (nil: no way).
local function clientFilters(auraFilters, negationPrefix)
    local known = {}
    for _, token in pairs(auraFilters or {}) do
        known[token] = true
    end
    local offered = {}
    for _, filter in ipairs(FILTERS) do
        if known[filter.token] then
            local notToken = nil
            if negationPrefix ~= nil then
                notToken = negationPrefix .. filter.token
            elseif filter.negative ~= nil and known[filter.negative] then
                notToken = filter.negative
            end
            tinsert(offered, { token = filter.token, label = filter.label, notToken = notToken })
        end
    end
    return offered
end
AuraBuffer.clientFilters = clientFilters

local OFFERED_FILTERS = clientFilters(
    AuraUtil ~= nil and AuraUtil.AuraFilters or nil,
    AuraUtil ~= nil and AuraUtil.AuraFilterNegationPrefix or nil
)
AuraBuffer.OFFERED_FILTERS = OFFERED_FILTERS

local filterFields = {}
for _, filter in ipairs(OFFERED_FILTERS) do
    local choices = { { value = "any", label = L["Any"] }, { value = "only", label = L["Only"] } }
    if filter.notToken ~= nil then
        tinsert(choices, { value = "not", label = L["Not"] })
    end
    tinsert(filterFields, {
        key = "filter_" .. filter.token,
        type = "Choice",
        label = filter.label,
        persist = true,
        sortPriority = 3,
        default = "any",
        choices = choices,
    })
end
AuraBuffer:addFields(filterFields)

-- The filter string for a source: its HELPFUL or HARMFUL and every filter
-- set to Only or Not. choices: token -> "any" | "only" | "not".
function AuraBuffer.buildFilter(base, offered, choices)
    local parts = { base }
    for _, filter in ipairs(offered) do
        local choice = choices[filter.token]
        if choice == "only" then
            tinsert(parts, filter.token)
        elseif choice == "not" and filter.notToken ~= nil then
            tinsert(parts, filter.notToken)
        end
    end
    return table.concat(parts, "|")
end

local whenNonZero = secrets.whenNonZero
local whenText = secrets.whenText

-- The index read: the aura, and whether the game allowed the read at all.
local function auraAt(unit, index, filter)
    local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
    if not ok then
        return nil, false
    end
    return aura, true
end

-- The scanning tooltip, made on first use (headless runs have no frames;
-- tests hand in a stand-in through AuraBuffer.scanner).
local SCAN_NAME = "WowVisionAuraScanTooltip"
local scanner = nil

local function getScanner()
    if scanner ~= nil then
        return scanner
    end
    if AuraBuffer.scanner ~= nil then
        scanner = AuraBuffer.scanner
        return scanner
    end
    if CreateFrame == nil then
        return nil
    end
    local tooltip = CreateFrame("GameTooltip", SCAN_NAME, UIParent, "GameTooltipTemplate")
    scanner = {
        -- Fill with one aura; the number of lines (0: no such aura).
        fill = function(unit, index, filter)
            tooltip:ClearLines()
            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            local ok = pcall(tooltip.SetUnitAura, tooltip, unit, index, filter)
            if not ok then
                return 0
            end
            return tooltip:NumLines()
        end,
        -- The left text of a line of the last fill.
        line = function(index)
            local fontString = _G[SCAN_NAME .. "TextLeft" .. index]
            return fontString ~= nil and fontString:GetText() or nil
        end,
        -- The right text of a line of the last fill. A right side the fill
        -- left unused is hidden and may still hold an earlier aura's text.
        right = function(index)
            local fontString = _G[SCAN_NAME .. "TextRight" .. index]
            if fontString == nil then
                return nil
            end
            local shown = fontString:IsShown()
            if not secrets.isSecret(shown) and not shown then
                return nil
            end
            return fontString:GetText()
        end,
    }
    return scanner
end

-- The tooltip lines first to last of the last fill, each after ", ".
local function joinedLines(scan, first, last)
    local text = ""
    for i = first, last do
        text = text .. whenText(scan.line(i), ", ", "")
    end
    return text
end

-- The lines after the name when the last one cannot be told apart (it is
-- the time left or, for an aura without a duration, the description). The
-- description setting keeps them all, in the game's order; with only the
-- time left wanted, the last line is the best guess.
local function unsplitText(scan, lines, wantRemaining, wantDescription)
    if lines < 2 then
        return ""
    end
    if wantDescription then
        return joinedLines(scan, 2, lines)
    end
    return wantRemaining and joinedLines(scan, lines, lines) or ""
end

-- The rest of the aura's tooltip, for the index read. The game writes the
-- name, then the description, then the time left as the last line
-- ("12 seconds remaining") when the aura has a duration, and no such line
-- when it has none. Returns the time left and the description, each led by
-- ", ". A secret duration cannot tell which case it is (unsplitText).
local function detailTexts(unit, index, filter, duration, wantRemaining, wantDescription)
    if not wantRemaining and not wantDescription then
        return "", ""
    end
    local scan = getScanner()
    if scan == nil then
        return "", ""
    end
    local lines = scan.fill(unit, index, filter)
    if lines < 2 then
        return "", ""
    end
    if secrets.isSecret(duration) then
        return "", unsplitText(scan, lines, wantRemaining, wantDescription)
    end
    if duration == nil or duration <= 0 then
        return "", wantDescription and joinedLines(scan, 2, lines) or ""
    end
    return wantRemaining and whenText(scan.line(lines), ", ", "") or "",
        wantDescription and joinedLines(scan, 2, lines - 1) or ""
end

-- Blizzard's button for one of the player's auras. Buttons hold the position
-- in the unit's whole list, so only an unfiltered read can match them: a
-- filter renumbers the positions, and another aura's count would be said. A
-- button that is hidden, for example a buff collapsed away, has none to give.
local PLAYER_FRAMES = {
    HELPFUL = { frame = "BuffFrame", auraType = "Buff" },
    HARMFUL = { frame = "DebuffFrame", auraType = "Debuff" },
}

local function playerButton(unit, index, filter)
    local source = PLAYER_FRAMES[filter]
    local container = source ~= nil and unit == "player" and _G[source.frame] or nil
    if not container or container.auraFrames == nil then
        return nil
    end
    for _, button in ipairs(container.auraFrames) do
        local info = button.buttonInfo
        if button.hasValidInfo and button.unit == unit and info ~= nil and info.auraType == source.auraType then
            if not secrets.isSecret(info.index) and info.index == index then
                return button
            end
        end
    end
    return nil
end

-- ", 3 stacks" from the button's count, which Blizzard only shows for two or
-- more. Not yet seen in the game with a stacking aura under restriction, so
-- it stays quiet if a button is not what it should be.
local function stackText(unit, index, filter)
    local ok, text = pcall(function()
        local button = playerButton(unit, index, filter)
        if button == nil or button.Count == nil then
            return ""
        end
        local shown = button.Count:IsShown()
        if not secrets.isSecret(shown) and not shown then
            return ""
        end
        return whenText(button.Count:GetText(), ", ", " " .. L["stacks"])
    end)
    return ok and text or ""
end

-- The aura as its tooltip tells it, where the index read is refused: the
-- name, the stacks if they can be read, for a debuff the dispel type, then
-- the other lines in the game's order (the description, then the time left
-- when the aura has a duration; which of the two the last line is cannot
-- be told under restriction, see unsplitText).
local function tooltipText(unit, index, filter, harmful, wantRemaining, wantDescription)
    local scan = getScanner()
    if scan == nil then
        return L["unavailable"]
    end
    local lines = scan.fill(unit, index, filter)
    if lines == 0 then
        return L["Gone"]
    end
    local text = scan.line(1)
    if not secrets.hasText(text) then
        text = L["unavailable"]
    end
    text = text .. stackText(unit, index, filter)
    if harmful then
        text = text .. whenText(scan.right(1), ", ", "")
    end
    return text .. unsplitText(scan, lines, wantRemaining, wantDescription)
end

-- One aura, by its position in a unit's list: read afresh when spoken.
local AuraItem = WowVision.Class("AuraItem", WowVision.buffers.BufferItem)
AuraItem:addFields({
    { key = "unit" },
    { key = "filter" },
    { key = "index" },
    { key = "harmful" },
    { key = "speakRemaining", type = "Bool", default = true },
    { key = "speakDescription", type = "Bool", default = true },
})

function AuraItem:getFocusString()
    local aura, allowed = auraAt(self.unit, self.index, self.filter)
    if not allowed then
        return tooltipText(self.unit, self.index, self.filter, self.harmful, self.speakRemaining, self.speakDescription)
    end
    if aura == nil then
        return L["Gone"]
    end
    -- name, stacks, time left, dispel type, then the description: the
    -- short facts first, the long text last
    local remaining, description =
        detailTexts(self.unit, self.index, self.filter, aura.duration, self.speakRemaining, self.speakDescription)
    local text = aura.name
    text = text .. whenNonZero(aura.applications, ", ", " " .. L["stacks"])
    text = text .. remaining
    if self.harmful then
        text = text .. whenText(aura.dispelName, ", ", "")
    end
    return text .. description
end

-- The aura's whole tooltip, for the tooltip keys (Shift-Up and Shift-Down
-- line by line): the game's own text, description included.
function AuraItem:getTooltipData()
    return { type = "Aura", unit = self.unit, index = self.index, filter = self.filter }
end

AuraBuffer.AuraItem = AuraItem

-- How many auras a unit has under a filter: by the index read where
-- allowed, by filling tooltips where not; nil when neither can tell.
local function countAuras(unit, filter)
    local scan = nil
    for i = 1, MAX_INDEX do
        local present
        if scan == nil then
            local aura, allowed = auraAt(unit, i, filter)
            if allowed then
                present = aura ~= nil
            else
                scan = getScanner()
                if scan == nil then
                    return nil
                end
            end
        end
        if scan ~= nil then
            present = scan.fill(unit, i, filter) > 0
        end
        if not present then
            return i - 1
        end
    end
    return MAX_INDEX
end

-- One shared frame rebuilds the live buffers, once per frame at most, when
-- a source unit's auras or the unit itself changed.
local live = setmetatable({}, { __mode = "k" })
local frame = nil
local anyDirty = false

local UNIT_EVENTS = { UNIT_AURA = true, UNIT_PET = true }
local WORLD_EVENTS = { PLAYER_TARGET_CHANGED = true, PLAYER_FOCUS_CHANGED = true, PLAYER_ENTERING_WORLD = true }

local function ensureFrame()
    if frame ~= nil or CreateFrame == nil then
        return
    end
    frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, event, unit)
        for buffer in pairs(live) do
            if buffer:listensTo(event, unit) then
                buffer.dirty = true
                anyDirty = true
            end
        end
    end)
    frame:SetScript("OnUpdate", function()
        if not anyDirty then
            return
        end
        anyDirty = false
        for buffer in pairs(live) do
            if buffer.dirty then
                buffer.dirty = false
                buffer:rebuild()
            end
        end
    end)
end

function AuraBuffer:initialize(obj)
    WowVision.buffers.Buffer.initialize(self, obj)
    self.dirty = false
    local keys = { "sources", "onlyMine", "speakRemaining", "speakDescription" }
    for _, filter in ipairs(OFFERED_FILTERS) do
        tinsert(keys, "filter_" .. filter.token)
    end
    for _, key in ipairs(keys) do
        self.class:getField(key).events.valueChange:subscribe(self, function(subscriber, event, target)
            if target == subscriber then
                -- setting Cast by Me retires the old Only My Auras
                if key == "filter_PLAYER" and subscriber.onlyMine then
                    subscriber.onlyMine = false
                end
                subscriber:rebuild()
            end
        end)
    end
    live[self] = true
    ensureFrame()
    self:rebuild()
end

-- Whether an event concerns one of this buffer's units. UNIT_AURA names the
-- unit; UNIT_PET names the owner (the player's pet changed).
function AuraBuffer:listensTo(event, unit)
    if WORLD_EVENTS[event] then
        return true
    end
    if not UNIT_EVENTS[event] then
        return false
    end
    for _, value in ipairs(self.sources or {}) do
        local source = SOURCE_BY_VALUE[value]
        if source ~= nil then
            if event == "UNIT_PET" then
                if source.unit == "pet" and unit == "player" then
                    return true
                end
            elseif source.unit == unit then
                return true
            end
        end
    end
    return false
end

function AuraBuffer:filterFor(source)
    local choices = {}
    for _, filter in ipairs(OFFERED_FILTERS) do
        choices[filter.token] = self["filter_" .. filter.token]
    end
    -- the old Only My Auras, until Cast by Me is set
    if self.onlyMine and (choices.PLAYER == nil or choices.PLAYER == "any") then
        choices.PLAYER = "only"
    end
    return AuraBuffer.buildFilter(source.filter, OFFERED_FILTERS, choices)
end

-- The auras of each source in the game's order, with no heading in the
-- way; a source with nothing to list says so instead ("Target Debuffs,
-- none", "Focus Debuffs, no focus", or unavailable). The focus keeps its
-- position.
function AuraBuffer:rebuild()
    if C_UnitAuras == nil or C_UnitAuras.GetAuraDataByIndex == nil then
        return
    end
    local index = self.index
    self.items = {}
    for _, value in ipairs(self.sources or {}) do
        local source = SOURCE_BY_VALUE[value]
        if source ~= nil then
            local message = nil
            if not UnitExists(source.unit) then
                message = source.missing
            else
                local filter = self:filterFor(source)
                local count = countAuras(source.unit, filter)
                if count == nil then
                    message = L["unavailable"]
                elseif count == 0 then
                    message = L["none"]
                else
                    for i = 1, count do
                        tinsert(self.items, AuraItem:new({
                            unit = source.unit,
                            filter = filter,
                            index = i,
                            harmful = source.filter == "HARMFUL",
                            speakRemaining = self.speakRemaining,
                            speakDescription = self.speakDescription,
                        }))
                    end
                end
            end
            if message ~= nil then
                tinsert(self.items, WowVision.buffers.MessageItem:new({ data = source.label .. ", " .. message }))
            end
        end
    end
    if index > #self.items then
        index = #self.items
    end
    self.index = index
end

-- Unnamed, the buffer is called by its one source, or Auras.
function AuraBuffer:getLabel()
    if self.label ~= nil and self.label ~= "" then
        return self.label
    end
    local sources = self.sources or {}
    if #sources == 1 and SOURCE_BY_VALUE[sources[1]] ~= nil then
        return SOURCE_BY_VALUE[sources[1]].label
    end
    return L["Auras"]
end

function AuraBuffer:unsubscribe()
    live[self] = nil
end

WowVision.buffers.AuraBuffer = AuraBuffer
