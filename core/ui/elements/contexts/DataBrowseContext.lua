local Context, parent = WowVision.ui:CreateElementType("DataBrowseContext", "StackContext")

Context.info:addFields({
    { key = "directory", required = true, compareMode = "direct" },
})

function Context:initialize()
    parent.initialize(self)

    self:addEvent("confirm")
    self:addEvent("cancel")
    self.selectedSource = nil
    self.pathSegments = {}

    self.closeBinding = self:addBinding({
        binding = "close",
        targetFrame = self,
        enabled = true,
    })
end

function Context:onSetInfo()
    if self.directory then
        self:pushDirectory(self.directory, true)
    end
end

function Context:buildPath(entryKey)
    local parts = {}
    for _, segment in ipairs(self.pathSegments) do
        tinsert(parts, segment)
    end
    tinsert(parts, entryKey)
    return table.concat(parts, "/")
end

function Context:pushDirectory(directory, isRoot)
    if not isRoot then
        tinsert(self.pathSegments, directory.key)
    end

    local list = WowVision.ui:CreateElement("List")
    local label = (directory.getLabel and directory:getLabel()) or directory.label or directory.key or ""
    list:setLabel(label)

    for _, subdir in ipairs(directory.subdirectories) do
        local button = WowVision.ui:CreateElement("Button")
        local subdirLabel = (subdir.getLabel and subdir:getLabel()) or subdir.label or subdir.key or ""
        button:setLabel(subdirLabel)
        button.events.click:subscribe(self, function(self, event)
            self:pushDirectory(subdir)
        end)
        list:add(button)
    end

    for _, entry in ipairs(directory.entries) do
        local element = entry:getElement()
        local path = self:buildPath(entry.key)
        element.events.click:subscribe(self, function(self, event)
            self.selectedSource = entry
            self.selectedPath = path
            self:emitEvent("confirm", self, entry, path)
        end)
        list:add(element)
    end

    self:add(list)
end

function Context:handleEscape()
    if #self.children > 1 then
        self:pop()
        tremove(self.pathSegments)
    else
        self:emitEvent("cancel", self)
    end
end

function Context:onBindingPressed(binding)
    if binding.key == "close" then
        WowVision.base.speech:stop()
        if WowVision.consts.UI_DELAY > 0 then
            C_Timer.After(0.01, function()
                self:handleEscape()
            end)
        else
            self:handleEscape()
        end
        return true
    end
    return false
end

function Context:getLabel()
    return "browse"
end
