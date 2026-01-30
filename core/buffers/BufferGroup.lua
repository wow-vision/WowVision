local L = WowVision:getLocale()

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

-- Add a buffer to the group and persist to db
function BufferGroup:addBuffer(buffer)
    self:add(buffer)
    if self.db and self.db.children then
        tinsert(self.db.children, buffer:getDefaultDB())
        -- Link the buffer to its db entry
        buffer.db = self.db.children[#self.db.children]
    end
end

-- Remove a buffer from the group and persist to db
function BufferGroup:removeBuffer(index)
    local buffer = self.items[index]
    if buffer then
        self:remove(buffer)
        if self.db and self.db.children then
            tremove(self.db.children, index)
        end
    end
end

-- Get the buffer type key for a buffer
function BufferGroup:getBufferTypeKey(buffer)
    -- Buffer classes are named like "StaticBuffer", "TrackedBuffer"
    local className = buffer.class.name
    if className:sub(-6) == "Buffer" then
        return className:sub(1, -7)
    end
    return className
end

-- UI Generation

-- Lazily register virtual elements on first use
function BufferGroup:ensureVirtualElements()
    local gen = WowVision.ui.generator
    if gen:hasElement("BufferGroup/manager") then
        return
    end

    gen:Element("BufferGroup/manager", function(props)
        return props.group:buildManager()
    end)

    gen:Element("BufferGroup/typeSelector", function(props)
        return props.group:buildTypeSelector()
    end)

    gen:Element("BufferGroup/bufferEditor", function(props)
        return props.group:buildBufferEditor(props.index)
    end)
end

-- Build the buffer type selector
function BufferGroup:buildTypeSelector()
    local group = self
    local children = {}

    -- Get available buffer types (excluding Group for now)
    local bufferTypes = { "Static", "Tracked" }

    for _, typeKey in ipairs(bufferTypes) do
        tinsert(children, {
            "Button",
            key = typeKey,
            label = typeKey,
            events = {
                click = function(event, button)
                    -- Create new buffer with defaults
                    local newBuffer = WowVision.buffers:create(typeKey, {
                        label = L["New Buffer"],
                    })
                    group:addBuffer(newBuffer)
                    -- Pop type selector and open editor for new buffer
                    button.context:pop()
                    button.context:addGenerated({
                        "BufferGroup/bufferEditor",
                        group = group,
                        index = #group.items,
                    })
                end,
            },
        })
    end

    return {
        "List",
        label = L["Select Buffer Type"],
        children = children,
    }
end

-- Build editor for a specific buffer
function BufferGroup:buildBufferEditor(index)
    local group = self
    local buffer = self.items[index]
    if not buffer then
        return { "List", label = L["Buffer Not Found"], children = {} }
    end

    local children = {}

    -- Buffer settings
    local settingsGen = buffer:getSettingsGenerator()
    settingsGen.key = "settings"
    tinsert(children, settingsGen)

    -- Remove button
    tinsert(children, {
        "Button",
        key = "remove",
        label = L["Remove"],
        events = {
            click = function(event, button)
                group:removeBuffer(index)
                button.context:pop()
            end,
        },
    })

    return {
        "List",
        label = buffer:getLabel() or (self:getBufferTypeKey(buffer) .. " Buffer"),
        children = children,
    }
end

-- Build the buffer manager UI
function BufferGroup:buildManager()
    local group = self
    local children = {}

    -- List existing buffers
    for i, buffer in ipairs(self.items) do
        local bufferLabel = buffer:getLabel() or (self:getBufferTypeKey(buffer) .. " Buffer")
        tinsert(children, {
            "Button",
            key = "buffer_" .. i,
            label = bufferLabel,
            events = {
                click = function(event, button)
                    button.context:addGenerated({
                        "BufferGroup/bufferEditor",
                        group = group,
                        index = i,
                    })
                end,
            },
        })
    end

    -- Add buffer button
    tinsert(children, {
        "Button",
        key = "add",
        label = L["Add"],
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "BufferGroup/typeSelector",
                    group = group,
                })
            end,
        },
    })

    return {
        "List",
        label = self:getLabel() or L["Buffer Group"],
        children = children,
    }
end

-- Override getSettingsGenerator to show buffer management UI
function BufferGroup:getSettingsGenerator()
    self:ensureVirtualElements()
    local group = self

    return {
        "Button",
        label = (self:getLabel() or L["Buffer Group"]) .. " (" .. #self.items .. " buffers)",
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "BufferGroup/manager",
                    group = group,
                })
            end,
        },
    }
end

WowVision.buffers.BufferGroup = BufferGroup
