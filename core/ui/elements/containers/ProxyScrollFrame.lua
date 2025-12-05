local ProxyScrollFrame, parent = WowVision.ui:CreateElementType("ProxyScrollFrame", "ProxyWidget")

-- Define InfoClass fields at class level
ProxyScrollFrame.info:addFields({
    {
        key = "getNumEntries",
        default = function()
            return function(self)
                return nil
            end
        end,
    },
    { key = "getElement", default = nil, required = true },
    {
        key = "getElementIndex",
        default = function()
            return function(self, element)
                --Element here is the game's UI element, not a virtual element
                local id = element:GetID()
                return element.index or id
            end
        end,
    },
    {
        key = "getElementHeight",
        default = function()
            return function(self)
                return self.frame.buttonHeight
            end
        end,
    },
    {
        key = "getButtons",
        default = function()
            return function(self)
                return self.frame.buttons or { self.scrollChild:GetChildren() }
            end
        end,
    },
})

-- Override inherited defaults
ProxyScrollFrame.info:updateFields({
    { key = "displayType", default = "List" },
    { key = "sync", default = true },
})

function ProxyScrollFrame:initialize()
    parent.initialize(self)
    self.childPanel = WowVision.ui:CreateElement("GeneratorPanel", { generator = WowVision.ui.generator })
    self.buttons = {}
    self.currentElement = nil
    self.currentIndex = -1
    self.direction = "vertical"
end

function ProxyScrollFrame:getFocus()
    if self.childPanel and self.childPanel:getFocused() then
        return self.childPanel
    end
    return nil
end

function ProxyScrollFrame:focusCurrent()
    if self.currentElement then
        self.childPanel:focus()
    end
end

function ProxyScrollFrame:unfocusCurrent()
    if self.focus then
        self.childPanel:unfocus()
        self.focus = nil
    end
end

function ProxyScrollFrame:setFrame(frame)
    if not frame or frame:GetObjectType() ~= "ScrollFrame" then
        error("Tried to pass non-scroll frame to a ProxyScrollFrame.")
    end
    parent.setFrame(self, frame)
    local scrollChild = frame:GetScrollChild()
    self.scrollChild = scrollChild
    if scrollChild == nil then
        error("ScrollFrame has no scroll child.")
    end
    self.scrollBar = frame.scrollBar or frame.ScrollBar
    if not self.scrollBar then
        error("ProxyScrollFrame does not have scroll bar.")
    end
    self:updateButtons()
end

function ProxyScrollFrame:getInitialScrollOffset()
    if self.initialScrollOffset then
        return self.initialScrollOffset
    end
    self.initialScrollOffset = self.scrollChild:GetTop() - self.buttons[1]:GetTop()
    return self.initialScrollOffset
end

function ProxyScrollFrame:setCurrentIndex(index)
    local numEntries = self:getNumEntries()
    if index < 1 or (numEntries and index > numEntries) then
        error("Index out of bounds for scroll frame.")
    end
    self:unfocusCurrent()
    local originalScroll = self.scrollBar:GetValue()
    local offset = self:getInitialScrollOffset() + self:getElementHeight() * (index - 1)
    self.scrollBar:SetValue(offset)
    self:updateButtons()
    local newElement = self:findElementByIndex(index)
    if newElement then
        self.currentElement = index
        self.currentIndex = index
        local child = self:getElement(newElement)
        self:setChild(child)
        self.childPanel:onUpdate()
        return self.currentElement
    end

    --Element with matching index is not here, return to original position
    self.scrollBar:SetValue(originalScroll)
    self:updateButtons()
    newElement = self:findElementByIndex(index)
    if newElement then
        self.currentElement = newElement.index
        self.currentIndex = index
        self:setChild(self:getElement(newElement))
        return self.currentElement
    end
    error("Error retrieving original scroll element after failed scroll to index.")
end

function ProxyScrollFrame:findElementByIndex(index)
    for i = 1, #self.buttons do
        local button = self.buttons[i]
        if button and button:IsShown() and button:IsVisible() then
            local elementIndex = self:getElementIndex(button)
            if elementIndex == index then
                return button
            end
        end
    end
end

function ProxyScrollFrame:updateButtons()
    self.buttons = self:getButtons()
end

function ProxyScrollFrame:onUpdate()
    self.childPanel:onUpdate()
end

function ProxyScrollFrame:setChild(root)
    self.childPanel:setStartingElement(root)
end

function ProxyScrollFrame:onFocus()
    self:updateButtons()
    local numEntries = self:getNumEntries()
    if numEntries < 1 then
        return
    end
    if self.currentIndex < 1 or self.currentIndex > numEntries then
        self:setCurrentIndex(1)
    end
end

function ProxyScrollFrame:onUnfocus()
    self.childPanel:unfocus()
    self:setChild(nil)
    self.currentElement = nil
    self.currentIndex = -1
end

function ProxyScrollFrame:getDirectionKeys()
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

function ProxyScrollFrame:isContainer()
    return true
end
