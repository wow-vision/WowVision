local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The mount journal: search, the mount list (a modern ScrollBox piloted
-- with data-first labels from the mount journal API), and the mount button.

local function mountLabel(index)
    local name, _, _, isActive = C_MountJournal.GetDisplayedMountInfo(index)
    if name == nil then
        return nil
    end
    if isActive then
        return name .. " (" .. L["Mounted"] .. ")"
    end
    return name
end

local function mountRow(data, index, helpers)
    local _, spellID = C_MountJournal.GetDisplayedMountInfo(index)
    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return mountLabel(index)
                end,
                kind = kinds.label,
            },
        },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
            {
                binding = "drag",
                type = "Function",
                func = function()
                    local row = helpers.target()
                    local dragButton = row ~= nil and row.DragButton or nil
                    if dragButton ~= nil then
                        local script = dragButton:GetScript("OnDragStart")
                        if script ~= nil then
                            script(dragButton)
                        end
                    end
                end,
            },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltip = spellID ~= nil and { type = "Mount", spellID = spellID } or nil,
    }
end

function module.renderMountJournal(builder)
    builder:beginStop("search")
    builder:addItem(
        ControlId.structural("search"),
        nodes.proxyEditBox({ editBox = MountJournalSearchBox, label = L["Search"] })
    )
    -- Own stop: an edit box cannot share a stop with anything after it (tab
    -- is both its entrance and its exit).
    if MountJournalSearchBox:GetText() ~= "" and MountJournalSearchBox.clearButton ~= nil then
        builder:beginStop("clearSearch")
        builder:addItem(
            ControlId.forObject(MountJournalSearchBox.clearButton),
            nodes.proxyButton({ target = MountJournalSearchBox.clearButton, label = L["Clear"] })
        )
    end

    builder:beginStop("mounts")
    nodes.scrollBoxList(builder, {
        scrollBox = MountJournal.ScrollBox,
        key = "mounts",
        label = L["Mounts"],
        id = function(data, index)
            local mountID = select(12, C_MountJournal.GetDisplayedMountInfo(index))
            if mountID ~= nil then
                return ControlId.structural("mount:" .. mountID)
            end
            return ControlId.structural("mount:" .. index)
        end,
        row = mountRow,
    })

    if MountJournalMountButton ~= nil and MountJournalMountButton:IsShown() then
        builder:beginStop("mountButton")
        builder:addItem(
            ControlId.forObject(MountJournalMountButton),
            nodes.proxyButton({ target = MountJournalMountButton })
        )
    end
end
