-- SlashCommandManager handles registration and dispatch of slash commands
-- Supports both WowVision subcommands (/wv <name>) and global commands (/<name>)

local SlashCommandManager = WowVision.Class("SlashCommandManager")

function SlashCommandManager:initialize()
    -- Commands scoped to WowVision (/wv <name>)
    self.wowvisionCommands = {}
    -- Commands scoped globally (/<name>)
    self.globalCommands = {}
    -- Track global command handles for unregistration
    self.globalHandles = {}
end

-- Create a SlashCommand instance from config
function SlashCommandManager:createCommand(config, module)
    return WowVision.SlashCommandClass:new(config, module)
end

-- Register a command (called when module is enabled)
function SlashCommandManager:registerCommand(command)
    if not command:canRegister() then
        return false
    end

    local name = command.name:lower()

    if command.scope == "WowVision" then
        self.wowvisionCommands[name] = command
    elseif command.scope == "Global" then
        self.globalCommands[name] = command
        -- Register with WoW's slash command system
        self:_registerGlobalCommand(command)
    end

    command._registered = true
    return true
end

-- Unregister a command (called when module is disabled)
function SlashCommandManager:unregisterCommand(command)
    if not command._registered then
        return
    end

    local name = command.name:lower()

    if command.scope == "WowVision" then
        self.wowvisionCommands[name] = nil
    elseif command.scope == "Global" then
        self.globalCommands[name] = nil
        self:_unregisterGlobalCommand(command)
    end

    command._registered = false
end

-- Register a global command with WoW's slash command system
function SlashCommandManager:_registerGlobalCommand(command)
    local name = command.name:upper()
    local slashName = "SLASH_WOWVISION_" .. name .. "1"

    -- Set the slash command text
    _G[slashName] = "/" .. command.name:lower()

    -- Create the handler
    SlashCmdList["WOWVISION_" .. name] = function(msg)
        command:execute(msg)
    end

    self.globalHandles[command.name:lower()] = name
end

-- Unregister a global command from WoW's slash command system
function SlashCommandManager:_unregisterGlobalCommand(command)
    local name = self.globalHandles[command.name:lower()]
    if name then
        SlashCmdList["WOWVISION_" .. name] = nil
        self.globalHandles[command.name:lower()] = nil
    end
end

-- Dispatch a WowVision subcommand (/wv <name> <args>)
-- Returns true if a command was found and executed
function SlashCommandManager:dispatch(msg)
    -- Parse command name and args
    local name, args = msg:match("^(%S+)%s*(.*)$")

    if not name then
        -- No command specified, return false to let caller handle default
        return false
    end

    name = name:lower()
    local command = self.wowvisionCommands[name]

    if command then
        command:execute(args)
        return true
    end

    return false
end

-- Get a command by name (for help, etc.)
function SlashCommandManager:getCommand(name, scope)
    name = name:lower()
    if scope == "Global" then
        return self.globalCommands[name]
    else
        return self.wowvisionCommands[name]
    end
end

-- List all registered commands
function SlashCommandManager:listCommands(scope)
    local commands = {}
    local source = scope == "Global" and self.globalCommands or self.wowvisionCommands

    for name, command in pairs(source) do
        tinsert(commands, command)
    end

    return commands
end

WowVision.SlashCommandManager = SlashCommandManager:new()
