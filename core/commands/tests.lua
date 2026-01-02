local testRunner = WowVision.testing.testRunner

testRunner:addSuite("SlashCommand", {
    ["initialize sets name and func"] = function(t)
        local called = false
        local cmd = WowVision.SlashCommandClass:new({
            name = "test",
            func = function() called = true end,
        })
        t:assertEqual(cmd.name, "test")
        t:assertNotNil(cmd.func)
    end,

    ["execute calls func with args"] = function(t)
        local receivedArgs = nil
        local cmd = WowVision.SlashCommandClass:new({
            name = "test",
            func = function(args) receivedArgs = args end,
        })
        cmd:execute("hello world")
        t:assertEqual(receivedArgs, "hello world")
    end,

    ["execute passes module to func"] = function(t)
        local receivedModule = nil
        local testModule = { name = "TestModule" }
        local cmd = WowVision.SlashCommandClass:new({
            name = "test",
            func = function(args, module) receivedModule = module end,
        }, testModule)
        cmd:execute("")
        t:assertEqual(receivedModule, testModule)
    end,

    ["scope defaults to WowVision"] = function(t)
        local cmd = WowVision.SlashCommandClass:new({
            name = "test",
            func = function() end,
        })
        t:assertEqual(cmd.scope, "WowVision")
    end,

    ["canRegister returns true with no conflicts"] = function(t)
        local cmd = WowVision.SlashCommandClass:new({
            name = "test",
            func = function() end,
            conflictingAddons = {},
        })
        t:assertTrue(cmd:canRegister())
    end,

    ["canRegister returns true when loadedAddons is nil"] = function(t)
        local oldLoaded = WowVision.loadedAddons
        WowVision.loadedAddons = nil
        local cmd = WowVision.SlashCommandClass:new({
            name = "test",
            func = function() end,
            conflictingAddons = { "SomeAddon" },
        })
        t:assertTrue(cmd:canRegister())
        WowVision.loadedAddons = oldLoaded
    end,

    ["canRegister returns false when conflicting addon loaded"] = function(t)
        local oldLoaded = WowVision.loadedAddons
        WowVision.loadedAddons = { ConflictAddon = true }
        local cmd = WowVision.SlashCommandClass:new({
            name = "test",
            func = function() end,
            conflictingAddons = { "ConflictAddon" },
        })
        t:assertFalse(cmd:canRegister())
        WowVision.loadedAddons = oldLoaded
    end,

    ["canRegister checks lowercase addon names"] = function(t)
        local oldLoaded = WowVision.loadedAddons
        WowVision.loadedAddons = { conflictaddon = true }
        local cmd = WowVision.SlashCommandClass:new({
            name = "test",
            func = function() end,
            conflictingAddons = { "ConflictAddon" },
        })
        t:assertFalse(cmd:canRegister())
        WowVision.loadedAddons = oldLoaded
    end,
})

testRunner:addSuite("SlashCommandManager", {
    ["createCommand returns SlashCommand instance"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local cmd = manager:createCommand({
            name = "test",
            func = function() end,
        })
        t:assertNotNil(cmd)
        t:assertEqual(cmd.name, "test")
    end,

    ["registerCommand adds WowVision command"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local cmd = manager:createCommand({
            name = "mytest",
            func = function() end,
            scope = "WowVision",
        })
        local result = manager:registerCommand(cmd)
        t:assertTrue(result)
        t:assertNotNil(manager.wowvisionCommands["mytest"])
    end,

    ["registerCommand sets _registered flag"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local cmd = manager:createCommand({
            name = "test",
            func = function() end,
        })
        t:assertFalse(cmd._registered)
        manager:registerCommand(cmd)
        t:assertTrue(cmd._registered)
    end,

    ["registerCommand returns false for conflicting addon"] = function(t)
        local oldLoaded = WowVision.loadedAddons
        WowVision.loadedAddons = { ConflictAddon = true }
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local cmd = manager:createCommand({
            name = "test",
            func = function() end,
            conflictingAddons = { "ConflictAddon" },
        })
        local result = manager:registerCommand(cmd)
        t:assertFalse(result)
        WowVision.loadedAddons = oldLoaded
    end,

    ["unregisterCommand removes command"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local cmd = manager:createCommand({
            name = "test",
            func = function() end,
        })
        manager:registerCommand(cmd)
        t:assertNotNil(manager.wowvisionCommands["test"])
        manager:unregisterCommand(cmd)
        t:assertNil(manager.wowvisionCommands["test"])
        t:assertFalse(cmd._registered)
    end,

    ["dispatch executes matching command"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local called = false
        local cmd = manager:createCommand({
            name = "test",
            func = function() called = true end,
        })
        manager:registerCommand(cmd)
        local result = manager:dispatch("test")
        t:assertTrue(result)
        t:assertTrue(called)
    end,

    ["dispatch passes args to command"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local receivedArgs = nil
        local cmd = manager:createCommand({
            name = "test",
            func = function(args) receivedArgs = args end,
        })
        manager:registerCommand(cmd)
        manager:dispatch("test hello world")
        t:assertEqual(receivedArgs, "hello world")
    end,

    ["dispatch returns false for unknown command"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local result = manager:dispatch("unknown")
        t:assertFalse(result)
    end,

    ["dispatch returns false for empty message"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local result = manager:dispatch("")
        t:assertFalse(result)
    end,

    ["dispatch is case insensitive"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local called = false
        local cmd = manager:createCommand({
            name = "Test",
            func = function() called = true end,
        })
        manager:registerCommand(cmd)
        local result = manager:dispatch("TEST")
        t:assertTrue(result)
        t:assertTrue(called)
    end,

    ["getCommand returns command by name"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        local cmd = manager:createCommand({
            name = "test",
            func = function() end,
        })
        manager:registerCommand(cmd)
        local found = manager:getCommand("test")
        t:assertEqual(found, cmd)
    end,

    ["listCommands returns all commands"] = function(t)
        local manager = WowVision.Class("TestManager", WowVision.SlashCommandManager.class):new()
        manager:registerCommand(manager:createCommand({ name = "a", func = function() end }))
        manager:registerCommand(manager:createCommand({ name = "b", func = function() end }))
        local commands = manager:listCommands()
        t:assertEqual(#commands, 2)
    end,
})
