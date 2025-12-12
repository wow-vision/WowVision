local module = WowVision.base:createModule("buffers")
local L = module.L
module:setLabel(L["Buffers"])

function module:onFullEnable()
    local group = WowVision.buffers.BufferGroup:new()
    group:setLabel(L["Buffers"])

    local general = WowVision.buffers:create("Static", {
        key = "general",
        label = L["General"],
    })
    general:addObject("Health", { unit = "player" })
    general:addObject("Power", { unit = "player" })
    general:addObject("PlayerXP", {})
    general:addObject("PlayerMoney", {})
    general:addObject("PVP", { unit = "player" })

    group:add(general)
    self.group = group
end

module:registerBinding({
    type = "Function",
    key = "buffers/previousItem",
    inputs = { "ALT-UP" },
    label = L["Previous Buffer Item"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        local buffer = module.group:getFocus()
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
        local buffer = module.group:getFocus()
        if buffer then
            buffer:UIFocusDirection(-1)
        end
    end,
})

module:registerBinding({
    type = "Function",
    key = "buffers/nextBuffer",
    inputs = { "ALT-RIGHT" },
    label = L["Next Buffer"],
    delay = 0.01,
    interruptSpeech = true,
    func = function()
        module.group:UIFocusDirection(1)
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
        module.group:UIFocusDirection(-1)
    end,
})
