local ViewList = {}

function ViewList:setupViewList()
    self.index = -1
    self.items = {}
    self.reverse = false
    self.wrap = false
    self.allowRefocus = false
end

function ViewList:add(index, item)
    if item then
        tinsert(self.items, index, item)
        if index <= self.index then
            self.index = self.index + 1
        end
        return true
    end
    tinsert(self.items, index)
    return true
end

function ViewList:remove(item)
    for i, v in ipairs(self.items) do
        if item == v then
            table.remove(self.items, i)
            if i <= self.index then
                self.index = self.index - 1
            end
            return true
        end
    end
    return false
end

function ViewList:clear()
    self.items = {}
end

function ViewList:getFocus()
    if #self.items == 0 then
        return nil
    end
    if self.index < 1 then
        self.index = 1
    end
    return self.items[self.index]
end

function ViewList:focusIndex(index)
    if index == self.index and not self.allowRefocus then
        return nil
    end
    if index >= 1 and index <= #self.items then
        self.index = index
        return self:getFocus()
    end
    return nil
end

function ViewList:focusDirection(direction)
    if #self.items == 0 or direction == 0 then
        return nil
    end
    local target
    if self.reverse then
        direction = direction * -1
    end
    if self.index < 0 or self.index > #self.items then
        if direction > 0 then
            target = 1
        end
        if direction < 0 then
            if self.wrap then
                target = #self.items
            else
                target = 1
            end
        end
    else
        target = self.index + direction
    end
    if target >= 1 and target <= #self.items then
        return self:focusIndex(target)
    end
    if self.wrap then
        if target < 1 then
            return self:focusIndex(#self.items)
        else
            return self:focusIndex(1)
        end
    else
        return self:focusIndex(self.index)
    end
end

function ViewList:UIFocusDirection(direction)
    local result = self:focusDirection(direction)
    if result == nil then
        return
    end
    WowVision:speak(result:getFocusString())
end

WowVision.ViewList = ViewList
