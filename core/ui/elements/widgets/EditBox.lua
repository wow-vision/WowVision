local EditBox, parent = WowVision.ui:CreateElementType("EditBox", "Widget")
local L = WowVision:getLocale()

-- Define InfoClass fields at class level
EditBox.info:addFields({
    { key = "autoInputOnFocus", default = true },
    {
        key = "type",
        default = "string",
        set = function(obj, key, value)
            obj.type = value
            if value == "string" then
                obj.frame:SetNumeric(false)
            elseif value == "number" then
                obj.frame:SetNumeric(true)
            elseif value == "decimal" then
                obj.frame:SetNumeric(false)
            end
        end,
    },
})

function EditBox:initialize()
    parent.initialize(self)
    self.frame = CreateFrame("EditBox")
    self.frame:SetAutoFocus(false)
    self.frame:Hide()

    self:addProp({
        key = "autoInputOnFocus",
        default = true,
    })

    self:addProp({
        key = "type",
        default = "string",
        set = function(value)
            self.type = value
            if value == "string" then
                self.frame:SetNumeric(false)
            elseif value == "number" then
                self.frame:SetNumeric(true)
            elseif value == "decimal" then
                self.frame:SetNumeric(false) --apparently numeric text fields only take integers
            end
        end,
    })
end

function EditBox:getValue()
    if self.type == "decimal" then
        return tonumber(self.frame:GetText())
    end
    if self.frame:IsNumeric() then
        return self.frame:GetNumber()
    end
    return self.frame:GetText()
end

function EditBox:setValue(value)
    if value == nil then
        return nil
    end
    local setValue = nil
    if self.type == "decimal" then
        setValue = tostring(value)
    end
    if self.frame:IsNumeric() then
        setValue = tonumber(value)
    else
        setValue = tostring(value)
    end
    if not setValue then
        return nil
    end

    if not self.frame:HasFocus() then
        if self.type == "string" or self.type == "decimal" then
            self.frame:SetText(setValue)
        else
            self.frame:SetNumber(setValue)
        end
    end

    parent.setValue(self, value)
end

function EditBox:onFocus()
    parent.onFocus(self)
    if self.autoInputOnFocus then
        self:input()
    end
end

function EditBox:onUnfocus()
    parent.onUnfocus(self)
    self:leaveInput()
end

function EditBox:input()
    self.frame:Show()
    self.frame:SetFocus()
    self.frame:SetScript("OnTabPressed", function(frame)
        local binding
        if IsShiftKeyDown() then
            binding = WowVision.input:getBinding("previous")
        else
            binding = WowVision.input:getBinding("next")
        end
        WowVision.UIHost:onBindingPressed(binding)
    end)

    if self.frame:IsMultiLine() then
        self.frame:SetScript("OnEnterPressed", nil)
    else
        self.frame:SetScript("OnEnterPressed", function(frame)
            self:leaveInput()
        end)
    end

    self.frame:SetScript("OnEscapePressed", function(frame)
        self:leaveInput()
    end)

    self.frame:SetScript("OnTextChanged", function(frame, userInput)
        local value = self:getValue()
        self:setValue(value)
    end)
end

function EditBox:leaveInput()
    if not self.frame:HasFocus() then
        return
    end
    self.frame:ClearFocus()
    self.frame:Hide()
end

function EditBox:onClick()
    if not self.frame:HasFocus() then
        self:input()
    end
    parent.onClick(self)
end
