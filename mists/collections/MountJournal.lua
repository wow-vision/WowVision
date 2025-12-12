local module = WowVision.base.windows.collections
local L = module.L
local gen = module:hasUI()

gen:Element("collections/MountJournal", function(props)
    local frame = props.frame
    local result =
        { "Panel", label = L["Mounts"], children = {
            { "collections/MountJournal/SearchBox" },
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
