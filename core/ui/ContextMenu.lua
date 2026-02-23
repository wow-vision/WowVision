local L = WowVision:getLocale()

-- Menu item classes (lightweight descriptors, not UIElements)

local ContextMenuButton = WowVision.Class("ContextMenuButton")

function ContextMenuButton:initialize(config)
    self.label = config.label
    self.popOnClick = config.popOnClick ~= false
    self.events = { click = WowVision.Event:new("click") }
end

local ContextMenuCheckbox = WowVision.Class("ContextMenuCheckbox")

function ContextMenuCheckbox:initialize(config)
    self.label = config.label
    self.value = config.value or false
    self.popOnClick = config.popOnClick == true
    self.events = { valueChange = WowVision.Event:new("valueChange") }
end

local ContextMenuSeparator = WowVision.Class("ContextMenuSeparator")

function ContextMenuSeparator:initialize(label)
    self.label = label
end

-- ContextMenu builder (created fresh each time the menu opens)

local ContextMenu = WowVision.Class("ContextMenu")

function ContextMenu:initialize(element)
    self.element = element
    self.items = {}
end

function ContextMenu:addButton(config)
    local item = ContextMenuButton:new(config)
    tinsert(self.items, item)
    return item
end

function ContextMenu:addCheckbox(config)
    local item = ContextMenuCheckbox:new(config)
    tinsert(self.items, item)
    return item
end

function ContextMenu:addSeparator(label)
    local item = ContextMenuSeparator:new(label)
    tinsert(self.items, item)
    return item
end

function ContextMenu:buildMenuDef()
    local children = {}
    for _, item in ipairs(self.items) do
        if item:isInstanceOf(ContextMenuButton) then
            local menuItem = item
            tinsert(children, {
                "Button",
                label = item.label,
                events = {
                    click = function(_, source)
                        menuItem.events.click:emit(self.element)
                        if menuItem.popOnClick then
                            source.context:pop()
                        end
                    end,
                },
            })
        elseif item:isInstanceOf(ContextMenuCheckbox) then
            local menuItem = item
            tinsert(children, {
                "Checkbox",
                label = item.label,
                value = item.value,
                events = {
                    click = function(_, source)
                        local newValue = not source:getValue()
                        menuItem.events.valueChange:emit(self.element, newValue)
                        if menuItem.popOnClick then
                            source.context:pop()
                        end
                    end,
                },
            })
        elseif item:isInstanceOf(ContextMenuSeparator) then
            tinsert(children, {
                "Text",
                label = item.label or "",
                displayType = "Separator",
            })
        end
    end
    return { "List", displayType = "", label = L["Context Menu"], children = children }
end

function ContextMenu:open()
    if #self.items == 0 then
        return
    end
    local menuDef = self:buildMenuDef()
    self.element.context:addGenerated(menuDef)
end

WowVision.ContextMenu = ContextMenu

-- ContextMenuManager (global singleton for tag subscriptions)

local ContextMenuManager = WowVision.Class("ContextMenuManager")

function ContextMenuManager:initialize()
    self.subscribers = {}
end

function ContextMenuManager:subscribe(tag, handler, owner)
    if not self.subscribers[tag] then
        self.subscribers[tag] = {}
    end
    tinsert(self.subscribers[tag], { handler = handler, owner = owner })
end

function ContextMenuManager:unsubscribe(owner)
    for tag, handlers in pairs(self.subscribers) do
        for i = #handlers, 1, -1 do
            if handlers[i].owner == owner then
                table.remove(handlers, i)
            end
        end
    end
end

function ContextMenuManager:build(tags, menu, element)
    if not tags then
        return
    end
    for _, tag in ipairs(tags) do
        local handlers = self.subscribers[tag]
        if handlers then
            for _, entry in ipairs(handlers) do
                entry.handler(menu, element)
            end
        end
    end
end

WowVision.contextMenuManager = ContextMenuManager:new()
