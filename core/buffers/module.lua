local module = WowVision.base:createModule("buffers")
local L = module.L
module:setLabel(L["Buffers"])

function module:onFullEnable()
    -- Root group contains child groups
    local root = WowVision.buffers.BufferGroup:new()
    root:setLabel(L["Buffers"])

    -- General group
    local generalGroup = WowVision.buffers.BufferGroup:new()
    generalGroup:setLabel(L["General"])

    local generalBuffer = WowVision.buffers:create("Static", {
        key = "general",
        label = L["General"],
        objects = {
            { type = "Health", params = { unit = "player" } },
            { type = "Power", params = { unit = "player" } },
            { type = "PlayerXP" },
            { type = "PlayerMoney" },
            { type = "PVP", params = { unit = "player" } },
        },
    })

    generalGroup:add(generalBuffer)
    root:add(generalGroup)

    self.root = root
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

-- Item navigation (Alt-Up/Down)
module:registerBinding({
    type = "Function",
    key = "buffers/previousItem",
    inputs = { "ALT-UP" },
    label = L["Previous Buffer Item"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        local buffer = module:getCurrentBuffer()
        if buffer then
            buffer:UIFocusDirection(1)
        end
    end,
})

module:registerBinding({
    type = "Function",
    key = "buffers/nextItem",
    inputs = { "ALT-DOWN" },
    label = L["Next Buffer Item"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        local buffer = module:getCurrentBuffer()
        if buffer then
            buffer:UIFocusDirection(-1)
        end
    end,
})

-- Buffer navigation (Alt-Left/Right)
module:registerBinding({
    type = "Function",
    key = "buffers/nextBuffer",
    inputs = { "ALT-RIGHT" },
    label = L["Next Buffer"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        local group = module:getCurrentGroup()
        if group then
            group:UIFocusDirection(1)
        end
    end,
})

module:registerBinding({
    type = "Function",
    key = "buffers/previousBuffer",
    inputs = { "ALT-LEFT" },
    label = L["Previous Buffer"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        local group = module:getCurrentGroup()
        if group then
            group:UIFocusDirection(-1)
        end
    end,
})

-- Group navigation (Alt-Ctrl-Left/Right)
module:registerBinding({
    type = "Function",
    key = "buffers/nextGroup",
    inputs = { "ALT-CTRL-RIGHT" },
    label = L["Next Buffer Group"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        if module.root then
            module.root:UIFocusDirection(1)
        end
    end,
})

module:registerBinding({
    type = "Function",
    key = "buffers/previousGroup",
    inputs = { "ALT-CTRL-LEFT" },
    label = L["Previous Buffer Group"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        if module.root then
            module.root:UIFocusDirection(-1)
        end
    end,
})
