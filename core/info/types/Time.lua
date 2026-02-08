local info = WowVision.info
local L = WowVision:getLocale()

local TimeField, parent = info:CreateFieldClass("Time", "Number")

function TimeField:setup(config)
    parent.setup(self, config)
    self.timeType = config.timeType or "duration" -- "duration" or "timestamp"
end

function TimeField:getInfo()
    local result = parent.getInfo(self)
    result.timeType = self.timeType
    return result
end

-- Format a duration in seconds to human-readable string
-- Omits zero components (e.g., "1 hour 5 seconds" skips minutes)
local function formatDuration(seconds)
    if seconds == nil then
        return nil
    end
    seconds = math.floor(seconds)
    if seconds < 0 then
        seconds = 0
    end

    local days = math.floor(seconds / 86400)
    seconds = seconds - days * 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds - hours * 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60

    local parts = {}
    if days > 0 then
        tinsert(parts, days .. " " .. (days == 1 and L["day"] or L["days"]))
    end
    if hours > 0 then
        tinsert(parts, hours .. " " .. (hours == 1 and L["hour"] or L["hours"]))
    end
    if minutes > 0 then
        tinsert(parts, minutes .. " " .. (minutes == 1 and L["minute"] or L["minutes"]))
    end
    if seconds > 0 or #parts == 0 then
        tinsert(parts, seconds .. " " .. (seconds == 1 and L["second"] or L["seconds"]))
    end

    return table.concat(parts, " ")
end

-- Format a Unix timestamp to human-readable date/time
local function formatTimestamp(timestamp)
    if timestamp == nil then
        return nil
    end
    return date("%B %d, %Y %I:%M %p", timestamp)
end

function TimeField:formatTime(value)
    if self.timeType == "timestamp" then
        return formatTimestamp(value)
    end
    return formatDuration(value)
end

function TimeField:getValueString(obj, value)
    if value == nil then
        return nil
    end
    return self:formatTime(value)
end

-- Used by template context builders to format raw values for display
function TimeField:formatForDisplay(value)
    if value == nil then
        return nil
    end
    return self:formatTime(value)
end
