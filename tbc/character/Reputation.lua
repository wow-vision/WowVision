local char = WowVision.tbc.character
local gen = char.gen
local L = char.L

local NUM_FACTIONS_DISPLAYED = 15

-- Map ReputationBar frames to their display indices (since GetID() returns 0)
local reputationBarIndices = {}
for i = 1, NUM_FACTIONS_DISPLAYED do
    local frame = _G["ReputationBar" .. i]
    if frame then
        reputationBarIndices[frame] = i
    end
end

-- Build a single element for a reputation row
-- Each row has ReputationBar[i] (StatusBar) and ReputationHeader[i] (Button for headers)
local function buildReputationElement(self, frame)
    local i = reputationBarIndices[frame]
    if not i then
        return nil
    end
    local bar = frame -- frame IS ReputationBar[i]
    local header = _G["ReputationHeader" .. i]

    local isHeader = header and header:IsShown()
    local isBar = bar and bar:IsShown()

    -- Must have either a header or a bar showing
    if not isHeader and not isBar then
        return nil
    end

    -- Get faction name from UI element
    -- For headers, the name is on the header button's Text, not on the bar
    local name
    if isHeader and header.Text then
        name = header.Text:GetText() or ""
    else
        local nameText = _G["ReputationBar" .. i .. "FactionName"]
        name = nameText and nameText:GetText() or ""
    end

    if not name or name == "" then
        return nil
    end

    local label = name

    -- Get standing text from UI element
    local standingFrame = _G["ReputationBar" .. i .. "FactionStanding"]
    local standingText = standingFrame and standingFrame:GetText() or ""
    if standingText and standingText ~= "" then
        label = label .. " - " .. standingText
    end

    -- Add progress if available from bar tooltip
    if bar.tooltip and bar.tooltip ~= "" then
        label = label .. bar.tooltip
    end

    -- Check if this is a header by seeing if ReputationHeader is shown
    local headerState = nil

    if isHeader then
        -- This is a header row - use the header button for clicking (it's a Button)
        if header.isCollapsed then
            headerState = "collapsed"
        else
            headerState = "expanded"
        end
        return {
            "ProxyButton",
            frame = header,
            label = label,
            header = headerState,
        }
    else
        -- For regular rows, the bar is a StatusBar that uses OnMouseUp, not OnClick
        -- Use a Button element with a click handler that calls ReputationBar_OnClick directly
        return {
            "Button",
            label = label,
            events = {
                click = function()
                    ReputationBar_OnClick(bar)
                end,
            },
        }
    end
end

local function getNumFactions()
    return GetNumFactions()
end

local function getReputationIndex(self, frame)
    local offset = FauxScrollFrame_GetOffset(ReputationListScrollFrame) or 0
    local displayIndex = reputationBarIndices[frame] or 0
    return displayIndex + offset
end

-- Return the ReputationBar frames (used for positioning even if headers use different frames)
local function getReputationRows()
    local rows = {}
    for i = 1, NUM_FACTIONS_DISPLAYED do
        local frame = _G["ReputationBar" .. i]
        if frame then
            tinsert(rows, frame)
        end
    end
    return rows
end

gen:Element("character/Reputation", function(props)
    -- If scroll frame is shown, use ProxyFauxScrollFrame
    if ReputationListScrollFrame and ReputationListScrollFrame:IsShown() then
        return {
            "ProxyFauxScrollFrame",
            frame = ReputationListScrollFrame,
            buttonHeight = REPUTATIONFRAME_FACTIONHEIGHT,
            updateFunction = ReputationFrame_Update,
            getNumEntries = getNumFactions,
            getElement = buildReputationElement,
            getElementIndex = getReputationIndex,
            getButtons = getReputationRows,
        }
    end

    -- Scroll frame is hidden (not enough factions to scroll), render rows directly
    local children = {}
    for i = 1, NUM_FACTIONS_DISPLAYED do
        local frame = _G["ReputationBar" .. i]
        if frame then
            local element = buildReputationElement(nil, frame)
            if element then
                tinsert(children, element)
            end
        end
    end

    if #children == 0 then
        return nil
    end

    return {
        "List",
        label = L["Reputation"],
        children = children,
    }
end)

gen:Element("character/ReputationDetail", function(props)
    local frame = ReputationDetailFrame
    if not frame or not frame:IsShown() then
        return nil
    end

    local children = {}

    -- Faction name and description as static text
    local factionName = ReputationDetailFactionName and ReputationDetailFactionName:GetText() or ""
    local description = ReputationDetailFactionDescription and ReputationDetailFactionDescription:GetText() or ""

    if description and description ~= "" then
        tinsert(children, {
            "Text",
            text = description,
        })
    end

    -- At War checkbox
    if ReputationDetailAtWarCheckbox and ReputationDetailAtWarCheckbox:IsShown() then
        tinsert(children, {
            "ProxyCheckButton",
            frame = ReputationDetailAtWarCheckbox,
            label = L["At War"],
        })
    end

    -- Move to Inactive checkbox
    if ReputationDetailInactiveCheckbox and ReputationDetailInactiveCheckbox:IsShown() then
        tinsert(children, {
            "ProxyCheckButton",
            frame = ReputationDetailInactiveCheckbox,
            label = MOVE_TO_INACTIVE or "Move to Inactive",
        })
    end

    -- Show on Main Screen checkbox (watch bar)
    if ReputationDetailMainScreenCheckbox and ReputationDetailMainScreenCheckbox:IsShown() then
        tinsert(children, {
            "ProxyCheckButton",
            frame = ReputationDetailMainScreenCheckbox,
            label = L["Watched"],
        })
    end

    -- Close button
    if ReputationDetailCloseButton then
        tinsert(children, {
            "ProxyButton",
            frame = ReputationDetailCloseButton,
            label = CLOSE or "Close",
        })
    end

    return {
        "List",
        label = factionName,
        children = children,
    }
end)
