-- Keeping the game's speech audible, for every game version.
--
-- The game plays text-to-speech on its Dialog sound channel. With that
-- channel switched off (the Sound_EnableDialog CVar at 0) SpeakText makes no
-- sound, and the line is dropped, not held: a line spoken with the channel
-- off was never heard, the next one after it came back was (user test in
-- WoW: Forever, 2026-11-16).
--
-- Spoken (the voice-over addon: Spoken Quests, Places and the rest) switches
-- the channel off to silence the NPCs' own voices under its clips, its
-- Silence NPC Voices setting, on by default. It does so for as long as one of
-- its clips plays, and in the frame a gossip or quest window opens for an NPC
-- it has any voice for, before it knows whether it has this very line. So
-- WowVision said nothing while a clip played, and the gossip window did not
-- read itself even where Spoken had no line for it.
--
-- Before a line goes to the engine, Spoken's mute is lifted through its
-- public API, Spoken:MuteChannel("Dialog", false). That call does nothing
-- unless Spoken itself holds the channel off: a channel the player switched
-- off stays off, a fade of the Dialog volume Spoken had under way is undone
-- by Spoken itself, and its own record of the mute stays right (it mutes
-- again with its next clip). The price: after WowVision spoke, an NPC's own
-- voice may be heard under the rest of a Spoken clip.
--
-- The CVar is not asked first: Spoken fades the Dialog volume down for half
-- a second before it switches the channel off, and a line that starts in
-- that half second would be cut with the CVar still reading on.
local channel = {}

-- Lift the mute this Spoken API table holds on the Dialog channel. False
-- when there is no such API, or the call failed.
function channel.lift(spoken)
    if type(spoken) ~= "table" or type(spoken.MuteChannel) ~= "function" then
        return false
    end
    return (pcall(spoken.MuteChannel, spoken, "Dialog", false))
end

-- A line is about to be handed to the engine.
function channel.ready()
    channel.lift(_G.Spoken)
end

WowVision.speechChannel = channel
