local MenuManager = WowVision.Class("MenuManager")

function MenuManager:initialize()
    self.registeredMenus = {}
    self.menuFrame = nil
    self.menuWindow = nil
end

function MenuManager:setActiveDescription(description)
    self.activeDescription = description
end

function MenuManager:registerMenu(menu, description)
    if self.registeredMenus[menu] then
        return nil
    end
    self.registeredMenus[menu] = description
    Menu.ModifyMenu(menu, function(owner, root, data)
        if self.registeredMenus[menu] then
            self:setActiveDescription(description)
        else
            self:setActiveDescription(nil)
        end
    end)
end

function MenuManager:unregisterMenu(menu)
    self.registeredMenus[menu] = nil
end

function MenuManager:update()
    local manager = Menu:GetManager()
    if not manager then
        self.activeDescription = nil
        return
    end
    local dropdownMenuFrame = manager:GetOpenMenu()
    if not dropdownMenuFrame then
        self.activeDescription = nil
        if self.menuWindow then
            WowVision.UIHost.windowManager:closeWindow(self.menuWindow)
            self.menuWindow = nil
            self.menuFrame = nil
        end
        return
    end

    if self.menuFrame and dropdownMenuFrame and dropdownMenuFrame == self.menuFrame then
        return
    end

    local panel = WowVision.ui:CreateElement(
        "DropdownGeneratorPanel",
        WowVision.ui.generator,
        dropdownMenuFrame,
        self.activeDescription
    )
    local newMenuWindow = WowVision.UIHost:openTemporaryWindow({
        name = "dropdown",
        virtual = false,
        rootElement = panel,
    })
    if newMenuWindow then
    end
    if self.menuWindow then
        WowVision.UIHost.windowManager:closeWindow(self.menuWindow)
    end
    self.menuWindow = newMenuWindow
    self.menuFrame = dropdownMenuFrame
end

WowVision.MenuManager = MenuManager
