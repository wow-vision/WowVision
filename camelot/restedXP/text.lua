-- What is said, as plain functions: display text turned into speech, where something lies relative to the player,
-- how far, and how a step or the arrow reads. No game calls here; the tests run them as they are.
local ns = WowVision.restedXP
local L = ns.L

local Text = {}
ns.Text = Text

-- Display text as speech: colour codes (the hex form, the named |cn...: form and RestedXP's own |cRXP_...
-- tokens), textures, atlas icons and hyperlink wrappers out (a link keeps the text it shows), the "::id" suffix
-- RestedXP puts after creature names, whitespace collapsed. nil when nothing is left.
function Text.plain(value)
    if value == nil then
        return nil
    end
    local text = tostring(value)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|cn[^:|]+:", "")
    text = text:gsub("|cRXP_%u+_", "")
    text = text:gsub("|r", "")
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|A.-|a", "")
    text = text:gsub("|H.-|h", "")
    text = text:gsub("|h", "")
    text = text:gsub("|n", " ")
    text = text:gsub("::%d+", "")
    text = text:gsub("[%s]+", " ")
    text = text:match("^%s*(.-)%s*$")
    if text == "" then
        return nil
    end
    return text
end

-- "35 mètres" ("yards" in English: the French game calls its distance unit mètres).
function Text.yards(distance)
    local count = math.floor((distance or 0) + 0.5)
    if count == 1 then
        return L["1 yard"]
    end
    return string.format(L["%d yards"], count)
end

-- Where something lies, from the player's bearing to it and the way the player faces (both in radians, counter
-- clockwise from north: HereBeDragons' angle and GetPlayerFacing). The result is in degrees, 0 straight ahead,
-- positive to the right, from -180 to 180. RestedXP turns its arrow by angle - facing, counter clockwise.
function Text.relativeDegrees(angle, facing)
    local degrees = -math.deg(angle - facing)
    degrees = degrees % 360
    if degrees > 180 then
        degrees = degrees - 360
    end
    return degrees
end

-- "devant vous", "à 2 heures, à droite", "derrière vous": the clock position plus the side, for a bearing
-- from Text.relativeDegrees.
function Text.direction(degrees)
    local size = math.abs(degrees)
    if size < 15 then
        return L["ahead of you"]
    end
    if size > 165 then
        return L["behind you"]
    end
    local hour = math.floor(size / 30 + 0.5)
    if hour < 1 then
        hour = 1
    elseif hour > 5 then
        hour = 5
    end
    if degrees > 0 then
        return string.format(L["at %d o'clock, to your right"], hour)
    end
    return string.format(L["at %d o'clock, to your left"], 12 - hour)
end

-- One step as it is read: its title, then its lines. A line that is done says so. lines are { text, done }.
function Text.step(title, lines)
    local parts = {}
    if title ~= nil and title ~= "" then
        tinsert(parts, title)
    end
    for _, line in ipairs(lines) do
        if line.done then
            tinsert(parts, line.text .. ", " .. L["done"])
        else
            tinsert(parts, line.text)
        end
    end
    return table.concat(parts, ". ")
end

-- What the arrow says. arrow is { title, distance, degrees, otherContinent, none } (see Source.arrow).
function Text.arrow(arrow)
    if arrow == nil or arrow.none then
        return L["No destination in the guide right now."]
    end
    local parts = {}
    if arrow.title ~= nil then
        tinsert(parts, arrow.title)
    end
    if arrow.otherContinent then
        tinsert(parts, L["on another continent"])
    else
        if arrow.degrees ~= nil then
            tinsert(parts, Text.direction(arrow.degrees))
        end
        if arrow.distance ~= nil then
            tinsert(parts, Text.yards(arrow.distance))
        end
    end
    if #parts == 0 then
        return L["Destination unknown."]
    end
    return table.concat(parts, ", ")
end
