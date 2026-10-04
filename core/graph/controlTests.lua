local testRunner = WowVision.testing.testRunner
local graph = WowVision.graph
local ControlId = graph.ControlId
local Builder = graph.Builder

local function sid(key)
    return ControlId.structural(key)
end

--
-- ScrollBox adapter tests
--

local function makeFakeScrollBox(rows)
    local provider = {
        Find = function(self, index)
            return rows[index]
        end,
    }
    local visibleFrames = {}
    local scrollBox = {
        scrolledTo = nil,
        GetDataProviderSize = function(self)
            return #rows
        end,
        GetDataProvider = function(self)
            return provider
        end,
        ScrollToElementDataIndex = function(self, index)
            self.scrolledTo = index
            visibleFrames[rows[index]] = { name = "frame" .. index }
        end,
        FindFrame = function(self, data)
            return visibleFrames[data]
        end,
    }
    return scrollBox
end

testRunner:addSuite("GraphScrollBox", {
    ["rows come from the data provider with data identity"] = function(t)
        local rows = { { name = "Sword" }, { name = "Shield" }, { name = "Potion" } }
        local scrollBox = makeFakeScrollBox(rows)
        local builder = Builder:new()
        graph.nodes.scrollBoxList(builder, {
            scrollBox = scrollBox,
            label = "Items",
            rowLabel = function(data)
                return data.name
            end,
        })
        local render = builder:build()
        t:assertEqual(#render.order, 3)
        t:assertEqual(render.order[1].id.reference, rows[1])
        t:assertEqual(graph.resolveText(render.order[2].vtable.announcements[1]), "Shield")
        t:assertEqual(render.order[3].positionIndex, 3)
        t:assertEqual(render.order[1].parent.vtable.announcements[1].text, "Items")
    end,

    ["focus scrolls and the click target resolves the materialized frame"] = function(t)
        local rows = { { name = "Sword" }, { name = "Shield" } }
        local scrollBox = makeFakeScrollBox(rows)
        local builder = Builder:new()
        graph.nodes.scrollBoxList(builder, {
            scrollBox = scrollBox,
            rowLabel = function(data)
                return data.name
            end,
        })
        local render = builder:build()
        local node = render.order[2]
        local targetFn = node.vtable.bindings[1].target
        t:assertType(targetFn, "function")
        t:assertNil(targetFn(), "offscreen row has no frame yet")
        node.vtable.onFocus()
        t:assertEqual(scrollBox.scrolledTo, 2)
        t:assertNotNil(targetFn(), "scrolled row resolves its frame")
        t:assertEqual(node.vtable.bindings[1].emulatedKey, "LeftButton")
    end,

    ["custom rows compose the scroll hook and lazy target"] = function(t)
        local rows = { { name = "Lot" } }
        local scrollBox = makeFakeScrollBox(rows)
        local builder = Builder:new()
        graph.nodes.scrollBoxList(builder, {
            scrollBox = scrollBox,
            row = function(data, index, helpers)
                return {
                    controlType = graph.controlTypes.button,
                    announcements = { { text = data.name } },
                    bindings = {
                        { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                    },
                    onFocus = helpers.onFocus,
                }
            end,
        })
        local render = builder:build()
        render.order[1].vtable.onFocus()
        t:assertEqual(scrollBox.scrolledTo, 1)
        t:assertNotNil(render.order[1].vtable.bindings[1].target())
    end,

    ["two lists in one build need distinct keys"] = function(t)
        local rowsA = { { name = "General" }, { name = "Combat" } }
        local rowsB = { { name = "Volume" }, { name = "Music" } }
        local builder = Builder:new()
        graph.nodes.scrollBoxList(builder, {
            scrollBox = makeFakeScrollBox(rowsA),
            key = "categories",
            rowLabel = function(data)
                return data.name
            end,
        })
        graph.nodes.scrollBoxList(builder, {
            scrollBox = makeFakeScrollBox(rowsB),
            key = "settings",
            rowLabel = function(data)
                return data.name
            end,
        })
        local render = builder:build()
        t:assertEqual(#render.order, 4)
        t:assertEqual(render.order[1].id.key, "categories:1")
        t:assertEqual(render.order[3].id.key, "settings:1")
    end,

    ["templates dispatch by frameTemplate with fallbacks"] = function(t)
        local rows = {
            { frameTemplate = "Known", name = "First" },
            { frameTemplate = "Mystery", name = "Second" },
            { frameTemplate = "Skipped", name = "Third" },
        }
        local scrollBox = makeFakeScrollBox(rows)
        local builder = Builder:new()
        local emitted = {}
        graph.nodes.scrollBoxList(builder, {
            scrollBox = scrollBox,
            key = "t",
            templates = {
                Known = function(b, data, index, helpers)
                    tinsert(emitted, data.name)
                    b:addItem(helpers.id, graph.nodes.text({ label = data.name }))
                end,
                Skipped = function() end,
            },
        })
        local render = builder:build()
        t:assertEqual(emitted[1], "First")
        t:assertEqual(#render.order, 2, "known plus not-implemented; skipped emits nothing")
        local fallback = render.order[2]
        t:assertTrue(graph.resolveText(fallback.vtable.announcements[1]):find("Mystery") ~= nil)
    end,

    ["an empty provider emits a landable Empty placeholder"] = function(t)
        local scrollBox = makeFakeScrollBox({})
        local builder = Builder:new()
        graph.nodes.scrollBoxList(builder, {
            scrollBox = scrollBox,
            key = "rows",
            rowLabel = function(data)
                return ""
            end,
        })
        local render = builder:build()
        t:assertEqual(#render.order, 1)
        t:assertEqual(render.order[1].id.key, "rows:empty")
    end,
})

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

    ["proxy factories skip hidden targets"] = function(t)
        local hidden = {
            IsShown = function()
                return false
            end,
        }
        t:assertEqual(graph.nodes.proxyButton({ target = hidden }), nil)
        t:assertEqual(graph.nodes.proxyCheckButton({ target = hidden }), nil)
        t:assertEqual(graph.nodes.proxyEditBox({ editBox = hidden }), nil)
        local allowed = graph.nodes.proxyButton({ target = hidden, allowHidden = true })
        t:assertEqual(allowed.controlType, graph.controlTypes.button)
        -- addItem skips nil vtables, so call sites need no guards.
        local b = Builder:new()
        b:addItem(sid("gone"), nil)
        local render = b:addLabel(sid("real"), "Real"):build()
        t:assertEqual(#render.order, 1)
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

    ["attachHover runs hover scripts around existing hooks"] = function(t)
        if CreateFrame ~= nil then
            return -- headless-only: fake frames cannot pass the real ExecuteFrameScript
        end
        local frame = {
            _scripts = {},
            HasScript = function(self, script)
                return true
            end,
        }
        local order = {}
        local vtable = graph.nodes.attachHover({
            onFocus = function()
                tinsert(order, "base")
            end,
        }, frame)
        vtable.onFocus()
        t:assertEqual(order[1], "base", "existing hook runs before hover")
        t:assertEqual(frame._scripts[1], "OnEnter")
        vtable.onUnfocus()
        t:assertEqual(frame._scripts[2], "OnLeave")
    end,

    ["proxyButton hover=false runs no frame scripts and keeps its tooltip"] = function(t)
        local frame = {
            _scripts = {},
            HasScript = function(self, script)
                return true
            end,
        }
        local tooltip = { type = "Game", mode = "immediate" }
        local vtable = graph.nodes.proxyButton({ target = frame, label = "OK", hover = false, tooltip = tooltip })
        t:assertNil(vtable.onFocus)
        t:assertNil(vtable.onUnfocus)
        t:assertEqual(vtable.tooltipFrame, frame)
        t:assertEqual(vtable.tooltip, tooltip)
        t:assertEqual(#frame._scripts, 0)
    end,

    ["proxyButton hovers its target on focus"] = function(t)
        if CreateFrame ~= nil then
            return -- headless-only: fake frames cannot pass the real ExecuteFrameScript
        end
        local frame = {
            _scripts = {},
            HasScript = function(self, script)
                return true
            end,
        }
        local vtable = graph.nodes.proxyButton({ target = frame, label = "OK" })
        vtable.onFocus()
        vtable.onUnfocus()
        t:assertEqual(frame._scripts[1], "OnEnter")
        t:assertEqual(frame._scripts[2], "OnLeave")
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

testRunner:addSuite("GraphFoundButton", {
    ["joinLabel keeps the parts after a missing one"] = function(t)
        local nodes = graph.nodes
        t:assertEqual(nodes.joinLabel("Toy", nil, "Favorite"), "Toy, Favorite")
        t:assertEqual(nodes.joinLabel("Toy", false, "", "Favorite"), "Toy, Favorite")
        t:assertEqual(nodes.joinLabel(nil, nil), "")
    end,

    ["proxyFoundButton resolves the frame on every read"] = function(t)
        local first = { name = "First" }
        local second = { name = "Second" }
        local current = first
        local vtable = graph.nodes.proxyFoundButton({
            find = function()
                return current
            end,
            label = function(frame)
                return frame.name
            end,
        })
        local label = vtable.announcements[1].text
        t:assertEqual(label(), "First")
        current = second
        t:assertEqual(label(), "Second")
        current = nil
        t:assertNil(label())
        t:assertEqual(vtable.bindings[1].target, vtable.bindings[2].target)
        t:assertNil(vtable.tooltip)
    end,

    ["proxyFoundButton rightClick=false drops the right click everywhere"] = function(t)
        local dragged = nil
        local frame = {
            GetScript = function(self, name)
                return name == "OnDragStart" and function(owner)
                    dragged = owner
                end or nil
            end,
        }
        local vtable = graph.nodes.proxyFoundButton({
            find = function()
                return frame
            end,
            label = function()
                return "Tab"
            end,
            rightClick = false,
            drag = true,
        })
        for _, binding in ipairs(vtable.bindings) do
            t:assertNotEqual(binding.binding, "rightClick")
        end
        local labels = {}
        vtable.contextActions(function(entry)
            tinsert(labels, entry)
        end)
        t:assertEqual(#labels, 2, "left click and drag")
        labels[2].onActivate()
        t:assertEqual(dragged, frame, "drag runs the found frame's own drag script")
        dragged = nil
        vtable.bindings[#vtable.bindings].func()
        t:assertEqual(dragged, frame)
    end,

    ["proxyFoundButton without drag offers no Drag entry"] = function(t)
        local vtable = graph.nodes.proxyFoundButton({
            find = function()
                return {}
            end,
            label = function()
                return "Tab"
            end,
        })
        local count = 0
        vtable.contextActions(function()
            count = count + 1
        end)
        t:assertEqual(count, 2, "left and right click only")
        for _, binding in ipairs(vtable.bindings) do
            t:assertNotEqual(binding.binding, "drag")
        end
    end,

    ["dragScript tolerates a missing frame or script"] = function(t)
        graph.nodes.dragScript(function()
            return nil
        end)()
        graph.nodes.dragScript({})()
        t:assertTrue(true)
    end,
})

--
-- Dropdown menu rows with attached utility buttons
--

local function fakeFontString(text)
    return {
        GetObjectType = function()
            return "FontString"
        end,
        GetText = function()
            return text
        end,
    }
end

-- A utility button as MenuTemplates attaches it: hidden, with a click
-- script and hover scripts that write its name into the game tooltip.
local function fakeUtilityButton(tooltipTitle, left, tooltipState)
    local scripts = {}
    local button = {
        GetObjectType = function()
            return "Button"
        end,
        IsShown = function()
            return false
        end,
        GetLeft = function()
            return left
        end,
        GetScript = function(self, name)
            return scripts[name]
        end,
        HasScript = function(self, name)
            return scripts[name] ~= nil
        end,
    }
    scripts.OnClick = function() end
    scripts.OnEnter = function()
        tooltipState.shown = true
        tooltipState.line = tooltipTitle
    end
    scripts.OnLeave = function()
        tooltipState.shown = false
        tooltipState.line = nil
    end
    return button
end

local function fakeMenuRow(fontStrings, children)
    return {
        GetObjectType = function()
            return "Button"
        end,
        IsShown = function()
            return true
        end,
        GetRegions = function()
            return unpack(fontStrings)
        end,
        GetChildren = function()
            return unpack(children)
        end,
    }
end

-- Runs body with stand-ins for the tooltip globals the label probe reads.
local function withTooltipGlobals(body)
    local state = { shown = false, line = nil }
    local saved = { GameTooltip, GameTooltipTextLeft1, ExecuteFrameScript, GetTime }
    GameTooltip = {
        IsShown = function()
            return state.shown
        end,
        GetOwner = function()
            return nil
        end,
    }
    GameTooltipTextLeft1 = {
        GetText = function()
            return state.line
        end,
    }
    ExecuteFrameScript = function(frame, name)
        local script = frame:GetScript(name)
        if script ~= nil then
            script(frame)
        end
    end
    local clock = 0
    GetTime = function()
        clock = clock + 1
        return clock
    end
    local ok, err = pcall(body, state)
    GameTooltip, GameTooltipTextLeft1, ExecuteFrameScript, GetTime = unpack(saved, 1, 4)
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("GraphDropdownRows", {
    ["a row with attached buttons becomes a horizontal row in screen order"] = function(t)
        withTooltipGlobals(function(state)
            local play = fakeUtilityButton("Play Sample", 10, state)
            local gear = fakeUtilityButton("Edit", 200, state)
            local delete = fakeUtilityButton("Delete", 180, state)
            local row = fakeMenuRow(
                { fakeFontString("Low Thud"), fakeFontString("On Aura Applied") },
                { play, gear, delete }
            )
            local builder = Builder:new()
            builder:beginStop("menu")
            graph.dropdown.emitRow(builder, row)
            local render = builder:build()
            t:assertEqual(#render.order, 4)
            t:assertEqual(graph.resolveText(render.order[1].vtable.announcements[1]), "Low Thud, On Aura Applied")
            t:assertEqual(render.order[2].id.reference, play)
            t:assertEqual(render.order[3].id.reference, delete, "sorted by screen position, not creation order")
            t:assertEqual(render.order[4].id.reference, gear)
            t:assertEqual(graph.resolveText(render.order[2].vtable.announcements[1]), "Play Sample")
            t:assertEqual(graph.resolveText(render.order[3].vtable.announcements[1]), "Delete")
            t:assertEqual(graph.resolveText(render.order[4].vtable.announcements[1]), "Edit")
            t:assertEqual(render.order[1].transitions.right.destination, render.order[2].id)
            t:assertEqual(render.order[4].transitions.left.destination, render.order[3].id)
            t:assertEqual(render.order[2].positionIndex, 2)
            t:assertEqual(render.order[2].positionCount, 4)
            t:assertFalse(state.shown, "the label probe leaves the tooltip hidden")
        end)
    end,

    ["a row without buttons stays a single item"] = function(t)
        withTooltipGlobals(function()
            local row = fakeMenuRow({ fakeFontString("Rename Layout") }, {})
            local builder = Builder:new()
            builder:beginStop("menu")
            graph.dropdown.emitRow(builder, row)
            local render = builder:build()
            t:assertEqual(#render.order, 1)
            t:assertEqual(graph.resolveText(render.order[1].vtable.announcements[1]), "Rename Layout")
            t:assertNil(render.order[1].transitions.right)
        end)
    end,

    ["child frames without a click script are not buttons"] = function(t)
        local swatch = {
            GetObjectType = function()
                return "Button"
            end,
            GetScript = function()
                return nil
            end,
        }
        local label = {
            GetObjectType = function()
                return "Frame"
            end,
        }
        local row = fakeMenuRow({ fakeFontString("Red") }, { swatch, label })
        t:assertEqual(#graph.dropdown.rowButtons(row), 0)
    end,

    ["the label is read from a tooltip the button already owns without re-hovering"] = function(t)
        withTooltipGlobals(function(state)
            local button = fakeUtilityButton("Delete Layout", 5, state)
            state.shown = true
            state.line = "Delete Layout"
            GameTooltip.GetOwner = function()
                return button
            end
            local entered = false
            local enter = button:GetScript("OnEnter")
            local scripts = { OnEnter = enter }
            button.HasScript = function()
                return true
            end
            button.GetScript = function(self, name)
                if name == "OnEnter" then
                    return function()
                        entered = true
                    end
                end
                return scripts[name]
            end
            t:assertEqual(graph.dropdown.rowButtonLabel(button)(), "Delete Layout")
            t:assertFalse(entered)
            t:assertTrue(state.shown, "the owned tooltip is left showing")
        end)
    end,
})
