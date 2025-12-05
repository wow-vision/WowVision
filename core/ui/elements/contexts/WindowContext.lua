local Context, parent = WowVision.ui:CreateElementType("WindowContext", "StackContext")

-- Define InfoClass fields at class level
Context.info:addFields({
    { key = "hookEscape", default = false },
    { key = "innate", default = false },
})

function Context:initialize(window)
    parent.initialize(self)
    self.window = window
    self.closeBinding = self:addBinding({
        binding = "close",
        targetFrame = self,
        enabled = false,
    })
    self:addProp({
        key = "hookEscape",
        default = false,
    })
    self:addProp({
        key = "innate",
        default = false,
    })

    self._open = true
end

function Context:setHookEscape(value)
    self.hookEscape = value
    self.closeBinding.enabled = value
end

function Context:add(element, index)
    parent.add(self, element, index)
    element:setContext(self)
end

function Context:onUnfocus()
    if self.innate and self._open then
        self:closeWindow()
    end
end

function Context:closeWindow(shouldHandleContext)
    if not self._open then
        return
    end
    self._open = false
    if self.onClose then
        self:onClose()
    end
    -- self.window is the config object from CreateElement, ref contains the actual Window
    WowVision.UIHost.windowManager:closeWindow(self.window.ref, shouldHandleContext)
end

function Context:handleEscape()
    local peak = self.children[#self.children]
    if peak then
        self:pop()
    end
    if #self.children == 0 then
        self:closeWindow()
    end
end

function Context:onRemove()
    self:closeWindow(false)
    parent.onRemove(self)
end

function Context:onBindingPressed(binding)
    if self.hookEscape and binding.key == "close" then
        WowVision.base.speech:stop()
        C_Timer.After(0.01, function()
            self:handleEscape()
        end)
        return true
    end
    return false
end
