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

-- Whether navigation may land on an item: one that reports itself disabled
-- (a buffer or buffer group switched off) is skipped.
local function isNavigable(item)
    return type(item) ~= "table" or item.getEnabled == nil or item:getEnabled() ~= false
end

-- The index one step on from "from", wrapping if the list wraps; nil past
-- an end otherwise.
local function nextIndex(list, from, direction)
    local target = from + direction
    if target >= 1 and target <= #list.items then
        return target
    end
    if list.wrap then
        return target < 1 and #list.items or 1
    end
    return nil
end

function ViewList:focusDirection(direction)
    if #self.items == 0 or direction == 0 then
        return nil
    end
    if self.reverse then
        direction = direction * -1
    end
    local target
    if self.index < 1 or self.index > #self.items then
        target = (direction < 0 and self.wrap) and #self.items or 1
    else
        target = nextIndex(self, self.index, direction)
    end
    -- Step past disabled items; one full pass without a navigable one stays put.
    local steps = 0
    while target ~= nil and not isNavigable(self.items[target]) do
        steps = steps + 1
        if steps >= #self.items then
            target = nil
        else
            target = nextIndex(self, target, direction)
        end
    end
    if target == nil then
        return self:focusIndex(self.index)
    end
    return self:focusIndex(target)
end

function ViewList:UIFocusDirection(direction)
    local result = self:focusDirection(direction)
    if result == nil then
        return
    end
    WowVision:speak(result:getFocusString())
end

WowVision.ViewList = ViewList
