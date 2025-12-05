local ProxyEditBox, parent = WowVision.ui:CreateElementType("ProxyEditBox", "ProxyWidget")
local L = WowVision:getLocale()

-- Define InfoClass fields at class level
ProxyEditBox.info:addFields({
    { key = "autoInputOnFocus", default = true },
    { key = "hookTab", default = true },
    { key = "hookEnter", default = false },
    { key = "fixAutoFocus", default = false },
})

function ProxyEditBox:initialize()
    parent.initialize(self)
end

function ProxyEditBox:getValue()
    if not self.frame then
        return nil
    end
    if self.frame:IsNumeric() then
        return self.frame:GetNumber()
    end
    return self.frame:GetText()
end

function ProxyEditBox:onFocus()
    parent.onFocus(self)
    if not self.frame then
        return
    end
    if self.fixAutoFocus then
        self.frame:SetAutoFocus(false)
    end
    if self.frame:IsEnabled() then
        if self.autoInputOnFocus then
            self:input()
        end
    end
end

function ProxyEditBox:input()
    if not self.frame then
        return
    end
    self.frame:SetFocus()
    if self.hookTab then
        self.frame:SetScript("OnTabPressed", function(frame)
            local binding
            if IsShiftKeyDown() then
                binding = WowVision.input:getBinding("previous")
            else
                binding = WowVision.input:getBinding("next")
            end
            WowVision.UIHost:onBindingPressed(binding)
        end)
    end
    if self.hookEnter then
        self.frame:SetScript("OnEnterPressed", function(frame)
            self.frame:ClearFocus()
        end)
    end
end

function ProxyEditBox:onUnfocus()
    parent.onUnfocus(self)
    if self.frame then
        self.frame:ClearFocus()
    end
end

function ProxyEditBox:onClick(binding)
    if self.frame and not self.frame:HasFocus() and self.frame:IsEnabled() then
        self:input()
    end
end
