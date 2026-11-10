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

-- Walking events as "kind name" joined by ",".
local function kinds(events)
    local out = {}
    for _, e in ipairs(events) do
        tinsert(out, e.name ~= nil and (e.kind .. " " .. e.name) or e.kind)
    end
    return table.concat(out, ",")
end

-- The same read every half second from `from` to `to` (inclusive);
-- returns every event on the way.
local function walkFor(walk, counts, from, to, indoors, position)
    local all = {}
    local now = from
    while now <= to + 1e-9 do
        local read = { counts = counts, now = now, indoors = indoors }
        if position ~= nil then
            local px, py = position(now)
            read.px, read.py, read.continent = px, py, 0
        end
        for _, e in ipairs(walk:update(read)) do
            tinsert(all, e)
        end
        now = now + 0.5
    end
    return all
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

    ["a white objective inside the line is detail, not a dot"] = function(t)
        -- Quest objective tracking on, Northshire, 2026-09-24.
        local dots = Scan.parseMouseover(tooltip(
            "Goldhain\nStormwind\nDeputy Willem\nWölfe an der Grenze|cffffffff\n-Zähes Wolfsfleisch: 1/8|r\nMailbox"
        ))
        t:assertEqual(names(dots), "Goldhain,Stormwind,Deputy Willem,Wölfe an der Grenze,Mailbox")
        t:assertFalse(dots[4].otherLevel)
        t:assertFalse(dots[5].otherLevel)
    end,

    ["an arrow texture before a name is not part of it"] = function(t)
        -- Walking log, Elwynn, 2026-09-28.
        local dots = Scan.parseMouseover(tooltip(
            "Friedensblume\n|TInterface\\Minimap\\Minimap-PositionArrows:0:0:0:0:16:32:0:16:0:16|tSilberblatt\n"
                .. "|TInterface\\Minimap\\Minimap-PositionArrows:0:0:0:0:16:32:0:16:16:32|tSilberblatt"
        ))
        t:assertEqual(names(dots), "Friedensblume,Silberblatt,Silberblatt")
        t:assertNil(dots[1].arrow)
        t:assertEqual(dots[2].arrow.top, 0)
        t:assertEqual(dots[2].arrow.bottom, 0.5)
        t:assertEqual(dots[3].arrow.top, 0.5)
        t:assertEqual(Scan.counts(dots)["Silberblatt"], 2)
        -- The top half is above the player, the bottom half below.
        t:assertEqual(Scan.arrowLevel(dots[2].arrow), "above")
        t:assertEqual(Scan.arrowLevel(dots[3].arrow), "below")
        t:assertNil(Scan.arrowLevel(nil))
        t:assertNil(Scan.arrowLevel({ spec = "odd" }))
        t:assertNil(Scan.arrowLevel(Scan.textureCoords("Interface\\Other:0:0:0:0:16:32:0:16:0:16")))
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

    ["a raw read lists the other fields of lines and data"] = function(t)
        local data = { type = 0, lines = { { leftText = "Friedensblume", leftColor = GOLD, type = 5, args = { icon = "|T1:0|t" } } } }
        local lines = Scan.rawLines(data)
        t:assertEqual(#lines, 3)
        t:assertEqual(lines[2], "  fields: args={icon=||T1:0||t}, type=5")
        t:assertEqual(lines[3], "data fields: type=0")
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

    ["a gathering list claims the names that contain one of its names"] = function(t)
        local names = {
            herbs = { spells = { 2383 }, enUS = { "Peacebloom" }, deDE = { "Silberblatt", "Friedensblume" } },
            mining = { spells = { 2580 }, enUS = { "Copper Vein" }, deDE = { "Kupfervorkommen" } },
        }
        local kinds, other = Scan.gatheringKinds({
            { spellID = 2383, name = "Kräutersuche", active = true },
            { spellID = 2580, name = "Mineraliensuche", active = false },
        }, names, "deDE")
        t:assertEqual(#kinds, 1)
        t:assertEqual(other, false)
        local result = Scan.classify({
            baseline = Scan.parseMouseover(tooltip("Marshal McBride\nVerkümmertes Silberblatt\nFriedensblume\nFriedensblume\nKupfervorkommen")),
            gathering = kinds,
        })
        t:assertEqual(find(result, "Verkümmertes Silberblatt").category, "spell:2383")
        t:assertEqual(find(result, "Friedensblume").category, "spell:2383")
        t:assertEqual(find(result, "Friedensblume").count, 2)
        t:assertEqual(find(result, "Marshal McBride").category, "questGiver")
        -- Mining is off: its names are not looked for.
        t:assertEqual(find(result, "Kupfervorkommen").category, "questGiver")
        t:assertNil(find(result, "Friedensblume", "questGiver"))
    end,

    ["a missing locale falls back to the English names"] = function(t)
        local kinds = Scan.gatheringKinds(
            { { spellID = 2383, name = "Find Herbs", active = true } },
            { herbs = { spells = { 2383 }, enUS = { "Peacebloom" } } },
            "esES"
        )
        t:assertEqual(Scan.gatheringCategory("Peacebloom", kinds).category, "spell:2383")
    end,

    ["another tracking spell leaves the baseline unsorted"] = function(t)
        local _, other = Scan.gatheringKinds({ { spellID = 1494, name = "Track Beasts", active = true } }, Scan.gatheringNames, "enUS")
        t:assertEqual(other, true)
        local result = Scan.classify({
            baseline = Scan.parseMouseover(tooltip("Marshal McBride\nYoung Wolf")),
            baselineCategory = "unsorted",
        })
        t:assertEqual(find(result, "Young Wolf").category, "unsorted")
    end,

    ["the shipped lists cover every locale of every kind"] = function(t)
        for key, kind in pairs(Scan.gatheringNames) do
            t:assertTrue(#kind.spells > 0, key)
            t:assertEqual(#kind.deDE, #kind.enUS)
            t:assertEqual(#kind.frFR, #kind.enUS)
        end
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

    ["the read's count decides the dots: one group each"] = function(t)
        local comps = Scan.components(sweep({ { 30, 20 }, { -40, -10 } }, 9.4, 8, 110))
        t:assertEqual(#comps, 2)
        local ks = Scan.dotsByCount(comps, 2, Scan.singleSize(comps))
        t:assertEqual(ks[1], 1)
        t:assertEqual(ks[2], 1)
    end,

    ["the read's count: one dot, a second small group holds none"] = function(t)
        local comps = Scan.components(sweep({ { 30, 20 }, { -40, -10 } }, 9.4, 8, 110))
        -- Make the second group a sliver.
        local small = comps[1].size < comps[2].size and 1 or 2
        comps[small].size = 1
        local ks = Scan.dotsByCount(comps, 1, nil)
        t:assertEqual(ks[small], 0)
        t:assertEqual(ks[3 - small], 1)
    end,

    ["the read's count: two touching dots in one group are two"] = function(t)
        local comps = Scan.components(sweep({ { 0, 30 }, { 18, 30 } }, 9.4, 8, 110))
        t:assertEqual(#comps, 1)
        t:assertEqual(Scan.dotsByCount(comps, 2, nil)[1], 2)
    end,

    ["without a count the size estimate stays"] = function(t)
        local comps = Scan.components(sweep({ { 30, 20 }, { -40, -10 } }, 9.4, 2, 110))
        local ks = Scan.dotsByCount(comps, nil, Scan.singleSize(comps))
        t:assertEqual(ks[1], 1)
        t:assertEqual(ks[2], 1)
    end,

    ["world to offset undoes offset to world, also turned"] = function(t)
        for _, facing in ipairs({ 0, 1, 2.5 }) do
            local north, west = Scan.offsetToWorld(12, -30, 2.35, facing)
            local ox, oy = Scan.worldToOffset(north, west, 2.35, facing)
            t:assertTrue(math.abs(ox - 12) < 1e-9 and math.abs(oy + 30) < 1e-9)
        end
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

    ["walking: a name is spoken once, a short gap stays silent"] = function(t)
        local walk = Scan.Walk.new()
        local events = walk:update({ counts = { Mailbox = 1 }, now = 0 })
        t:assertEqual(kinds(events), "new Mailbox")
        t:assertEqual(kinds(walk:update({ counts = { Mailbox = 1 }, now = 0.5 })), "")
        -- Half a second, then five seconds, missing: back, not new.
        t:assertEqual(kinds(walk:update({ counts = {}, now = 1 })), "fewer Mailbox")
        t:assertEqual(kinds(walk:update({ counts = { Mailbox = 1 }, now = 1.5 })), "back Mailbox")
        walkFor(walk, {}, 2, 7)
        t:assertEqual(kinds(walk:update({ counts = { Mailbox = 1 }, now = 7.5 })), "back Mailbox")
    end,

    ["walking: 30 seconds of walking without it means gone, then it is new again"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0 })
        local events = walkFor(walk, {}, 0.5, 31)
        t:assertEqual(kinds(events), "fewer Mailbox,gone Mailbox")
        t:assertEqual(kinds(walk:update({ counts = { Mailbox = 1 }, now = 31.5 })), "new Mailbox")
    end,

    ["walking: standing still adds at most one second to the clock"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1, Peacebloom = 1 }, now = 0 })
        -- The mailbox left view as the player stopped; five minutes later
        -- the walk goes on: one second counted, not three hundred.
        walk:update({ counts = { Peacebloom = 1 }, now = 0.5 })
        t:assertEqual(kinds(walk:update({ counts = { Peacebloom = 1 }, now = 300 })), "")
        t:assertEqual(kinds(walk:update({ counts = { Peacebloom = 1, Mailbox = 1 }, now = 300.5 })), "back Mailbox")
    end,

    ["walking: time indoors is not missing time"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1, ["Olivia Burnside"] = 1 }, now = 0 })
        -- Into the inn: only the innkeeper in view, for two minutes.
        local events = walkFor(walk, { Innkeeper = 1 }, 0.5, 120, true)
        t:assertEqual(kinds(events), "indoors,new Innkeeper,fewer Mailbox,fewer Olivia Burnside")
        -- Out again: everything back, nothing spoken.
        events = walk:update({ counts = { Mailbox = 1, ["Olivia Burnside"] = 1 }, now = 120.5 })
        t:assertEqual(kinds(events), "outdoors,fewer Innkeeper,back Mailbox,back Olivia Burnside")
    end,

    ["walking: a second dot of a name in view is new"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Peacebloom = 1 }, now = 0 })
        local events = walk:update({ counts = { Peacebloom = 2 }, now = 0.5 })
        t:assertEqual(kinds(events), "new Peacebloom")
        t:assertEqual(events[1].remembered, 1)
        -- One of them missing for good: dropped to one, then two is new again.
        events = walkFor(walk, { Peacebloom = 1 }, 1, 31)
        t:assertEqual(kinds(events), "fewer Peacebloom,gone Peacebloom")
        t:assertEqual(kinds(walk:update({ counts = { Peacebloom = 2 }, now = 31.5 })), "new Peacebloom")
    end,

    ["walking, placed: only walking past range and back makes it new"] = function(t)
        local walk = Scan.Walk.new()
        local function at(x, counts, now)
            return walk:update({ counts = counts, now = now, px = x, py = 0, continent = 0, radius = 233 })
        end
        local events, locate = at(220, { Mailbox = 1 }, 0)
        t:assertEqual(kinds(events), "new Mailbox")
        t:assertEqual(table.concat(locate, ","), "Mailbox")
        local result = walk:placed("Mailbox", { { wx = 0, wy = 0 } }, 0)
        t:assertEqual(#result.placed, 1)
        -- Out of view just past the rim for a minute, walking outdoors:
        -- it may or may not show there, so nothing is said.
        events = walkFor(walk, {}, 0.5, 60, false, function()
            return 250, 0
        end)
        t:assertEqual(kinds(events), "")
        t:assertEqual(kinds(at(225, { Mailbox = 1 }, 60.5)), "")
        -- Past range plus margin: left; back in view: new.
        t:assertEqual(kinds(at(260, {}, 61)), "left Mailbox")
        t:assertEqual(kinds(at(230, { Mailbox = 1 }, 61.5)), "new Mailbox")
    end,

    ["walking, back in view: another place is a new dot, the old one gone"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 0, py = 0, continent = 0, radius = 150 })
        walk:placed("Mailbox", { { wx = 50, wy = 0 } }, 0)
        t:assertEqual(kinds(walk:update({ counts = {}, now = 0.5, px = 10, py = 0, continent = 0, radius = 150 })), "fewer Mailbox")
        local events, locate, verify = walk:update({ counts = { Mailbox = 1 }, now = 5, px = 20, py = 0, continent = 0, radius = 150 })
        t:assertEqual(kinds(events), "back Mailbox")
        t:assertEqual(table.concat(locate, ","), "Mailbox")
        t:assertTrue(verify.Mailbox)
        -- The one in view stands 90 yards from the remembered one.
        local result = walk:placed("Mailbox", { { wx = -40, wy = 60 } }, 0, { px = 20, py = 0, radius = 150 })
        t:assertEqual(result.new, 1)
        t:assertEqual(result.dropped, 1)
        t:assertEqual(#walk.names.Mailbox.dots, 1)
    end,

    ["walking, back in view: the same place is the same dot, silent"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 0, py = 0, continent = 0, radius = 150 })
        walk:placed("Mailbox", { { wx = 50, wy = 0 } }, 0)
        walk:update({ counts = {}, now = 0.5, px = 10, py = 0, continent = 0, radius = 150 })
        walk:update({ counts = { Mailbox = 1 }, now = 3, px = 20, py = 0, continent = 0, radius = 150 })
        local result = walk:placed("Mailbox", { { wx = 58, wy = 6 } }, 0, { px = 20, py = 0, radius = 150 })
        t:assertEqual(result.new, 0)
        t:assertEqual(result.dropped, 0)
        t:assertEqual(result.refreshed, 1)
    end,

    ["walking, placed: the view radius shrinking and growing changes nothing"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 0, py = 0, continent = 0, radius = 233 })
        walk:placed("Mailbox", { { wx = 200, wy = 0 } }, 0)
        walk:update({ counts = { Mailbox = 1 }, now = 0.5, px = 0, py = 0, continent = 0, radius = 233 })
        -- The radius drops to 150: the mailbox at 200 yards no longer shows.
        local events = walk:update({ counts = {}, now = 1, px = 5, py = 0, continent = 0, radius = 150 })
        t:assertEqual(kinds(events), "")
        -- Back to 233 a little later: the same mailbox, nothing said.
        events = walk:update({ counts = { Mailbox = 1 }, now = 20, px = 10, py = 0, continent = 0, radius = 233 })
        t:assertEqual(kinds(events), "")
        t:assertEqual(#walk.names.Mailbox.dots, 1)
    end,

    ["walking, back in view: a far place matches with the larger allowance"] = function(t)
        t:assertEqual(Scan.Walk.matchFor(0), 25)
        t:assertEqual(Scan.Walk.matchFor(100), 50)
        t:assertEqual(Scan.Walk.matchFor(400), 60)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 0, py = 0, continent = 0, radius = 233 })
        walk:placed("Mailbox", { { wx = 180, wy = 0 } }, 0)
        walk:update({ counts = {}, now = 0.5, px = 0, py = 0, continent = 0, radius = 233 })
        walk:update({ counts = { Mailbox = 1 }, now = 3, px = 0, py = 0, continent = 0, radius = 233 })
        -- Found again 40 yards off, 210 yards out: the same mailbox.
        local result = walk:placed(
            "Mailbox",
            { { wx = 210, wy = 25, match = Scan.Walk.matchFor(211) } },
            0,
            { px = 0, py = 0, radius = 233 }
        )
        t:assertEqual(result.new, 0)
        t:assertEqual(result.refreshed, 1)
    end,

    ["walking, placed: the closest pairs match first"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 2 }, now = 0, px = 0, py = 0, continent = 0, radius = 233 })
        walk:placed("Mailbox", { { wx = 0, wy = 0 }, { wx = 50, wy = 0 } }, 0)
        -- Dot by dot, the one at 0 would take the place at 28 (its
        -- nearest) and leave the one at 50 without.
        local result = walk:placed("Mailbox", { { wx = 28, wy = 0, match = 32 }, { wx = -30, wy = 0, match = 32 } }, 0)
        t:assertEqual(result.refreshed, 2)
        t:assertEqual(result.extra, 0)
    end,

    ["walking, back after the minimap showed only the building: no place check"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 0, py = 0, continent = 0, radius = 233 })
        walk:placed("Mailbox", { { wx = 100, wy = 0 } }, 0)
        walk:update({ counts = { Mailbox = 1 }, now = 0.5, px = 0, py = 0, continent = 0, radius = 233 })
        walk:update({ counts = {}, now = 1, px = 5, py = 0, continent = 0, radius = 233, indoors = true })
        local events, locate, verify = walk:update({ counts = { Mailbox = 1 }, now = 9, px = 10, py = 0, continent = 0, radius = 233 })
        t:assertEqual(kinds(events), "outdoors,back Mailbox")
        t:assertEqual(#locate, 0)
        t:assertNil(verify.Mailbox)
    end,

    ["walking, back in view: an empty sweep drops nothing"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 0, py = 0, continent = 0, radius = 150 })
        walk:placed("Mailbox", { { wx = 50, wy = 0 } }, 0)
        walk:update({ counts = {}, now = 0.5, px = 10, py = 0, continent = 0, radius = 150 })
        walk:update({ counts = { Mailbox = 1 }, now = 3, px = 20, py = 0, continent = 0, radius = 150 })
        local result = walk:placed("Mailbox", {}, 0, { px = 20, py = 0, radius = 150 })
        t:assertEqual(result.dropped, 0)
        t:assertEqual(#walk.names.Mailbox.dots, 1)
    end,

    ["walking, back while the minimap shows only the building: no place check"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 0, py = 0, continent = 0, radius = 233 })
        walk:placed("Mailbox", { { wx = 100, wy = 0 } }, 0)
        walk:update({ counts = { Mailbox = 1 }, now = 0.5, px = 0, py = 0, continent = 0, radius = 233 })
        walk:update({ counts = {}, now = 1, px = 5, py = 0, continent = 0, radius = 233 })
        local _, locate, verify = walk:update({ counts = { Mailbox = 1 }, now = 3, px = 10, py = 0, continent = 0, radius = 233, indoors = true })
        t:assertEqual(#locate, 0)
        t:assertNil(verify.Mailbox)
    end,

    ["walking, placed: a building changes nothing"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 100, py = 0, continent = 0 })
        walk:placed("Mailbox", { { wx = 0, wy = 0 } }, 0)
        local events = walkFor(walk, {}, 0.5, 120, true, function()
            return 100, 0
        end)
        t:assertEqual(kinds(events), "indoors,fewer Mailbox")
        events = walk:update({ counts = { Mailbox = 1 }, now = 120.5, px = 100, py = 0, continent = 0 })
        t:assertEqual(kinds(events), "outdoors,back Mailbox")
    end,

    ["walking, placed: missing 30 s while it should show means gone"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Peacebloom = 1 }, now = 0, px = 50, py = 0, continent = 0 })
        walk:placed("Peacebloom", { { wx = 0, wy = 0 } }, 0)
        -- Picked by someone else; the player walks around nearby.
        local events = walkFor(walk, {}, 0.5, 31, false, function(now)
            return 50 + now, 0
        end)
        t:assertEqual(kinds(events), "fewer Peacebloom,gone Peacebloom")
        t:assertNil(walk.names["Peacebloom"])
    end,

    ["walking, placed: a second one in view is new, the first found again stays"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Peacebloom = 1 }, now = 0, px = 0, py = 0, continent = 0 })
        walk:placed("Peacebloom", { { wx = 100, wy = 0 } }, 0)
        local events, locate = walk:update({ counts = { Peacebloom = 2 }, now = 0.5, px = 0, py = 0, continent = 0 })
        t:assertEqual(kinds(events), "new Peacebloom")
        t:assertEqual(#locate, 1)
        -- The sweep finds both: the old one moved a little, the new one far off.
        local result = walk:placed("Peacebloom", { { wx = -150, wy = 20 }, { wx = 104, wy = 3 } }, 0)
        t:assertEqual(result.refreshed, 1)
        t:assertEqual(#result.placed, 1)
        t:assertEqual(result.placed[1].wx, -150)
        t:assertEqual(result.extra, 0)
        t:assertEqual(walk.names["Peacebloom"].dots[1].wx, 104)
    end,

    ["walking, placed: one still in view past its range goes to the name rule"] = function(t)
        -- A town's arrow: always about 209 yards ahead.
        local walk = Scan.Walk.new()
        walk:update({ counts = { Goldshire = 1 }, now = 0, px = 0, py = 0, continent = 0 })
        walk:placed("Goldshire", { { wx = 209, wy = 0 } }, 0)
        local events = walkFor(walk, { Goldshire = 1 }, 0.5, 80, false, function(now)
            return now * 7, 0
        end)
        t:assertEqual(kinds(events), "follows Goldshire")
        t:assertTrue(walk.nameOnly["Goldshire"])
        -- A new read of it asks for no place any more.
        local _, locate = walk:update({ counts = { Goldshire = 2 }, now = 81, px = 567, py = 0, continent = 0 })
        t:assertEqual(#locate, 0)
    end,

    ["walking, placed: a hearthstone is a jump, not a dot following"] = function(t)
        local walk = Scan.Walk.new()
        walk:update({ counts = { Mailbox = 1 }, now = 0, px = 100, py = 0, continent = 0 })
        walk:placed("Mailbox", { { wx = 0, wy = 0 } }, 0)
        local events = walk:update({ counts = { Mailbox = 1 }, now = 12, px = 5000, py = 0, continent = 0 })
        t:assertEqual(kinds(events), "jump,left Mailbox,new Mailbox")
        t:assertNil(walk.nameOnly["Mailbox"])
    end,

    ["a read with more of any name than the baseline has extras"] = function(t)
        local base = { { name = "Marshal McBride" } }
        t:assertFalse(Scan.hasExtras(base, { { name = "Marshal McBride" } }))
        t:assertTrue(Scan.hasExtras(base, { { name = "Marshal McBride" }, { name = "Mailbox" } }))
        t:assertTrue(Scan.hasExtras({ { name = "Mailbox" } }, { { name = "Mailbox" }, { name = "Mailbox" } }))
        t:assertEqual(Scan.median({ 3, 1, 2, 10 }), 2.5)
    end,
})
