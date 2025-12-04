local ProxyButton, parent = WowVision.ui:CreateElementType("ProxyButton", "ProxyWidget")
local L = WowVision:getLocale()

-- Define InfoClass fields at class level
ProxyButton.info:addFields({
    { key = "clickType", default = "direct" },
    { key = "clicks", default = nil },
    { key = "header", default = nil },
})

-- Remove value from liveFields (equivalent to live = false)
ProxyButton.liveFields.value = nil

local function setupUniqueBindings(self)
    self:addBinding({
        binding = "leftClick",
        type = "Click",
    })
    self:addBinding({
        binding = "rightClick",
        type = "Click",
    })
end

ProxyButton.setupUniqueBindings = setupUniqueBindings

function ProxyButton:initialize()
    parent.initialize(self, "ProxyButton")
    self:setProp("displayType", "Button")
    self:addProp({
        key = "clickType",
        default = "direct",
    })

    self:addProp({
        key = "macroCall",
        default = nil,
    })

    self:addProp({
        key = "clicks",
        default = nil,
    })

    self:addProp({
        key = "header",
        default = nil,
    })

    self:updateProp({
        key = "value",
        live = false,
    })
end

function ProxyButton:getLabel()
    if self.dropdown then
        local regions = { self.frame:GetRegions() }
        if regions[1]:GetObjectType() == "Texture" then
            if regions[1]:GetTexture() == 130940 then
                return regions[3]:GetText()
            elseif regions[1]:GetTexture() == 136810 and regions[2] then
                return regions[2]:GetText()
            end
        end
        return regions[1]:GetText()
    end
    return parent.getLabel(self)
end

function ProxyButton:getExtras()
    local extras = parent.getExtras(self)
    if self.header == "collapsed" then
        tinsert(extras, 1, L["Collapsed"])
    elseif self.header == "expanded" then
        tinsert(extras, 1, L["Expanded"])
    end
    return extras
end
