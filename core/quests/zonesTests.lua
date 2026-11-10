local testRunner = WowVision.testing.testRunner

local function node(entry)
    return { key = "quest:" .. entry.questId, label = entry.title, distance = entry.distance }
end

local function distanceOf(n)
    return n.distance
end

local function labels(list)
    local out = {}
    for _, item in ipairs(list) do
        tinsert(out, item.label)
    end
    return table.concat(out, ", ")
end

testRunner:addSuite("QuestZones", {
    ["quests group under their zone, in quest log order"] = function(t)
        local zones = WowVision.quests.zoneGroups({
            { questId = 1, title = "A", zone = "Elwynn Forest" },
            { questId = 2, title = "B", zone = "Westfall" },
            { questId = 3, title = "C", zone = "Elwynn Forest" },
        }, node, distanceOf)
        t:assertEqual(labels(zones), "Elwynn Forest, Westfall")
        t:assertEqual(zones[1].key, "zone:Elwynn Forest")
        t:assertEqual(labels(zones[1].children), "A, C")
        t:assertEqual(zones[1].detail, "2 quests")
        t:assertEqual(labels(zones[2].children), "B")
    end,

    ["within a zone the nearest quest comes first, those without a place last"] = function(t)
        local zones = WowVision.quests.zoneGroups({
            { questId = 1, title = "Far", zone = "Z", distance = 300 },
            { questId = 2, title = "Nowhere", zone = "Z" },
            { questId = 3, title = "Near", zone = "Z", distance = 20 },
            { questId = 4, title = "Also nowhere", zone = "Z" },
            { questId = 5, title = "Middle", zone = "Z", distance = 100 },
        }, node, distanceOf)
        t:assertEqual(labels(zones[1].children), "Near, Middle, Far, Nowhere, Also nowhere")
    end,

    ["a quest without a zone goes under Unknown"] = function(t)
        local zones = WowVision.quests.zoneGroups({ { questId = 1, title = "A" } }, node, distanceOf)
        t:assertEqual(zones[1].label, "Unknown")
        t:assertEqual(zones[1].key, "zone:")
    end,

    ["a distance that fails to read counts as no place"] = function(t)
        local zones = WowVision.quests.zoneGroups({
            { questId = 1, title = "Broken", zone = "Z" },
            { questId = 2, title = "Fine", zone = "Z", distance = 5 },
        }, node, function(n)
            if n.label == "Broken" then
                error("no position")
            end
            return n.distance
        end)
        t:assertEqual(labels(zones[1].children), "Fine, Broken")
    end,
})
