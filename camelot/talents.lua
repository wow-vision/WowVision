local module = WowVision.base.windows.spellbook
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local talentTree = WowVision.talentTree
local spellSearch = WowVision.spellSearch

-- The WoW: Forever class talents: the talents page of PlayerSpellsFrame,
-- opened by the talents key. One tree holds the class's three
-- specializations side by side, as in the classic talent window, each
-- under a header with the points spent in it. The page reads the
-- specialization tabs (primary and secondary, once dual specialization is
-- learned) with the activate button, the unspent points, the talent search
-- and its options, the talents a stop per specialization
-- (retail/talentTree.lua), then apply, undo, and the reset menu.

-- The tabs come from the tab system: real buttons, so real clicks. The
-- selected tab is disabled by the tab system, so it reads as selected
-- rather than disabled; the locked one reads why. Active marks the
-- specialization in use.
local function renderSpecTabs(builder, talentsFrame)
    local tabSystem = talentsFrame.TabSystem
    if not tabSystem:IsShown() then
        return
    end
    local tabs = {}
    for _, tab in ipairs(tabSystem.tabs) do
        if tab:IsShown() then
            tinsert(tabs, tab)
        end
    end
    if #tabs == 0 then
        return
    end
    builder:beginStop("specTabs")
    builder:pushContext("specTabs", L["Tabs"])
    builder:startRow()
    for _, tab in ipairs(tabs) do
        local captured = tab
        local vtable = nodes.proxyFoundButton({
            find = function()
                return captured
            end,
            label = function()
                return captured.tabText
            end,
            selected = function()
                return captured.isSelected
            end,
            rightClick = false,
        })
        tinsert(vtable.announcements, {
            text = function()
                if captured:IsActive() then
                    return L["Active"]
                end
                local disabled, reason = captured:IsForceDisabled()
                if disabled then
                    return reason or L["Locked"]
                end
                return nil
            end,
            kind = kinds.value,
        })
        builder:addItem(ControlId.structural("specTab:" .. captured:GetTabID()), vtable)
    end
    builder:endRow()
    builder:popContext()

    -- The shown tab's state: the activate button while another
    -- specialization is in use, else the game's Active line.
    local activeSpec = talentsFrame.ActiveSpec
    if activeSpec:IsShown() then
        if activeSpec.ActivateButton:IsShown() then
            builder:addItem(
                ControlId.forObject(activeSpec.ActivateButton),
                nodes.proxyButton({ target = activeSpec.ActivateButton, hover = false })
            )
        elseif activeSpec.ActiveLabel:IsShown() then
            builder:addItem(
                ControlId.structural("activeLabel"),
                nodes.text({
                    label = function()
                        return activeSpec.ActiveLabel:GetText()
                    end,
                })
            )
        end
    end
end

local function renderUnspentPoints(builder, talentsFrame)
    local display = talentsFrame.ClassCurrencyDisplay
    builder:beginStop("points")
    builder:addItem(
        ControlId.structural("unspent"),
        nodes.text({
            label = function()
                -- The game's label ends in a colon before the number.
                local label = nodes.shownText(display.UnspentLabel)
                return nodes.joinLabel(
                    label ~= nil and label:gsub(":%s*$", "") or nil,
                    nodes.shownText(display.CurrentAmountContainer.CurrencyAmount)
                )
            end,
        })
    )
end

-- The specializations as the headers over the tree name them, with the
-- points spent in each (the header's number). None while the frame has no
-- tree yet (a character without a talent loadout).
local function specGroups(talentsFrame)
    local treeID = talentsFrame:GetTalentTreeID()
    if treeID == nil then
        return {}
    end
    local displayInfos = C_Traits.GetGroupDisplayInfoByTreeID(treeID) or {}
    local groupIDs = {}
    for _, displayInfo in ipairs(displayInfos) do
        tinsert(groupIDs, displayInfo.groupID)
    end
    local spentByGroup = {}
    local configID = talentsFrame:GetConfigID()
    if configID ~= nil and #groupIDs > 0 then
        for _, groupInfo in ipairs(C_Traits.GetGroupCurrencyInfo(configID, groupIDs) or {}) do
            local currencyInfo = groupInfo.currencyInfos ~= nil and groupInfo.currencyInfos[1] or nil
            spentByGroup[groupInfo.traitNodeGroupID] = currencyInfo ~= nil and currencyInfo.spent or nil
        end
    end
    local groups = {}
    for _, displayInfo in ipairs(displayInfos) do
        local spent = spentByGroup[displayInfo.groupID] or 0
        tinsert(groups, {
            id = displayInfo.groupID,
            label = nodes.joinLabel(displayInfo.displayName, talentTree.pointsText(spent)),
        })
    end
    return groups
end

function module.renderClassTalents(builder, talentsFrame)
    builder:pushContext("talents", L["Talents"])
    renderSpecTabs(builder, talentsFrame)
    renderUnspentPoints(builder, talentsFrame)

    builder:beginStop("search")
    builder:addItem(ControlId.structural("search"), spellSearch.node(talentsFrame.SearchBox))
    builder:beginStop("searchOptions")
    builder:addItem(
        ControlId.forObject(talentsFrame.SearchOptionsDropdown),
        nodes.proxyDropdown({ target = talentsFrame.SearchOptionsDropdown, label = L["Options"] })
    )

    -- The specializations sit right under the page: the game shows all
    -- three side by side at once, a stop each, with nothing to switch.
    talentTree.renderTalents(builder, talentsFrame, {
        key = "tree",
        label = false,
        groups = specGroups(talentsFrame),
    })
    -- The reset button is a menu: the whole tree, or one currency's part.
    talentTree.renderCommitButtons(
        builder,
        talentsFrame,
        nodes.proxyDropdown({
            target = talentsFrame.ResetButton,
            label = TALENT_FRAME_RESET_BUTTON_DROPDOWN_TITLE or L["Reset Tree"],
        })
    )
    builder:popContext()
end
