-- Settings pages built with Spoken's layout library, read into the game
-- options window (Spoken itself and its parts: Quests, Gossip, Places,
-- Readables, Bosses, World Chatter).
--
-- Those are canvas pages: frames the addon draws itself, of which the
-- options window's two lists know nothing, so nothing on them was read. But
-- every one of them is built through one library (the global SpokenLayout,
-- Spoken/UI/Layout.lua), and the library keeps a record of what it builds:
--   layout.items    the page top to bottom: { kind = "section", text, rows,
--                   button }, { kind = "row", control, shown, members },
--                   { kind = "group", text } ... { kind = "groupEnd" }
--   layout.entries  the page's search index: { frame, label, tooltip } for
--                   every control
--   layout.defaults the header's Defaults button
-- and its controls carry what the library's own tests drive them with:
-- layoutRead, layoutSlider and layoutRange, layoutChoose, layoutReason (why
-- a row is greyed out), layoutChecked and layoutSelected. The page is read
-- from that record, not from the screen: order, labels, tooltips and hidden
-- rows are the library's own, and a control is worked by the click or value
-- change the mouse would give it. Nothing here is protected: these are an
-- addon's frames, run by addon code as the mouse runs them.
--
-- Everything is read defensively. The record is Spoken's own and may change
-- with its versions: a page that no longer looks like one is not read, and
-- a row of a kind not known here is left out.
local pages = {}

local function objectType(frame)
    if type(frame) ~= "table" or frame.GetObjectType == nil then
        return nil
    end
    local ok, kind = pcall(frame.GetObjectType, frame)
    return ok and kind or nil
end

local function textOf(region)
    if type(region) ~= "table" or region.GetText == nil then
        return nil
    end
    local ok, text = pcall(region.GetText, region)
    if ok and type(text) == "string" and text ~= "" then
        return text
    end
    return nil
end
pages.textOf = textOf

local function shown(frame)
    if type(frame) ~= "table" or frame.IsShown == nil then
        return false
    end
    local ok, visible = pcall(frame.IsShown, frame)
    return ok and visible and true or false
end

-- A plain string out of a string, or a function that gives one.
local function plain(value)
    if type(value) == "function" then
        local ok, result = pcall(value)
        value = ok and result or nil
    end
    if type(value) == "string" and value ~= "" then
        return value
    end
    return nil
end

local function join(...)
    local parts = {}
    for i = 1, select("#", ...) do
        local part = select(i, ...)
        if part ~= nil and part ~= "" then
            parts[#parts + 1] = tostring(part)
        end
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ", ")
end
pages.join = join

function pages.isLayout(layout)
    return type(layout) == "table" and type(layout.items) == "table" and type(layout.entries) == "table"
end

-- What kind of row a control is, or nil for one not known here.
function pages.kindOf(control)
    if type(control) ~= "table" then
        return nil
    end
    if control.layoutSlider ~= nil then
        return "slider"
    end
    if control.layoutChoose ~= nil then
        return "dropdown"
    end
    if control.layoutCard ~= nil then
        return "card"
    end
    if control.layoutTile ~= nil then
        return "tile"
    end
    if control.layoutLink ~= nil then
        return "link"
    end
    if control.layoutStatusLine ~= nil then
        return "field"
    end
    local kind = objectType(control)
    if kind == "CheckButton" then
        return "checkbox"
    end
    if kind == "Button" then
        return "button"
    end
    if kind == "FontString" then
        return "note"
    end
    return nil
end

-- The controls of one row: a row of cards holds several (members), a list
-- is one row whose panel holds a row per entry (layoutRows).
local function controlsOf(row)
    if type(row.members) == "table" then
        return row.members
    end
    local control = row.control
    if type(control) == "table" and type(control.layoutRows) == "table" then
        return control.layoutRows
    end
    return { control }
end

-- The page as a flat list, top to bottom: { kind, control, label, tooltip,
-- section = { key, label }? } per control. Rows the page hides are left out
-- (row.shown is false), and so is a note without words.
function pages.describe(layout)
    local list = {}
    if not pages.isLayout(layout) then
        return list
    end
    local labels = {}
    for _, entry in ipairs(layout.entries) do
        if type(entry) == "table" and entry.frame ~= nil then
            labels[entry.frame] = entry
        end
    end
    local function add(control, section)
        local kind = pages.kindOf(control)
        if kind == nil or (kind == "note" and textOf(control) == nil) then
            return
        end
        local entry = labels[control]
        list[#list + 1] = {
            kind = kind,
            control = control,
            section = section,
            label = entry ~= nil and plain(entry.label) or nil,
            tooltip = entry ~= nil and plain(entry.tooltip) or nil,
        }
    end
    local function addRows(rows, section)
        for _, row in ipairs(rows) do
            if type(row) == "table" and row.shown ~= false then
                for _, control in ipairs(controlsOf(row)) do
                    add(control, section)
                end
            end
        end
    end
    local group = nil
    local sections = 0
    for _, item in ipairs(layout.items) do
        if type(item) == "table" then
            if item.kind == "group" then
                group = item
            elseif item.kind == "groupEnd" then
                group = nil
            elseif item.kind == "section" then
                sections = sections + 1
                -- inside a group a section's name stands under the group's
                local title = join(group ~= nil and plain(group.text) or nil, plain(item.text))
                local section = title ~= nil and { key = sections, label = title } or nil
                if item.button ~= nil and shown(item.button) then
                    add(item.button, section)
                end
                addRows(item.rows or {}, section)
            elseif item.kind == "row" then
                addRows({ item }, nil)
            end
        end
    end
    if layout.defaults ~= nil and shown(layout.defaults) then
        add(layout.defaults, nil)
    end
    return list
end

-- Why a control does nothing right now: the library's reason (a string, or
-- true where it gives none), or nil while it works.
function pages.reasonOf(control)
    local reason = control.layoutReason
    if reason ~= nil and reason ~= false then
        return reason
    end
    if control.IsEnabled ~= nil then
        local ok, enabled = pcall(control.IsEnabled, control)
        if ok and enabled == false then
            return true
        end
    end
    return nil
end

-- What a status field shows: its words and its figure ("Voice Packs", "2/4").
local function fieldValue(control)
    return join(plain(control.value), plain(control.message))
end

local function click(frame)
    if type(frame) == "table" and frame.Click ~= nil then
        frame:Click()
    end
end

-- ---- nodes ----

-- The node of one described control, or nil. context: { scroller? }.
function pages.node(entry, context)
    local graph = WowVision.graph
    local nodes = graph.nodes
    local kinds = graph.kinds
    local L = WowVision:getLocale()
    local control = entry.control
    local kind = entry.kind
    local vtable = nil
    local extraTooltip = nil

    if kind == "checkbox" then
        vtable = nodes.toggle({
            label = entry.label or textOf(control.layoutLabel) or "",
            get = function()
                return control:GetChecked() and true or false
            end,
            set = function()
                click(control)
            end,
        })
    elseif kind == "slider" then
        local range = type(control.layoutRange) == "table" and control.layoutRange or {}
        local function get()
            if control.layoutRead ~= nil then
                return control.layoutRead()
            end
            return control.layoutSlider:GetValue()
        end
        vtable = nodes.number({
            label = entry.label or textOf(control.layoutLabel) or "",
            get = get,
            set = function(value)
                value = tonumber(value)
                if value == nil then
                    error("not a number")
                end
                if range[1] ~= nil and value < range[1] then
                    value = range[1]
                end
                if range[2] ~= nil and value > range[2] then
                    value = range[2]
                end
                -- the slider's own value-changed handler writes the setting
                control.layoutSlider:SetValue(value)
            end,
            step = range[3] or 1,
            valueText = function()
                -- as the page shows it ("30%", "1.5s"), else the bare number
                local text = textOf(control.RightText) or textOf(control.layoutValue)
                if text ~= nil then
                    return text
                end
                local value = get()
                return value ~= nil and tostring(value) or nil
            end,
        })
    elseif kind == "dropdown" then
        local dropdown = control.Dropdown or control
        local function classicPart(suffix)
            local name = control.GetName ~= nil and control:GetName() or nil
            return name ~= nil and _G[name .. suffix] or nil
        end
        local function valueText()
            return textOf(dropdown.Text) or textOf(dropdown) or textOf(classicPart("Text"))
        end
        vtable = {
            controlType = graph.controlTypes.dropdown,
            announcements = {
                { text = entry.label or textOf(control.layoutLabel) or "", kind = kinds.label },
                { text = valueText, kind = kinds.value, live = "focus" },
            },
            -- the control's real menu, which the dropdown watcher reads like any other
            onActivate = function()
                if control.layoutDropdown then
                    click(classicPart("Button"))
                else
                    nodes.openDropdown(dropdown)
                end
            end,
            stateText = valueText,
        }
    elseif kind == "card" then
        local item = control.layoutCard
        extraTooltip = plain(item.text)
        local function valueText()
            local state = control.layoutChecked and L["Checked"] or L["Unchecked"]
            return join(state, control.status ~= nil and fieldValue(control.status) or nil)
        end
        vtable = nodes.toggle({
            label = entry.label or plain(item.title) or "",
            get = function()
                return control.layoutChecked == true
            end,
            set = function()
                click(control.check)
            end,
            valueText = valueText,
        })
    elseif kind == "tile" then
        local item = control.layoutTile
        extraTooltip = plain(item.text)
        vtable = nodes.button({
            label = entry.label or plain(item.title) or "",
            selected = function()
                return control.layoutSelected == true
            end,
            onActivate = function()
                click(control)
            end,
        })
    elseif kind == "link" then
        local item = control.layoutLink
        vtable = nodes.text({ label = join(entry.label or plain(item.title), plain(item.url)) or "" })
    elseif kind == "field" then
        local caption = textOf(control.layoutLabel) or entry.label
        local button = control.layoutButton
        if objectType(control) == "Button" then
            -- a key binding: Enter is the click that waits for a key
            vtable = nodes.button({
                label = caption or "",
                value = function()
                    return fieldValue(control)
                end,
                onActivate = function()
                    click(control)
                end,
            })
        elseif button ~= nil and shown(button) then
            -- something to get (a voice pack): its button
            vtable = nodes.button({
                label = function()
                    return join(caption, textOf(button)) or ""
                end,
                onActivate = function()
                    click(button)
                end,
            })
        else
            vtable = nodes.text({
                label = function()
                    return join(caption, fieldValue(control)) or ""
                end,
                live = "focus",
            })
        end
    elseif kind == "button" then
        vtable = nodes.button({
            -- live: a cycle button's caption carries its value
            label = function()
                return textOf(control) or entry.label or ""
            end,
            onActivate = function()
                click(control)
            end,
        })
    elseif kind == "note" then
        vtable = nodes.text({
            label = function()
                return textOf(control) or ""
            end,
        })
    end
    if vtable == nil then
        return nil
    end

    -- Greyed-out rows are still read, say Disabled and take no key, as the
    -- game's own settings rows do (windows/options/ui.lua).
    local function disabled()
        return pages.reasonOf(control) ~= nil
    end
    tinsert(vtable.announcements, {
        text = function()
            return disabled() and L["Disabled"] or nil
        end,
        kind = kinds.enabled,
    })
    local stateText = vtable.stateText
    vtable.stateText = function(...)
        if disabled() then
            return L["Disabled"]
        end
        return stateText ~= nil and stateText(...) or nil
    end
    for _, key in ipairs({ "onActivate", "onAdjust" }) do
        local handler = vtable[key]
        if handler ~= nil then
            vtable[key] = function(...)
                if not disabled() then
                    return handler(...)
                end
            end
        end
    end

    local reason = pages.reasonOf(control)
    local tooltip = join(entry.tooltip, extraTooltip, type(reason) == "string" and reason or nil)
    if tooltip ~= nil then
        vtable.tooltip = { type = "Text", text = tooltip }
    end

    -- Bring the row into view on the page, for whoever looks on: where the
    -- library's own search lands a row (Options:ShowRow).
    local scroller = context ~= nil and context.scroller or nil
    if scroller ~= nil and scroller.ScrollTo ~= nil then
        vtable.onFocus = function()
            local y = control.layoutY
            if type(y) == "number" then
                pcall(scroller.ScrollTo, scroller, -y - 60)
            end
        end
    end
    return vtable
end

-- A list row's own button (the button to a module's page), as an entry
-- after the row.
local function cardButton(entry)
    local control = entry.control
    local button = entry.kind == "card" and control.button or nil
    if button == nil or not shown(button) then
        return nil
    end
    local nodes = WowVision.graph.nodes
    local L = WowVision:getLocale()
    local vtable = nodes.button({
        label = function()
            return join(entry.label or plain(control.layoutCard.title), textOf(button)) or ""
        end,
        onActivate = function()
            if pages.reasonOf(button) == nil then
                click(button)
            end
        end,
    })
    tinsert(vtable.announcements, {
        text = function()
            return pages.reasonOf(button) ~= nil and L["Disabled"] or nil
        end,
        kind = WowVision.graph.kinds.enabled,
    })
    return button, vtable
end

-- ---- the page in the options window ----

-- The canvas frame the settings panel shows now and its category's name, or
-- nil on one of the game's own list pages.
local function currentCanvas(panel)
    local ok, frame, title = pcall(function()
        local layout = panel:GetCurrentLayout()
        if layout == nil or layout.GetFrame == nil then
            return nil
        end
        if layout.IsVerticalLayout ~= nil and layout:IsVerticalLayout() then
            return nil
        end
        local category = panel:GetCurrentCategory()
        local name = category ~= nil and category.GetName ~= nil and category:GetName() or nil
        return layout:GetFrame(), name
    end)
    if ok and frame ~= nil then
        return frame, title
    end
    return nil
end

-- The layout a canvas frame was built with and its scroller: on the frame
-- itself where the page keeps it there, else from Spoken's list of pages.
function pages.layoutOf(frame, spokenEnv)
    if type(frame) ~= "table" then
        return nil
    end
    if pages.isLayout(frame.layout) then
        local parent = frame.layout.parent
        return frame.layout, type(parent) == "table" and parent.layoutScroller or nil
    end
    local options = type(spokenEnv) == "table" and spokenEnv.Options or nil
    if type(options) ~= "table" or type(options.Pages) ~= "function" then
        return nil
    end
    local ok, list = pcall(options.Pages, options)
    if not ok or type(list) ~= "table" then
        return nil
    end
    for _, page in ipairs(list) do
        if type(page) == "table" and page.frame == frame and pages.isLayout(page.layout) then
            return page.layout, page.scroller
        end
    end
    return nil
end

-- The settings panel shows an addon's own page: one tab stop with its rows,
-- where the page is one this file can read. Returns whether it was.
function pages.render(builder, panel)
    local frame, title = currentCanvas(panel)
    if frame == nil then
        return false
    end
    local layout, scroller = pages.layoutOf(frame, rawget(_G, "SpokenEnv"))
    if layout == nil then
        return false
    end
    local list = pages.describe(layout)
    if #list == 0 then
        return false
    end
    local ControlId = WowVision.graph.ControlId
    local context = { scroller = scroller }
    builder:beginStop("settings")
    builder:pushContext("page", title or WowVision:getLocale()["Options"])
    local current = nil
    for _, entry in ipairs(list) do
        local key = entry.section ~= nil and entry.section.key or nil
        if key ~= current then
            if current ~= nil then
                builder:popContext()
            end
            if key ~= nil then
                builder:pushContext("section:" .. key, entry.section.label)
            end
            current = key
        end
        local vtable = pages.node(entry, context)
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(entry.control), vtable)
        end
        local button, buttonNode = cardButton(entry)
        if button ~= nil then
            builder:addItem(ControlId.forObject(button), buttonNode)
        end
    end
    if current ~= nil then
        builder:popContext()
    end
    builder:popContext()
    return true
end

WowVision.layoutPages = pages
