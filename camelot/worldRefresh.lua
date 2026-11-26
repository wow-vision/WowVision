-- World refresh (WoW: Forever): the game is about to move the player to another copy of the world (a shard
-- transfer), counts the time down, and lets the player go at once.
--
-- The game used to ask with a popup, which the popups window read. Since the build of 2026-11 it shows a toast
-- instead (Blizzard_SocialToast: ShardTransferImminentFrame, an alert frame over the chat with a countdown), and the
-- popup only opens when that toast is clicked. A toast is no window and nothing read it, so the refresh came
-- without a word (reported 2026-11-24).
--
-- What this does:
--   * says the countdown when it starts, with where to find the way to act, again at one minute, and when the time
--     is up (the game then says the refresh can come at any time);
--   * puts World Refresh first in the WowVision menu for as long as the toast is shown. Enter there is a real click
--     on the toast, so the game opens its own popup (Refresh Now, Okay), which the popups window reads as before.
--
-- The toast is clicked, never the popup shown from here: a popup an addon shows is tainted (windows/pending.lua
-- has what that costs), and its Refresh Now button would run the game's transfer call as the addon.
--
-- The texts are the game's own where it has them (the same strings the toast formats), so they come in the game's
-- language.
local refresh = {}
WowVision.worldRefresh = refresh

local L = WowVision:getLocale()

-- A reminder when this many seconds are left, if the countdown started with more than REMIND_MARGIN beyond it.
refresh.REMIND_AT = 60
refresh.REMIND_MARGIN = 30

local function gameString(name)
    local value = rawget(_G, name)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return nil
end

local function plain(text)
    local nodes = WowVision.graph ~= nil and WowVision.graph.nodes or nil
    if nodes ~= nil and nodes.plainText ~= nil then
        return nodes.plainText(text)
    end
    return text
end

-- What is left, as the toast words it in its first seconds: the game's countdown line with the number in seconds
-- below a minute, else in minutes rounded up; the game's "at any time" line once the time is up. remaining nil
-- (the game would not say) is the plain statement without a time. strings: the game's texts, for the tests.
function refresh.text(remaining, strings)
    strings = strings
        or {
            anytime = gameString("SHARD_TRANSFER_ANYTIME"),
            countdown = gameString("SHARD_TRANSFER_COUNTDOWN_MESSAGE"),
            seconds = gameString("SECONDS"),
            minutes = gameString("MINUTES"),
        }
    if remaining == nil then
        return L["The world is about to refresh"]
    end
    if remaining <= 0 then
        if strings.anytime ~= nil then
            return plain(strings.anytime)
        end
        return L["The world can refresh at any time"]
    end
    local count, unit, fallback
    if remaining < 60 then
        count, unit, fallback = math.ceil(remaining), strings.seconds, L["The world refreshes in %d seconds"]
    else
        count, unit, fallback = math.ceil(remaining / 60), strings.minutes, L["The world refreshes in %d minutes"]
    end
    if strings.countdown ~= nil and unit ~= nil then
        local ok, text = pcall(string.format, strings.countdown, count, unit)
        if ok and text ~= nil and text ~= "" then
            return plain(text)
        end
    end
    return string.format(fallback, count)
end

-- What is said when the countdown starts: the time, and where the way to act is.
function refresh.announcement(remaining, strings)
    local text = refresh.text(remaining, strings)
    -- the game's lines end in a full stop, WowVision's own do not
    local gap = text:find("[%.!?]$") ~= nil and " " or ". "
    return text .. gap .. L["To refresh now, open the WowVision menu and choose World Refresh"]
end

-- When to speak again after the start: at REMIND_AT seconds left (only when that is a while off), and when the
-- time is up. Each step is { delay = seconds from now, ended = true for the one after the end }. Nothing without
-- a known time.
function refresh.plan(remaining)
    local steps = {}
    if remaining == nil or remaining <= 0 then
        return steps
    end
    if remaining > refresh.REMIND_AT + refresh.REMIND_MARGIN then
        tinsert(steps, { delay = remaining - refresh.REMIND_AT, ended = false })
    end
    tinsert(steps, { delay = remaining + 1, ended = true })
    return steps
end

-- ---------------------------------------------------------------- the game

-- Everything below needs the toast. Without it (a build that asks some other way) there is nothing to read here.
local frame = rawget(_G, "ShardTransferImminentFrame")
if frame == nil or CreateFrame == nil then
    return
end

local graph = WowVision.graph
local nodes = graph.nodes

-- Seconds until the refresh; nil when the game will not say (no function, an error, a value kept secret).
local function remaining()
    local get = rawget(_G, "GetEvictionTimeRemaining")
    if get == nil then
        return nil
    end
    local ok, seconds = pcall(get)
    if not ok or seconds == nil or WowVision.secrets.isSecret(seconds) or type(seconds) ~= "number" then
        return nil
    end
    return seconds
end

-- One countdown: active from its start to its end (cancelled, or the refresh came). The number tells a countdown's
-- reminders from those of an earlier one.
local active = false
local countdown = 0

local function start()
    active = true
    countdown = countdown + 1
    local mine = countdown
    local left = remaining()
    WowVision:notify(refresh.announcement(left))
    for _, step in ipairs(refresh.plan(left)) do
        C_Timer.After(step.delay, function()
            if active and mine == countdown then
                -- after the end the game's clock may still say a fraction of a second: it is up
                WowVision:notify(refresh.text(step.ended and 0 or remaining()))
            end
        end)
    end
end

local function stop()
    active = false
    countdown = countdown + 1
end

local events = CreateFrame("Frame")
events:RegisterEvent("SHARD_TRANSFER_IMMINENT")
events:RegisterEvent("SHARD_TRANSFER_CANCELLED")
events:RegisterEvent("SHARD_TRANSFER")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event)
    if event == "SHARD_TRANSFER_IMMINENT" then
        start()
    elseif event == "SHARD_TRANSFER_CANCELLED" then
        local was = active
        stop()
        if was then
            WowVision:notify(L["World refresh cancelled"])
        end
    elseif event == "SHARD_TRANSFER" then
        stop()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- a countdown that was already running at login or after a loading screen: the game shows its toast at
        -- once, without the event. Said after the login lines.
        C_Timer.After(6, function()
            local left = remaining()
            if not active and left ~= nil and left > 0 then
                start()
            end
        end)
    end
end)

-- First in the WowVision menu while the toast is shown (after Pending). Enter is a real click on the toast: the
-- game opens its popup. hover = false: the toast's own OnEnter writes to the alert system as the addon.
graph.settings.registerRootEntry(function(builder)
    if not frame:IsShown() then
        return
    end
    builder:addItem(
        graph.ControlId.structural("worldRefresh"),
        nodes.proxyButton({
            target = frame,
            hover = false,
            label = function()
                return nodes.joinLabel(L["World Refresh"], refresh.text(remaining()))
            end,
        })
    )
end)
