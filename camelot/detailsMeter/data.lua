-- The data and what is said of it: the kinds of figure (damage, healing, interrupts...), the fights, what the screen
-- shows (the selection), the ranked list of one fight, the spells and the targets of one player, and the sentences made
-- of them. Everything the game gives goes through ns.Game; every value it gives may be hidden (secret) in combat, so a
-- figure is only joined into a sentence, never compared or calculated, unless Text.isNumber says it can be read.
local ns = WowVision.detailsMeter
local L = ns.L
local Text = ns.Text
local Game = ns.Game

local Data = {}
ns.Data = Data

-- ------------------------------------------------------------------ cache

-- The screen is drawn again every tick and the game's answer is a fresh table of tables: it is asked at most once per
-- ttl seconds for the same thing.
local cache = {}

function Data.cached(key, ttl, build)
    local now = Game.now()
    local entry = cache[key]
    if entry == nil or now < entry.time or now - entry.time >= ttl then
        local first, second = build()
        entry = { time = now, first = first, second = second }
        cache[key] = entry
    end
    return entry.first, entry.second
end

function Data.clearCache()
    for key in pairs(cache) do
        cache[key] = nil
    end
end

-- A yes from a value that may be hidden: only its truth is looked at, and a refusal counts as no.
local function truth(value)
    local ok, result = pcall(function()
        if value then
            return true
        end
        return false
    end)
    return ok and result == true
end

-- The sum of the values of a list of entries, nil when one of them cannot be read (then no percent is said).
local function sumValues(entries)
    local total = 0
    for _, entry in ipairs(entries) do
        if not Text.isNumber(entry.value) then
            return nil
        end
        total = total + entry.value
    end
    return total
end

-- --------------------------------------------------------- kinds of figure

-- kind: "amount" = a total and a per-second figure, "rate" = the per-second figure is the one that counts, "count" =
-- a number of times. phrase: how the figure is said in a sentence ("%s damage"), phraseOne for exactly one.
local ATTRIBUTES = {
    { key = "DamageDone", label = "Damage done", global = "DAMAGE_METER_TYPE_DAMAGE_DONE", kind = "amount", phrase = "%s damage" },
    { key = "Dps", label = "Damage per second", global = "DAMAGE_METER_TYPE_DPS", kind = "rate", phrase = "%s damage per second" },
    { key = "HealingDone", label = "Healing done", global = "DAMAGE_METER_TYPE_HEALING_DONE", kind = "amount", phrase = "%s healing" },
    { key = "Hps", label = "Healing per second", global = "DAMAGE_METER_TYPE_HPS", kind = "rate", phrase = "%s healing per second" },
    { key = "Absorbs", label = "Absorbs", global = "DAMAGE_METER_TYPE_ABSORBS", kind = "amount", phrase = "%s absorbed" },
    { key = "Interrupts", label = "Interrupts", global = "DAMAGE_METER_TYPE_INTERRUPTS", kind = "count", phrase = "%s interrupts", phraseOne = "%s interrupt" },
    { key = "Dispels", label = "Dispels", global = "DAMAGE_METER_TYPE_DISPELS", kind = "count", phrase = "%s dispels", phraseOne = "%s dispel" },
    { key = "DamageTaken", label = "Damage taken", global = "DAMAGE_METER_TYPE_DAMAGE_TAKEN", kind = "amount", phrase = "%s damage taken", from = true },
    { key = "AvoidableDamageTaken", label = "Avoidable damage taken", global = "DAMAGE_METER_TYPE_AVOIDABLE_DAMAGE_TAKEN", kind = "amount", phrase = "%s avoidable damage taken", from = true },
    { key = "Deaths", label = "Deaths", global = "DAMAGE_METER_TYPE_DEATHS", kind = "count", phrase = "%s deaths", phraseOne = "%s death" },
    { key = "EnemyDamageTaken", label = "Damage taken by the enemies", global = "DAMAGE_METER_TYPE_ENEMY_DAMAGE_TAKEN", kind = "amount", phrase = "%s damage taken by the enemies" },
}

-- The kinds of figure this game's damage meter has, in the order above: each with the value the game knows it by.
function Data.attributes()
    local list = {}
    for _, entry in ipairs(ATTRIBUTES) do
        local value = Game.meterType(entry.key)
        if value ~= nil then
            local copy = { value = value }
            for key, field in pairs(entry) do
                copy[key] = field
            end
            list[#list + 1] = copy
        end
    end
    return list
end

function Data.attribute(key)
    for _, attribute in ipairs(Data.attributes()) do
        if attribute.key == key then
            return attribute
        end
    end
    return nil
end

function Data.attributeFromValue(value)
    if value == nil then
        return nil
    end
    for _, attribute in ipairs(Data.attributes()) do
        if attribute.value == value then
            return attribute
        end
    end
    return nil
end

-- The key of the kind of figure to start with: damage done, or the first the game has.
function Data.defaultAttribute()
    local list = Data.attributes()
    for _, attribute in ipairs(list) do
        if attribute.key == "DamageDone" then
            return attribute.key
        end
    end
    return list[1] and list[1].key or nil
end

-- Its name: the game's own word for it (what Details shows), else ours.
function Data.attributeName(attribute)
    return Game.globalString(attribute.global) or L[attribute.label]
end

function Data.attributeChoices()
    local choices = {}
    for _, attribute in ipairs(Data.attributes()) do
        choices[#choices + 1] = { label = Data.attributeName(attribute), value = attribute.key }
    end
    return choices
end

-- -------------------------------------------------------------------- fights

function Data.segmentKey(segment)
    if segment.kind == "id" then
        return "id:" .. tostring(segment.id)
    end
    return segment.kind
end

function Data.parseSegment(key)
    if key == "overall" then
        return { kind = "overall" }
    end
    local id = type(key) == "string" and key:match("^id:(%d+)$") or nil
    if id then
        return { kind = "id", id = tonumber(id) }
    end
    return { kind = "current" }
end

local function sessions()
    return (Data.cached("sessions", 1, function()
        return Game.sessions()
    end))
end

-- One fight of the game's list as a line: "Fight 5, Gruul, 3 minutes 20 seconds".
function Data.sessionLabel(session)
    local parts = { string.format(L["Fight %d"], session.sessionID) }
    local name = session.name
    if name and (Text.isSecret(name) or (type(name) == "string" and name ~= "")) then
        parts[#parts + 1] = name
    end
    parts[#parts + 1] = Text.duration(session.durationSeconds)
    return Text.join(parts, ", ")
end

function Data.segmentLabel(segment)
    if segment.kind == "overall" then
        return L["All fights together"]
    elseif segment.kind == "id" then
        for _, session in ipairs(sessions()) do
            if type(session) == "table" and session.sessionID == segment.id then
                return Data.sessionLabel(session)
            end
        end
        return string.format(L["Fight %d"], segment.id)
    end
    return L["Current fight"]
end

-- The fights to choose from: the current one, all together, then the kept ones, the newest first.
function Data.segmentChoices()
    local choices = {
        { label = L["Current fight"], value = "current" },
        { label = L["All fights together"], value = "overall" },
    }
    local list = sessions()
    for index = #list, 1, -1 do
        local session = list[index]
        if type(session) == "table" and type(session.sessionID) == "number" then
            choices[#choices + 1] = { label = Data.sessionLabel(session), value = "id:" .. session.sessionID }
        end
    end
    return choices
end

-- -------------------------------------------------------------- the selection

-- What the screen shows: { segment, attribute (a key), followed }. Where Details' first open window is when it is
-- followed (and has a window), else what the player chose last.
function Data.selection(attributeOverride)
    local selection = {
        segment = Data.parseSegment(Game.getSetting("segment")),
        attribute = Game.getSetting("attribute"),
        followed = false,
    }
    if Game.getSetting("follow") ~= false then
        local window = Game.detailsWindow()
        if window ~= nil then
            selection.followed = true
            if window.segment ~= nil then
                selection.segment = window.segment
            end
            local attribute = Data.attributeFromValue(window.attributeValue)
            if attribute ~= nil then
                selection.attribute = attribute.key
            end
        end
    end
    if attributeOverride ~= nil then
        selection.attribute = attributeOverride
    end
    if Data.attribute(selection.attribute) == nil then
        selection.attribute = Data.defaultAttribute()
    end
    return selection
end

function Data.selectionKey(selection)
    return Data.segmentKey(selection.segment) .. "|" .. tostring(selection.attribute)
end

-- The player picks the fight or the kind of figure: both stay as they are now, the one picked changes, and Details is
-- no longer followed (the toggle brings it back).
function Data.choose(what, value)
    local current = Data.selection()
    Game.setSetting("segment", Data.segmentKey(current.segment))
    Game.setSetting("attribute", current.attribute)
    Game.setSetting(what, value)
    Game.setSetting("follow", false)
    Data.clearCache()
end

-- The choice one step away in the fights or the measures, in the order of the list and round again, without changing
-- anything: what the buttons name before they are pressed. what: "segment" or "attribute"; step: 1 or -1. Returns the
-- choice ({ label, value }), its place and how many there are; nil when there is nothing to choose from.
function Data.neighbor(what, step)
    local choices
    if what == "segment" then
        choices = Data.segmentChoices()
    else
        choices = Data.attributeChoices()
    end
    if #choices == 0 then
        return nil
    end
    local current = Data.selection()
    local key = what == "segment" and Data.segmentKey(current.segment) or current.attribute
    local position
    for index, choice in ipairs(choices) do
        if choice.value == key then
            position = index
        end
    end
    local target
    if position == nil then
        target = step > 0 and 1 or #choices
    else
        target = (position - 1 + step) % #choices + 1
    end
    return choices[target], target, #choices
end

-- One step, taken (what Left and Right do on the controls, the buttons, and the keys). Returns what Data.neighbor did.
function Data.cycle(what, step)
    local choice, target, count = Data.neighbor(what, step)
    if choice == nil then
        return nil
    end
    Data.choose(what, choice.value)
    return choice, target, count
end

-- The newest of the fights the game keeps ({ label, value }), nil when it keeps none: the first after "current" and
-- "overall" in the list of fights.
function Data.lastKept()
    return Data.segmentChoices()[3]
end

-- -------------------------------------------------------------- the ranked list

-- What one source (a player, a creature) shows of itself.
local function makeRow(attribute, source, index)
    local row = {
        index = index,
        name = Text.name(source.name),
        guid = source.sourceGUID,
        creatureId = source.sourceCreatureID,
        class = source.classFilename,
        me = truth(source.isLocalPlayer),
        amount = source.totalAmount,
        perSecond = source.amountPerSecond,
    }
    if attribute.kind == "rate" then
        row.value = row.perSecond or row.amount
    else
        row.value = row.amount
    end
    return row
end

-- The ranked list of one fight for one kind of figure: { selection, attribute, segmentLabel, duration, rows, total },
-- or nil and why: "missing", "disabled", "nodata". total is nil when a figure is hidden.
function Data.read(selection)
    local available, reason = Game.available()
    if not available then
        return nil, reason
    end
    local attribute = Data.attribute(selection.attribute)
    if attribute == nil then
        return nil, "missing"
    end
    local session = Game.session(selection.segment, attribute.value)
    if session == nil or type(session.combatSources) ~= "table" then
        return nil, "nodata"
    end
    local view = {
        selection = selection,
        attribute = attribute,
        segmentLabel = Data.segmentLabel(selection.segment),
        duration = session.durationSeconds,
        rows = {},
    }
    local sources = session.combatSources
    for index = 1, #sources do
        if type(sources[index]) == "table" then
            view.rows[#view.rows + 1] = makeRow(attribute, sources[index], #view.rows + 1)
        end
    end
    view.total = sumValues(view.rows)
    return view
end

-- The same, for a screen drawn every tick.
function Data.view(selection)
    return Data.cached("view|" .. Data.selectionKey(selection), 0.5, function()
        return Data.read(selection)
    end)
end

-- The row of the player, and its rank.
function Data.mine(view)
    for index, row in ipairs(view.rows) do
        if row.me then
            return row, index
        end
    end
    return nil
end

-- What identifies a row from one drawing of the screen to the next: its GUID when it can be read, else its place.
function Data.rowKey(row)
    local guid = row.guid
    if not Text.isSecret(guid) and type(guid) == "string" and guid ~= "" then
        return "row:" .. guid
    end
    return "pos:" .. row.index
end

-- What to remember of a row to find it again: the player (me), its GUID, or its place in the list.
function Data.reference(row)
    local ref = { me = row.me, index = row.index, name = row.name }
    if not Text.isSecret(row.guid) and type(row.guid) == "string" and row.guid ~= "" then
        ref.guid = row.guid
    end
    return ref
end

function Data.findRow(view, ref)
    if view == nil or ref == nil then
        return nil
    end
    if ref.me then
        return (Data.mine(view))
    end
    if ref.guid then
        for _, row in ipairs(view.rows) do
            if not Text.isSecret(row.guid) and row.guid == ref.guid then
                return row
            end
        end
        return nil
    end
    return view.rows[ref.index]
end

-- ---------------------------------------------------------------- sentences

-- The figures of one line, without units (the screen has said which kind of figure it lists): "15000", "1240 per
-- second", "28 percent". attribute decides what is said; total is the sum of the list (nil: no percent).
function Data.figures(attribute, entry, total)
    local parts = { Text.amount(entry.value) or L["hidden"] }
    if attribute.kind == "amount" then
        local perSecond = Text.amount(entry.perSecond)
        if perSecond and not (Text.isNumber(entry.perSecond) and entry.perSecond <= 0) then
            parts[#parts + 1] = Text.fill(L["%s per second"], perSecond)
        end
    end
    local percent = Text.percent(entry.value, total)
    if percent then
        parts[#parts + 1] = percent
    end
    return parts
end

-- A line of the list: the name, "you" for the player, the figures.
function Data.rowLabel(view, row)
    local parts = { row.name or L["unknown"] }
    if row.me then
        parts[#parts + 1] = L["you"]
    end
    for _, figure in ipairs(Data.figures(view.attribute, row, view.total)) do
        parts[#parts + 1] = figure
    end
    return Text.join(parts, ", ")
end

-- The figure of an entry with its unit, for a sentence: "1240 damage per second", "15000 damage, 1240 per second",
-- "3 interrupts".
function Data.phrase(attribute, entry)
    local figure = Text.amount(entry.value) or L["hidden"]
    if attribute.kind == "count" then
        local one = Text.isNumber(entry.value) and entry.value == 1
        return Text.fill(L[one and attribute.phraseOne or attribute.phrase], figure)
    end
    local phrase = Text.fill(L[attribute.phrase], figure)
    if attribute.kind == "amount" then
        local perSecond = Text.amount(entry.perSecond)
        if perSecond and not (Text.isNumber(entry.perSecond) and entry.perSecond <= 0) then
            phrase = phrase .. ", " .. Text.fill(L["%s per second"], perSecond)
        end
    end
    return phrase
end

-- Why there is no list.
function Data.reasonText(reason)
    if reason == "missing" then
        return L["The game's damage meter is not available."]
    elseif reason == "disabled" then
        return L["The game's damage meter is turned off."]
    end
    return L["Nothing to read for this fight yet."]
end

-- "Group: 54000 damage, 5 in the list, 1 minute 20 seconds, following Details." The total only where it means
-- something (not for a per-second kind) and can be read.
function Data.groupLine(selection, view)
    local parts = {}
    if view.total and view.attribute.kind ~= "rate" then
        parts[#parts + 1] = Data.phrase(view.attribute, { value = view.total })
    end
    parts[#parts + 1] = string.format(L["%d in the list"], #view.rows)
    parts[#parts + 1] = Text.duration(view.duration)
    if selection.followed then
        parts[#parts + 1] = L["following Details"]
    end
    return Text.fill(L["Group: %s"], Text.join(parts, ", ")) .. "."
end

-- "You: 1240 damage per second, second of 5" (nothing of the fight, no full stop: a piece of a longer sentence).
function Data.mineLine(view)
    local row = Data.mine(view)
    if row == nil then
        return L["You are not in this list"]
    end
    return Text.fill(L["You: %s"], Text.join({ Data.phrase(view.attribute, row), Text.rankPhrase(row.index, #view.rows) }, ", "))
end

-- What the screen says first, and what a change of fight or measure says back: which fight and which figures, then
-- your own line. "Current fight, Damage done. You: 15000 damage, 1241 per second, second of 3."
function Data.overview(selection, view, reason)
    if view == nil then
        return Data.reasonText(reason)
    end
    return Text.join({ view.segmentLabel, Data.attributeName(view.attribute) }, ", ") .. ". " .. Data.mineLine(view) .. "."
end

-- The overview of what is shown now, read afresh (what a change of fight or measure says back).
function Data.readout()
    local selection = Data.selection()
    local view, reason = Data.read(selection)
    return Data.overview(selection, view, reason)
end

-- The best of the list, when it is not you: "The best: Bob, 24000 damage, 1500 per second". nil when you are the best
-- (your rank said it) or the list is empty.
function Data.bestLine(view)
    local best = view.rows[1]
    if best == nil or best.me then
        return nil
    end
    return Text.fill(L["The best: %s"], Text.join({ best.name or L["unknown"], Data.phrase(view.attribute, best) }, ", "))
end

-- "You: 1240 damage per second, second of 5." (the fight first when it is not the current one)
function Data.mineSentence(view)
    local row = Data.mine(view)
    local line
    if row == nil then
        line = Text.join({ Data.attributeName(view.attribute), L["You are not in this list"] }, ", ")
    else
        line = Text.fill(L["You: %s"], Text.join({ Data.phrase(view.attribute, row), Text.rankPhrase(row.index, #view.rows) }, ", "))
    end
    if view.selection.segment.kind ~= "current" then
        line = view.segmentLabel .. ". " .. line
    end
    return line .. "."
end

-- What the quick key says: your line and rank, then the best when it is not you.
function Data.quickSentence(view)
    local sentence = Data.mineSentence(view)
    local best = Data.bestLine(view)
    if best then
        sentence = sentence .. " " .. best .. "."
    end
    return sentence
end

-- The first few of the list, one after the other: "Damage done. First Name, 15000. Second Name, 12000."
function Data.topSentence(view, count)
    local parts = { Data.attributeName(view.attribute) }
    if #view.rows == 0 then
        parts[#parts + 1] = L["Nobody in this list yet."]
    end
    for index = 1, math.min(count, #view.rows) do
        local row = view.rows[index]
        local figure = Text.amount(row.value) or L["hidden"]
        local name = row.name or L["unknown"]
        if row.me then
            name = name .. ", " .. L["you"]
        end
        parts[#parts + 1] = Text.ordinal(index) .. " " .. name .. ", " .. figure
    end
    local line = Text.join(parts, ". ")
    if view.selection.segment.kind ~= "current" then
        line = view.segmentLabel .. ". " .. line
    end
    return line .. "."
end

-- ------------------------------------------------------------------ one player

-- The two lines that open a player: who, where in the list, which fight; then how much.
function Data.playerHeader(view, row)
    return Text.line(
        ", ",
        row.name or L["unknown"],
        Game.className(row.class),
        Text.rankPhrase(row.index, #view.rows),
        view.segmentLabel,
        Data.attributeName(view.attribute)
    ) .. "."
end

-- How many spells and targets the lines below hold: "4 spells, 2 targets". spells: what Data.spells gave (nil: none to
-- say); targets: the list of Data.targets, nil when this kind has none or they cannot be known yet.
function Data.playerCounts(spells, targets)
    local parts = {}
    if spells ~= nil then
        parts[#parts + 1] = Text.counted(#spells.entries, "%d spell", "%d spells")
    end
    if targets ~= nil then
        parts[#parts + 1] = Text.counted(#targets, "%d target", "%d targets")
    end
    return Text.join(parts, ", ")
end

-- How much, and how much of the group; then, when given, what the lines below hold.
function Data.playerTotals(view, row, counts)
    local parts = { Data.phrase(view.attribute, row) }
    local percent = Text.percent(row.value, view.total)
    if percent then
        parts[#parts + 1] = Text.fill(L["%s of the group"], percent)
    end
    local line = Text.join(parts, ", ") .. "."
    if counts then
        line = line .. " " .. counts .. "."
    end
    return line
end

-- The spells of one player: { entries, total } or nil and why. An entry: name, figures, and what the game says of the
-- spell (a pet cast it, it can kill, it can be avoided, who cast it when it is damage taken).
function Data.spells(view, row)
    local source = Game.sourceSpells(view.selection.segment, view.attribute.value, row.guid, row.creatureId)
    if source == nil or type(source.combatSpells) ~= "table" then
        return nil, "nodata"
    end
    local list = source.combatSpells
    local entries = {}
    for index = 1, #list do
        local spell = list[index]
        if type(spell) == "table" then
            local entry = {
                id = spell.spellID,
                amount = spell.totalAmount,
                perSecond = spell.amountPerSecond,
                creature = spell.creatureName,
                deadly = truth(spell.isDeadly),
                avoidable = truth(spell.isAvoidable),
                details = spell.combatSpellDetails,
            }
            if view.attribute.kind == "rate" then
                entry.value = entry.perSecond or entry.amount
            else
                entry.value = entry.amount
            end
            entries[#entries + 1] = entry
        end
    end
    return { entries = entries, total = sumValues(entries) }
end

-- The pet that cast a spell: "pet Rex" when its name can be read. The game hides the names of every creature in combat
-- and a spell of the player's own has an empty name there too, so a hidden name cannot be told from an empty one: for a
-- hunter (whose pet is the one that matters) it is joined through the game's WrapString, which drops everything,
-- the separator included, when the name is empty; for the other classes it is left out. Returns the plain part, or
-- nothing and the hidden suffix (which carries its own separator).
local function petText(entry, class)
    local name = entry.creature
    if not name then
        return nil
    end
    if Text.isSecret(name) then
        if not Text.isSecret(class) and class == "HUNTER" then
            return nil, Game.wrapString(name, ", " .. Text.fill(L["pet %s"], ""), "")
        end
        return nil
    end
    if type(name) == "string" and name ~= "" then
        return Text.fill(L["pet %s"], name)
    end
    return nil
end

function Data.spellLabel(view, row, spells, entry)
    local parts = { Game.spellName(entry.id) or L["unknown spell"] }
    for _, figure in ipairs(Data.figures(view.attribute, entry, spells.total)) do
        parts[#parts + 1] = figure
    end
    local pet, hiddenPet = petText(entry, row.class)
    parts[#parts + 1] = pet
    local after = {}
    local details = entry.details
    if view.attribute.from and type(details) == "table" then
        local caster = Text.name(details.unitName)
        if caster then
            after[#after + 1] = Text.fill(L["from %s"], caster)
        end
    end
    if entry.deadly then
        after[#after + 1] = L["deadly"]
    end
    if entry.avoidable then
        after[#after + 1] = L["avoidable"]
    end
    local label = Text.join(parts, ", ")
    if hiddenPet then
        label = label .. hiddenPet
    end
    local rest = Text.join(after, ", ")
    if rest then
        label = label .. ", " .. rest
    end
    return label
end

-- How many enemies are looked at at most when the targets of a player are worked out (one call of the game each).
Data.MAX_ENEMIES = 40

-- The targets of a player (the enemies that took damage from it), worked out from the game's list of the damage the
-- enemies took: { { name, amount }, ... } the biggest first, or nil and why: "combat" (names are hidden then),
-- "missing", "nodata". The shape of that list is what Details reads for its own targets.
function Data.targets(view, row)
    if Game.inCombat() or not row.name or Text.isSecret(row.name) then
        return nil, "combat"
    end
    local enemyType = Game.meterType("EnemyDamageTaken")
    if enemyType == nil then
        return nil, "missing"
    end
    local segment = view.selection.segment
    local session = Game.session(segment, enemyType)
    if session == nil or type(session.combatSources) ~= "table" then
        return nil, "nodata"
    end
    local list = {}
    local sources = session.combatSources
    for index = 1, math.min(#sources, Data.MAX_ENEMIES) do
        local enemy = sources[index]
        if type(enemy) == "table" then
            local spells = Game.sourceSpells(segment, enemyType, nil, enemy.sourceCreatureID)
            local amount = 0
            if spells ~= nil and type(spells.combatSpells) == "table" then
                for position = 1, #spells.combatSpells do
                    local spell = spells.combatSpells[position]
                    local details = type(spell) == "table" and spell.combatSpellDetails or nil
                    if
                        type(details) == "table"
                        and not Text.isSecret(details.unitName)
                        and Text.name(details.unitName) == row.name
                        and Text.isNumber(spell.totalAmount)
                    then
                        amount = amount + spell.totalAmount
                    end
                end
            end
            if amount > 0 then
                list[#list + 1] = { name = Text.name(enemy.name) or L["unknown"], amount = amount }
            end
        end
    end
    table.sort(list, function(a, b)
        return a.amount > b.amount
    end)
    return list
end

-- --------------------------------------------------------------------- reset

-- What a reset takes away, in a question ("Erase 4 kept fights, ...?") or, said afterwards, in a statement.
local function scope(count, zero, one, many)
    if count == 0 then
        return L[zero]
    elseif count == 1 then
        return L[one]
    end
    return string.format(L[many], count)
end

function Data.resetQuestion()
    return scope(
        #Game.sessions(),
        "Erase the current fight and the total of all fights? This cannot be undone.",
        "Erase 1 kept fight, the current fight and the total of all fights? This cannot be undone.",
        "Erase %d kept fights, the current fight and the total of all fights? This cannot be undone."
    )
end

function Data.erasedText(count)
    return scope(
        count,
        "Data erased: the current fight and the total of all fights.",
        "Data erased: 1 kept fight, the current fight and the total of all fights.",
        "Data erased: %d kept fights, the current fight and the total of all fights."
    )
end

-- How long the game is given to forget its fights before it is looked at again.
Data.RESET_WAIT = 0.6

-- Erases the fights: Details' own reset (which also resets the game's meter) or the game's, never during a fight. What
-- was erased is said once the game has been looked at again, so it is not claimed before it is true. speak: what says
-- it. Returns whether the erasing was asked for.
function Data.reset(speak)
    local count = #Game.sessions()
    local ok, reason = Game.resetAll()
    if not ok then
        if reason == "combat" then
            speak(L["Erasing is not possible during a fight. Try again after it."])
        else
            speak(L["The damage meter cannot be erased from here."])
        end
        return false
    end
    Data.clearCache()
    Game.after(Data.RESET_WAIT, function()
        Data.clearCache()
        local left = #Game.sessions()
        if left > 0 then
            speak(Text.counted(left, "The game still keeps %d fight: the data could not be erased.", "The game still keeps %d fights: the data could not be erased."))
        else
            speak(Data.erasedText(count))
        end
    end)
    return true
end
