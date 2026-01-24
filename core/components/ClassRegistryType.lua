local ClassRegistryType = WowVision.Class("ClassRegistryType", WowVision.components.RegistryType)
    :include(WowVision.InfoClass)
ClassRegistryType.info:addFields({
    { key = "baseClass", required = true },
    { key = "mixins", default = {} },
    { key = "classNamePrefix", default = "" },
    { key = "classNameSuffix", default = "" },
})

function ClassRegistryType:createType(config)
    -- Determine parent class
    local parentClass
    if config.parent then
        parentClass = self.registry.types:get(config.parent)
        if not parentClass then
            error("ClassRegistryType: Unknown parent type '" .. config.parent .. "'")
        end
    else
        parentClass = self.baseClass
    end

    -- Create new class with optional prefix/suffix
    local className = self.classNamePrefix .. config.key .. self.classNameSuffix
    local newClass = WowVision.Class(className, parentClass)

    -- Always include InfoClass so each type gets its own info object
    newClass:include(WowVision.InfoClass)

    -- Apply mixins
    for _, mixin in ipairs(self.mixins) do
        newClass:include(mixin)
    end

    return newClass
end

function ClassRegistryType:createComponent(typeClass, config)
    return typeClass:new(config)
end

function ClassRegistryType:isComponentOfType(component, typeClass)
    return component:isInstanceOf(typeClass)
end

WowVision.components.registryTypes:register("class", ClassRegistryType)
WowVision.components.ClassRegistryType = ClassRegistryType
