local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- Shared pieces for the WoW: Forever collection tabs: the toy box,
-- heirlooms, and appearances are paged grids of fixed or pooled buttons,
-- and a button shows a different collectible on every page.

-- A row over the button currently showing one collectible. find() returns
-- that button (or nil) and is resolved on every read and click, since
-- page flips and refilters rebind the buttons; the host re-engages the
-- click when the resolution drifts. No hover scripts: the buttons' OnEnter
-- writes state (new-item flags, the tooltip refresh field) and would run as
-- the addon; the tooltip is filled directly instead.
-- config: {
--   find = function() -> frame?,
--   label = function(frame) -> string,
--   tooltip = function(tooltip, frame)?,
--   selected = function() -> bool?,
--   rightClick = false?   -- drop the right click (nothing on right)
-- }
function module.foundButtonNode(config)
    local find = config.find
    local announcements = {
        {
            text = function()
                local frame = find()
                return frame ~= nil and config.label(frame) or nil
            end,
            kind = kinds.label,
        },
    }
    if config.selected ~= nil then
        tinsert(announcements, {
            text = function()
                return config.selected() and L["selected"] or nil
            end,
            kind = kinds.selected,
        })
    end
    local bindings = {
        { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = find },
    }
    if config.rightClick ~= false then
        tinsert(bindings, { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = find })
    end
    tinsert(bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local frame = find()
            local script = frame ~= nil and frame:GetScript("OnDragStart") or nil
            if script ~= nil then
                script(frame)
            end
        end,
    })
    local vtable = {
        controlType = graph.controlTypes.button,
        contextActions = nodes.proxyContextActions(find),
        announcements = announcements,
        bindings = bindings,
    }
    if config.tooltip ~= nil then
        -- The reader anchors the tooltip to this frame; without one it
        -- reads nothing.
        vtable.tooltipFrame = find
        vtable.tooltip = {
            type = "Game",
            mode = "immediate",
            populate = function(tooltip)
                local frame = find()
                if frame ~= nil then
                    config.tooltip(tooltip, frame)
                end
            end,
        }
    end
    return vtable
end

-- Join the non-empty parts of a label with commas.
function module.joinLabel(parts)
    local out = {}
    for _, part in ipairs(parts) do
        if part ~= nil and part ~= "" and part ~= false then
            tinsert(out, part)
        end
    end
    return table.concat(out, ", ")
end

-- The text of a FontString when shown and non-empty, else nil.
function module.shownText(fontString)
    if fontString == nil or not fontString:IsShown() then
        return nil
    end
    local text = fontString:GetText()
    if text == nil or text == "" then
        return nil
    end
    return text
end

-- A dropdown reading its name and its current pick.
function module.namedDropdown(dropdown, name)
    local current = nodes.frameText(dropdown)
    return nodes.proxyDropdown({
        target = dropdown,
        label = function()
            return module.joinLabel({ name, current() })
        end,
    })
end

-- A search box and a filter dropdown, each its own stop (an edit box
-- cannot share a stop with anything after it).
function module.renderSearchAndFilter(builder, key, searchBox, filterDropdown)
    if searchBox ~= nil then
        builder:beginStop(key .. "Search")
        builder:addItem(
            ControlId.structural(key .. "Search"),
            nodes.proxyEditBox({ editBox = searchBox, label = L["Search"] })
        )
    end
    if filterDropdown ~= nil then
        builder:beginStop(key .. "Filter")
        builder:addItem(
            ControlId.forObject(filterDropdown),
            nodes.proxyDropdown({ target = filterDropdown, label = L["Filter"] })
        )
    end
end

-- A collections paging frame (CollectionsPagingMixin): previous page, the
-- page text, next page, as one row. Nothing while there is one page.
function module.renderPaging(builder, key, paging)
    if paging == nil or not paging:IsShown() or (paging.GetMaxPages ~= nil and paging:GetMaxPages() <= 1) then
        return
    end
    builder:beginStop(key .. "Paging")
    builder:startRow()
    builder:addItem(
        ControlId.forObject(paging.PrevPageButton),
        nodes.proxyButton({ target = paging.PrevPageButton, label = L["Previous Page"] })
    )
    if paging.PageText ~= nil then
        builder:addItem(
            ControlId.structural(key .. "PageText"),
            nodes.text({
                label = function()
                    return paging.PageText:GetText() or ""
                end,
            })
        )
    end
    builder:addItem(
        ControlId.forObject(paging.NextPageButton),
        nodes.proxyButton({ target = paging.NextPageButton, label = L["Next Page"] })
    )
    builder:endRow()
end
