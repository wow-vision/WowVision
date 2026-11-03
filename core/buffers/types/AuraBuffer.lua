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
--   dispel type, stacks, and the time left from the aura's tooltip, gated
--   on the duration through the game's string utilities, which take secret
--   numbers (C_StringUtil.TruncateWhenZero, WrapString).
-- - A tooltip of our own filled by index (GameTooltip:SetUnitAura), which
--   the game allows under restriction (measured 2026-10-24): the line count
--   is plain, the text secret. An aura exists while the tooltip has lines;
--   its first line is the name and its last the time left (or, for an aura
--   without a duration, its description).
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
    {
        key = "onlyMine",
        type = "Bool",
        label = L["Only My Auras"],
        persist = true,
        sortPriority = 2,
        default = false,
    },
})

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
    }
    return scanner
end

-- The time left, from the aura's tooltip, for the index read: the game
-- writes it as the last line ("12 seconds remaining") when the aura has a
-- duration, and no such line when it has none. The line cannot be
-- inspected, so it is kept only while the duration is non-zero, with the
-- total after it: "12 seconds remaining, of 18 seconds".
local function remainingText(unit, index, filter, duration)
    local scan = getScanner()
    if scan == nil then
        return ""
    end
    local lines = scan.fill(unit, index, filter)
    if lines < 2 then
        return ""
    end
    local last = scan.line(lines)
    if not secrets.hasText(last) then
        return ""
    end
    return whenNonZero(duration, ", " .. last .. ", " .. L["of"] .. " ", " " .. L["seconds"])
end

-- The aura as its tooltip tells it, where the index read is refused: the
-- name, then the last line (the time left, or the description of an aura
-- without a duration).
local function tooltipText(unit, index, filter)
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
    if lines >= 2 then
        text = text .. whenText(scan.line(lines), ", ", "")
    end
    return text
end

-- One aura, by its position in a unit's list: read afresh when spoken.
local AuraItem = WowVision.Class("AuraItem", WowVision.buffers.BufferItem)
AuraItem:addFields({
    { key = "unit" },
    { key = "filter" },
    { key = "index" },
    { key = "harmful" },
})

function AuraItem:getFocusString()
    local aura, allowed = auraAt(self.unit, self.index, self.filter)
    if not allowed then
        return tooltipText(self.unit, self.index, self.filter)
    end
    if aura == nil then
        return L["Gone"]
    end
    local text = aura.name
    text = text .. whenNonZero(aura.applications, ", ", " " .. L["stacks"])
    text = text .. remainingText(self.unit, self.index, self.filter, aura.duration)
    if self.harmful then
        text = text .. whenText(aura.dispelName, ", ", "")
    end
    return text
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
    for _, key in ipairs({ "sources", "onlyMine" }) do
        self.class:getField(key).events.valueChange:subscribe(self, function(subscriber, event, target)
            if target == subscriber then
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
    if self.onlyMine then
        return source.filter .. "|PLAYER"
    end
    return source.filter
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
                        tinsert(self.items, AuraItem:new({ unit = source.unit, filter = filter, index = i, harmful = source.filter == "HARMFUL" }))
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
