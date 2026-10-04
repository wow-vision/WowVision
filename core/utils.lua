local utils = {}

function utils.splitString(str, delim)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delim, from, true)
    while delim_from do
        tinsert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim, from, true)
    end
    tinsert(result, string.sub(str, from))
    return result
end

-- Lowercase for case-insensitive matching. Lua's lower() only folds ASCII,
-- so on its own a capital umlaut or accented capital never matches its
-- small form ("Öl" against "öl"). This also folds the accented Latin
-- capitals of German and French, which UTF-8 writes as two bytes:
--   U+00C0..U+00DE (lead byte 195, second byte 128..158) -> second byte + 32
--     (not U+00D7, the multiplication sign)
--   U+0152 OE ligature and U+0178 Y with diaeresis
-- Accents are kept: "ö" does not match "o". Strings without those bytes,
-- which is nearly every English name, take the plain lower() path only.
local function foldLatin1(second)
    if second == "\151" then
        return nil
    end
    return "\195" .. string.char(string.byte(second) + 32)
end

function utils.foldCase(text)
    local lowered = string.lower(text)
    if string.find(lowered, "\195", 1, true) ~= nil then
        lowered = string.gsub(lowered, "\195([\128-\158])", foldLatin1)
    end
    if string.find(lowered, "\197", 1, true) ~= nil then
        lowered = string.gsub(lowered, "\197\146", "\197\147")
        lowered = string.gsub(lowered, "\197\184", "\195\191")
    end
    return lowered
end

WowVision.utils = utils
