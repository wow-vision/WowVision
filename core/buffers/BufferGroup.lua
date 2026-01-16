local BufferGroup, parent = WowVision.buffers:createType("Group")

function BufferGroup:initialize(config)
    parent.initialize(self, config)
    self.wrap = true
end

function BufferGroup:getDefaultDB()
    local db = parent.getDefaultDB(self)
    db.children = {}
    return db
end

function BufferGroup:setDB(db)
    self.items = {}
    parent.setDB(self, db)
    for _, child in ipairs(db.children) do
        local buffer = WowVision.buffers:create(child.type, child)
        self:add(buffer)
    end
end

WowVision.buffers.BufferGroup = BufferGroup
