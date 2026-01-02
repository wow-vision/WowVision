local addonName, WowVisionNamespace = ...
WowVision = LibStub("AceAddon-3.0"):NewAddon("WowVision", "AceConsole-3.0")
WowVision.Class = WowVisionNamespace.Class

-- Cache loaded addons immediately at file load time (before any modules register windows)
-- This must happen before Window:initialize() calls checkConflictingAddons()
WowVision.loadedAddons = {}
for i = 1, C_AddOns.GetNumAddOns() do
    local name = C_AddOns.GetAddOnInfo(i)
    if C_AddOns.IsAddOnLoaded(i) then
        WowVision.loadedAddons[name] = true
        WowVision.loadedAddons[name:lower()] = true
    end
end

function WowVision:OnInitialize()
    self.L = LibStub("AceLocale-3.0"):GetLocale("WowVision")
    self:registerCommands()
    local defaultDB = self.base:getDefaultDBRecursive()
    if WowVisionDB == nil or WowVision.profiles ~= nil then
        WowVisionDB = {}
    end
    self.db = WowVision.dbManager:reconcile(defaultDB, WowVisionDB)
    self.base:setDBObj(self.db)
end

function WowVision:OnEnable()
    self.base:enable()
    self.profiler = WowVision.Profiler:new()
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function()
        WowVision:OnUpdate()
    end)
    self.fullEnable = true
    self.base:fullEnable()
end

function WowVision:OnDisable()
    self.updateFrame:SetScript("OnUpdate", nil)
    self.updateFrame = nil
    self.base:disable()
end

function WowVision:OnUpdate()
    local profiler = self.profiler
    profiler:beginFrame()

    profiler:start("objects")
    WowVision.objects:update()
    profiler:stop("objects")

    profiler:start("modules")
    WowVision.Module.runAllUpdates()
    profiler:stop("modules")

    profiler:start("uihost")
    self.UIHost:update()
    profiler:stop("uihost")

    profiler:endFrame()
end

function WowVision:speak(text)
    self.base.speech:speak(text)
end

function WowVision:SlashCommand(msg)
    -- Try to dispatch through the command manager first
    if msg and msg ~= "" and WowVision.SlashCommandManager:dispatch(msg) then
        return
    end

    -- Default behavior: open the menu
    local root = self.base:getMenuPanel()
    self.UIHost:openTemporaryWindow({
        generated = true,
        rootElement = root,
        hookEscape = true,
    })
end

function WowVision:InspectCommand(args)
    local frame = CreateFrame("Frame")
    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(frame, key)
        if key == "ESCAPE" then
            frame:Hide()
        end
        print(key)
    end)
    frame:Show()
end

function WowVision:translate(locale)
    return LibStub("AceLocale-3.0"):NewLocale("WowVision", locale, true)
end

function WowVision:getLocale()
    return self.L or LibStub("AceLocale-3.0"):GetLocale("WowVision")
end

function WowVision:recursiveComp(a, b, level)
    if level == 0 then
        return nil, "level"
    end
    local level = 10 or level
    if a == nil or b == nil then
        return a == b
    end
    local aType, bType = type(a), type(b)
    if aType == "table" and bType == "table" then
        for k, v in pairs(a) do
            if not b[k] then
                return false
            end
            local result, error = self:recursiveComp(v, b[k], level - 1)
            if not result then
                return false, error
            end
        end
        for k, v in pairs(b) do
            if not a[k] then
                return false
            end
        end
        return true
    elseif aType ~= bType then
        return false
    end
    return a == b
end

function WowVision:play(path, channel)
    local channel = channel or "SFX"
    local resource = WowVision.audio.directory:getPath(path)
    if not resource then
        return nil
    end
    resource:play()
end

function WowVision:registerCommands()
    -- Register the main /wv entry point (uses Ace3)
    self:RegisterChatCommand("wv", "SlashCommand")

    -- Register WowVision-scoped subcommands (/wv <name>)
    self.base:registerCommand({
        name = "dev",
        description = "Enable developer tools",
        func = function(args)
            WowVision:globalizeDevTools()
            print("Developer tools active")
        end,
    })

    self.base:registerCommand({
        name = "profile",
        description = "Profiler commands (start/stop/report/reset)",
        func = function(args)
            if args == "stop" then
                WowVision.profiler:report()
                WowVision.profiler:disable()
            elseif args == "report" then
                WowVision.profiler:report()
            elseif args == "reset" then
                WowVision.profiler:reset()
                print("Profiler reset")
            else
                WowVision.profiler:enable()
                print("Profiler enabled")
            end
        end,
    })

    self.base:registerCommand({
        name = "bind",
        description = "Show keybindings",
        func = function(args)
            local root = { "binding/List", bindings = WowVision.input.bindings }
            WowVision.UIHost:openTemporaryWindow({
                generated = true,
                rootElement = root,
                hookEscape = true,
            })
        end,
    })

    self.base:registerCommand({
        name = "version",
        description = "Show addon version",
        func = function(args)
            local version = C_AddOns.GetAddOnMetadata(addonName, "version")
            if version == nil then
                error("Version data unavailable.")
            end
            print(version)
        end,
    })

    self.base:registerCommand({
        name = "tests",
        description = "Run test cases. Usage: /wv tests [suite]",
        func = function(args)
            local suiteName = args ~= "" and args or nil
            WowVision.testing.runAndShow(suiteName)
        end,
    })

    -- Register global commands (/<name>)
    self.base:registerCommand({
        name = "uiinsp",
        description = "UI inspection tool",
        scope = "Global",
        func = function(args)
            WowVision:InspectCommand(args)
        end,
    })

    self.base:registerCommand({
        name = "pquit",
        description = "Leave party",
        scope = "Global",
        conflictingAddons = { "Sku" },
        func = function(args)
            LeaveParty()
        end,
    })

    self.base:registerCommand({
        name = "dquit",
        description = "Leave dungeon/LFG group",
        scope = "Global",
        conflictingAddons = { "Sku" },
        func = function(args)
            if IsPartyLFG() then
                ConfirmOrLeaveLFGParty()
            end
            local inInstance, instanceType = IsInInstance()
            if not inInstance then
                return
            end
            if instanceType == "pvp" or instanceType == "arena" then
                ConfirmOrLeaveBattlefield()
            end
        end,
    })

    self.base:registerCommand({
        name = "enableaddon",
        description = "Enable an addon and reload",
        scope = "Global",
        conflictingAddons = { "BlindSlash" },
        func = function(args)
            WowVision:EnableAddon(args)
        end,
    })

    self.base:registerCommand({
        name = "disableaddon",
        description = "Disable an addon and reload",
        scope = "Global",
        conflictingAddons = { "BlindSlash" },
        func = function(args)
            WowVision:DisableAddon(args)
        end,
    })

    self.base:registerCommand({
        name = "close",
        description = "Force close WowVision UI",
        func = function(args)
            WowVision.UIHost:close()
        end,
    })
end

local function setAddonStates(state, ...)
    local addons = { ... }
    local action = C_AddOns.DisableAddOn
    if state then
        action = C_AddOns.EnableAddOn
    end
    for _, v in ipairs(addons) do
        local v = string.lower(v)
        local addonList = { v }
        if v == "sku" then
            addonList = {
                "Sku",
                "SkuAudioData_en",
                "SkuAudioData_de",
                "SkuBeaconSoundsets",
                "SkuCustomBeaconsAdditional",
                "SkuCustomBeaconsEssential",
            }
        end
        for _, addon in ipairs(addonList) do
            action(addon)
        end
    end
    ReloadUI()
end

function WowVision:EnableAddon(name)
    if name == nil or name == "" then
        print("Syntax: /enableaddon <name>")
        return
    end
    setAddonStates(true, name)
end

function WowVision:DisableAddon(name)
    if name == nil or name == "" then
        print("Syntax: /disableaddon <name")
        return
    end
    setAddonStates(false, name)
end
