local testRunner = WowVision.testing.testRunner
local pages = WowVision.layoutPages

-- Stand-ins for the frames Spoken's layout library builds: an object type,
-- a text, a shown flag, and what a click does.
local function frame(kind, fields)
    local object = fields or {}
    object.shownFlag = object.shownFlag ~= false
    function object:GetObjectType()
        return kind
    end
    function object:GetText()
        return self.text
    end
    function object:IsShown()
        return self.shownFlag
    end
    function object:Click()
        self.clicks = (self.clicks or 0) + 1
        if self.onClick ~= nil then
            self.onClick(self)
        end
    end
    return object
end

local function checkbox(checked)
    local box = frame("CheckButton", { checked = checked })
    function box:GetChecked()
        return self.checked
    end
    box.onClick = function(self)
        self.checked = not self.checked
    end
    return box
end

local function kindsOf(list)
    local out = {}
    for i, entry in ipairs(list) do
        out[i] = entry.kind
    end
    return table.concat(out, ",")
end

local function part(vtable, kind)
    for _, announcement in ipairs(vtable.announcements) do
        if announcement.kind == kind then
            local text = announcement.text
            if type(text) == "function" then
                text = text()
            end
            return text
        end
    end
    return nil
end

local kinds = WowVision.graph.kinds

testRunner:addSuite("LayoutPages", {
    ["only a table with items and entries is a page"] = function(t)
        t:assertTrue(pages.isLayout({ items = {}, entries = {} }))
        t:assertFalse(pages.isLayout({ items = {} }))
        t:assertFalse(pages.isLayout(nil))
        t:assertEqual(#pages.describe({ items = {} }), 0)
    end,

    ["the page reads top to bottom with labels from the search index"] = function(t)
        local box = checkbox(true)
        local note = frame("FontString", { text = "Applies to every part." })
        local button = frame("Button", { text = "Reset" })
        local hidden = checkbox(false)
        local heading = frame("Button", { text = "Test" })
        local layout = {
            entries = {
                { frame = box, label = "Silence NPC Voices", tooltip = "Mutes the game's dialogue." },
                { frame = hidden, label = "Hidden" },
                { frame = heading, label = "Test" },
            },
            items = {
                { kind = "intro" },
                { kind = "row", control = button },
                {
                    kind = "section",
                    text = "While Reading",
                    button = heading,
                    rows = {
                        { control = box, shown = true },
                        { control = hidden, shown = false },
                        { control = note },
                    },
                },
            },
        }
        local list = pages.describe(layout)
        t:assertEqual(kindsOf(list), "button,button,checkbox,note")
        t:assertNil(list[1].section)
        t:assertEqual(list[2].control, heading)
        t:assertEqual(list[3].label, "Silence NPC Voices")
        t:assertEqual(list[3].tooltip, "Mutes the game's dialogue.")
        t:assertEqual(list[3].section.label, "While Reading")
        t:assertEqual(list[3].section.key, list[4].section.key)
    end,

    ["a section in a group stands under the group's name"] = function(t)
        local first, second = checkbox(false), checkbox(false)
        local layout = {
            entries = {},
            items = {
                { kind = "group", text = "Narrator" },
                { kind = "section", text = "Window", rows = { { control = first } } },
                { kind = "section", rows = { { control = second } } },
                { kind = "groupEnd" },
                { kind = "section", text = "Audio", rows = { { control = checkbox(false) } } },
            },
        }
        local list = pages.describe(layout)
        t:assertEqual(list[1].section.label, "Narrator, Window")
        t:assertEqual(list[2].section.label, "Narrator")
        t:assertEqual(list[3].section.label, "Audio")
        t:assertNotEqual(list[1].section.key, list[2].section.key)
    end,

    ["a list is a row per entry, a row of cards a control per card"] = function(t)
        local quests = frame("Button", { layoutCard = { title = "Quests" } })
        local places = frame("Button", { layoutCard = { title = "Places" } })
        local panel = frame("Frame", { layoutRows = { quests, places } })
        local minimal = frame("Button", { layoutTile = { title = "Minimal" } })
        local classic = frame("Button", { layoutTile = { title = "Classic" } })
        local layout = {
            entries = { { frame = quests, label = "Quests" } },
            items = {
                { kind = "row", control = panel },
                { kind = "row", control = minimal, members = { minimal, classic } },
            },
        }
        local list = pages.describe(layout)
        t:assertEqual(kindsOf(list), "card,card,tile,tile")
        t:assertEqual(list[1].label, "Quests")
        t:assertNil(list[2].label)
    end,

    ["the kinds of row"] = function(t)
        t:assertEqual(pages.kindOf(frame("Frame", { layoutSlider = {} })), "slider")
        t:assertEqual(pages.kindOf(frame("Frame", { layoutChoose = function() end })), "dropdown")
        t:assertEqual(pages.kindOf(frame("Frame", { layoutLink = {} })), "link")
        t:assertEqual(pages.kindOf(frame("Frame", { layoutStatusLine = {} })), "field")
        t:assertEqual(pages.kindOf(checkbox(false)), "checkbox")
        t:assertNil(pages.kindOf(frame("Frame")))
        t:assertNil(pages.kindOf(nil))
    end,

    ["a checkbox is worked by its own click"] = function(t)
        local box = checkbox(false)
        local vtable = pages.node({ kind = "checkbox", control = box, label = "Silence NPC Voices" })
        t:assertEqual(part(vtable, kinds.label), "Silence NPC Voices")
        vtable.onActivate()
        t:assertEqual(box.clicks, 1)
        t:assertTrue(box.checked)
        t:assertNil(part(vtable, kinds.enabled))
    end,

    ["a greyed-out row says Disabled, takes no key and gives its reason"] = function(t)
        local box = checkbox(false)
        box.layoutReason = "Switch Quests on first."
        local entry = { kind = "checkbox", control = box, label = "Autoplay", tooltip = "Reads by itself." }
        local vtable = pages.node(entry)
        t:assertNotNil(part(vtable, kinds.enabled))
        vtable.onActivate()
        t:assertNil(box.clicks)
        t:assertEqual(vtable.tooltip.text, "Reads by itself., Switch Quests on first.")
    end,

    ["a slider sets its own slider within the range and reads as the page shows it"] = function(t)
        local value = 0.3
        local slider = {}
        function slider:SetValue(v)
            value = v
        end
        local control = frame("Frame", {
            layoutSlider = slider,
            layoutRange = { 0, 1, 0.05 },
            layoutRead = function()
                return value
            end,
            RightText = frame("FontString", { text = "30%" }),
        })
        local vtable = pages.node({ kind = "slider", control = control, label = "Music" })
        t:assertEqual(part(vtable, kinds.value), "30%")
        vtable.onAdjust(1, false)
        t:assertTrue(math.abs(value - 0.35) < 0.0001)
        value = 0.98
        vtable.onAdjust(1, false)
        t:assertEqual(value, 1)
    end,

    ["a dropdown reads its pick and opens its own menu"] = function(t)
        local opened = 0
        local dropdown = frame("DropdownButton", { Text = frame("FontString", { text = "Master" }) })
        function dropdown:OpenMenu()
            opened = opened + 1
        end
        local control = frame("Frame", { layoutChoose = function() end, Dropdown = dropdown })
        local vtable = pages.node({ kind = "dropdown", control = control, label = "Sound Channel" })
        t:assertEqual(part(vtable, kinds.value), "Master")
        vtable.onActivate()
        t:assertEqual(opened, 1)
    end,

    ["a module's row is a checkbox with its voice packs, its button an entry of its own"] = function(t)
        local check = checkbox(true)
        local row = frame("Button", {
            layoutCard = { title = "Quests", text = "Quest text read aloud." },
            layoutChecked = true,
            check = check,
            status = { value = "2/4", message = "Voice Packs" },
        })
        local vtable = pages.node({ kind = "card", control = row, label = "Quests" })
        t:assertEqual(part(vtable, kinds.label), "Quests")
        t:assertTrue(part(vtable, kinds.value):find("2/4, Voice Packs", 1, true) ~= nil)
        t:assertEqual(vtable.tooltip.text, "Quest text read aloud.")
        vtable.onActivate()
        t:assertEqual(check.clicks, 1)
    end,

    ["a style's tile is a button that says when it is the chosen one"] = function(t)
        local item = { title = "Subtitle", text = "Words only." }
        local tile = frame("Button", { layoutTile = item, layoutSelected = true })
        local vtable = pages.node({ kind = "tile", control = tile })
        t:assertEqual(part(vtable, kinds.label), "Subtitle")
        t:assertNotNil(part(vtable, kinds.selected))
        vtable.onActivate()
        t:assertEqual(tile.clicks, 1)
    end,

    ["a button reads its caption live, a key field its key"] = function(t)
        local cycle = frame("Button", { text = "Voice: Narrator" })
        local vtable = pages.node({ kind = "button", control = cycle, label = "Voice: %s" })
        t:assertEqual(part(vtable, kinds.label), "Voice: Narrator")
        cycle.text = "Voice: Original"
        t:assertEqual(part(vtable, kinds.label), "Voice: Original")

        local key = frame("Button", {
            layoutStatusLine = {},
            layoutLabel = frame("FontString", { text = "Play or Pause" }),
            message = "Ctrl-P",
        })
        local keyNode = pages.node({ kind = "field", control = key })
        t:assertEqual(part(keyNode, kinds.label), "Play or Pause")
        t:assertEqual(part(keyNode, kinds.value), "Ctrl-P")
        keyNode.onActivate()
        t:assertEqual(key.clicks, 1)
    end,

    ["a page's layout is found on its frame or in Spoken's list of pages"] = function(t)
        local scroller = {}
        local layout = { items = {}, entries = {}, parent = { layoutScroller = scroller } }
        local own = { layout = layout }
        local found, foundScroller = pages.layoutOf(own, nil)
        t:assertEqual(found, layout)
        t:assertEqual(foundScroller, scroller)

        local listed = {}
        local other = { items = {}, entries = {} }
        local env = {
            Options = {
                Pages = function()
                    return { { frame = {}, layout = layout }, { frame = listed, layout = other, scroller = scroller } }
                end,
            },
        }
        found, foundScroller = pages.layoutOf(listed, env)
        t:assertEqual(found, other)
        t:assertEqual(foundScroller, scroller)
        t:assertNil(pages.layoutOf({}, env))
        t:assertNil(pages.layoutOf({}, nil))
        t:assertNil(pages.layoutOf(nil, env))
    end,
})
