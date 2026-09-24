local testRunner = WowVision.testing.testRunner
local Scan = WowVision.minimapScan

-- The minimap scanner's pure half. Tooltip texts are the ones measured on
-- WoW: Forever on 2026-09-24 (German client, Northshire and Stormwind).

local GOLD = { r = 1, g = 0.82, b = 0 }

local function tooltip(text, color)
    return { lines = { { leftText = text, leftColor = color or GOLD } } }
end

local function names(dots)
    local out = {}
    for i, dot in ipairs(dots) do
        out[i] = dot.name
    end
    return table.concat(out, ",")
end

local function find(list, name, category)
    for _, item in ipairs(list) do
        if item.name == name and (category == nil or item.category == category) then
            return item
        end
    end
    return nil
end

testRunner:addSuite("MinimapScan", {
    ["one gold line splits into dots, a title joins the name before it"] = function(t)
        local dots = Scan.parseMouseover(tooltip("Llane Beshere\n <Kriegerlehrer>\nMarshal McBride"))
        t:assertEqual(names(dots), "Llane Beshere,Marshal McBride")
        t:assertEqual(dots[1].subtitle, "Kriegerlehrer")
        t:assertNil(dots[2].subtitle)
    end,

    ["repeated names stay separate dots and count up"] = function(t)
        local dots = Scan.parseMouseover(tooltip("Mailbox\nMailbox\nOlivia Burnside\nMailbox"))
        local counts = Scan.counts(dots)
        t:assertEqual(counts["Mailbox"], 3)
        t:assertEqual(counts["Olivia Burnside"], 1)
    end,

    ["colour codes, empty parts and white detail lines are not dots"] = function(t)
        local data = {
            lines = {
                { leftText = "|cffffd200Peacebloom|r\n\n", leftColor = GOLD },
                { leftText = "Requires Herbalism", leftColor = { r = 1, g = 1, b = 1 } },
            },
        }
        t:assertEqual(names(Scan.parseMouseover(data)), "Peacebloom")
    end,

    ["grey names are on another level, until the colour ends"] = function(t)
        -- Northshire from outside the abbey, 2026-09-24.
        local dots = Scan.parseMouseover(tooltip(
            "Eagan Peltskinner\nDeputy Willem\n|cffb0b0b0Llane Beshere\n <Kriegerlehrer>|r\n|cffb0b0b0Marshal McBride|r\nMailbox"
        ))
        t:assertEqual(names(dots), "Eagan Peltskinner,Deputy Willem,Llane Beshere,Marshal McBride,Mailbox")
        t:assertFalse(dots[2].otherLevel)
        t:assertTrue(dots[3].otherLevel)
        t:assertEqual(dots[3].subtitle, "Kriegerlehrer")
        t:assertTrue(dots[4].otherLevel)
        t:assertFalse(dots[5].otherLevel)
    end,

    ["an indoor scan only judges indoor entries"] = function(t)
        local store = Scan.Store.new()
        store:upsert({ name = "Deputy Willem", category = "questGiver", wx = 40, wy = 0, continent = 0 }, 15)
        store:upsert({ name = "Marshal McBride", category = "questGiver", wx = 5, wy = 0, continent = 0, indoors = true }, 15)
        store:upsert({ name = "Old Guy", category = "questGiver", wx = 10, wy = 0, continent = 0, indoors = true }, 15)
        -- Inside the abbey only McBride answers; Willem outside is unseen, not gone.
        local present = Scan.presentByCategory({ { name = "Marshal McBride", category = "questGiver", count = 1 } })
        t:assertEqual(store:dropMissing(present, 0, 0, 0, 135, true), 1)
        t:assertEqual(#store:near(0, 0, 0, 150, "Deputy Willem"), 1)
        t:assertEqual(#store:near(0, 0, 0, 150, "Old Guy"), 0)
    end,

    ["secret text and missing data read as nothing"] = function(t)
        t:assertEqual(#Scan.parseMouseover(nil), 0)
        local secret = function()
            return true
        end
        t:assertEqual(#Scan.parseMouseover(tooltip("Hidden"), secret), 0)
    end,

    ["a raw read keeps colours and escapes visible"] = function(t)
        local lines = Scan.rawLines(tooltip("|cffb0b0b0Mailbox|r\nMarshal McBride"))
        t:assertEqual(#lines, 1)
        t:assertEqual(lines[1], "[ffd100] ||cffb0b0b0Mailbox||r\\nMarshal McBride")
        t:assertEqual(Scan.rawLines(nil)[1], "no tooltip data")
    end,

    ["the signature ignores order"] = function(t)
        local a = Scan.parseMouseover(tooltip("B\nA"))
        local b = Scan.parseMouseover(tooltip("A\nB"))
        t:assertEqual(Scan.signature(a), Scan.signature(b))
    end,

    ["sorting passes split quest givers, roles and titles (Stormwind)"] = function(t)
        local base = Scan.parseMouseover(tooltip("Renato Gallina\nHarlan Bagley\nRema Schneider"))
        local passes = {
            baseline = base,
            filters = {
                {
                    category = "auctioneer",
                    dots = Scan.parseMouseover(tooltip("Auktionator Chilton\nAuktionator Fitch\nHarlan Bagley\nRenato Gallina\nRema Schneider")),
                },
                {
                    category = "mailboxes",
                    dots = Scan.parseMouseover(tooltip("Mailbox\nMailbox\nMailbox\nRenato Gallina\nHarlan Bagley\nRema Schneider")),
                },
                {
                    category = "classTrainers",
                    dots = Scan.parseMouseover(tooltip("Llane Beshere\n <Kriegerlehrer>\nRenato Gallina\nHarlan Bagley\nRema Schneider")),
                },
                { category = "banker", dots = base },
                {
                    category = "questGiver",
                    flag = "trivial",
                    dots = Scan.parseMouseover(tooltip("Old Quest Guy\nRenato Gallina\nHarlan Bagley\nRema Schneider")),
                },
            },
        }
        local result = Scan.classify(passes)
        t:assertEqual(find(result, "Harlan Bagley").category, "questGiver")
        t:assertEqual(find(result, "Auktionator Fitch").category, "auctioneer")
        t:assertEqual(find(result, "Mailbox").count, 3)
        t:assertEqual(find(result, "Llane Beshere").subtitle, "Kriegerlehrer")
        t:assertEqual(find(result, "Old Quest Guy").flag, "trivial")
        t:assertEqual(find(result, "Old Quest Guy").category, "questGiver")
        t:assertNil(find(result, "Harlan Bagley", "banker"))
    end,

    ["a tracking spell switched off claims the names that vanish"] = function(t)
        local result = Scan.classify({
            baseline = Scan.parseMouseover(tooltip("Marshal McBride\nPeacebloom\nPeacebloom")),
            spells = { { category = "spell:2383", dots = Scan.parseMouseover(tooltip("Marshal McBride")) } },
        })
        t:assertEqual(find(result, "Peacebloom").category, "spell:2383")
        t:assertEqual(find(result, "Peacebloom").count, 2)
        t:assertEqual(find(result, "Marshal McBride").category, "questGiver")
        t:assertNil(find(result, "Peacebloom", "questGiver"))
    end,

    ["unsorted spells leave the baseline unsorted"] = function(t)
        local result = Scan.classify({
            baseline = Scan.parseMouseover(tooltip("Marshal McBride\nPeacebloom")),
            baselineCategory = "unsorted",
        })
        t:assertEqual(find(result, "Peacebloom").category, "unsorted")
    end,

    ["offsets turn into yards north and west"] = function(t)
        -- Up on a north-up minimap is north; right is east (negative west).
        local north, west = Scan.offsetToWorld(0, 10, 1.5, 0)
        t:assertEqual(math.floor(north + 0.5), 15)
        t:assertEqual(math.floor(west + 0.5), 0)
        north, west = Scan.offsetToWorld(10, 0, 1.5, 0)
        t:assertEqual(math.floor(north + 0.5), 0)
        t:assertEqual(math.floor(west + 0.5), -15)
        -- Rotating minimap, facing west (pi/2): up is west.
        north, west = Scan.offsetToWorld(0, 10, 1.5, math.pi / 2)
        t:assertEqual(math.floor(north + 0.5), 0)
        t:assertEqual(math.floor(west + 0.5), 15)
    end,

    ["the store merges close finds and drops what is gone"] = function(t)
        local store = Scan.Store.new()
        local dot = { name = "Mailbox", category = "mailboxes", wx = 0, wy = 0, continent = 0 }
        local _, isNew = store:upsert(dot, 15)
        t:assertTrue(isNew)
        _, isNew = store:upsert({ name = "Mailbox", category = "mailboxes", wx = 5, wy = 5, continent = 0 }, 15)
        t:assertFalse(isNew)
        store:upsert({ name = "Mailbox", category = "mailboxes", wx = 80, wy = 0, continent = 0 }, 15)
        store:upsert({ name = "Peacebloom", category = "spell:2383", wx = 20, wy = 0, continent = 0 }, 15)
        store:upsert({ name = "Peacebloom", category = "spell:2383", wx = 500, wy = 0, continent = 0 }, 15)
        t:assertEqual(#store:near(0, 0, 0, 150, "Mailbox", "mailboxes"), 2)
        -- The herb in range was picked; the far one is out of range and stays.
        local present = Scan.presentByCategory({ { name = "Mailbox", category = "mailboxes", count = 2 } })
        t:assertEqual(store:dropMissing(present, 0, 0, 0, 135), 1)
        t:assertEqual(#store:byCategory("spell:2383"), 1)
        t:assertEqual(#store:byCategory("mailboxes"), 2)
    end,

    ["around lists one category nearest first, on the continent only"] = function(t)
        local store = Scan.Store.new()
        store:upsert({ name = "Far", category = "banker", wx = 90, wy = 0, continent = 0 }, 15)
        store:upsert({ name = "Near", category = "banker", wx = 0, wy = 20, continent = 0 }, 15)
        store:upsert({ name = "Mailbox", category = "mailboxes", wx = 5, wy = 0, continent = 0 }, 15)
        store:upsert({ name = "Elsewhere", category = "banker", wx = 0, wy = 0, continent = 1 }, 15)
        local list = store:around(0, 0, 0, nil, "banker")
        t:assertEqual(#list, 2)
        t:assertEqual(list[1].entry.name, "Near")
        t:assertEqual(list[1].distance, 20)
        t:assertEqual(#store:around(0, 0, 0, 50, "banker"), 1)
        t:assertEqual(#store:around(0, 0, 0, 50), 2)
    end,

    ["only names short of their count need placing"] = function(t)
        local store = Scan.Store.new()
        store:upsert({ name = "Mailbox", category = "mailboxes", wx = 0, wy = 0, continent = 0 }, 15)
        local work = Scan.missingWork({
            { name = "Mailbox", category = "mailboxes", count = 3 },
            { name = "Olivia Burnside", category = "banker", count = 1 },
        }, store, 0, 0, 0, 150)
        t:assertEqual(#work, 2)
        store:upsert({ name = "Olivia Burnside", category = "banker", wx = 10, wy = 0, continent = 0 }, 15)
        work = Scan.missingWork({ { name = "Olivia Burnside", category = "banker", count = 1 } }, store, 0, 0, 0, 150)
        t:assertEqual(#work, 0)
    end,

    ["a giver on a finished quest's point takes it in"] = function(t)
        local points = { { wx = 100, wy = 100 } }
        t:assertEqual(Scan.giverStatus(105, 98, points, 15), "turnIn")
        t:assertEqual(Scan.giverStatus(0, 0, points, 15), "available")
        t:assertEqual(Scan.giverStatus(0, 0, nil, 15), "available")
    end,
    ["a title-only dot takes the real name of the NPC carrying that title"] = function(t)
        local candidates = {
            { name = "Deputy Willem", lines = {} },
            { name = "Riley Pelt", lines = { "Kürschnerlehrerin in Ausbildung" } },
            { name = "Janos Hammerknuckle", lines = { "<Waffenschmied>" } },
        }
        t:assertEqual(Scan.pickName("Kürschnerlehrerin in Ausbildung", candidates), "Riley Pelt")
        t:assertEqual(Scan.pickName("Waffenschmied", candidates), "Janos Hammerknuckle")
        local name, reason = Scan.pickName("Deputy Willem", candidates)
        t:assertNil(name)
        t:assertEqual(reason, "named")
        name, reason = Scan.pickName("Stallmeister", candidates)
        t:assertNil(name)
        t:assertEqual(reason, "none")
    end,

    ["colour codes and brackets do not hide a title"] = function(t)
        t:assertEqual(Scan.cleanLine("|cffffd200 <Kürschnerlehrerin in Ausbildung>|r"), "Kürschnerlehrerin in Ausbildung")
        local candidates = { { name = "Riley Pelt", lines = { "|cff00ff00Kürschnerlehrerin in Ausbildung|r" } } }
        t:assertEqual(Scan.pickName(" <Kürschnerlehrerin in Ausbildung>", candidates), "Riley Pelt")
    end,

    ["two NPCs of one title: only a clearly closer one wins"] = function(t)
        local near = { name = "Riley Pelt", lines = { "Trainee" }, minRange = 0, maxRange = 5 }
        local far = { name = "Tom Hide", lines = { "Trainee" }, minRange = 20, maxRange = 25 }
        t:assertEqual(Scan.pickName("Trainee", { far, near }), "Riley Pelt")
        local close = { name = "Tom Hide", lines = { "Trainee" }, minRange = 3, maxRange = 8 }
        local name, reason = Scan.pickName("Trainee", { near, close })
        t:assertNil(name)
        t:assertEqual(reason, "ambiguous")
        name, reason = Scan.pickName("Trainee", { { name = "A", lines = { "Trainee" } }, { name = "B", lines = { "Trainee" } } })
        t:assertEqual(reason, "ambiguous")
        -- The same NPC seen twice (nameplate and soft interact) is one match.
        t:assertEqual(Scan.pickName("Trainee", { near, near }), "Riley Pelt")
    end,

    ["points of interest split off as sorted names"] = function(t)
        local rest, names = Scan.splitCategory({
            { name = "Stormwind", category = "poi", count = 1 },
            { name = "Deputy Willem", category = "questGiver", count = 1 },
            { name = "Goldhain", category = "poi", count = 1 },
            { name = "Goldhain", category = "poi", count = 1 },
        }, "poi")
        t:assertEqual(#rest, 1)
        t:assertEqual(rest[1].name, "Deputy Willem")
        t:assertEqual(table.concat(names, ","), "Goldhain,Stormwind")
    end,
})

-- A simulated sweep: dots (offsets) answering over a square of `half`
-- units each way, asked at every cell. Returns key -> { ix, iy, n }.
local function sweep(dots, half, step, radius)
    local hits = {}
    for _, cell in ipairs(Scan.sweepCells(radius, step)) do
        local x, y = cell[1] * step, cell[2] * step
        local n = 0
        for _, dot in ipairs(dots) do
            if math.abs(x - dot[1]) <= half and math.abs(y - dot[2]) <= half then
                n = n + 1
            end
        end
        if n > 0 then
            hits[Scan.cellKey(cell[1], cell[2])] = { ix = cell[1], iy = cell[2], n = n }
        end
    end
    return hits
end

testRunner:addSuite("MinimapSweep", {
    ["the sweep asks every cell inside the radius"] = function(t)
        -- Centre, 4 on the axes at 1 and 2 steps, 4 diagonals.
        t:assertEqual(#Scan.sweepCells(4, 2), 13)
    end,

    ["dots apart are one group each, of one dot"] = function(t)
        local comps = Scan.components(sweep({ { 30, 20 }, { -40, -10 } }, 9.4, 2, 110))
        t:assertEqual(#comps, 2)
        local single = Scan.singleSize(comps)
        t:assertEqual(Scan.dotsInComponent(comps[1], single), 1)
        t:assertEqual(Scan.dotsInComponent(comps[2], single), 1)
    end,

    ["overlapping dots of one name count as two and split near their places"] = function(t)
        local hits = sweep({ { 20, 0 }, { 32, 6 }, { -50, 40 } }, 9.4, 2, 110)
        local comps = Scan.components(hits)
        t:assertEqual(#comps, 2)
        local single = Scan.singleSize(comps)
        local merged = comps[1].size > comps[2].size and comps[1] or comps[2]
        t:assertEqual(merged.maxN, 2)
        t:assertEqual(Scan.dotsInComponent(merged, single), 2)
        local centres = Scan.splitComponent(merged, 2, 2)
        table.sort(centres, function(a, b)
            return a[1] < b[1]
        end)
        t:assertTrue(math.abs(centres[1][1] - 20) <= 4 and math.abs(centres[1][2] - 0) <= 4)
        t:assertTrue(math.abs(centres[2][1] - 32) <= 4 and math.abs(centres[2][2] - 6) <= 4)
    end,

    ["dots only touching count as two by the size of their group"] = function(t)
        -- 18 units apart: patches of 9.4 each way touch, no cell in both.
        local hits = sweep({ { 0, 30 }, { 18, 30 }, { -60, -20 } }, 9.4, 2, 110)
        local comps = Scan.components(hits)
        t:assertEqual(#comps, 2)
        local single = Scan.singleSize(comps)
        local big = comps[1].size > comps[2].size and comps[1] or comps[2]
        t:assertEqual(big.maxN, 1)
        t:assertEqual(Scan.dotsInComponent(big, single), 2)
    end,

    ["the middle row and a column span the patch"] = function(t)
        local comp = Scan.components(sweep({ { 10, -6 } }, 9.4, 2, 110))[1]
        local iy, minX, maxX = Scan.middleRow(comp)
        t:assertEqual(iy, -3)
        t:assertEqual(minX, 1)
        t:assertEqual(maxX, 9)
        local minY, maxY = Scan.column(comp, 5)
        t:assertEqual(minY, -7)
        t:assertEqual(maxY, 1)
        t:assertNil(Scan.column(comp, 40))
    end,

    ["a full patch has its dot in the middle, a cut one from the near edge"] = function(t)
        t:assertEqual(Scan.edgeCentre(10, 28.8, 9.4), 19.4)
        -- Rim dot at 95: its patch ends at 99 where the minimap ends.
        t:assertEqual(Scan.edgeCentre(85.6, 99, 9.4), 95)
        t:assertEqual(Scan.edgeCentre(-99, -85.6, 9.4), -95)
        t:assertEqual(Scan.edgeCentre(1, 5, nil), 3)
    end,

    ["a read with more of any name than the baseline has extras"] = function(t)
        local base = { { name = "Marshal McBride" } }
        t:assertFalse(Scan.hasExtras(base, { { name = "Marshal McBride" } }))
        t:assertTrue(Scan.hasExtras(base, { { name = "Marshal McBride" }, { name = "Mailbox" } }))
        t:assertTrue(Scan.hasExtras({ { name = "Mailbox" } }, { { name = "Mailbox" }, { name = "Mailbox" } }))
        t:assertEqual(Scan.median({ 3, 1, 2, 10 }), 2.5)
    end,
})
