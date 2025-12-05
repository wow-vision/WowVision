local Context, parent = WowVision.ui:CreateElementType("ConfirmationContext", "Context")

-- Define InfoClass fields at class level
Context.info:addFields({
    {
        key = "prompt",
        default = "Confirm?",
        set = function(obj, key, value)
            obj.prompt = value
            if obj.promptText then
                obj.promptText:setProp("text", value)
            end
        end,
    },
})

function Context:initialize()
    parent.initialize(self)
    self.direction = "vertical"
    self:addProp({
        key = "prompt",
        default = "Confirm?",
        set = function(value)
            self.prompt = value
            if self.promptText then
                self.promptText:setProp("text", value)
            end
        end,
    })

    self:addEvent("confirm")
    self:addEvent("cancel")

    self:createUI()
end

function Context:createUI()
    local panel = WowVision.ui:CreateElement("Panel")
    panel:setProp("layout", true)
    panel:setProp("shouldAnnounce", false)
    panel:setProp("direction", "vertical")

    self.promptText = WowVision.ui:CreateElement("Text")
    self.promptText:setProp("text", self.prompt)
    panel:add(self.promptText)

    self.confirmButton = WowVision.ui:CreateElement("Button")
    self.confirmButton:setLabel("Yes")
    self.confirmButton.events.click:subscribe(self, function(self, event)
        self:confirm()
    end)
    panel:add(self.confirmButton)

    self.cancelButton = WowVision.ui:CreateElement("Button")
    self.cancelButton:setLabel("No")
    self.cancelButton.events.click:subscribe(self, function(self, event)
        self:cancel()
    end)
    panel:add(self.cancelButton)

    self:add(panel)
end

function Context:confirm()
    self:emitEvent("confirm", self)
end

function Context:cancel()
    self:emitEvent("cancel", self)
end

function Context:getLabel()
    return "confirm"
end
