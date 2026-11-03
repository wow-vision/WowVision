local module = WowVision.base.targeting

-- A probe for crowd control detection (/wv cctest [unit], default target):
-- whether a unit has a crowd control aura, by filling a tooltip of our own
-- with its first aura under the game's CROWD_CONTROL filter. A tooltip with
-- lines = controlled. Under Retail's restriction the line count stays plain
-- (see AuraBuffer.lua). The fill may take frames to arrive, so the count is
-- watched for 30 frames and every change is noted with its frame. The index
-- read with the same filter is shown beside it (refused under restriction).
local FILTER = "HARMFUL|CROWD_CONTROL"
local FRAMES = 30

local tooltip = nil
local driver = nil

-- "/wv cctest watch": on every target change, the crowd control result on
-- each of the next WATCH_FRAMES frames, and the frame of the first UNIT_AURA
-- for the target after the change (with whether it was a full update), in
-- one line. Measures when a new target's auras are in place, for the
-- crowd control alert's settle window (crowdControl.lua).
local WATCH_FRAMES = 10
local watching = false
local watchFrame = nil

local function startWatch()
    if watchFrame == nil then
        watchFrame = CreateFrame("Frame")
        if tooltip == nil then
            tooltip = CreateFrame("GameTooltip", "WowVisionCCTestTooltip", UIParent, "GameTooltipTemplate")
            driver = CreateFrame("Frame")
        end
    end
    local frames, results, auraFrame, fullUpdate = -1, {}, nil, nil
    local function sample()
        tooltip:ClearLines()
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        local ok = pcall(tooltip.SetUnitAura, tooltip, "target", 1, FILTER)
        return ok and tooltip:NumLines() > 0
    end
    watchFrame:SetScript("OnEvent", function(self, event, unit, info)
        if event == "PLAYER_TARGET_CHANGED" then
            frames, results, auraFrame, fullUpdate = 0, { sample() and "yes" or "no" }, nil, nil
            self:SetScript("OnUpdate", function(updater)
                frames = frames + 1
                tinsert(results, sample() and "yes" or "no")
                if frames >= WATCH_FRAMES then
                    updater:SetScript("OnUpdate", nil)
                    local aura = "no aura event"
                    if auraFrame ~= nil then
                        aura = "aura event at frame " .. auraFrame .. (fullUpdate and ", full update" or "")
                    end
                    print("CC watch. Controlled per frame from 0: " .. table.concat(results, " ") .. ". " .. aura)
                end
            end)
        elseif event == "UNIT_AURA" and frames >= 0 and auraFrame == nil then
            auraFrame = frames
            local okFull, full = pcall(function()
                return type(info) == "table" and info.isFullUpdate == true
            end)
            fullUpdate = okFull and full
        end
    end)
    watchFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    watchFrame:RegisterUnitEvent("UNIT_AURA", "target")
end

local function stopWatch()
    if watchFrame ~= nil then
        watchFrame:UnregisterAllEvents()
        watchFrame:SetScript("OnUpdate", nil)
        watchFrame:SetScript("OnEvent", nil)
    end
end

module:registerCommand({
    name = "cctest",
    description = "Test crowd control detection on a unit (default target), or \"watch\" to measure each target change",
    func = function(args)
        if args == "watch" then
            watching = not watching
            if watching then
                startWatch()
            else
                stopWatch()
            end
            print("CC watch " .. (watching and "on" or "off"))
            return
        end
        local unit = (args ~= nil and args ~= "") and args or "target"
        if not UnitExists(unit) then
            print("CC test: no " .. unit)
            return
        end
        if tooltip == nil then
            tooltip = CreateFrame("GameTooltip", "WowVisionCCTestTooltip", UIParent, "GameTooltipTemplate")
            driver = CreateFrame("Frame")
        end
        tooltip:ClearLines()
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        local filled = pcall(tooltip.SetUnitAura, tooltip, unit, 1, FILTER)

        local readOk, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, 1, FILTER)
        local read = "refused"
        if readOk then
            read = aura ~= nil and "found" or "none"
        end

        local last = tooltip:NumLines()
        local changes = { "frame 0 lines " .. last }
        local frames = 0
        driver:SetScript("OnUpdate", function(self)
            frames = frames + 1
            local lines = tooltip:NumLines()
            if lines ~= last then
                tinsert(changes, "frame " .. frames .. " lines " .. lines)
                last = lines
            end
            if frames >= FRAMES then
                self:SetScript("OnUpdate", nil)
                print(
                    "CC test "
                        .. unit
                        .. ". Fill "
                        .. (filled and "allowed" or "refused")
                        .. ". Index read "
                        .. read
                        .. ". "
                        .. table.concat(changes, ", ")
                        .. ". Controlled "
                        .. (last > 0 and "yes" or "no")
                )
            end
        end)
    end,
})
