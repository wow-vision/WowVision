local module = WowVision.base.windows:createModule("GameMenu")
local L = module.L
module:setLabel(L["Game Menu"])

local graph = WowVision.graph
local ControlId = graph.ControlId

-- The escape menu: the pilot screen for the graph framework. Enumerates the
-- menu's live buttons each rebuild; Enter clicks the real button securely via
-- the node's Click binding.
local function buttonLabel(button)
    return function()
        local text = button:GetText()
        if text ~= nil and text ~= "" then
            return text
        end
        local regions = { button:GetRegions() }
        for _, region in ipairs(regions) do
            if region.GetText ~= nil then
                local regionText = region:GetText()
                if regionText ~= nil and regionText ~= "" then
                    return regionText
                end
            end
        end
        return nil
    end
end

local function render(builder, screen)
    local frame = GameMenuFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    local buttons = {}
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:GetObjectType() == "Button" and child:IsShown() then
            tinsert(buttons, child)
        end
    end
    table.sort(buttons, function(a, b)
        return a:GetTop() > b:GetTop()
    end)

    -- One tab stop per entry, matching the old tab-cycled menu.
    builder:pushContext(L["Menu"])
    for _, button in ipairs(buttons) do
        builder:beginStop()
        builder:addItem(ControlId.forObject(button), {
            controlType = graph.controlTypes.button,
            announcements = { { text = buttonLabel(button), kind = graph.kinds.label } },
            bindings = {
                { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = button },
            },
        })
    end
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "GameMenuFrame",
    frameName = "GameMenuFrame",
    graphScreen = { render = render },
})
