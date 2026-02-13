-- SyncedContainer mixin
-- Provides shared behavior for synced container elements (ProxyScrollFrame, ProxyScrollBox, etc.)
-- These elements manage a single childPanel (GeneratorPanel) that displays the current item,
-- navigated by currentIndex into some data source.

local SyncedContainer = {}
WowVision.SyncedContainer = SyncedContainer

function SyncedContainer:included(klass)
    klass.info:updateFields({
        { key = "displayType", default = "List" },
        { key = "sync", default = true },
    })
    klass.info:addFields({
        { key = "wrap", default = false },
    })
end

function SyncedContainer:initSyncedContainer()
    self.childPanel = WowVision.ui:CreateElement("GeneratorPanel", { generator = WowVision.ui.generator })
    self.currentIndex = -1
    self.direction = "vertical"
end

function SyncedContainer:focusCurrent()
    if self.currentIndex >= 1 then
        self.childPanel:focus()
    end
end

function SyncedContainer:unfocusCurrent()
    if self.childPanel:getFocused() then
        self.childPanel:unfocus()
    end
end

function SyncedContainer:setChild(root)
    self.childPanel:setStartingElement(root)
end

function SyncedContainer:isContainer()
    return true
end

function SyncedContainer:getDirectionKeys()
    if self.direction == "vertical" then
        return "up", "down"
    elseif self.direction == "horizontal" then
        return "left", "right"
    elseif self.direction == "tab" then
        return "previous", "next"
    elseif self.direction == "grid" then
        return "up", "right", "down", "left"
    end
    return nil
end

function SyncedContainer:onSyncedFocus()
    local numEntries = self:getNumEntries()
    if numEntries < 1 then
        return
    end
    if self.currentIndex < 1 or self.currentIndex > numEntries then
        -- Clamp to valid range (preserves approximate position if list shrank)
        self:setCurrentIndex(math.max(1, math.min(self.currentIndex, numEntries)))
    end
end

function SyncedContainer:onSyncedUnfocus()
    self:unfocusCurrent()
    self:setChild(nil)
    -- Do NOT reset currentIndex - Navigator preserves and restores it
end

function SyncedContainer:onSyncedUpdate()
    self.childPanel:onUpdate()
end
