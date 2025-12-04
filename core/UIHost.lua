local UIHost = WowVision.Class("UIHost")
local L = WowVision:getLocale()

function UIHost:initialize()
    self.frame = CreateFrame("Button", "WowVisionHost", UIParent)
    self.frame:EnableMouse(true)
    self.frame:RegisterForClicks("AnyDown")
    self.tooltip = WowVision.Tooltip:new("UIHost")
    self.inCombat = false
    self.windowContext = WowVision.ui:CreateElement("HorizontalContext")
    self.windowContext:setLabel("window context")
    self.windowManager = WowVision.WindowManager:new(self.windowContext)
    self.menuManager = WowVision.MenuManager:new()
    self.hookedFuncs = {} --hooksecurefunc
    self.navigator = nil
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:SetScript("OnEvent", function(frame, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if self._open then
                self:close()
            end
            self.inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.inCombat = false
        end
    end)
end

function UIHost:onBindingPressed(binding)
    local stopped = WowVision.base.speech:uiStop()
    if self.navigator then
        if not stopped then
            self.navigator:onBindingPressed(binding)
            return
        end
        --necessary due to bugs with the implementation of tts
        C_Timer.After(0.01, function()
            self.navigator:onBindingPressed(binding)
        end)
    end
end

function UIHost:bind()
    self.navigator:activate()
end

function UIHost:shouldClose()
    if #self.context.children > 1 then
        return false
    end
    if #self.windowContext.children <= 0 then
        return true
    end
    return false
end

function UIHost:show()
    if self.inCombat then
        return
    end
    self:bind()
    --self.frame:Show()
    if self.context then
        self.context:focus()
    end
end

function UIHost:hide()
    if self.inCombat then
        return
    end
    --self.frame:Hide()
    if self.bindingSet then
        self.bindingSet:deactivateAll()
    end
    self.navigator:deactivate()
    if self.context then
        self.context:unfocus()
    end
end

function UIHost:open(context)
    if self._open then
        if context then
            self.context:add(context)
        end
        return
    end
    self.context = WowVision.ui:CreateElement("StackContext")
    self.context:setLabel("root context")
    self.context:add(self.windowContext)
    if context then
        self.context:add(context)
    end
    local navigatorClass = WowVision.navigators:get("Windowed")
    self.navigator = navigatorClass:new(self.context)
    self._open = true
    WowVision.base.speech:uiStop()
    self:show()
end

function UIHost:close()
    self:hide()
    self.context:onRemove()
    self.navigator = nil
    self.context = nil
    self._open = false
end

function UIHost:openWindow(window)
    return self.windowManager:openWindow(window)
end

function UIHost:closeWindow(window)
    return self.windowManager:closeWindow(window)
end

function UIHost:update()
    if self.inCombat then
        return
    end
    self.windowManager:update()
    self.menuManager:update()
    if self.context then
        self.context:update()
    end
    if self.navigator then
        self.navigator:update()
    end
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
