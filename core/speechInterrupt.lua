-- Cutting a screen reader bridge voice, for every game version.
--
-- A voice that hands the text to a screen reader (SAPI2SR, NVDA's bridge)
-- ends each line at once, while the screen reader goes on reading it, so
-- StopSpeakingText has nothing left to stop there and NVDA reads the old
-- line to its end. Only a key press made NVDA stop by itself; controller
-- presses never did (user test 2026-10-23). What does reach the bridge is
-- the next line itself: after a stop, the next line handed over carries
-- MARK, and the bridge as patched for Sku (its installer 5.1, "Patch C")
-- stops NVDA's speech when it sees it, then reads the line. Real SAPI
-- voices skip the bookmark silently, and so does an unpatched bridge
-- (measured in Sku, 2026-09-18; confirmed by the user in WoW: Forever,
-- 2026-10-23).
--
-- Any stop counts, whoever calls it (ours, Blizzard's, another addon's):
-- the game's StopSpeakingText is watched. Each version's speech module
-- passes the text it hands to the engine through handOver; lines without
-- a stop in front queue as before.
local interrupt = {}

interrupt.MARK = '<bookmark mark="skuint"/>'

-- The Mac client speaks through the system's speech, which knows no SAPI
-- markup and reads the bookmark aloud ("bookmark" after every line that
-- follows a stop). There is no screen reader bridge there to cut, so the
-- mark is never added. Read once: the client does not change.
interrupt.enabled = not (IsMacClient ~= nil and IsMacClient() == true)

local pending = false

function interrupt.noteStop()
    pending = true
end

-- The text as handed to the engine: with MARK when a stop came before it.
-- Secret text takes the concatenation like any other.
function interrupt.handOver(text)
    if pending and interrupt.enabled then
        pending = false
        return text .. interrupt.MARK
    end
    return text
end

function interrupt._reset()
    pending = false
    interrupt.enabled = true
end

if C_VoiceChat ~= nil and C_VoiceChat.StopSpeakingText ~= nil and hooksecurefunc ~= nil then
    hooksecurefunc(C_VoiceChat, "StopSpeakingText", interrupt.noteStop)
end

WowVision.speechInterrupt = interrupt
