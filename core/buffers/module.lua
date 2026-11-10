local module = WowVision.base:createModule("buffers")
local L = module.L
module:setLabel(L["Buffers"])

-- Alt-Up and Alt-Down walk the current buffer's items. Items are appended,
-- so the newest sits last: Alt-Down moves toward it and Alt-Up toward the
-- first. Invert swaps both keys for players used to the earlier scheme,
-- where Alt-Up moved toward the newest item.
local settings = module:hasSettings()
settings:add({
    type = "Bool",
    key = "invertItemDirection",
    label = L["Invert Item Direction"],
    default = false,
})

-- The first Alt-Down after Alt was let go lands on the first item, and so does
-- entering a buffer (Alt-Left/Right, Alt-Ctrl-Left/Right). With Alt held,
-- Alt-Down walks on.
settings:add({
    type = "Bool",
    key = "alwaysStartAtTop",
    label = L["Always Start at Top"],
    default = false,
})

function WowVision.buffers.startsAtTop()
    return module.settings.alwaysStartAtTop
end

-- The first buffer key while Alt is held opens the buffers, letting go of Alt
-- closes them. The two sounds of Sku's reading panel (SkuTTS), the same files.
settings:add({
    type = "Bool",
    key = "openCloseSounds",
    label = L["Sounds When Opening and Closing"],
    default = true,
})

local function playRunSound(path)
    if module.settings.openCloseSounds then
        WowVision:play(path)
    end
end

function WowVision.buffers.runStarted()
    playRunSound("Sound/WowVision/alerts/on3_1.mp3")
end

function WowVision.buffers.runEnded()
    playRunSound("Sound/WowVision/alerts/off2.mp3")
end

local function itemDirection(direction)
    if module.settings.invertItemDirection then
        return -direction
    end
    return direction
end

function module:getDefaultData()
    -- Root group contains child groups
    local root = WowVision.buffers.RootBufferGroup:new()
    root:setLabel(L["Buffers"])

    -- General group
    local generalGroup = WowVision.buffers.BufferGroup:new()
    generalGroup:setLabel(L["General"])

    local generalBuffer = WowVision.buffers:create("Static", {
        label = L["General"],
        items = {
            { object = { type = "Health", units = { "player" } } },
            { object = { type = "Power", units = { "player" } } },
            { object = { type = "PlayerXP" } },
            { object = { type = "PlayerMoney" } },
            { object = { type = "PlayerBags" } },
            { object = { type = "PlayerDurability" } },
            { object = { type = "PlayerMail" } },
            { object = { type = "Hearthstone" } },
            { object = { type = "GameClock" } },
            { object = { type = "PVP", units = { "player" } } },
        },
    })

    generalGroup:add(generalBuffer)
    root:add(generalGroup)
    return WowVision.classes.instanceConfig(root)
end

function module:onFullEnable()
    local root = WowVision.buffers.RootBufferGroup:new(self.db.data)
    root:setDB({
        char = self.db.data,
        global = self.globalDB ~= nil and self.globalDB.data or nil,
    })
    self.root = root
end

-- Module-level scope moves every top-level buffer group (children ride
-- along inside their configs).
function module:onSetScope(scope)
    if self.root == nil then
        return
    end
    local field = self.root.class:getField("items")
    for _, item in ipairs(self.root.items or {}) do
        field:setComponentScope(self.root, item, scope)
    end
end

function module:getScopeState()
    if self.root == nil then
        return nil
    end
    local field = self.root.class:getField("items")
    local result = nil
    for _, item in ipairs(self.root.items or {}) do
        local side = field:scopeOf(item)
        if result == nil then
            result = side
        elseif result ~= side then
            return nil
        end
    end
    return result or "global"
end

function module:getGraphMenuItems(builder)
    if self.root then
        local field = self.root.class:getField("items")
        builder:addItem(
            WowVision.graph.ControlId.structural("buffers"),
            WowVision.graph.settings.controlFor(field, self.root)
        )
    end
end

-- The focused item's tooltip becomes the current one, for the tooltip keys
-- (Shift-Up and Shift-Down read it line by line): an item offering one
-- (getTooltipData, an aura's) sets it after every buffer key; an item without
-- one clears a tooltip the buffers set before, never one a window set.
local tooltipFromBuffers = false
function module:syncTooltip()
    local tooltip = WowVision.UIHost ~= nil and WowVision.UIHost.tooltip or nil
    if tooltip == nil then
        return
    end
    local buffer = self:getCurrentBuffer()
    local item = buffer ~= nil and buffer:getFocus() or nil
    local data = item ~= nil and item.getTooltipData ~= nil and item:getTooltipData() or nil
    if data ~= nil then
        local ok, err = pcall(tooltip.set, tooltip, nil, data)
        if not ok then
            geterrorhandler()(err)
        end
        tooltipFromBuffers = ok
    elseif tooltipFromBuffers then
        tooltip:reset()
        tooltipFromBuffers = false
    end
end

-- Helper to get current group
function module:getCurrentGroup()
    return self.root and self.root:getFocus()
end

-- Helper to get current buffer
function module:getCurrentBuffer()
    local group = self:getCurrentGroup()
    return group and group:getFocus()
end

-- Letting go of Alt ends a run through the buffers (Always Start at Top).
module:registerEvent("event", "MODIFIER_STATE_CHANGED")

function module:onEvent(event)
    if event == "MODIFIER_STATE_CHANGED" and not IsAltKeyDown() then
        WowVision.buffers.endRun()
    end
end

local function moveItem(direction)
    local buffer = module:getCurrentBuffer()
    if buffer then
        local newRun = WowVision.buffers.takeNewRun()
        buffer:UIMoveItem(itemDirection(direction), newRun and module.settings.alwaysStartAtTop)
        module:syncTooltip()
    end
end

-- Item navigation (Alt-Up/Down)
module:registerBinding({
    type = "Function",
    key = "buffers/previousItem",
    inputs = { "ALT-UP" },
    label = L["Previous Buffer Item"],
    interruptSpeech = true,
    func = function()
        moveItem(-1)
    end,
})

module:registerBinding({
    type = "Function",
    key = "buffers/nextItem",
    inputs = { "ALT-DOWN" },
    label = L["Next Buffer Item"],
    interruptSpeech = true,
    func = function()
        moveItem(1)
    end,
})

-- Buffer navigation (Alt-Left/Right)
module:registerBinding({
    type = "Function",
    key = "buffers/nextBuffer",
    inputs = { "ALT-RIGHT" },
    label = L["Next Buffer"],
    interruptSpeech = true,
    func = function()
        local group = module:getCurrentGroup()
        if group then
            group:UIFocusDirection(1)
            module:syncTooltip()
        end
    end,
})

module:registerBinding({
    type = "Function",
    key = "buffers/previousBuffer",
    inputs = { "ALT-LEFT" },
    label = L["Previous Buffer"],
    interruptSpeech = true,
    func = function()
        local group = module:getCurrentGroup()
        if group then
            group:UIFocusDirection(-1)
            module:syncTooltip()
        end
    end,
})

-- Group navigation (Alt-Ctrl-Left/Right)
module:registerBinding({
    type = "Function",
    key = "buffers/nextGroup",
    inputs = { "ALT-CTRL-RIGHT" },
    label = L["Next Buffer Group"],
    interruptSpeech = true,
    func = function()
        if module.root then
            module.root:UIFocusDirection(1)
            module:syncTooltip()
        end
    end,
})

module:registerBinding({
    type = "Function",
    key = "buffers/previousGroup",
    inputs = { "ALT-CTRL-LEFT" },
    label = L["Previous Buffer Group"],
    interruptSpeech = true,
    func = function()
        if module.root then
            module.root:UIFocusDirection(-1)
            module:syncTooltip()
        end
    end,
})
