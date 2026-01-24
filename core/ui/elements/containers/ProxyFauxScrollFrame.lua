local ProxyFauxScrollFrame, parent = WowVision.ui:CreateElementType("ProxyFauxScrollFrame", "ProxyWidget")

-- Define InfoClass fields at class level
ProxyFauxScrollFrame.info:addFields({
    {
        key = "getNumEntries",
        default = function()
            return function(self)
                return 0
            end
        end,
    },
    { key = "getElement", default = nil, required = true },
    {
        key = "getElementIndex",
        default = function()
            return function(self, button)
                local offset = FauxScrollFrame_GetOffset(self.frame) or 0
                return button:GetID() + offset
            end
        end,
    },
    {
        key = "getButtons",
        default = function()
            return function(self)
                return {}
            end
        end,
        required = true,
    },
    {
        key = "buttonHeight",
        default = nil,
        required = true,
    },
    {
        key = "updateFunction",
        default = nil,
        required = true,
    },
})

-- Override inherited defaults
ProxyFauxScrollFrame.info:updateFields({
    { key = "displayType", default = "List" },
    { key = "sync", default = true },
})

function ProxyFauxScrollFrame:initialize()
    parent.initialize(self)
    self.childPanel = WowVision.ui:CreateElement("GeneratorPanel", { generator = WowVision.ui.generator })
    self.buttons = {}
    self.currentElement = nil
    self.currentIndex = -1
    self.direction = "vertical"
end

function ProxyFauxScrollFrame:getFocus()
    if self.childPanel and self.childPanel:getFocused() then
        return self.childPanel
    end
    return nil
end

function ProxyFauxScrollFrame:focusCurrent()
    if self.currentElement then
        self.childPanel:focus()
    end
end

function ProxyFauxScrollFrame:unfocusCurrent()
    if self.focus then
        self.childPanel:unfocus()
        self.focus = nil
    end
end

function ProxyFauxScrollFrame:setFrame(frame)
    if not frame or frame:GetObjectType() ~= "ScrollFrame" then
        error("Tried to pass non-scroll frame to a ProxyFauxScrollFrame.")
    end
    parent.setFrame(self, frame)
end

function ProxyFauxScrollFrame:onSetInfo()
    parent.onSetInfo(self)
    if self.frame then
        self:updateButtons()
    end
end

function ProxyFauxScrollFrame:scrollToIndex(index)
    local pixelOffset = (index - 1) * self.buttonHeight
    FauxScrollFrame_OnVerticalScroll(self.frame, pixelOffset, self.buttonHeight, self.updateFunction)
end

function ProxyFauxScrollFrame:setCurrentIndex(index)
    local numEntries = self:getNumEntries()
    if index < 1 or (numEntries and index > numEntries) then
        return nil
    end

    self:unfocusCurrent()

    -- Check if the item is currently visible
    local offset = FauxScrollFrame_GetOffset(self.frame) or 0
    local numDisplayed = #self.buttons

    -- If index is not in visible range, scroll to it
    if index <= offset or index > offset + numDisplayed then
        self:scrollToIndex(index)
        self:updateButtons()
    end

    -- Find the button for this index
    local button = self:findButtonByIndex(index)
    if button then
        self.currentIndex = index
        self.currentElement = button
        local child = self:getElement(button)
        self:setChild(child)
        self.childPanel:onUpdate()
        return index
    end

    return nil
end

function ProxyFauxScrollFrame:findButtonByIndex(index)
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button then
            local buttonIndex = self:getElementIndex(button)
            if buttonIndex == index then
                return button
            end
        end
    end
    return nil
end

function ProxyFauxScrollFrame:updateButtons()
    self.buttons = self:getButtons()
end

function ProxyFauxScrollFrame:onUpdate()
    self.childPanel:onUpdate()
end

function ProxyFauxScrollFrame:setChild(root)
    self.childPanel:setStartingElement(root)
end

function ProxyFauxScrollFrame:onFocus()
    self:updateButtons()
    local numEntries = self:getNumEntries()
    if numEntries < 1 then
        return
    end
    if self.currentIndex < 1 or self.currentIndex > numEntries then
        self:setCurrentIndex(1)
    else
        -- Re-focus current index in case display changed
        self:setCurrentIndex(self.currentIndex)
    end
end

function ProxyFauxScrollFrame:onUnfocus()
    self.childPanel:unfocus()
    self:setChild(nil)
    self.currentElement = nil
    self.currentIndex = -1
end

function ProxyFauxScrollFrame:getDirectionKeys()
    if self.direction == "vertical" then
        return "up", "down"
    elseif self.direction == "horizontal" then
        return "left", "right"
    elseif self.direction == "tab" then
        return "previous", "next"
    elseif self.direction == "grid" then
        return "up", "right", "down", "left"
    end
    return nil
end

function ProxyFauxScrollFrame:isContainer()
    return true
end
