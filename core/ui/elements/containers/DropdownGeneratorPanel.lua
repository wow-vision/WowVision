local DropdownGeneratorPanel, parent = WowVision.ui:CreateElementType("DropdownGeneratorPanel", "GeneratorPanel")

function DropdownGeneratorPanel:initialize(generator, dropdown, description)
    parent.initialize(self, generator, nil)
    self.dropdown = dropdown
    self.description = description
end

function DropdownGeneratorPanel:generateButton(frame, regions)
    return { "ProxyButton", frame = frame, dropdown = true }
end

function DropdownGeneratorPanel:generateCheckbox(frame, regions)
    return { "ProxyCheckButton", frame = frame, dropdown = true }
end

function DropdownGeneratorPanel:generateTitle(frame, regions)
    local text = regions[1]:GetText() or ""
    return { "Text", displayType = "Separator", text = text }
end

function DropdownGeneratorPanel:generateFrame(index, frame)
    if self.description then
        local newFrame = self.description[index]
        if newFrame then
            if not newFrame.frame then
                newFrame.frame = frame
            end
            return newFrame
        end
    end
    local regions = { frame:GetRegions() }
    if #regions < 1 then
        return
    end
    if frame:GetObjectType() == "Button" then
        if regions[1]:GetObjectType() == "Texture" and regions[1]:GetTexture() == 130940 then
            return self:generateButton(frame, regions)
        elseif regions[1]:GetObjectType() == "Texture" and regions[1]:GetTexture() == 136810 then
            if #regions == 3 then
                return self:generateCheckbox(frame, regions)
            end
        end
        return self:generateButton(frame, regions)
    end
    if regions[1]:GetObjectType() == "FontString" then
        return self:generateTitle(frame, regions)
    end

    return nil
end

function DropdownGeneratorPanel:generateFromDropdown()
    local frames = { self.dropdown:GetChildren() }
    local result = { "List", label = "Dropdown", displayType = "", children = {} }

    for i = 3, #frames do
        local frame = frames[i]
        local newFrame = self:generateFrame(i - 2, frame)
        if newFrame then
            tinsert(result.children, newFrame)
        end
    end
    return result
end

function DropdownGeneratorPanel:onUpdate()
    self:setStartingElement(self:generateFromDropdown())
    parent.onUpdate(self)
end
