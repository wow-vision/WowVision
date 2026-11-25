-- The RestedXP leveling guide (third-party addon RXPGuides) with WowVision (module.lua): its window, arrow and menus
-- are drawn for the mouse and the eyes. source.lua reads what it shows, menu.lua and options.lua its menus and
-- settings, guidance.lua leads to the arrow's destination with WowVision's beacon or routes, import.lua drives its
-- guide importer, screens.lua draws the screens. None of RestedXP's code is copied and its files are not changed.
local ns = { L = WowVision:getLocale() }
WowVision.restedXP = ns

-- The screens time their work through this; WowVision's own profiler measures modules.
ns.Perf = {
    time = function(_, fn, ...)
        return fn(...)
    end,
}
