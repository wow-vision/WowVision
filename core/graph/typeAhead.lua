local graph = WowVision.graph

-- Letter navigation (type-ahead) in lists that own the keyboard (the WowVision menu, context and dropdown menus; see
-- Host.lua): a letter moves focus to the next entry of the current list whose label starts with it, the same letter
-- again to the one after, wrapping at the end; the same letter repeated keeps cycling. Two different letters within
-- TIMEOUT of each other filter the list, as Sku's menu does (Host.lua, Builder:_applyListFilter): only the entries
-- containing the text stay, under a "Filter: text" line, and further letters add to it. A list that cannot be filtered
-- (a row, raw nodes) searches for the typed start instead ("go" finds "Goldshire"). Pure Lua: the headless suite tests
-- it.
local typeAhead = {}
graph.typeAhead = typeAhead

typeAhead.TIMEOUT = 0.5   -- seconds between two letters of one search text

-- Accented letters folded to their base letter, so "u" finds "Übersicht" (no umlaut key is needed). A typed umlaut
-- stays what it is and finds that umlaut only (typed, matcher). UTF-8, lower and upper case.
local FOLD = {
    ["ä"] = "a", ["Ä"] = "a", ["à"] = "a", ["À"] = "a", ["á"] = "a", ["Á"] = "a", ["â"] = "a", ["Â"] = "a",
    ["ã"] = "a", ["Ã"] = "a", ["å"] = "a", ["Å"] = "a", ["æ"] = "ae", ["Æ"] = "ae",
    ["ç"] = "c", ["Ç"] = "c",
    ["è"] = "e", ["È"] = "e", ["é"] = "e", ["É"] = "e", ["ê"] = "e", ["Ê"] = "e", ["ë"] = "e", ["Ë"] = "e",
    ["ì"] = "i", ["Ì"] = "i", ["í"] = "i", ["Í"] = "i", ["î"] = "i", ["Î"] = "i", ["ï"] = "i", ["Ï"] = "i",
    ["ñ"] = "n", ["Ñ"] = "n",
    ["ö"] = "o", ["Ö"] = "o", ["ò"] = "o", ["Ò"] = "o", ["ó"] = "o", ["Ó"] = "o", ["ô"] = "o", ["Ô"] = "o",
    ["õ"] = "o", ["Õ"] = "o", ["ø"] = "o", ["Ø"] = "o", ["œ"] = "oe", ["Œ"] = "oe",
    ["ü"] = "u", ["Ü"] = "u", ["ù"] = "u", ["Ù"] = "u", ["ú"] = "u", ["Ú"] = "u", ["û"] = "u", ["Û"] = "u",
    ["ý"] = "y", ["Ý"] = "y", ["ÿ"] = "y",
    ["ß"] = "ss",
}

-- Lower case without accents; other multibyte characters stay as they are.
function typeAhead.fold(text)
    text = text:gsub("[\192-\244][\128-\191]*", function(char)
        return FOLD[char] or char
    end)
    return text:lower()
end

local UMLAUTS = { ["Ä"] = "ä", ["Ö"] = "ö", ["Ü"] = "ü", ["ä"] = "ä", ["ö"] = "ö", ["ü"] = "ü", ["ß"] = "ß" }

-- Lower case that keeps the umlauts and ß, other accents folded: the text a player types.
function typeAhead.typed(text)
    text = text:gsub("[\192-\244][\128-\191]*", function(char)
        return UMLAUTS[char] or FOLD[char] or char
    end)
    return (text:gsub("[A-Z]", string.lower))
end

-- A label the game keeps secret (a hidden name in a dungeon) cannot be
-- searched: it matches nothing, typing never throws on it.
local function labelText(label, normal)
    if type(label) ~= "string" or WowVision.secrets.isSecret(label) then
        return ""
    end
    local text = label:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", "")
        :gsub("|n", " ")
    text = normal(text)
    local start = text:find("[%a\128-\255]")
    return start ~= nil and text:sub(start) or ""
end

-- What a label is matched by: the spoken text without the game's escape codes (colours |cAARRGGBB..|r, textures
-- |T..|t, atlases |A..|a, line breaks |n), folded, from its first letter on (leading punctuation, numbers and
-- spaces do not count).
function typeAhead.matchText(label)
    return labelText(label, typeAhead.fold)
end

-- The same with the umlauts kept: what a typed text containing an umlaut is compared with.
function typeAhead.exactText(label)
    return labelText(label, typeAhead.typed)
end

-- How labels are read for a typed text: "u" finds U and Ü, "ü" only Ü.
function typeAhead.matcher(text)
    return text:find("[\128-\255]") ~= nil and typeAhead.exactText or typeAhead.matchText
end

-- The typed search: feed(state, letter, now) returns the text to search for. A letter after a pause starts a new
-- text; letters within TIMEOUT add to it; a text of one letter repeated searches that letter alone (cycling).
-- Returns the search text and whether it is a cycle (the next match after the current entry) or a growing text (the
-- current entry still counts).
function typeAhead.newState()
    return { text = "", at = nil }
end

function typeAhead.feed(state, letter, now)
    letter = typeAhead.typed(letter)
    if state.at ~= nil and now - state.at < typeAhead.TIMEOUT and state.text ~= "" then
        state.text = state.text .. letter
    else
        state.text = letter
    end
    state.at = now
    local first = state.text:sub(1, #letter)
    if state.text == first:rep(math.floor(#state.text / #letter)) then
        return letter, true
    end
    return state.text, false
end

-- Whether a filter text occurs anywhere in a label (a match text, see matchText): how a filtered list keeps an entry.
function typeAhead.contains(label, text)
    return text ~= "" and label:find(text, 1, true) ~= nil
end

-- The entry to go to: index into labels (match texts, see matchText), searching from the entry after current
-- (cycle) or from current itself (a growing text), wrapping around. nil when no entry starts with text.
function typeAhead.find(labels, current, text, cycle)
    local count = #labels
    if count == 0 or text == "" then
        return nil
    end
    current = current or 0
    local first = cycle and 1 or 0
    for step = first, count - 1 + first do
        local index = (current - 1 + step) % count + 1
        if labels[index]:sub(1, #text) == text then
            return index
        end
    end
    return nil
end
