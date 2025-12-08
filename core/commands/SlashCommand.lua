-- SlashCommand class for defining slash commands
-- Commands can be scoped to WowVision (/wv <name>) or Global (/<name>)

local SlashCommand = WowVision.Class("SlashCommand")
SlashCommand:include(WowVision.InfoClass)

SlashCommand.info:addFields({
    { key = "name", required = true }, -- Command name (e.g., "version")
    { key = "func", required = true }, -- function(args, module) to execute
    { key = "description", default = "" }, -- Help text for the command
    { key = "scope", default = "WowVision" }, -- "WowVision" (subcommand) or "Global" (top-level)
    { key = "conflictingAddons", default = {} }, -- Addons that conflict with this command
})

function SlashCommand:initialize(config, module)
    self:setInfo(config)
    self.module = module
    self._registered = false
end

function SlashCommand:execute(args)
    self.func(args, self.module)
end

-- Check if command can be registered (no conflicting addons)
function SlashCommand:canRegister()
    local loaded = WowVision.loadedAddons
    if not loaded then
        return true
    end
    for _, addon in ipairs(self.conflictingAddons) do
        if loaded[addon] or loaded[addon:lower()] then
            return false
        end
    end
    return true
end

WowVision.SlashCommandClass = SlashCommand
