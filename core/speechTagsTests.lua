local testRunner = WowVision.testing.testRunner
local speechTags = WowVision.speechTags

-- A speech module stand-in: a queue that takes the tag in like the real ones.
local function newModule()
    local module = { queue = {} }
    speechTags.install(module)
    function module:speak(text)
        tinsert(self.queue, { text = text, tag = self.queueTag })
    end
    return module
end

local function texts(queue)
    local out = {}
    for _, item in ipairs(queue) do
        tinsert(out, item.text)
    end
    return table.concat(out, ",")
end

testRunner:addSuite("SpeechTags", {
    ["lines queued inside withTag carry the tag, others none"] = function(t)
        local module = newModule()
        local tag = { owner = "water" }
        module:speak("before")
        module:withTag(tag, function()
            module:speak("swimming")
        end)
        module:speak("after")
        t:assertNil(module.queue[1].tag)
        t:assertEqual(module.queue[2].tag, tag)
        t:assertNil(module.queue[3].tag)
    end,

    ["dropQueued takes only the owner's lines"] = function(t)
        local module = newModule()
        local water, indoors = {}, {}
        module:withTag({ owner = water }, function()
            module:speak("swimming")
        end)
        module:speak("quest text")
        module:withTag({ owner = indoors }, function()
            module:speak("indoors")
        end)
        module:withTag({ owner = water }, function()
            module:speak("diving")
        end)
        module:dropQueued(water)
        t:assertEqual(texts(module.queue), "quest text,indoors")
    end,

    ["nested withTag restores the outer tag"] = function(t)
        local module = newModule()
        local outer, inner = { owner = 1 }, { owner = 2 }
        module:withTag(outer, function()
            module:withTag(inner, function()
                t:assertEqual(module:currentTag(), inner)
            end)
            t:assertEqual(module:currentTag(), outer)
        end)
        t:assertNil(module:currentTag())
    end,

    ["an error inside withTag is reported and the tag put back"] = function(t)
        local module = newModule()
        local reported = nil
        local oldHandler = geterrorhandler
        geterrorhandler = function()
            return function(err)
                reported = err
            end
        end
        local ok = module:withTag({ owner = 1 }, function()
            error("boom")
        end)
        geterrorhandler = oldHandler
        t:assertFalse(ok)
        t:assertTrue(reported ~= nil and tostring(reported):find("boom") ~= nil)
        t:assertNil(module:currentTag())
    end,

    ["a module without a queue drops nothing and does not fail"] = function(t)
        local module = {}
        speechTags.install(module)
        module:dropQueued({})
        local ran = false
        t:assertTrue(module:withTag({ owner = 1 }, function()
            ran = true
        end))
        t:assertTrue(ran)
    end,
})
