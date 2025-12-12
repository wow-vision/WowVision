local module = WowVision.base.windows.collections
local L = module.L
local gen = module:hasUI()

gen:Element("collections/MountJournal", function(props)
    local frame = props.frame
    local result =
        { "Panel", label = L["Mounts"], children = {
            { "collections/MountJournal/SearchBox" },
            {"collections/MountJournal/MountList", frame = frame.ScrollBox},
            {"ProxyButton",
            frame = MountJournalMountButton
                }
        } }
    return result
end)

gen:Element("collections/MountJournal/SearchBox", function(props)
    local frame = MountJournalSearchBox
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "ProxyEditBox", frame = frame, label = L["Search"] },
        },
    }
    if frame:GetText() ~= "" then
        tinsert(result.children, { "ProxyButton", frame = frame.clearButton, label = L["Clear"] })
    end
    return result
end)

local function MountList_GetButton(self, button)
    local label = button.name:GetText()
    if button.active then
        label = label .. " (" .. L["Mounted"] .. ")"
    end
    return {"ProxyButton",
    frame = button,
    dragFrame = button.DragButton,
    label = label
}
end

gen:Element("collections/MountJournal/MountList", function(props)
    return {"ProxyScrollBox",
    frame = MountJournal.ScrollBox,
    label = L["Mounts"],
    getElement = MountList_GetButton,
    ordered = false
}
end)