local Context, parent = WowVision.ui:CreateElementType("WindowContext", "StackContext")

-- Define InfoClass fields at class level
Context.info:addFields({
    { key = "window", default = nil, compareMode = "direct" },
    {
        key = "hookEscape",
        default = false,
        set = function(obj, key, value)
            obj:setHookEscape(value)
        end,
    },
    { key = "innate", default = false },
    { key = "onClose", default = nil, compareMode = "direct" },
})

function Context:initialize()
    parent.initialize(self)
    self.closeBinding = self:addBinding({
        binding = "close",
        targetFrame = self,
        enabled = false,
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
    WowVision.UIHost.windowManager:closeWindow(self.window, shouldHandleContext)
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
        if WowVision.consts.UI_DELAY > 0 then
            C_Timer.After(0.01, function()
                self:handleEscape()
            end)
        else
            self:handleEscape()
        end
        return true
    end
    return false
end
