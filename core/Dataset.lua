local Dataset = WowVision.Class("Dataset")

function Dataset:initialize()
    self.data = {}
    self.pointsById = {}
    self.filters = {}
end

function Dataset:clear()
    self.data = {}
    self.pointsById = {}
end

function Dataset:addPoint(point)
    if point.id == nil then
        error("Datapoints must have a unique id.")
    end
    if self:validate(point) then
        tinsert(self.data, point)
        self.pointsById[point.id] = point
        return true
    end
    return false
end

function Dataset:validateFilter(data, filter)
    if #filter == 3 then
        local a = data[filter[1]]
        local b = data[filter[3]]
        local operator = filter[2]
        if operator == "=" then
            return a == b
        elseif operator == "~=" then
            return a ~= b
        elseif operator == "<" then
            return a < b
        elseif operator == "<=" then
            return a <= b
        elseif operator == ">" then
            return a > b
        elseif operator == ">=" then
            return a >= b
        end
    end
    return false
end

function Dataset:validate(data)
    for _, f in ipairs(self.filters) do
        if not self:validateFilter(data, f) then
            return false
        end
    end
    return true
end

function Dataset:filter(filters)
    local dataset = Dataset:new()

    for _, f in ipairs(self.filters) do
        tinsert(dataset.filters, f)
    end

    for _, f in ipairs(filters) do
        tinsert(dataset.filters, f)
    end

    for _, point in ipairs(self.data) do
        dataset:addPoint(point)
    end

    return dataset
end

WowVision.Dataset = Dataset
