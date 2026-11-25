-- Name sources: fills in the names Questie's database lacks in the game's language (creatures, the titles under their
-- names, world objects), so WowNav's lists, the scanner and Questie's tooltips read them. names.lua walks the database
-- and decides, sources.lua holds the outside dictionaries, module.lua applies the rows through the database's public
-- correction layer.
WowVision.nameSources = { L = WowVision:getLocale() }
