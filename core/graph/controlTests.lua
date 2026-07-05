local testRunner = WowVision.testing.testRunner
local graph = WowVision.graph
local ControlId = graph.ControlId
local Builder = graph.Builder

local function sid(key)
    return ControlId.structural(key)
end

--
-- Node factory tests
--

testRunner:addSuite("GraphNodes", {
    ["proxyButton binds secure clicks with both mouse buttons"] = function(t)
        local target = {}
        local vtable = graph.nodes.proxyButton({ target = target })
        t:assertEqual(vtable.controlType, graph.controlTypes.button)
        t:assertEqual(#vtable.bindings, 2)
        t:assertEqual(vtable.bindings[1].binding, "leftClick")
        t:assertEqual(vtable.bindings[1].type, "Click")
        t:assertEqual(vtable.bindings[1].emulatedKey, "LeftButton")
        t:assertEqual(vtable.bindings[1].target, target)
        t:assertEqual(vtable.bindings[2].emulatedKey, "RightButton")
        t:assertError(function()
            graph.nodes.proxyButton({})
        end)
    end,

    ["button requires a label and a handler"] = function(t)
        local ran = false
        local vtable = graph.nodes.button({
            label = "OK",
            onActivate = function()
                ran = true
            end,
        })
        vtable.onActivate()
        t:assertTrue(ran)
        t:assertError(function()
            graph.nodes.button({ label = "OK" })
        end)
        t:assertError(function()
            graph.nodes.button({ onActivate = function() end })
        end)
    end,

    ["text carries the live scope"] = function(t)
        local vtable = graph.nodes.text({ label = "Line", live = "always" })
        t:assertEqual(vtable.announcements[1].live, "always")
        t:assertEqual(vtable.controlType, graph.controlTypes.text)
    end,

    ["toggle flips through get and set and reports state"] = function(t)
        local value = false
        local vtable = graph.nodes.toggle({
            label = "Enable",
            get = function()
                return value
            end,
            set = function(v)
                value = v
            end,
        })
        t:assertEqual(vtable.controlType, graph.controlTypes.toggle)
        vtable.onActivate()
        t:assertTrue(value)
        vtable.onActivate()
        t:assertFalse(value)
        t:assertEqual(vtable.announcements[2].live, "focus")
        t:assertEqual(vtable.announcements[2].kind, graph.kinds.value)
    end,

    ["number adjusts by step and large step"] = function(t)
        local value = 50
        local vtable = graph.nodes.number({
            label = "Volume",
            get = function()
                return value
            end,
            set = function(v)
                value = v
            end,
            step = 5,
        })
        vtable.onAdjust(1, false)
        t:assertEqual(value, 55)
        vtable.onAdjust(-1, true)
        t:assertEqual(value, 5)
    end,

    ["number survives a rejecting setter"] = function(t)
        local vtable = graph.nodes.number({
            label = "Volume",
            get = function()
                return 10
            end,
            set = function()
                error("validation rejected")
            end,
        })
        vtable.onAdjust(1, false)
        t:assertEqual(vtable.announcements[1].text, "Volume")
    end,

    ["choice reads the current option label as its value"] = function(t)
        local value = "b"
        local vtable = graph.nodes.choice({
            label = "Voice",
            get = function()
                return value
            end,
            set = function(v)
                value = v
            end,
            choices = {
                { label = "Alpha", value = "a" },
                { label = "Beta", value = "b" },
            },
        })
        t:assertEqual(vtable.controlType, graph.controlTypes.dropdown)
        t:assertEqual(graph.resolveText(vtable.announcements[2]), "Beta")
    end,

    ["settings renderer emits controls, fallbacks, and child buttons"] = function(t)
        local store = { enabled = true, volume = 80 }
        local function fakeField(typeKey, key)
            return {
                typeKey = typeKey,
                key = key,
                showInUI = true,
                getLabel = function()
                    return key
                end,
                get = function(self, obj)
                    return store[key]
                end,
                set = function(self, obj, v)
                    store[key] = v
                end,
                getValueString = function(self, obj, value)
                    return tostring(value)
                end,
            }
        end
        local fakeFrame = {
            label = "Speech",
            info = {
                fields = {
                    fakeField("Bool", "enabled"),
                    fakeField("Number", "volume"),
                    fakeField("SomeUnregisteredType", "mystery"),
                },
            },
            children = { { key = "child", label = "Advanced" } },
        }
        local builder = Builder:new()
        graph.settings.renderInto(builder, fakeFrame)
        local render = builder:build()
        t:assertNotNil(render.nodes["field:enabled"])
        t:assertEqual(render.nodes["field:enabled"].vtable.controlType, graph.controlTypes.toggle)
        t:assertNotNil(render.nodes["field:volume"].vtable.onAdjust)
        t:assertEqual(render.nodes["field:mystery"].vtable.controlType, graph.controlTypes.text)
        t:assertNotNil(render.nodes["child:child"])
        t:assertEqual(render.nodes["field:enabled"].parent.vtable.announcements[1].text, "Speech")
        -- The toggle drives the real store through the field.
        render.nodes["field:enabled"].vtable.onActivate()
        t:assertFalse(store.enabled)
    end,

    ["all field types have registered controls"] = function(t)
        local expected = {
            "Bool",
            "Number",
            "Choice",
            "String",
            "ComponentArray",
            "Time",
            "VoicePack",
            "Spell",
            "Alert",
            "Template",
            "Object",
            "TrackingConfig",
            "Array",
            "DataBrowse",
        }
        for _, typeKey in ipairs(expected) do
            t:assertTrue(graph.settings.hasFieldControl(typeKey), typeKey .. " control missing")
        end
    end,

    ["button value parts read live"] = function(t)
        local value = "10"
        local vtable = graph.nodes.button({
            label = "Volume",
            value = function()
                return value
            end,
            onActivate = function() end,
        })
        t:assertEqual(vtable.announcements[2].kind, graph.kinds.value)
        t:assertEqual(vtable.announcements[2].live, "focus")
        t:assertEqual(graph.resolveText(vtable.announcements[2]), "10")
    end,

    ["array control renders element rows with remove and add"] = function(t)
        local store = { "alpha", "beta" }
        local elementField = {
            typeKey = "String",
            key = "_element",
            showInUI = true,
            getLabel = function()
                return "Value"
            end,
            get = function(self, obj)
                return obj._element
            end,
            set = function(self, obj, v)
                obj._element = v
            end,
            getValueString = function(self, obj, value)
                return tostring(value)
            end,
            getDefault = function()
                return ""
            end,
        }
        local fakeField = {
            typeKey = "Array",
            key = "items",
            getLabel = function()
                return "Items"
            end,
            getLength = function(self, owner)
                return #store
            end,
            getElementField = function()
                return elementField
            end,
            createElementProxy = function(self, owner, index)
                return setmetatable({}, {
                    __index = function(_, k)
                        if k == "_element" then
                            return store[index]
                        end
                    end,
                    __newindex = function(_, k, v)
                        if k == "_element" then
                            store[index] = v
                        end
                    end,
                })
            end,
            removeElement = function(self, owner, index)
                table.remove(store, index)
            end,
            addElement = function(self, owner, value)
                tinsert(store, value)
            end,
        }
        local vtable = graph.settings.controlFor(fakeField, {})
        t:assertEqual(graph.resolveText(vtable.announcements[1]), "Items (2)")
    end,

    ["componentArray control reads label with count"] = function(t)
        local fakeField = {
            typeKey = "ComponentArray",
            key = "items",
            getLabel = function()
                return "Buffers"
            end,
            getLength = function(self, owner)
                return 2
            end,
        }
        local vtable = graph.settings.controlFor(fakeField, {})
        t:assertEqual(graph.resolveText(vtable.announcements[1]), "Buffers (2)")
        t:assertNotNil(vtable.onActivate)
    end,

    ["renderObjectInto emits class fields and honors the override hook"] = function(t)
        local store = { name = "General" }
        local fakeInstance = {
            class = {
                info = {
                    fields = {
                        {
                            typeKey = "String",
                            key = "name",
                            showInUI = true,
                            getLabel = function()
                                return "Name"
                            end,
                            get = function(self, obj)
                                return store.name
                            end,
                            set = function(self, obj, v)
                                store.name = v
                            end,
                            getValueString = function(self, obj, value)
                                return tostring(value)
                            end,
                        },
                    },
                },
            },
        }
        local builder = Builder:new()
        graph.settings.renderObjectInto(builder, fakeInstance)
        local render = builder:build()
        t:assertNotNil(render.nodes["field:name"])
        t:assertEqual(render.nodes["field:name"].vtable.controlType, graph.controlTypes.editBox)

        local overrideRan = false
        local overriding = {
            renderGraphSettings = function(self, b)
                overrideRan = true
            end,
        }
        graph.settings.renderObjectInto(Builder:new(), overriding)
        t:assertTrue(overrideRan)
    end,

    ["module menu renders toggle, submodules, hook items, and settings"] = function(t)
        local enabledState = true
        local hookRan = false
        local sub1 = {
            key = "zeta",
            submodules = {},
            getLabel = function()
                return "Zeta"
            end,
        }
        local sub2 = {
            key = "alpha",
            submodules = {},
            getLabel = function()
                return "Alpha"
            end,
        }
        local fakeModule = {
            key = "root",
            submodules = { sub1, sub2 },
            getLabel = function()
                return "WowVision"
            end,
            isVital = function()
                return false
            end,
            getEnabled = function()
                return enabledState
            end,
            setEnabled = function(self, value)
                enabledState = value
            end,
            getGraphMenuItems = function(self, builder)
                hookRan = true
                builder:addItem(sid("extra"), graph.nodes.button({
                    label = "Extra",
                    onActivate = function() end,
                }))
            end,
            settingsRoot = {
                label = "Settings",
                info = { fields = {} },
                children = {},
            },
        }
        local builder = Builder:new()
        graph.settings.renderModuleInto(builder, fakeModule)
        local render = builder:build()
        t:assertNotNil(render.nodes["enabled"])
        t:assertTrue(hookRan)
        t:assertNotNil(render.nodes["extra"])
        -- Submodules sort by label: Alpha before Zeta.
        local alphaIndex, zetaIndex
        for i, node in ipairs(render.order) do
            if node.id.key == "module:alpha" then
                alphaIndex = i
            elseif node.id.key == "module:zeta" then
                zetaIndex = i
            end
        end
        t:assertTrue(alphaIndex < zetaIndex)
        -- The enabled toggle drives the module.
        render.nodes["enabled"].vtable.onActivate()
        t:assertFalse(enabledState)
    end,

    ["proxyButtonMenu emits one stop per button with shared positions"] = function(t)
        local a, b, c = {}, {}, {}
        local builder = Builder:new()
        graph.nodes.proxyButtonMenu(builder, { label = "Menu", buttons = { a, b, c } })
        local render = builder:build()
        t:assertEqual(#render.order, 3)
        local first = render.order[1]
        local third = render.order[3]
        t:assertEqual(first.id.reference, a)
        t:assertEqual(third.positionIndex, 3)
        t:assertEqual(third.positionCount, 3)
        t:assertNotEqual(first.stopKey, third.stopKey)
        t:assertEqual(first.parent.vtable.announcements[1].text, "Menu")
        t:assertNil(first.transitions.down, "single-node stops have no arrow edges")
    end,
})
