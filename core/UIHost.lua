local UIHost = WowVision.Class("UIHost")

-- Hosts the shared UI services: the tooltip reader, the window manager's
-- detection loop, the graph host update, combat gating, and the secure
-- click/function helpers. Screen presentation itself lives in the graph
-- framework (core/graph/).
function UIHost:initialize()
    self.tooltip = WowVision.Tooltip:new("UIHost")
    self.inCombat = false
    self.windowManager = WowVision.WindowManager:new()
    self.hookedFuncs = {} --hooksecurefunc
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:SetScript("OnEvent", function(frame, event)
        if event == "PLAYER_REGEN_DISABLED" then
            self.inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.inCombat = false
        end
    end)
end

function UIHost:openWindow(window)
    return self.windowManager:openWindow(window)
end

function UIHost:openTemporaryWindow(config)
    return self.windowManager:openTemporaryWindow(config)
end

function UIHost:closeWindow(window)
    return self.windowManager:closeWindow(window)
end

function UIHost:update()
    if self.inCombat then
        return
    end
    self.windowManager:update()
    WowVision.graph.dropdown.update()
    WowVision.graphHost:update()
end

--Function hooks
function UIHost:hookFunc(tbl, name, func)
    local newFunc = function(...)
        for _, v in ipairs(WowVision.UIHost.hookedFuncs[tbl][name]) do
            v(...)
        end
    end
    if not self.hookedFuncs[tbl] then
        self.hookedFuncs[tbl] = { [name] = { func, [func] = true } }
        hooksecurefunc(tbl, name, newFunc)
        return
    end
    if not self.hookedFuncs[tbl][name] then
        self.hookedFuncs[tbl][name] = { func, [func] = true }
        hooksecurefunc(tbl, name, newFunc)
        return
    end
    if not self.hookedFuncs[tbl][name][func] then
        self.hookedFuncs[tbl][name][func] = true
        tinsert(self.hookedFuncs[tbl][name], func)
    end
end

function UIHost:unhookFunc(tbl, name, func)
    if not self.hookedFuncs[tbl] then
        return
    end
    local funcList = self.hookedFuncs[tbl][name]
    if not funcList then
        return
    end
    funcList[func] = nil
    for i, v in ipairs(funcList) do
        if v == func then
            table.remove(funcList, i)
            return
        end
    end
end

--Secure clicks and function calls
function UIHostSecureClick(frame, key, down)
    --needs to be used as part of a securecall
    frame:Click(key, down)
end

function UIHostSecureFunc(frame, func)
    --needs to be used as part of a securecall
    frame[func](frame)
end

function UIHostSecureScript(frame, script)
    ExecuteFrameScript(frame, script)
end

WowVision.UIHost = UIHost:new()
