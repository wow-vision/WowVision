local char = WowVision.tbc.character
local L = char.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC skills tab: a Faux list of skill lines with pool-relative row
-- ids. Headers click their SkillTypeLabel button; skill rows click the
-- row's Border button; labels are data-first from GetSkillLineInfo. The
-- selected skill's detail follows, with unlearn for abandonable skills.

local NUM_SKILLS_DISPLAYED = 12

local function skillButtons()
    local rows = {}
    for i = 1, NUM_SKILLS_DISPLAYED do
        local frame = _G["SkillRankFrame" .. i]
        if frame ~= nil then
            tinsert(rows, frame)
        end
    end
    return rows
end

local function skillIndexOf(button)
    local offset = FauxScrollFrame_GetOffset(SkillListScrollFrame) or 0
    return button:GetID() + offset
end

local function skillLabel(index)
    local skillName, isHeader, _, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(index)
    if skillName == nil or skillName == "" then
        return nil
    end
    if isHeader then
        return skillName
    end
    local label = skillName
    if skillMaxRank ~= nil and skillMaxRank > 1 then
        local displayRank = (skillRank or 0) + (numTempPoints or 0)
        label = label .. " " .. displayRank
        if skillModifier ~= nil and skillModifier ~= 0 then
            local sign = skillModifier > 0 and "+" or ""
            label = label .. " (" .. sign .. skillModifier .. ")"
        end
        label = label .. "/" .. skillMaxRank
    end
    return label
end

local function emitSkill(builder, index, helpers)
    local skillName, isHeader, isExpanded = GetSkillLineInfo(index)
    if skillName == nil or skillName == "" then
        return
    end

    local announcements = {
        {
            text = function()
                return skillLabel(index)
            end,
            kind = kinds.label,
        },
    }

    if isHeader then
        tinsert(announcements, {
            text = function()
                local _, _, expanded = GetSkillLineInfo(index)
                return expanded and L["Expanded"] or L["Collapsed"]
            end,
            kind = kinds.value,
        })
    else
        tinsert(announcements, {
            text = function()
                if index == GetSelectedSkill() then
                    return L["selected"]
                end
                return nil
            end,
            kind = kinds.selected,
        })
    end

    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            {
                binding = "leftClick",
                type = "Click",
                emulatedKey = "LeftButton",
                target = function()
                    local row = helpers.target()
                    if row == nil then
                        return nil
                    end
                    local slot = row:GetID()
                    if isHeader then
                        return _G["SkillTypeLabel" .. slot]
                    end
                    return _G["SkillRankFrame" .. slot .. "Border"]
                end,
            },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
    })
end

local function skillEntryId(index)
    local skillName, isHeader = GetSkillLineInfo(index)
    if skillName ~= nil and skillName ~= "" then
        return ControlId.structural((isHeader and "skillHeader:" or "skill:") .. skillName)
    end
    return ControlId.structural("skill:" .. index)
end

function char.renderSkills(builder)
    if SkillFrameCollapseAllButton ~= nil and SkillFrameCollapseAllButton:IsShown() then
        builder:beginStop("collapseAll")
        builder:addItem(
            ControlId.forObject(SkillFrameCollapseAllButton),
            nodes.proxyButton({
                target = SkillFrameCollapseAllButton,
                label = function()
                    return SkillFrameCollapseAllButton.isExpanded and L["Collapse All"] or L["Expand All"]
                end,
            })
        )
    end

    builder:beginStop("skills")
    nodes.hybridScrollList(builder, {
        scrollFrame = SkillListScrollFrame,
        key = "skills",
        label = L["Skills"],
        count = GetNumSkillLines,
        rowHeight = SKILLFRAME_SKILL_HEIGHT,
        buttons = skillButtons,
        indexOf = skillIndexOf,
        id = skillEntryId,
        emit = emitSkill,
    })

    local selectedSkill = GetSelectedSkill()
    if selectedSkill ~= nil and selectedSkill ~= 0 then
        local skillName, header, _, _, _, _, _, isAbandonable, _, _, _, _, skillDescription =
            GetSkillLineInfo(selectedSkill)
        if skillName ~= nil and skillName ~= "" and not header then
            builder:beginStop("skillDetail")
            builder:pushContext("skillDetail", L["Skill Details"])
            builder:addItem(
                ControlId.structural("skillRank"),
                nodes.text({
                    label = function()
                        return skillLabel(GetSelectedSkill())
                    end,
                })
            )
            builder:addItem(
                ControlId.structural("skillDescription"),
                nodes.text({
                    label = function()
                        local selected = GetSelectedSkill()
                        if selected == nil or selected == 0 then
                            return nil
                        end
                        local _, _, _, _, _, _, _, _, _, _, _, _, description = GetSkillLineInfo(selected)
                        if description ~= nil and description ~= "" then
                            return description
                        end
                        return nil
                    end,
                })
            )
            local unlearnButton = SkillDetailStatusBarUnlearnButton
            if isAbandonable and unlearnButton ~= nil and unlearnButton:IsShown() then
                builder:addItem(
                    ControlId.forObject(unlearnButton),
                    nodes.proxyButton({ target = unlearnButton, label = L["Unlearn"] })
                )
            end
            builder:popContext()
        end
    end
end
