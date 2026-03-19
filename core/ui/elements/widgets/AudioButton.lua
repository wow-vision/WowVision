local AudioButton, parent = WowVision.ui:CreateElementType("AudioButton", "Button")

AudioButton.info:addFields({
    { key = "source", default = nil, compareMode = "direct" },
})

AudioButton.info:updateFields({
    { key = "displayType", default = "Button" },
})

function AudioButton:initialize()
    parent.initialize(self)
end

function AudioButton:getHoverSound()
    if self.source and self.source.play then
        self.source:play()
    end
    return nil
end
