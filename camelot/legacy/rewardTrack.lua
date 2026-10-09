local module = WowVision.base.windows.legacy
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The reward track page: the Legacy renown (a renown faction) with its
-- level, the progress to the next level, and every level of the track with
-- its reward. The mouse track shows a few cards at a time and scrolls them
-- sideways; every card is listed here, so its arrows are left out, and a
-- card's click only centers it. A level's tooltip is the
-- card's own (the reward and what it does).

local function rewardNames(levelInfo)
    local names = {}
    for _, reward in ipairs(levelInfo.rewardInfo or {}) do
        local _, name = RenownRewardUtil.GetRenownRewardInfo(reward, nop)
        if name ~= nil then
            tinsert(names, name)
        end
    end
    return table.concat(names, ", ")
end

-- The renown level and the progress into the next one, read from the
-- faction (the bar under the cards is scaled to the cards on screen).
local function renderSummary(builder, page)
    local faction = page.majorFactionData
    builder:beginStop("summary")
    builder:addItem(
        ControlId.structural("points"),
        nodes.text({
            label = function()
                return nodes.joinLabel(nodes.shownText(page.PointsLabel), nodes.shownText(page.Points))
            end,
        })
    )
    if faction ~= nil and not C_MajorFactions.HasMaximumRenown(faction.factionID) then
        builder:addItem(
            ControlId.structural("progress"),
            nodes.text({
                label = function()
                    local data = C_MajorFactions.GetMajorFactionData(faction.factionID)
                    if data == nil then
                        return nil
                    end
                    return MAJOR_FACTION_RENOWN_CURRENT_PROGRESS:format(
                        data.renownReputationEarned,
                        data.renownLevelThreshold
                    )
                end,
            })
        )
    end
end

local function renderLevels(builder, page)
    local elements = page.LegacyRewardProgressFrame:GetElements()
    if elements == nil then
        return
    end
    builder:beginStop("levels")
    builder:pushContext("levels", L["Rewards"])
    for _, card in ipairs(elements) do
        local levelInfo = card.info
        if levelInfo ~= nil then
            local captured = card
            local level = levelInfo.level
            builder:addItem(ControlId.structural("level:" .. level), {
                controlType = graph.controlTypes.text,
                announcements = {
                    {
                        text = function()
                            local earned = level <= C_MajorFactions.GetCurrentRenownLevel(page.majorFactionData.factionID)
                            return nodes.joinLabel(
                                L["Level"] .. " " .. level,
                                rewardNames(levelInfo),
                                earned and L["Earned"]
                            )
                        end,
                        kind = kinds.label,
                    },
                },
                tooltipFrame = captured,
                tooltip = {
                    type = "Game",
                    mode = "immediate",
                    -- The reader owns the tooltip to the card, which is
                    -- what the card's refresh checks before filling it.
                    populate = function()
                        captured:RefreshTooltip()
                    end,
                },
            })
        end
    end
    builder:popContext()
end

function module.renderRewardTrack(builder, page)
    if page.majorFactionData == nil then
        return
    end
    renderSummary(builder, page)
    renderLevels(builder, page)
end
