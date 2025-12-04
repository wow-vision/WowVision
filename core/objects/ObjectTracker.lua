local ObjectTracker = WowVision.Class("ObjectTracker")

function ObjectTracker:initialize(trackingInfo)
    self.events = {
        add = WowVision.Event:new("add"),
        modify = WowVision.Event:new("modify"),
        remove = WowVision.Event:new("remove"),
    }
    self.items = {}
    self.trackingInfo = trackingInfo or {}
    if self.trackingInfo.params == nil then
        self.trackingInfo.params = {}
    end
end

function ObjectTracker:verify(obj)
    --params check
    for k, v in pairs(self.trackingInfo.params) do
        if v ~= obj.params[k] then
            return false
        end
    end
    return true
end

function ObjectTracker:add(obj)
    if self.items[obj] then
        return
    end
    if not self:verify(obj) then
        return
    end
    self.items[obj] = true
    self.events.add:emit(obj)
end

function ObjectTracker:modify(obj)
    if self:verify(obj) then
        self:add(obj)
    else
        self:remove(obj)
    end
end

function ObjectTracker:remove(obj)
    if self.items[obj] == nil then
        return
    end
    self.items[obj] = nil
    self.events.remove:emit(obj)
end

function ObjectTracker:untrack()
    if self.manager then
        self.manager:untrack(self)
    end
end

WowVision.objects.ObjectTracker = ObjectTracker
