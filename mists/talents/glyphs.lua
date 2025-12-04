local module = WowVision.base.windows.talents:createModule("glyphs")
local L = module.L
module:setLabel(L["Glyphs"])
local gen = module:hasUI()

gen:Element("talents/glyphs", {
    dynamicValues = function(props)
        return { props.frame and props.frame:IsShown() }
    end,
}, function(props)
    if not props.frame or not props.frame:IsShown() then
        return nil
    end
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "Text", key = "placeholder", text = "Not yet implemented" },
        },
    }
end)
