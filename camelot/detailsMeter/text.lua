-- The words: how a number, a duration, a rank and a sentence are said. Nothing here touches the game, except asking it
-- whether a value is a hidden (secret) one.
--
-- On WoW: Forever the game hides some values from addons (in combat and in instances): a hidden value can be joined
-- to a text with ".." and handed to the speech, and nothing else: no comparison (not even with nil), no calculation, no
-- measure, no pattern. So every function that may be given one tests it first, and a sentence that may hold one is
-- built by joining (Text.fill, Text.join), never by string.format or table.concat.
local ns = WowVision.detailsMeter
local L = ns.L

local Text = {}
ns.Text = Text

-- Whether the game hides this value from addons.
function Text.isSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value) == true
end

-- Whether this is a number that can be read (not hidden, not a hole of the arithmetic).
function Text.isNumber(value)
    return not Text.isSecret(value) and type(value) == "number" and value == value
end

-- The decimal separator of the language.
function Text.separator()
    if ns.locale == "frFR" or ns.locale == "deDE" then
        return ","
    end
    return "."
end

-- "%s" of a template replaced by a text that may be a hidden one (string.format cannot take it, ".." can).
function Text.fill(template, value)
    local first, last = template:find("%s", 1, true)
    if first == nil then
        return template
    end
    return template:sub(1, first - 1) .. value .. template:sub(last + 1)
end

-- The parts joined by the separator, the empty ones (nil) left out; a part may be hidden.
function Text.join(parts, separator)
    local result
    for index = 1, #parts do
        local part = parts[index]
        if part then
            if result then
                result = result .. separator .. part
            else
                result = part
            end
        end
    end
    return result
end

-- The same for parts given one by one: any of them may be nil, a hole in the middle included.
function Text.line(separator, ...)
    local result
    for index = 1, select("#", ...) do
        local part = select(index, ...)
        if part then
            if result then
                result = result .. separator .. part
            else
                result = part
            end
        end
    end
    return result
end

-- A count with its word: "1 second", "20 seconds".
function Text.counted(count, one, many)
    return string.format(count == 1 and L[one] or L[many], count)
end

-- A number between 1 million and 1 thousand million: "12,3 millions". Singular for exactly one (and, in French, for
-- anything under two).
local function scaled(value, one, many)
    local tenths = math.floor(value * 10 + 0.5)
    local whole = math.floor(tenths / 10)
    local text = string.format("%d", whole)
    if tenths % 10 ~= 0 then
        text = text .. Text.separator() .. string.format("%d", tenths % 10)
    end
    local singular = tenths == 10 or (ns.locale == "frFR" and tenths < 20)
    return string.format(singular and L[one] or L[many], text)
end

-- A number as it is best heard: whole up to a million ("1240" is read "mille deux cent quarante" by every voice),
-- then "1,5 million", then "2 milliards". nil when it is not a number that can be read.
function Text.number(value)
    if not Text.isNumber(value) then
        return nil
    end
    local sign = ""
    if value < 0 then
        sign = "-"
        value = -value
    end
    if value >= 1e9 then
        return sign .. scaled(value / 1e9, "%s billion", "%s billions")
    elseif value >= 1e6 then
        return sign .. scaled(value / 1e6, "%s million", "%s millions")
    end
    local whole = math.floor(value + 0.5)
    if whole == 0 and value > 0 then
        return L["less than one"]
    end
    return sign .. string.format("%d", whole)
end

-- A hidden number as digits: the game's own formatting takes it; failing that, joining it to a text does. nil when
-- neither works.
function Text.hiddenNumber(value)
    local ok, text = pcall(string.format, "%.0f", value)
    if ok and text then
        return text
    end
    ok, text = pcall(function()
        return "" .. value
    end)
    if ok and text then
        return text
    end
    return nil
end

-- A number of the game, readable or hidden, as speech; nil when there is nothing to say.
function Text.amount(value)
    if not value then
        return nil
    end
    if Text.isSecret(value) then
        return Text.hiddenNumber(value)
    end
    return Text.number(value)
end

-- A duration: "1 hour 3 minutes", "45 seconds". nil when it is not a number that can be read.
function Text.duration(seconds)
    if not Text.isNumber(seconds) then
        return nil
    end
    local total = math.floor(seconds + 0.5)
    if total < 0 then
        total = 0
    end
    local hours = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)
    local rest = total % 60
    local parts = {}
    if hours > 0 then
        parts[#parts + 1] = Text.counted(hours, "%d hour", "%d hours")
    end
    if minutes > 0 then
        parts[#parts + 1] = Text.counted(minutes, "%d minute", "%d minutes")
    end
    if rest > 0 or #parts == 0 then
        parts[#parts + 1] = Text.counted(rest, "%d second", "%d seconds")
    end
    return table.concat(parts, " ")
end

-- "28 percent": the part of the whole, when both can be read.
function Text.percent(part, whole)
    if not Text.isNumber(part) or not Text.isNumber(whole) or whole <= 0 then
        return nil
    end
    return string.format(L["%d percent"], math.floor(part / whole * 100 + 0.5))
end

-- The rank in words, up to ten: "second"; beyond, "number 12".
function Text.ordinal(rank)
    if rank >= 1 and rank <= 10 then
        return L["ordinal " .. math.floor(rank)]
    end
    return string.format(L["number %d"], rank)
end

-- "second of 5".
function Text.rankPhrase(rank, count)
    return string.format(L["%s of %d"], Text.ordinal(rank), count)
end

-- A player's name as it is said: without the realm ("Name-Realm" is "Name"); a hidden name goes through as it is; nil
-- when there is no name to say.
function Text.name(name)
    if not name then
        return nil
    end
    if Text.isSecret(name) then
        return name
    end
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local base = name:match("^(%S+)%-%S+$")
    return base or name
end

-- A word as the commands compare it: lower case, without accents.
local ACCENTS = {
    ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e", ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["ô"] = "o",
    ["ö"] = "o", ["û"] = "u", ["ù"] = "u", ["ü"] = "u", ["î"] = "i", ["ï"] = "i", ["ç"] = "c", ["ß"] = "ss",
    ["É"] = "e", ["È"] = "e", ["À"] = "a", ["Ä"] = "a", ["Ö"] = "o", ["Ü"] = "u", ["Ç"] = "c",
}
function Text.fold(word)
    word = tostring(word or ""):gsub("[\195][\128-\191]", function(letter)
        return ACCENTS[letter] or letter
    end)
    return (word:lower())
end
