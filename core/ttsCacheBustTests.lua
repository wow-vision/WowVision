local testRunner = WowVision.testing.testRunner
local cacheBust = WowVision.ttsCacheBust

local NBSP = "\194\160"

-- Run a test against a fresh in-memory store, restoring the real source after.
local function isolated(body)
    return function(t)
        local source = cacheBust.storeSource
        local store = { seen = {}, keys = 0, seed = 0 }
        cacheBust.storeSource = function()
            return store
        end
        cacheBust._reset()
        local ok, err = pcall(body, t, store)
        cacheBust.storeSource = source
        cacheBust._reset()
        if not ok then
            error(err, 0)
        end
    end
end

local function strip(text)
    return (string.gsub(text, NBSP, ""))
end

testRunner:addSuite("TTS cache bust", {
    ["every repeat of a text is unique for a full cycle"] = isolated(function(t)
        local seen = {}
        for i = 1, cacheBust.MAX do
            local spoken = cacheBust.bust("Close")
            t:assertNil(seen[spoken], "repeat " .. i .. " collided")
            seen[spoken] = true
        end
    end),

    ["the spoken words are unchanged"] = isolated(function(t)
        for _ = 1, 100 do
            t:assertEqual(strip(cacheBust.bust("Quest log, 3 of 12")), "Quest log, 3 of 12")
        end
    end),

    ["texts count independently"] = isolated(function(t, store)
        cacheBust.bust("a")
        cacheBust.bust("a")
        cacheBust.bust("b")
        t:assertEqual(store.keys, 2)
        -- "a": seeded at 1, repeated to 2. "b": seeded at the next seed, 2.
        t:assertEqual(store.seen["a"], 2)
        t:assertEqual(store.seen["b"], 2)
    end),

    ["a new text starts at the rotating seed, not at 1"] = isolated(function(t, store)
        store.seed = 40
        cacheBust.bust("fresh")
        t:assertEqual(store.seen["fresh"], 41)
    end),

    ["a wipe keeps the seed rotating"] = isolated(function(t, store)
        store.seed = 100
        for i = 1, cacheBust.KEYS_MAX do
            cacheBust.bust("text " .. i)
        end
        local seed = store.seed
        cacheBust.bust("after wipe")
        t:assertEqual(store.keys, 1)
        t:assertEqual(store.seen["after wipe"], (seed % cacheBust.MAX) + 1)
        t:assertNotEqual(store.seen["after wipe"], 1)
    end),

    ["long texts are keyed by a short hash"] = isolated(function(t, store)
        local long = string.rep("The quest text goes on. ", 40)
        local first = cacheBust.bust(long)
        local second = cacheBust.bust(long)
        t:assertNotEqual(first, second)
        t:assertEqual(store.keys, 1)
        for key in pairs(store.seen) do
            t:assertTrue(#key < 30, key)
        end
        t:assertNotEqual(cacheBust.textKey(long), cacheBust.textKey(long .. "x"))
    end),

    ["counts carry into a store bound later"] = function(t)
        local source = cacheBust.storeSource
        local bound = nil
        cacheBust.storeSource = function()
            return bound
        end
        cacheBust._reset()
        cacheBust.bust("early")
        cacheBust.bust("early")
        bound = { seen = {}, keys = 0, seed = 0 }
        cacheBust.bust("late")
        cacheBust.storeSource = source
        cacheBust._reset()
        -- "early" seeded at 1 and repeated to 2 before the store existed;
        -- "late" took the next seed, 2, after adoption.
        t:assertEqual(bound.seen["early"], 2)
        t:assertEqual(bound.seen["late"], 2)
        t:assertEqual(bound.keys, 2)
        t:assertEqual(bound.seed, 2)
    end,

    ["empty and non-string text pass through"] = isolated(function(t, store)
        t:assertEqual(cacheBust.bust(""), "")
        t:assertNil(cacheBust.bust(nil))
        t:assertEqual(store.keys, 0)
    end),

    ["secret values pass through untouched"] = isolated(function(t, store)
        local previous = issecretvalue
        issecretvalue = function()
            return true
        end
        local ok, result = pcall(cacheBust.bust, "secret")
        issecretvalue = previous
        t:assertTrue(ok, result)
        t:assertEqual(result, "secret")
        t:assertEqual(store.keys, 0)
    end),

    ["foreign text is busted unless it carries a buster"] = isolated(function(t)
        t:assertNotEqual(cacheBust.bustForeign("chat line"), "chat line")
        local ours = cacheBust.bust("menu")
        t:assertEqual(cacheBust.bustForeign(ours), ours)
        local sku = NBSP .. "menu" .. NBSP .. NBSP .. '<bookmark mark="skc2"/><bookmark mark="skuint"/>'
        t:assertEqual(cacheBust.bustForeign(sku), sku)
    end),
})
