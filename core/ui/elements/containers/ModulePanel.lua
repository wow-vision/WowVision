--This is a generated component
local gen = WowVision.ui.generator
local L = LibStub("AceLocale-3.0"):GetLocale("WowVision")

local function ModuleButton_Click(event, button)
    local menu = button.userdata:getMenuPanel()
    button.context:addGenerated(menu)
end

local function moduleSortComp(a, b)
    return a:getLabel() < b:getLabel()
end

gen:Element("ModulePanel", function(props)
    local module = props.module
    if not module then
        return nil
    end
    local result = { "List", label = module:getLabel(), children = {} }
    if not module:isVital() then
        --We don't want certain modules being disabled, like base and speech
        tinsert(result.children, {
            "Checkbox",
            label = L["Enabled"],
            bind = { type = "Method", target = module, getter = "getEnabled", setter = "setEnabled" },
        })
    end
    local submodules = {}
    for _, submodule in ipairs(module.submodules) do
        tinsert(submodules, submodule)
    end
    table.sort(submodules, moduleSortComp)

    for _, submodule in ipairs(submodules) do
        local submenu = submodule:getMenuPanel()
        if submenu then
            tinsert(result.children, {
                "Button",
                label = submodule:getLabel(),
                userdata = submodule,
                events = {
                    click = ModuleButton_Click,
                },
            })
        end
    end
    if props.additionalUI then
        tinsert(result.children, props.additionalUI)
    end
    if module.settingsRoot then
        tinsert(result.children, module.settingsRoot:getGenerator())
    end
    return result
end)
