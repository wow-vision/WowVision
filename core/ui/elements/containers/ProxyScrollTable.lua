local ProxyScrollTable, parent = WowVision.ui:CreateElementType("ProxyScrollTable", "ProxyScrollBox")

-- Define InfoClass fields at class level
ProxyScrollTable.info:addFields({
    { key = "headers", default = {} },
    { key = "getButtonData", default = nil },
})

function ProxyScrollTable:initialize()
    parent.initialize(self)
    self:addProp({
        key = "headers",
        default = {},
    })

    self:addProp({
        key = "getButtonData",
        default = nil,
    })
end

function ProxyScrollTable:getElement(button)
    return {
        "ProxyButton",
        frame = button,
        label = self:getButtonLabel(button),
        selected = WowVision:recursiveComp(button:GetRowData(), self.selectedElement),
    }
end

function ProxyScrollTable:getButtonLabel(button)
    local buttonData = self:getButtonData(button)
    local data = {}
    for _, v in ipairs(self.headers) do
        local value = buttonData[v.key]
        if value then
            value = tostring(value)
            if v.label then
                if v.flag then
                    tinsert(data, v.label)
                else
                    tinsert(data, v.label .. " " .. value)
                end
            else
                tinsert(data, value)
            end
        end
    end

    return table.concat(data, ", ")
end
