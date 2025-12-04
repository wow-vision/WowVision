local module = WowVision.base.windows:createModule("character")
local L = module.L
module:setLabel(L["Character"])
local gen = module:hasUI()

gen:Element("character", function(props)
    local result = { "Panel", label = "Character Frame", wrap = true, children = {} }
    local tab = CharacterFrame.selectedTab
    if tab == 1 then
        tinsert(result.children, { "character/PaperDoll", frame = PaperDollFrame })
    elseif tab == 4 then
        tinsert(result.children, { "character/Currency", frame = TokenFrame })
    else
        tinsert(result.children, { "Text", text = "Not yet implemented" })
    end
    tinsert(result.children, { "character/Tabs" })
    return result
end)

gen:Element("character/Tabs", function(props)
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    for i = 1, 4 do
        local tab = _G["CharacterFrameTab" .. i]
        if tab then
            tinsert(result.children, {
                "ProxyButton",
                frame = tab,
                selected = CharacterFrame.selectedTab == i,
            })
        end
    end
    return result
end)

gen:Element("character/PaperDoll", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "character/Equipment", frame = PaperDollItemsFrame },
            { "character/Stats" },
        },
    }
end)

local function getEquipmentLabel(frame, slot)
    ExecuteFrameScript(frame, "OnEnter")
    local label = GameTooltipTextLeft1:GetText()
    ExecuteFrameScript(frame, "OnLeave")
    return label
end

gen:Element("character/Equipment", function(props)
    local result = { "List", label = "Equipment", children = {} }
    local children = { props.frame:GetChildren() }
    for i, v in ipairs(children) do
        tinsert(result.children, {
            "ProxyButton",
            frame = v,
            label = getEquipmentLabel(v),
            tooltip = {
                type = "game",
                mode = "immediate",
            },
        })
    end
    return result
end)

gen:Element("character/Stats", function(props)
    local result = { "List", label = "Stats", children = {} }
    for i, k in ipairs(PAPERDOLL_STATCATEGORY_DEFAULTORDER) do
        local v = PAPERDOLL_STATCATEGORIES[k]
        local categoryFrame = _G["CharacterStatsPaneCategory" .. v.id]
        tinsert(result.children, { "character/StatsCategory", frame = categoryFrame })
    end
    return result
end)

gen:Element("character/StatsCategory", function(props)
    --PaperDollFrame_UpdateStatCategory(props.frame)
    local label = props.frame.NameText:GetText()
    if not label or label == "" then
        return nil
    end
    local result = { "List", direction = "horizontal", label = label, children = {} }
    local children = { props.frame:GetChildren() }
    for i = 2, #children do
        local stat = children[i]
        if stat:IsShown() then
            tinsert(result.children, {
                "ProxyButton",
                frame = stat,
                label = tostring(stat.Label:GetText()) .. " " .. tostring(stat.Value:GetText()),
                tooltip = {
                    type = "game",
                    mode = "immediate",
                },
            })
        end
    end
    return result
end)

local function getTokenNumEntries(self, element)
    return GetCurrencyListSize()
end

local function getTokenElement(self, button)
    local index = button.index
    local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maxQuantity, maxEarnable, quantityEarned, isTradeable, itemID =
        GetCurrencyListInfo(index)
    local label = name
    local header = nil
    if isHeader then
        if isExpanded then
            header = "expanded"
        else
            header = "collapsed"
        end
    elseif count ~= nil then
        label = label .. " " .. count
    end
    return { "ProxyButton", frame = button, label = label, header = header }
end

gen:Element("character/Currency", function(props)
    local frame = TokenFrameContainer
    local result = {
        "List",
        label = CharacterFrameTab4:GetText(),
        children = {
            {
                "ProxyScrollFrame",
                frame = frame,
                getNumEntries = getTokenNumEntries,
                getElement = getTokenElement,
            },
        },
    }
    return result
end)

module:registerWindow({
    name = "character",
    auto = true,
    generated = true,
    rootElement = "character",
    frameName = "CharacterFrame",
    conflictingAddons = { "Sku" },
})
