local testRunner = WowVision.testing.testRunner
local NewClass = WowVision.NewClass

local function counter()
    local n = { count = 0 }
    n.bump = function()
        n.count = n.count + 1
    end
    return n
end

testRunner:addSuite("ClassSystem", {
    -- ------------------------------------------------------------------
    -- Class basics
    -- ------------------------------------------------------------------
    ["new calls initialize with arguments"] = function(t)
        local A = NewClass("A")
        function A:initialize(x, y)
            self.sum = x + y
        end
        t:assertEqual(A:new(2, 3).sum, 5)
    end,

    ["methods inherit and override through the chain"] = function(t)
        local A = NewClass("A")
        function A:speak()
            return "a"
        end
        function A:base()
            return "base"
        end
        local B = NewClass("B", A)
        function B:speak()
            return "b"
        end
        local b = B:new()
        t:assertEqual(b:speak(), "b")
        t:assertEqual(b:base(), "base")
    end,

    ["direct parent method calls work"] = function(t)
        local A = NewClass("A")
        function A:initialize(x)
            self.x = x
        end
        local B = NewClass("B", A)
        function B:initialize(x)
            A.initialize(self, x * 2)
        end
        t:assertEqual(B:new(4).x, 8)
    end,

    ["isInstanceOf and isSubclassOf walk the chain"] = function(t)
        local A = NewClass("A")
        local B = NewClass("B", A)
        local b = B:new()
        t:assertTrue(b:isInstanceOf(B))
        t:assertTrue(b:isInstanceOf(A))
        t:assertTrue(B:isSubclassOf(A))
        t:assertTrue(not A:isSubclassOf(B))
        t:assertEqual(b.class, B)
        t:assertEqual(B.name, "B")
        t:assertEqual(B.super, A)
    end,

    ["include copies mixin methods and calls included"] = function(t)
        local got = nil
        local mixin = {
            greet = function(self)
                return "hi"
            end,
            included = function(self, class)
                got = class
            end,
        }
        local A = NewClass("A"):include(mixin)
        t:assertEqual(A:new():greet(), "hi")
        t:assertEqual(got, A)
    end,

    ["static is an alias for the class"] = function(t)
        local A = NewClass("A")
        function A.static:make()
            return self:new()
        end
        t:assertTrue(A:make():isInstanceOf(A))
    end,

    -- ------------------------------------------------------------------
    -- Fields: declaration, access, inheritance
    -- ------------------------------------------------------------------
    ["field reads fall back to the default"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "enabled", type = "Bool", default = true } })
        t:assertEqual(A:new().enabled, true)
    end,

    ["table defaults materialize per instance"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "bag", type = "Table", default = { n = 1 } } })
        local one, two = A:new(), A:new()
        one.bag.n = 5
        t:assertEqual(two.bag.n, 1)
    end,

    ["assignment stores and reads back"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "label", type = "String" } })
        local a = A:new()
        a.label = "hello"
        t:assertEqual(a.label, "hello")
    end,

    ["non-field keys stay plain instance variables"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "label" } })
        local a = A:new()
        a.scratch = { 1, 2 }
        t:assertEqual(rawget(a, "scratch")[2], 2)
    end,

    ["children inherit parent fields, parents never gain child fields"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "name", type = "String" } })
        local B = NewClass("B", A)
        B:addFields({ { key = "age", type = "Number" } })
        t:assertNotNil(B:getField("name"))
        t:assertNotNil(B:getField("age"))
        t:assertNil(A:getField("age")) -- THE footgun: impossible now
        t:assertEqual(#A:getFields(), 1)
        t:assertEqual(#B:getFields(), 2)
    end,

    ["parent fields declared late reach existing children"] = function(t)
        local A = NewClass("A")
        local B = NewClass("B", A)
        B:addFields({ { key = "own" } })
        t:assertEqual(#B:getFields(), 1) -- computed once, then...
        A:addFields({ { key = "late" } })
        t:assertNotNil(B:getField("late")) -- ...invalidated by the generation bump
    end,

    ["field objects are stable across schema recomputes"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "name" } })
        local before = A:getField("name")
        A:addFields({ { key = "other" } }) -- forces a recompute
        t:assertEqual(A:getField("name"), before)
    end,

    ["updateField overrides for the subclass only"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "size", type = "Number", default = 1 } })
        local B = NewClass("B", A)
        B:updateField({ key = "size", default = 9 })
        t:assertEqual(B:new().size, 9)
        t:assertEqual(A:new().size, 1)
        t:assertEqual(#B:getFields(), 1) -- replaced in place, not appended
    end,

    ["sibling classes share inherited field objects"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "shared" } })
        local B = NewClass("B", A)
        local C = NewClass("C", A)
        t:assertEqual(B:getField("shared"), C:getField("shared"))
    end,

    -- ------------------------------------------------------------------
    -- Validation, events, custom accessors
    -- ------------------------------------------------------------------
    ["type validation always runs on set"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "count", type = "Number", min = 0, max = 10 } })
        local a = A:new()
        a.count = "7"
        t:assertEqual(a.count, 7)
        a.count = 99
        t:assertEqual(a.count, 10) -- clamped
        local ok = pcall(function()
            a.count = "not a number"
        end)
        t:assertTrue(not ok)
    end,

    ["per-field validate beats the type validate"] = function(t)
        local A = NewClass("A")
        A:addFields({
            {
                key = "code",
                type = "Number",
                validate = function(field, value)
                    return tostring(value) .. "!"
                end,
            },
        })
        local a = A:new()
        a.code = 5
        t:assertEqual(a.code, "5!")
    end,

    ["choice fields reject values outside the set"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "mode", type = "Choice", choices = { "on", "off" } } })
        local a = A:new()
        a.mode = "on"
        t:assertEqual(a.mode, "on")
        t:assertTrue(not pcall(function()
            a.mode = "sideways"
        end))
    end,

    ["valueChange fires on change with obj, key, value"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "label" } })
        local a = A:new()
        local seen = nil
        A:getField("label").events.valueChange:subscribe(nil, function(event, obj, key, value)
            seen = { obj = obj, key = key, value = value }
        end)
        a.label = "x"
        t:assertEqual(seen.obj, a)
        t:assertEqual(seen.key, "label")
        t:assertEqual(seen.value, "x")
    end,

    ["setting an equal value neither persists nor emits"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "list", type = "Table" } })
        local a = A:new()
        a.list = { 1, 2 }
        local fired = counter()
        A:getField("list").events.valueChange:subscribe(nil, fired.bump)
        a.list = { 1, 2 } -- deep-equal
        t:assertEqual(fired.count, 0)
        a.list = { 1, 2, 3 }
        t:assertEqual(fired.count, 1)
    end,

    ["custom get and set functions own the storage"] = function(t)
        local A = NewClass("A")
        local backing = {}
        A:addFields({
            {
                key = "special",
                get = function(obj, key)
                    return backing[obj]
                end,
                set = function(obj, key, value)
                    backing[obj] = value
                end,
            },
        })
        local a = A:new()
        a.special = "stored"
        t:assertEqual(a.special, "stored")
        t:assertNil(rawget(a, "_values").special)
    end,

    ["once fields refuse a second value"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "id", once = true } })
        local a = A:new()
        a.id = 1
        t:assertTrue(not pcall(function()
            a.id = 2
        end))
    end,

    ["applyFields runs custom setters for defaults"] = function(t)
        local A = NewClass("A")
        A:addFields({
            {
                key = "enabled",
                default = true,
                get = function(obj)
                    return rawget(obj, "_enabled")
                end,
                set = function(obj, key, value)
                    rawset(obj, "_enabled", value)
                    rawset(obj, "_setterRan", true)
                end,
            },
        })
        function A:initialize(config)
            self:applyFields(config)
        end
        local a = A:new({})
        t:assertEqual(a.enabled, true)
        t:assertTrue(rawget(a, "_setterRan"))
        local b = A:new({ enabled = false })
        t:assertEqual(b.enabled, false)
    end,

    ["applyFields sets declared keys and enforces required"] = function(t)
        local A = NewClass("A")
        A:addFields({
            { key = "name", required = true },
            { key = "size", type = "Number", default = 2 },
        })
        function A:initialize(config)
            self:applyFields(config)
        end
        local a = A:new({ name = "thing" })
        t:assertEqual(a.name, "thing")
        t:assertEqual(a.size, 2)
        t:assertTrue(not pcall(function()
            A:new({})
        end))
    end,

    -- ------------------------------------------------------------------
    -- DB: routing, restore, defaults, recursion
    -- ------------------------------------------------------------------
    ["fields persist to the store their scope picks"] = function(t)
        local A = NewClass("A")
        A:addFields({
            { key = "acct", persist = true }, -- global by default
            { key = "mine", persist = true, global = false },
        })
        local a = A:new()
        local char, global = {}, {}
        a:setDB({ char = char, global = global })
        a.acct = "everyone"
        a.mine = "just me"
        t:assertEqual(global.acct, "everyone")
        t:assertNil(char.acct)
        t:assertEqual(char.mine, "just me")
        t:assertNil(global.mine)
    end,

    ["setDB restores values from the right stores"] = function(t)
        local A = NewClass("A")
        A:addFields({
            { key = "acct", persist = true },
            { key = "mine", persist = true, global = false },
        })
        local a = A:new()
        a:setDB({ char = { mine = "c" }, global = { acct = "g" } })
        t:assertEqual(a.acct, "g")
        t:assertEqual(a.mine, "c")
    end,

    ["setDB fills defaults for missing values without writing back"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "size", type = "Number", default = 4, persist = true } })
        local global = {}
        local a = A:new()
        a:setDB({ global = global })
        t:assertEqual(a.size, 4)
        t:assertNil(global.size) -- restore never persists
        a.size = 6
        t:assertEqual(global.size, 6) -- but the pair is bound afterwards
    end,

    ["a character-only pair captures global fields too"] = function(t)
        -- The nesting rule: below a char-scoped container the global store is
        -- structurally unreachable.
        local A = NewClass("A")
        A:addFields({ { key = "acct", persist = true } }) -- global-flagged
        local char = {}
        local a = A:new()
        a:setDB({ char = char })
        a.acct = "trapped"
        t:assertEqual(char.acct, "trapped")
    end,

    ["a bare node acts as a character pair"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "x", persist = true, global = false } })
        local node = { x = 1 }
        local a = A:new()
        a:setDB(node)
        t:assertEqual(a.x, 1)
        a.x = 2
        t:assertEqual(node.x, 2)
    end,

    ["setter return value is what persists"] = function(t)
        local A = NewClass("A")
        A:addFields({
            {
                key = "spell",
                persist = true,
                set = function(obj, key, value)
                    rawset(obj, "_spell", value)
                    return "canonical:" .. value
                end,
                get = function(obj)
                    return rawget(obj, "_spell")
                end,
            },
        })
        local global = {}
        local a = A:new()
        a:setDB({ global = global })
        a.spell = "frostbolt"
        t:assertEqual(a.spell, "frostbolt")
        t:assertEqual(global.spell, "canonical:frostbolt")
    end,

    ["function values never persist"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "dynamic", persist = true } })
        local global = {}
        local a = A:new()
        a:setDB({ global = global })
        a.dynamic = function()
            return 1
        end
        t:assertNil(global.dynamic)
    end,

    ["table fields persist deep copies, not references"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "opts", type = "Table", persist = true } })
        local global = {}
        local a = A:new()
        a:setDB({ global = global })
        local value = { volume = 5 }
        a.opts = value
        t:assertTrue(global.opts ~= value)
        t:assertEqual(global.opts.volume, 5)
    end,

    ["getDefaultDB splits by scope"] = function(t)
        local A = NewClass("A")
        A:addFields({
            { key = "acct", persist = true, default = "g" },
            { key = "mine", persist = true, global = false, default = "c" },
            { key = "runtime", default = "no persist" },
        })
        local a = A:new()
        local global = a:getDefaultDB("global")
        local char = a:getDefaultDB("char")
        t:assertEqual(global.acct, "g")
        t:assertNil(global.mine)
        t:assertEqual(char.mine, "c")
        t:assertNil(char.acct)
        t:assertNil(global.runtime)
    end,

    ["dict fields cascade setDB to children with threaded pairs"] = function(t)
        local Child = NewClass("Child")
        Child:addFields({
            { key = "acct", persist = true },
            { key = "mine", persist = true, global = false },
        })
        local Parent = NewClass("Parent")
        Parent:addFields({ { key = "kids", type = "Dict", persist = true } })
        local p = Parent:new()
        local kid = Child:new()
        rawget(p, "_values").kids = { alpha = kid }

        local char = { kids = { alpha = { mine = "c" } } }
        local global = { kids = { alpha = { acct = "g" } } }
        p:setDB({ char = char, global = global })
        t:assertEqual(kid.acct, "g")
        t:assertEqual(kid.mine, "c")

        kid.acct = "changed"
        t:assertEqual(global.kids.alpha.acct, "changed")
        kid.mine = "moved"
        t:assertEqual(char.kids.alpha.mine, "moved")
    end,

    ["a char-scoped dict forces the whole subtree to char"] = function(t)
        local Child = NewClass("Child")
        Child:addFields({ { key = "acct", persist = true } }) -- wants global
        local Parent = NewClass("Parent")
        Parent:addFields({ { key = "kids", type = "Dict", persist = true, global = false } })
        local p = Parent:new()
        local kid = Child:new()
        rawget(p, "_values").kids = { only = kid }

        local char, global = {}, {}
        p:setDB({ char = char, global = global })
        kid.acct = "kept local"
        t:assertEqual(char.kids.only.acct, "kept local")
        t:assertNil(global.kids) -- the global side was never descended
    end,

    ["instance arrays cascade by index and stamp array type"] = function(t)
        local Child = NewClass("Child")
        Child:addFields({ { key = "n", type = "Number", persist = true, default = 0 } })
        local Parent = NewClass("Parent")
        Parent:addFields({ { key = "items", type = "InstanceArray", persist = true } })
        local p = Parent:new()
        local one, two = Child:new(), Child:new()
        rawget(p, "_values").items = { one, two }

        local global = { items = { { n = 5 }, { n = 7 } } }
        p:setDB({ global = global })
        t:assertEqual(one.n, 5)
        t:assertEqual(two.n, 7)

        local defaults = p:getDefaultDB("global")
        t:assertEqual(defaults.items._type, "array")
        t:assertEqual(#defaults.items, 2)
    end,

    ["dict defaults recurse per scope"] = function(t)
        local Child = NewClass("Child")
        Child:addFields({
            { key = "acct", persist = true, default = "g" },
            { key = "mine", persist = true, global = false, default = "c" },
        })
        local Parent = NewClass("Parent")
        Parent:addFields({ { key = "kids", type = "Dict", persist = true } })
        local p = Parent:new()
        rawget(p, "_values").kids = { one = Child:new() }

        local global = p:getDefaultDB("global")
        local char = p:getDefaultDB("char")
        t:assertEqual(global.kids.one.acct, "g")
        t:assertNil(global.kids.one.mine)
        t:assertEqual(char.kids.one.mine, "c")
    end,

    ["onSetDB hook fires after restore"] = function(t)
        local A = NewClass("A")
        A:addFields({ { key = "x", persist = true } })
        local got = nil
        function A:onSetDB(pair)
            got = self.x
        end
        local a = A:new()
        a:setDB({ global = { x = "ready" } })
        t:assertEqual(got, "ready")
    end,
})
