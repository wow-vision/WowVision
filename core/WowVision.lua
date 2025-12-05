local addonName, WowVisionNamespace = ...
WowVision = LibStub("AceAddon-3.0"):NewAddon("WowVision", "AceConsole-3.0")
WowVision.Class = WowVisionNamespace.Class

function WowVision:OnInitialize()
    self.L = LibStub("AceLocale-3.0"):GetLocale("WowVision")
    self:cacheLoadedAddons()
    self:registerCommands()
    local defaultDB = self.base:getDefaultDBRecursive()
    if WowVisionDB == nil or WowVision.profiles ~= nil then
        WowVisionDB = {}
    end
    self.db = WowVision.dbManager:reconcile(defaultDB, WowVisionDB)
    self.base:setDBObj(self.db)
end

-- Cache all loaded addons at startup for O(1) lookups
-- Addons don't change during a session, so this is safe to cache once
function WowVision:cacheLoadedAddons()
    self.loadedAddons = {}
    for i = 1, C_AddOns.GetNumAddOns() do
        local name = C_AddOns.GetAddOnInfo(i)
        if C_AddOns.IsAddOnLoaded(i) then
            self.loadedAddons[name] = true
            self.loadedAddons[name:lower()] = true  -- case-insensitive lookup
        end
    end
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
    if msg == "dev" then
        self:globalizeDevTools()
        print("Developer tools active")
    elseif msg == "profile" then
        self.profiler:enable()
        print("Profiler enabled")
    elseif msg == "profile stop" then
        self.profiler:report()
        self.profiler:disable()
    elseif msg == "profile report" then
        self.profiler:report()
    elseif msg == "profile reset" then
        self.profiler:reset()
        print("Profiler reset")
    elseif msg == "bind" then
        local root = { "binding/List", bindings = WowVision.input.bindings }
        self.UIHost:openTemporaryWindow({
            generated = true,
            rootElement = root,
            hookEscape = true,
        })
    elseif msg == "version" then
        local version = C_AddOns.GetAddOnMetadata(addonName, "version")
        if version == nil then
            error("Version data unavailable.")
        end
        print(version)
    else
        local root = self.base:getMenuPanel()
        self.UIHost:openTemporaryWindow({
            generated = true,
            rootElement = root,
            hookEscape = true,
        })
    end
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

function WowVision:compareProps(prop, a, b)
    local result, err = nil, nil
    if prop.key == "children" then
        return true
    end
    if prop.type == "reference" then
        return a == b
    end
    result, err = WowVision:recursiveComp(a, b)
    if err then
        print("error when comparing prop", prop.key, ":", err)
        tprint(prop)
    end
    return result
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
    self:RegisterChatCommand("wv", "SlashCommand")
    self:RegisterChatCommand("wvbind", "BindCommand")
    self:RegisterChatCommand("uiinsp", "InspectCommand")
    if not SkuCore then
        self:RegisterChatCommand("pquit", "PartyQuitCommand")
        self:RegisterChatCommand("dquit", "InstanceGroupQuitCommand")
    end
    if not self.loadedAddons["BlindSlash"] then
        self:RegisterChatCommand("enableaddon", "EnableAddon")
        self:RegisterChatCommand("disableaddon", "DisableAddon")
    end
end

function WowVision:PartyQuitCommand()
    LeaveParty()
end

function WowVision:InstanceGroupQuitCommand()
    if IsPartyLFG() then
        ConfirmOrLeaveLFGParty()
    end
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
