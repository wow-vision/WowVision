local Template = WowVision.Class("Template"):include(WowVision.InfoClass)

Template.info:addFields({
    { key = "key", required = true },
    { key = "name", required = true },
    { key = "description" },
    { key = "format", required = true },
})

function Template:initialize(info)
    self:setInfo(info)
end

function Template:render(context, locale)
    locale = locale or WowVision:getLocale()
    return WowVision.templates.render(self.format, context, locale)
end

WowVision.templates.Template = Template
