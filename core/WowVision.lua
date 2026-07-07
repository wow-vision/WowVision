local addonName, WowVisionNamespace = ...
WowVision = LibStub("AceAddon-3.0"):NewAddon("WowVision", "AceConsole-3.0")
WowVision.Class = WowVisionNamespace.Class
WowVision.consts = WowVisionNamespace.consts

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
    self.db = WowVision.dbManager:beginReconcile(defaultDB, WowVisionDB)
    self.base:setDBObj(self.db)

    -- Global binding DB (profile-independent)
    local bindingDefaults = WowVision.input:getDefaultDB()
    if WowVisionDB.bindings == nil then
        WowVisionDB.bindings = {}
    end
    WowVisionDB.bindings = WowVision.dbManager:reconcile(bindingDefaults, WowVisionDB.bindings)
    WowVision.input:setDB(WowVisionDB.bindings)

    -- Global spell history (profile-independent)
    if WowVisionDB.spellHistory == nil then
        WowVisionDB.spellHistory = {}
    end
    WowVision.spellHistory:setDB(WowVisionDB.spellHistory)
    WowVision.spellHistory:startListening()
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
    WowVision.graph.settings.openMenu()
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
    local level = level or 10
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
        name = "gsettings",
        description = "Open a module's settings as a graph screen, for example gsettings speech",
        func = function(args)
            WowVision.graph.settings.openModuleSettings(args)
        end,
    })

    self.base:registerCommand({
        name = "gmenu",
        description = "Open the WowVision menu as a graph screen",
        func = function(args)
            WowVision.graph.settings.openMenu()
        end,
    })

    self.base:registerCommand({
        name = "gnode",
        description = "Dump the focused graph node's row frame structure, spoken and copyable",
        func = function(args)
            local lines = {}
            local host = WowVision.graphHost
            local screen = host:focusedScreen()
            local node = screen ~= nil and screen.keyGraph:currentNode() or nil
            if node == nil then
                print("No focused graph node")
                return
            end
            tinsert(lines, "node: " .. tostring(node.id.key))
            local debug = WowVision.graph.scrollBoxDebug[tostring(node.id.key)]
            if debug ~= nil then
                tinsert(lines, "row template: " .. debug.template)
                tinsert(lines, "row data name: " .. debug.name)
            end
            local ref = node.vtable.tooltipFrame
            local frame = type(ref) == "function" and ref() or ref
            if frame == nil then
                tinsert(lines, "no resolved frame")
            else
                local ok, err = pcall(function()
                    local name = frame.GetName ~= nil and frame:GetName() or nil
                    local objectType = frame.GetObjectType ~= nil and frame:GetObjectType() or "?"
                    tinsert(lines, "frame: " .. tostring(name or "unnamed") .. " (" .. objectType .. ")")
                    for key, value in pairs(frame) do
                        if type(value) == "table" and type(key) == "string" and value.GetObjectType ~= nil then
                            local entry = key .. ": " .. value:GetObjectType()
                            local text = value.GetText ~= nil and value:GetText() or nil
                            if text ~= nil and text ~= "" then
                                entry = entry .. " text " .. text
                            end
                            tinsert(lines, entry)
                            for subKey, subValue in pairs(value) do
                                if
                                    type(subValue) == "table"
                                    and type(subKey) == "string"
                                    and subValue.GetObjectType ~= nil
                                then
                                    local subEntry = key .. "." .. subKey .. ": " .. subValue:GetObjectType()
                                    local subText = subValue.GetText ~= nil and subValue:GetText() or nil
                                    if subText ~= nil and subText ~= "" then
                                        subEntry = subEntry .. " text " .. subText
                                    end
                                    tinsert(lines, subEntry)
                                end
                            end
                        end
                    end
                end)
                if not ok then
                    tinsert(lines, "dump errored: " .. tostring(err))
                end
            end
            local text = table.concat(lines, "\n")
            WowVision.testing.showResults(text)
            WowVision:speak(text)
        end,
    })

    self.base:registerCommand({
        name = "glive",
        description = "Dump the focused node's live watch state, spoken and copyable",
        func = function(args)
            local host = WowVision.graphHost
            local screen = host:focusedScreen()
            local node = screen ~= nil and screen.keyGraph:currentNode() or nil
            if node == nil then
                print("No focused graph node")
                return
            end
            local lines = {}
            tinsert(lines, "node: " .. tostring(node.id.key))
            tinsert(lines, "live key matches: " .. tostring(screen._liveKey == node.id))
            local debug = screen._liveDebug
            if debug ~= nil then
                tinsert(
                    lines,
                    "watch ticks "
                        .. debug.ticks
                        .. ", saw "
                        .. debug.partCount
                        .. " parts, stored "
                        .. debug.valueCount
                        .. ", baselined "
                        .. tostring(debug.baselined)
                )
            else
                tinsert(lines, "watch has never run")
            end
            local parts = WowVision.graph.announcer.effectiveAnnouncements(node)
            for i, part in ipairs(parts) do
                local resolved = WowVision.graph.resolveText(part)
                local cached = screen._liveValues[i]
                tinsert(
                    lines,
                    i
                        .. ": kind "
                        .. tostring(part.kind)
                        .. ", live "
                        .. tostring(part.live)
                        .. ", now "
                        .. tostring(resolved)
                        .. ", cached "
                        .. tostring(cached)
                )
            end
            local text = table.concat(lines, "\n")
            WowVision.testing.showResults(text)
            WowVision:speak(text)
        end,
    })

    self.base:registerCommand({
        name = "gdump",
        description = "Evaluate a Lua expression and describe the value, spoken and copyable",
        func = function(args)
            local chunk, err = loadstring("return " .. tostring(args))
            if chunk == nil then
                print("gdump: " .. tostring(err))
                return
            end
            local ok, value = pcall(chunk)
            if not ok then
                print("gdump: " .. tostring(value))
                return
            end
            local lines = {}
            tinsert(lines, "value: " .. tostring(value) .. " (type " .. type(value) .. ")")
            if type(value) == "table" then
                local okType, objectType = pcall(function()
                    return value:GetObjectType()
                end)
                tinsert(lines, "GetObjectType: " .. tostring(okType and objectType or ("ERR " .. tostring(objectType))))
                local okName, name = pcall(function()
                    return value:GetName()
                end)
                tinsert(lines, "GetName: " .. tostring(okName and name or "ERR"))
                local keys = {}
                for key in pairs(value) do
                    tinsert(keys, tostring(key))
                    if #keys >= 12 then
                        break
                    end
                end
                tinsert(lines, "keys: " .. table.concat(keys, ", "))
            end
            local text = table.concat(lines, "\n")
            WowVision.testing.showResults(text)
            WowVision:speak(text)
        end,
    })

    self.base:registerCommand({
        name = "gperf",
        description = "Profile the UI update loop for 120 frames and report min, average, and max milliseconds",
        func = function(args)
            if WowVision._perfActive then
                print("gperf already running")
                return
            end
            WowVision._perfActive = true
            local samples = {}
            local host = WowVision.UIHost
            local original = host.update
            host.update = function(self, ...)
                local started = debugprofilestop()
                original(self, ...)
                tinsert(samples, debugprofilestop() - started)
                if #samples >= 120 then
                    host.update = original
                    WowVision._perfActive = nil
                    local total, worst, best = 0, 0, math.huge
                    for _, sample in ipairs(samples) do
                        total = total + sample
                        if sample > worst then
                            worst = sample
                        end
                        if sample < best then
                            best = sample
                        end
                    end
                    local text = string.format(
                        "ui update over %d frames: min %.2f ms, avg %.2f ms, max %.2f ms",
                        #samples,
                        best,
                        total / #samples,
                        worst
                    )
                    WowVision.testing.showResults(text)
                    WowVision:speak(text)
                end
            end
            WowVision:speak("profiling 120 frames")
        end,
    })

    self.base:registerCommand({
        name = "gdrop",
        description = "Dump the open dropdown menu chain and the focused item's description state",
        func = function(args)
            local dropdown = WowVision.graph.dropdown
            local lines = {}
            tinsert(lines, "root: " .. tostring(dropdown.frame))
            if dropdown.frame ~= nil then
                local menus = dropdown.openMenuFrames(dropdown.frame)
                tinsert(lines, "open menus found: " .. #menus)
                for i, menu in ipairs(menus) do
                    local parent = menu:GetParent()
                    tinsert(
                        lines,
                        "menu "
                            .. i
                            .. ": id "
                            .. tostring(menu:GetID())
                            .. ", parent "
                            .. tostring(parent ~= nil and (parent:GetName() or "unnamed") or "nil")
                            .. ", children "
                            .. select("#", menu:GetChildren())
                    )
                end
            end
            local host = WowVision.graphHost
            local screen = host:focusedScreen()
            local node = screen ~= nil and screen.keyGraph:currentNode() or nil
            local item = node ~= nil and type(node.id.key) == "table" and node.id.key or nil
            if item ~= nil and item.GetElementDescription ~= nil then
                local ok, description = pcall(item.GetElementDescription, item)
                tinsert(lines, "description: " .. tostring(ok and description or ("ERR " .. tostring(description))))
                if ok and description ~= nil then
                    tinsert(lines, "canOpen fn: " .. tostring(description.CanOpenSubmenu ~= nil))
                    local ok2, can = pcall(description.CanOpenSubmenu, description)
                    tinsert(lines, "canOpen: " .. tostring(ok2 and can or ("ERR " .. tostring(can))))
                    local ok3, err3 = pcall(description.ForceOpenSubmenu, description)
                    tinsert(lines, "forceOpen: " .. tostring(ok3 and "called" or ("ERR " .. tostring(err3))))
                end
            else
                tinsert(lines, "focused node is not a frame-backed menu item")
            end
            local text = table.concat(lines, "\n")
            WowVision.testing.showResults(text)
            WowVision:speak(text)
        end,
    })

    self.base:registerCommand({
        name = "gtooltip",
        description = "Dump the graph tooltip reader state, spoken and copyable",
        func = function(args)
            local lines = {}
            local function add(label, fn)
                local ok, value = pcall(fn)
                if ok then
                    tinsert(lines, label .. ": " .. tostring(value))
                else
                    tinsert(lines, label .. " errored: " .. tostring(value))
                end
            end
            local host = WowVision.graphHost
            local screen = host:focusedScreen()
            local node = screen ~= nil and screen.keyGraph:currentNode() or nil
            add("focused node", function()
                return node ~= nil and tostring(node.id.key) or "none"
            end)
            add("has tooltip config", function()
                return node ~= nil and node.vtable.tooltip ~= nil
            end)
            add("has tooltip frame", function()
                return node ~= nil and node.vtable.tooltipFrame ~= nil
            end)
            add("resolved frame", function()
                local ref = node ~= nil and node.vtable.tooltipFrame or nil
                local frame = type(ref) == "function" and ref() or ref
                if frame == nil then
                    return "nil"
                end
                return frame.GetName ~= nil and (frame:GetName() or "unnamed") or "no GetName"
            end)
            add("host tooltip active", function()
                return host._tooltipActive
            end)
            local tooltip = WowVision.UIHost.tooltip
            add("reader has data", function()
                return tooltip.tooltipData ~= nil
            end)
            add("reader frame", function()
                local frame = tooltip.activeFrame
                if frame == nil then
                    return "nil"
                end
                return frame.GetName ~= nil and (frame:GetName() or "unnamed") or "no GetName"
            end)
            add("reader lines before read", function()
                return tooltip:getNumLines()
            end)
            add("full text", function()
                return tooltip:getText()
            end)
            local text = table.concat(lines, "\n")
            WowVision.testing.showResults(text)
            WowVision:speak(text)
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
        description = "Run test cases. Usage: /wv tests [suite] [--verbose]",
        func = function(args)
            WowVision.testing.runAndShow(args)
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
            local host = WowVision.graphHost
            for i = #host.stacks, 1, -1 do
                host:close(host.stacks[i])
            end
        end,
    })

    self.base:registerCommand({
        name = "testcd",
        description = "Test cooldown monitor with Starsurge",
        func = function(args)
            -- Create a full monitor with a rule, enable sound on ready and on_cooldown
            local monitor = WowVision.monitors:create("Cooldown", {
                label = "Test CD",
                rules = {
                    {
                        type = "CooldownState",
                        spell = 78674,
                    },
                },
            })

            local rule = WowVision.monitors.ruleRegistry:createTemporaryComponent({
                type = "CooldownState",
                spell = 78674,
            })

            -- Check DB state of alerts
            for _, key in ipairs({"ready", "on_cooldown"}) do
                local alert = rule[key]
                if alert then
                    print(key, "alert.db:", alert.db and "linked" or "NIL")
                    for _, output in ipairs(alert.outputs) do
                        print("  ", output.key, "output.db:", output.db and "linked" or "NIL")
                    end
                end
            end

            -- Now simulate what addElement does
            local config = rule.class.info:getData(rule)
            config.type = "CooldownState"
            -- Pretend we have a DB array
            local dbArr = { config }
            rule.db = dbArr[1]
            print("--- After setting rule.db ---")

            -- Now check if lazy link works
            for _, key in ipairs({"ready", "on_cooldown"}) do
                local alertField = rule.class.info:getField(key)
                if alertField then
                    local alert = alertField:getAlert(rule)
                    print(key, "alert.db:", alert.db and "linked" or "NIL")
                    for _, output in ipairs(alert.outputs) do
                        print("  ", output.key, "output.db:", output.db and "linked" or "NIL")
                    end
                end
            end
        end,
    })

    self.base:registerCommand({
        name = "dump",
        description = "Dump Sku waypoint cache to SavedVariables. Usage: /wv dump waypoints or /wv dump links. Then /reload to flush to disk.",
        func = function(args)
            if not WaypointCache then
                print("WaypointCache not found. Is Sku loaded?")
                return
            end

            WowVisionDump = WowVisionDump or {}
            local dumpType = strtrim(args)

            if dumpType == "links" then
                local buf = {}
                tinsert(buf, "fromIndex|toIndex")
                for i, wp in pairs(WaypointCache) do
                    if wp.links and wp.links.byId then
                        for targetIndex, _ in pairs(wp.links.byId) do
                            tinsert(buf, i .. "|" .. targetIndex)
                        end
                    end
                end
                WowVisionDump.links = table.concat(buf, "\n")
                print("Links saved to WowVisionDump. /reload to flush to disk.")
                self:speak("Done")

            elseif dumpType == "waypoints" then
                local buf = {}
                tinsert(buf, "index|typeId|dbIndex|spawn|worldX|worldY|continentId|areaId|uiMapId|size|createdBy|name|role|comments")

                local keys = {}
                for k, _ in pairs(WaypointCache) do
                    tinsert(keys, k)
                end
                table.sort(keys)

                for _, k in ipairs(keys) do
                    local wp = WaypointCache[k]
                    local comments = ""
                    if wp.comments then
                        for locale, entries in pairs(wp.comments) do
                            for ci, text in ipairs(entries) do
                                if text and text ~= "" then
                                    comments = comments .. locale .. ":" .. ci .. ":" .. tostring(text) .. "~"
                                end
                            end
                        end
                    end
                    tinsert(buf, k
                        .. "|" .. (wp.typeId or "")
                        .. "|" .. (wp.dbIndex or "")
                        .. "|" .. (wp.spawn or "")
                        .. "|" .. (wp.worldX or "")
                        .. "|" .. (wp.worldY or "")
                        .. "|" .. (wp.contintentId or "")
                        .. "|" .. (wp.areaId or "")
                        .. "|" .. (wp.uiMapId or "")
                        .. "|" .. (wp.size or "")
                        .. "|" .. (wp.createdBy or "")
                        .. "|" .. (wp.name or "")
                        .. "|" .. (wp.role or "")
                        .. "|" .. comments
                    )
                end

                WowVisionDump.waypoints = table.concat(buf, "\n")
                print("Waypoints saved to WowVisionDump (" .. (#keys) .. " entries). /reload to flush to disk.")
                self:speak("Done")
            else
                print("Usage: /wv dump waypoints or /wv dump links. Then /reload to flush to disk.")
            end
        end,
    })

end

function WowVision:showDumpFrame(text)
    if self._dumpFrame then
        self._dumpFrame:Show()
        self._dumpFrame.editBox:SetText(text)
        self._dumpFrame.editBox:HighlightText()
        self._dumpFrame.editBox:SetFocus()
        self:speak("Ready")
        return
    end

    local f = CreateFrame("Frame", "WowVisionDumpFrame", UIParent, "BackdropTemplate")
    f:SetSize(600, 400)
    f:SetPoint("CENTER")
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local editBox = CreateFrame("EditBox", nil, f)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetPoint("TOPLEFT", 12, -12)
    editBox:SetPoint("BOTTOMRIGHT", -12, 40)
    editBox:SetMaxLetters(0)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function()
        editBox:ClearFocus()
        f:Hide()
    end)

    local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    close:SetSize(80, 22)
    close:SetPoint("BOTTOM", 0, 12)
    close:SetText("Close")
    close:SetScript("OnClick", function() f:Hide() end)

    f.editBox = editBox
    self._dumpFrame = f

    editBox:SetText(text)
    editBox:SetFocus()
    editBox:HighlightText()
    self:speak("Ready")
end

-- Find addon index by name (case-insensitive)
local function findAddonIndex(name)
    local lowerName = name:lower()
    for i = 1, C_AddOns.GetNumAddOns() do
        local addonName = C_AddOns.GetAddOnInfo(i)
        if addonName and addonName:lower() == lowerName then
            return i
        end
    end
    return nil
end

local function setAddonStates(state, ...)
    local addons = { ... }
    local action = C_AddOns.DisableAddOn
    if state then
        action = C_AddOns.EnableAddOn
    end
    for _, v in ipairs(addons) do
        local addonList = { v }
        -- Special case: "sku" disables all Sku-related addons
        if string.lower(v) == "sku" then
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
            local index = findAddonIndex(addon)
            if index then
                action(index)
            end
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
        print("Syntax: /disableaddon <name>")
        return
    end
    setAddonStates(false, name)
end
