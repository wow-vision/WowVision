local module = WowVision.base.buffers:createModule("auras")
local L = module.L
module:setLabel(L["Player Auras"])

local secrets = WowVision.secrets
local graph = WowVision.graph

-- Every buff and debuff on the player at once, with no buffer to set up: a key that says them all (buffs, then
-- debuffs, each group with its number) and a short list window to walk through them, where Space reads an aura's
-- description. It adds no way of reading auras of its own. Each group is one of the Aura buffer's own buffers
-- (types/AuraBuffer.lua), made here and never registered or saved, so nothing of the player's saved buffers changes
-- and no key of theirs is taken; the buffer does the reading under every restriction the game puts on addons (the
-- secret values of Retail and WoW: Forever in combat and in instances).
--
-- Under those secrets a line can be a secret string: it can be joined with ".." and spoken, nothing else. So the
-- lines are only ever joined (secrets.join), never measured, compared, matched or formatted.

local WINDOW = "playerAuras"

-- The groups, buffs first, each the one source of its own Aura buffer.
local GROUPS = {
    { key = "buffs", source = "player:HELPFUL" },
    { key = "debuffs", source = "player:HARMFUL" },
}

-- The buffers of the open list window; nil while it is closed. They listen to the game's aura events only for as
-- long as they are held, and are read again on a timer (refreshHeld), so with the list closed this costs nothing. (The close of a fight, WindowManager:
-- closeOwnWindows, does not ask the window to close; what is left is let go of at the next opening.)
local held = nil

-- The open list reads its buffers again every REFRESH_SECONDS. The game's aura event alone is not enough: it
-- does not come in some instanced content (reported 2026-11), and the list would then show auras that are gone
-- and miss new ones for as long as it stays open. The event still brings a change in at once where it comes.
-- A read is the buffer's own (AuraBuffer:refresh); twice a second for two buffers, only while the list is open.
local REFRESH_SECONDS = 0.5
local refreshedAt = nil

local function refreshHeld()
    local now = GetTime ~= nil and GetTime() or 0
    if refreshedAt ~= nil and now - refreshedAt < REFRESH_SECONDS then
        return
    end
    refreshedAt = now
    for _, buffer in ipairs(held) do
        if buffer.refresh ~= nil then
            pcall(buffer.refresh, buffer)
        end
    end
end

-- One private Aura buffer per group, or nil when the game gives no aura reads (a client without them). The time
-- left and the dispel type are said, the description is for Space.
local function makeBuffers()
    if C_UnitAuras == nil or C_UnitAuras.GetAuraDataByIndex == nil then
        return nil
    end
    local buffers = {}
    for _, group in ipairs(GROUPS) do
        tinsert(
            buffers,
            WowVision.buffers.registry:createTemporaryComponent({
                type = "Aura",
                sources = { group.source },
                speakRemaining = true,
                speakDescription = false,
            })
        )
    end
    return buffers
end

local function release(buffers)
    for _, buffer in ipairs(buffers or {}) do
        buffer:unsubscribe()
    end
end

-- The groups as the buffers list them now: { { key, label, auras = { AuraItem... }, message = the item that says why
-- there is no aura ("Player Buffs, none"), or nil }, ... }. The label is the buffer's own, so it is what the Aura
-- buffer says.
local function readGroups(buffers)
    local groups = {}
    for index, group in ipairs(GROUPS) do
        local buffer = buffers[index]
        local auras, message = {}, nil
        for _, item in ipairs(buffer.items or {}) do
            -- an aura offers its tooltip; the message item that stands for "nothing to list" does not
            if item.getTooltipData ~= nil then
                tinsert(auras, item)
            elseif message == nil then
                message = item
            end
        end
        tinsert(groups, { key = group.key, label = buffer:getLabel(), auras = auras, message = message })
    end
    return groups
end

-- What an item says: the name, stacks, time left and dispel type. A secret string is passed on as it is; a failed
-- read says "unavailable".
local function lineOf(item)
    local ok, text = pcall(item.getFocusString, item)
    if not ok or not text then
        return L["unavailable"]
    end
    return text
end

local function numberOf(group, count)
    return string.format(L["%s: %s"], group.label, count)
end

-- "Player Buffs: 4. Player Debuffs: 1."
local function countText(groups)
    local parts = {}
    for _, group in ipairs(groups) do
        tinsert(parts, numberOf(group, #group.auras))
    end
    return secrets.join(parts, ". ") .. "."
end

-- Every group by its number, then its auras one after the other; a group with none says what its buffer says.
local function allText(groups)
    local parts = {}
    for _, group in ipairs(groups) do
        if #group.auras > 0 then
            tinsert(parts, numberOf(group, #group.auras))
            for _, item in ipairs(group.auras) do
                tinsert(parts, lineOf(item))
            end
        elseif group.message ~= nil then
            tinsert(parts, lineOf(group.message))
        else
            tinsert(parts, numberOf(group, 0))
        end
    end
    return secrets.join(parts, ". ")
end

-- Say them all (or only the numbers). The buffers are made for the read and let go of at once: the game is asked
-- afresh at every press.
local function say(onlyNumbers)
    local buffers = makeBuffers()
    if buffers == nil then
        -- why nothing happened is a message of the addon, not a reading
        WowVision:notify(L["Auras are not available."])
        return
    end
    local groups = readGroups(buffers)
    release(buffers)
    WowVision:speak(onlyNumbers and countText(groups) or allText(groups))
end

-- ---- the list window

-- One aura: its line is read when the focus lands on it (the time left changes every second, so it is not watched:
-- it would be said again each time it ticked), and Space reads its tooltip, description included.
local function auraNode(item)
    local vtable = graph.nodes.text({
        label = function()
            return lineOf(item)
        end,
        live = false,
    })
    vtable.tooltip = item:getTooltipData()
    return vtable
end

-- Two tab stops, the buffs and the debuffs. The buffers keep their lists current (they rebuild when the game says the
-- player's auras changed, and on the timer of refreshHeld where it does not say so), so the screen only reads them. An aura's name can be a secret and cannot key a table, so
-- an aura's id is its place in its group, as the Aura buffer's items are places too.
local function render(builder)
    if held == nil then
        return -- adding no nodes closes the screen
    end
    refreshHeld()
    local ControlId = graph.ControlId
    for _, group in ipairs(readGroups(held)) do
        local stop = "auras:" .. group.key
        builder:beginStop(stop)
        builder:pushContext(stop, group.label)
        if #group.auras == 0 then
            local message = group.message
            builder:addItem(
                ControlId.structural(stop .. ":none"),
                graph.nodes.text({
                    label = function()
                        if message ~= nil then
                            return lineOf(message)
                        end
                        return numberOf(group, 0)
                    end,
                })
            )
        else
            for index, item in ipairs(group.auras) do
                builder:addItem(ControlId.structural(stop .. ":" .. index), auraNode(item))
            end
        end
        builder:popContext()
    end
end

local function closeList()
    release(held)
    held = nil
    refreshedAt = nil
    WowVision.UIHost:closeWindow(WINDOW)
end

-- Opens the list, or, when it is already open, gives it fresh buffers.
local function openList()
    release(held)
    held = nil
    local buffers = makeBuffers()
    if buffers == nil then
        WowVision:notify(L["Auras are not available."])
        return
    end
    held = buffers
    -- just made, so just read: the first read on the timer comes one interval from now
    refreshedAt = GetTime ~= nil and GetTime() or 0
    WowVision.UIHost:openWindow(WINDOW)
end

-- A frameless window: the game cannot close it for us, so the screen holds Escape (captureClose). Every way the
-- window is asked to close (Escape, Close All Windows, /wv close) comes here, and the buffers are let go of.
module:registerWindow({
    type = "ManualWindow",
    name = WINDOW,
    graphScreen = { render = render, captureClose = true, onRequestClose = closeList },
})

module:registerBinding({
    type = "Function",
    key = "auras/say",
    label = L["Speak Player Auras"],
    inputs = { "ALT-CTRL-B" },
    interruptSpeech = true,
    func = function()
        say(false)
    end,
})

module:registerBinding({
    type = "Function",
    key = "auras/open",
    label = L["Player Auras"],
    opensWindow = true,
    inputs = { "ALT-SHIFT-B" },
    interruptSpeech = true,
    func = openList,
})

-- /wv auras opens the list, /wv auras say says every aura, /wv auras count says the numbers.
module:registerCommand({
    name = "auras",
    scope = "WowVision",
    description = "Player auras: opens the list; 'say' says every buff and debuff, 'count' only how many there are",
    func = function(args)
        local word = (args or ""):lower():match("^%s*(%S+)")
        if word == "say" then
            say(false)
        elseif word == "count" then
            say(true)
        else
            openList()
        end
    end,
})
