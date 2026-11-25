-- The loot browser's module: optional (OptionalDeps in WowVision_Camelot.toc), only with AtlasLootClassic or
-- AtlasLootContinued installed. Alt+L or /wv atlasloot opens or closes the screen, and it opens with AtlasLoot's own
-- window (/al) too, closing that window with it.
local loaded = WowVision.loadedAddons
if
    loaded == nil
    or not (
        loaded["AtlasLootClassic"]
        or loaded["atlaslootclassic"]
        or loaded["AtlasLootContinued"]
        or loaded["atlaslootcontinued"]
    )
then
    return
end

local ns = WowVision.atlasLoot
local L = ns.L
local Game = ns.Game
local Loot = ns.Loot
local Screen = ns.Screen

local module = WowVision.base.windows:createModule("atlasLoot")
module:setLabel(L["AtlasLoot"])
ns.module = module

-- Settings ----------------------------------------------------------------------

local settings = module:hasSettings()
local defaults = Game.defaults
settings:add({ type = "Bool", key = "classFilter", label = L["Only what my class can use"], default = defaults.classFilter })
settings:add({ type = "Bool", key = "levelFilter", label = L["Only what my level allows"], default = defaults.levelFilter })
settings:add({
    type = "Bool",
    key = "upgradesOnly",
    label = L["Only upgrades"],
    default = defaults.upgradesOnly,
})
settings:add({
    type = "Choice",
    key = "measure",
    label = L["Judge of upgrades"],
    default = defaults.measure,
    choices = Loot.measureChoices(),
})
settings:add({
    type = "Choice",
    key = "sort",
    label = L["Sort"],
    default = defaults.sort,
    choices = Loot.sortChoices(),
})
settings:add({
    type = "Bool",
    key = "openWithAl",
    label = L["Open with AtlasLoot's window (/al)"],
    default = defaults.openWithAl,
})
ns.settings = module.settings

-- Opening and closing ------------------------------------------------------------

-- Whether AtlasLoot's window opened the screen: closing the screen then closes that window too.
ns.openedByAl = false

function ns.toggle()
    ns.hookAtlasFrame()
    if Game.isOpen() then
        Screen.close()
        return
    end
    if Game.atlas() == nil then
        Game.speak(L["AtlasLoot is not installed or not enabled."])
        return
    end
    ns.openedByAl = false
    Screen.open()
end

function ns.afterClose()
    if not ns.openedByAl then
        return
    end
    ns.openedByAl = false
    local frame = Game.atlasFrame()
    if frame ~= nil and type(frame.IsShown) == "function" and frame:IsShown() then
        pcall(frame.Hide, frame)
    end
end

-- AtlasLoot's window is built a little after AtlasLoot is read, so this is tried again at the events below.
function ns.hookAtlasFrame()
    local frame = Game.atlasFrame()
    if frame == nil or ns.frameHooked or type(frame.HookScript) ~= "function" then
        return false
    end
    frame:HookScript(
        "OnShow",
        Game.guarded(function()
            if not module:getEnabled() or module.settings.openWithAl ~= true or Game.isOpen() or Game.atlas() == nil then
                return
            end
            ns.openedByAl = true
            Screen.open()
        end)
    )
    frame:HookScript(
        "OnHide",
        Game.guarded(function()
            if ns.openedByAl and Game.isOpen() then
                ns.openedByAl = false
                Game.close()
            end
        end)
    )
    ns.frameHooked = true
    return true
end

-- Events ------------------------------------------------------------------------

module:registerEvent("event", "PLAYER_ENTERING_WORLD")
module:registerEvent("event", "ADDON_LOADED")
module:registerEvent("event", "PLAYER_EQUIPMENT_CHANGED")
module:registerEvent("event", "PLAYER_LEVEL_UP")
module:registerEvent("event", "GET_ITEM_INFO_RECEIVED")

function module:onEvent(event, itemId, success)
    if event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_LEVEL_UP" then
        -- what is an upgrade depends on what is worn, and what a class can wear depends on its level
        Game.gearChanged()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- an item the server does not know never gets a name: the search must not wait for it
        Game.itemReceived(itemId, success)
    else
        ns.hookAtlasFrame()
    end
end

function module:onEnable()
    ns.hookAtlasFrame()
end

-- The key and the command -----------------------------------------------------------

module:registerBinding({
    type = "Function",
    key = "atlasLoot/open",
    label = L["Open the loot browser (AtlasLoot)"],
    inputs = { "ALT-L" },
    interruptSpeech = true,
    func = function()
        ns.toggle()
    end,
})

module:registerCommand({
    name = "atlasloot",
    description = L["Open or close the AtlasLoot loot browser."],
    func = function()
        ns.toggle()
    end,
})
