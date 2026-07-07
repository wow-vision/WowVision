local Template = WowVision.Class("Template")

Template:addFields({
    { key = "key", required = true },
    { key = "name", required = true },
    { key = "description" },
    { key = "format", required = true },
})

function Template:initialize(info)
    self:applyFields(info)
    -- Parse format into AST at creation time
    -- Locale values are resolved now and baked into literal nodes
    self.nodes, self.fields = WowVision.templates.parse(self.format, WowVision:getLocale())
end

function Template:render(context)
    return WowVision.templates.renderNodes(self.nodes, context)
end

WowVision.templates.Template = Template
