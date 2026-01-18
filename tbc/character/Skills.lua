local char = WowVision.tbc.character
local gen = char.gen
local L = char.L

local NUM_SKILLS_DISPLAYED = 12

-- Build a single element for a skill row
-- The frame passed in is SkillRankFrame[i], use its ID to find related frames
local function buildSkillElement(self, frame)
    local i = frame:GetID()
    local skillBar = frame
    local headerLabel = _G["SkillTypeLabel" .. i]

    -- Check if this is a header row
    if headerLabel and headerLabel:IsShown() then
        local name = headerLabel:GetText() or ""
        if name == "" then
            return nil
        end

        local headerState = headerLabel.isExpanded and "expanded" or "collapsed"

        return {
            "ProxyButton",
            frame = headerLabel,
            label = name,
            header = headerState,
        }
    end

    -- Check if this is a skill row
    if skillBar and skillBar:IsShown() then
        local nameText = _G["SkillRankFrame" .. i .. "SkillName"]
        local rankText = _G["SkillRankFrame" .. i .. "SkillRank"]

        local name = nameText and nameText:GetText() or ""
        if name == "" then
            return nil
        end

        local rank = rankText and rankText:GetText() or ""
        local label = name
        if rank and rank ~= "" then
            label = label .. " " .. rank
        end

        -- Mark as selected if this skill is currently selected
        local skillIndex = skillBar.skillIndex
        local isSelected = skillIndex and skillIndex == GetSelectedSkill()

        -- The clickable frame is SkillRankFrame[i]Border (a child Button)
        local borderButton = _G["SkillRankFrame" .. i .. "Border"]

        return {
            "ProxyButton",
            frame = borderButton,
            label = label,
            selected = isSelected,
        }
    end

    return nil
end

local function getNumEntries()
    return GetNumSkillLines()
end

local function getSkillIndex(self, frame)
    local offset = FauxScrollFrame_GetOffset(SkillListScrollFrame) or 0
    return frame:GetID() + offset
end

-- Return the actual SkillRankFrame elements
local function getSkillRows()
    local rows = {}
    for i = 1, NUM_SKILLS_DISPLAYED do
        local frame = _G["SkillRankFrame" .. i]
        if frame then
            tinsert(rows, frame)
        end
    end
    return rows
end

gen:Element("character/Skills", function(props)
    local children = {}

    -- Add collapse all button
    if SkillFrameCollapseAllButton and SkillFrameCollapseAllButton:IsShown() then
        local collapseLabel = SkillFrameCollapseAllButton.isExpanded and L["Collapse All"] or L["Expand All"]
        tinsert(children, {
            "ProxyButton",
            frame = SkillFrameCollapseAllButton,
            label = collapseLabel,
        })
    end

    -- If scroll frame is shown, use ProxyFauxScrollFrame
    if SkillListScrollFrame and SkillListScrollFrame:IsShown() then
        tinsert(children, {
            "ProxyFauxScrollFrame",
            frame = SkillListScrollFrame,
            buttonHeight = SKILLFRAME_SKILL_HEIGHT,
            updateFunction = SkillFrame_UpdateSkills,
            getNumEntries = getNumEntries,
            getElement = buildSkillElement,
            getElementIndex = getSkillIndex,
            getButtons = getSkillRows,
        })
    else
        -- Scroll frame is hidden (not enough skills to scroll), render rows directly
        for i = 1, NUM_SKILLS_DISPLAYED do
            local frame = _G["SkillRankFrame" .. i]
            if frame then
                local element = buildSkillElement(nil, frame)
                if element then
                    tinsert(children, element)
                end
            end
        end
    end

    if #children == 0 then
        return nil
    end

    return {
        "List",
        label = L["Skills"],
        children = children,
    }
end)

gen:Element("character/SkillsDetail", function(props)
    local selectedSkill = GetSelectedSkill()
    if not selectedSkill or selectedSkill == 0 then
        return nil
    end

    local skillName, header, isExpanded, skillRank, numTempPoints, skillModifier,
          skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType,
          skillDescription = GetSkillLineInfo(selectedSkill)

    -- Don't show detail for headers or empty
    if not skillName or skillName == "" or header then
        return nil
    end

    local children = {}

    -- Skill rank info
    local rankLabel = skillName
    if skillMaxRank and skillMaxRank > 1 then
        local displayRank = skillRank + (numTempPoints or 0)
        rankLabel = skillName .. " " .. displayRank .. "/" .. skillMaxRank
        if skillModifier and skillModifier ~= 0 then
            local sign = skillModifier > 0 and "+" or ""
            rankLabel = skillName .. " " .. displayRank .. " (" .. sign .. skillModifier .. ")/" .. skillMaxRank
        end
    end

    tinsert(children, {
        "Text",
        text = rankLabel,
    })

    -- Description
    if skillDescription and skillDescription ~= "" then
        tinsert(children, {
            "Text",
            text = skillDescription,
        })
    end

    -- Unlearn button (for abandonable skills like professions)
    local unlearnButton = SkillDetailStatusBarUnlearnButton
    if isAbandonable and unlearnButton and unlearnButton:IsShown() then
        tinsert(children, {
            "ProxyButton",
            frame = unlearnButton,
            label = L["Unlearn"],
        })
    end

    return {
        "List",
        label = L["Skill Details"],
        children = children,
    }
end)
