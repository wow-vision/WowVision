local testRunner = WowVision.testing.testRunner
local graph = WowVision.graph

-- Labels the game keeps secret (hidden names in a dungeon on WoW: Forever and
-- Retail). Here a secret is a plain string that issecretvalue claims; the
-- game's secret would throw on the comparison or gsub the code must avoid.
local function withSecretStrings(fn)
    return function(t)
        local saved = issecretvalue
        issecretvalue = function(value)
            return type(value) == "string" and value:sub(1, 7) == "secret:"
        end
        local ok, err = pcall(fn, t)
        issecretvalue = saved
        if not ok then
            error(err, 0)
        end
    end
end

testRunner:addSuite("SecretLabels", {
    ["type-ahead finds nothing in a secret label"] = withSecretStrings(function(t)
        t:assertEqual(graph.typeAhead.matchText("secret:Hogger"), "")
        t:assertEqual(graph.typeAhead.exactText("secret:Hogger"), "")
        t:assertEqual(graph.typeAhead.matchText("Hogger"), "hogger")
    end),

    ["the live watch: two secret reads in a row are no change"] = withSecretStrings(function(t)
        local changed = graph.GraphHost._liveChanged
        t:assertFalse(changed("secret:Hogger", "secret:Hogger"))
        t:assertFalse(changed("secret:Hogger", "secret:Defias"))
    end),

    ["the live watch: a text turning secret or plain is a change"] = withSecretStrings(function(t)
        local changed = graph.GraphHost._liveChanged
        t:assertTrue(changed("Unknown", "secret:Hogger"))
        t:assertTrue(changed("secret:Hogger", "Hogger"))
        t:assertTrue(changed(false, "secret:Hogger"))
    end),

    ["the live watch: plain texts compare as before"] = withSecretStrings(function(t)
        local changed = graph.GraphHost._liveChanged
        t:assertFalse(changed("Hogger", "Hogger"))
        t:assertTrue(changed("Hogger", "Defias"))
        t:assertTrue(changed(false, "Hogger"))
    end),
})
