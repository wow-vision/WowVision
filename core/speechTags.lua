-- Tagged lines in WowVision's speech queue, one copy for every client's speech
-- module (tbc/, mists/, retail/, vanilla/ speech.lua call speechTags.install).
--
-- Speech queued while `fn` runs in module:withTag(tag, fn) carries `tag` (a
-- table with an `owner`), so its caller finds its lines again and drops those
-- still waiting (module:dropQueued). This is for speech that goes through
-- C_VoiceChat.SpeakText from an alert's output: the environmental alerts drop
-- an indoors, flying or water line that is out of date before it is heard.
--
-- The queue reads module.queueTag when it takes a line in. A client without a
-- queue of its own (Vanilla speaks through the game's queue) and a client with
-- the Speech Queue setting off keep no lines here: tagging changes nothing and
-- there is nothing to drop.

local speechTags = {}
WowVision.speechTags = speechTags

function speechTags.install(module)
    module.queueTag = nil

    -- An error inside `fn` goes to the game's error handler with its own stack
    -- (utils.guardedCall; an error re-raised here would show this function's
    -- stack instead), and the tag is put back either way. Returns false when
    -- `fn` failed.
    function module:withTag(tag, fn)
        local old = self.queueTag
        self.queueTag = tag
        local ok = WowVision.utils.guardedCall(self, fn)
        self.queueTag = old
        return ok
    end

    -- The tag lines queued now get, nil outside withTag. For a caller that
    -- speaks later (a timer) and passes the tag on.
    function module:currentTag()
        return self.queueTag
    end

    -- Drops the waiting lines tagged by `owner`; never the one playing (the
    -- queue no longer holds it).
    function module:dropQueued(owner)
        local queue = self.queue
        if queue == nil then
            return
        end
        for i = #queue, 1, -1 do
            local tag = queue[i].tag
            if tag ~= nil and tag.owner == owner then
                tremove(queue, i)
            end
        end
    end
end
