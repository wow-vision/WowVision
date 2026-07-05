local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local L = WowVision:getLocale()

-- Dropdown menus, graph-side: watches the modern Menu manager for an open
-- menu anywhere and presents it as its own stack while it lives. Items are
-- the menu's real buttons (real clicks); titles read as text. Replaces the
-- legacy MenuManager path.
local dropdown = {
    stack = nil,
    frame = nil,
    overrides = {},
    active = nil,
}
graph.dropdown = dropdown

-- Per-menu item overrides for menus whose rows need custom handling:
-- emitters[index] = function(builder, itemFrame, index). Registered through
-- Module:registerDropdownMenu; mirrored into Menu.ModifyMenu so the active
-- set follows whichever menu generated last.
function dropdown.registerMenu(menuKey, emitters)
    if dropdown.overrides[menuKey] ~= nil then
        dropdown.overrides[menuKey] = emitters
        return
    end
    dropdown.overrides[menuKey] = emitters
    Menu.ModifyMenu(menuKey, function()
        dropdown.active = dropdown.overrides[menuKey]
    end)
end

function dropdown.unregisterMenu(menuKey)
    dropdown.overrides[menuKey] = nil
end

local RADIO_TEXTURE = 130940
local CHECK_TEXTURE = 136810

local function itemRegions(item)
    local labelRegion, stateRegion
    for _, region in ipairs({ item:GetRegions() }) do
        local kind = region:GetObjectType()
        if kind == "FontString" and labelRegion == nil then
            labelRegion = region
        elseif
            kind == "Texture"
            and (region:GetTexture() == CHECK_TEXTURE or region:GetTexture() == RADIO_TEXTURE)
        then
            stateRegion = region
        end
    end
    return labelRegion, stateRegion
end

local function renderMenu(builder, menuFrame)
    if menuFrame == nil or not menuFrame:IsShown() then
        return
    end
    builder:pushContext("dropdown", L["Dropdown"])
    builder:beginStop("items")

    local frames = { menuFrame:GetChildren() }
    for i = 3, #frames do
        local item = frames[i]
        local index = i - 2
        local override = dropdown.active ~= nil and dropdown.active[index] or nil
        if type(override) == "function" then
            local ok, err = pcall(override, builder, item, index)
            if not ok then
                geterrorhandler()(err)
            end
        elseif item:GetObjectType() == "Button" then
            local labelRegion, stateRegion = itemRegions(item)
            local vtable = nodes.proxyButton({
                target = item,
                label = function()
                    return labelRegion ~= nil and labelRegion:GetText() or nil
                end,
            })
            if vtable ~= nil then
                if stateRegion ~= nil then
                    -- Check and radio items show their mark texture when set.
                    vtable.controlType = graph.controlTypes.toggle
                    tinsert(vtable.announcements, {
                        text = function()
                            return stateRegion:IsShown() and L["Checked"] or L["Unchecked"]
                        end,
                        kind = kinds.value,
                    })
                end
                builder:addItem(ControlId.forObject(item), vtable)
            end
        else
            local labelRegion = itemRegions(item)
            if labelRegion ~= nil and item:IsShown() then
                builder:addItem(
                    ControlId.forObject(item),
                    nodes.text({
                        label = function()
                            return labelRegion:GetText()
                        end,
                    })
                )
            end
        end
    end

    builder:popContext()
end

-- Called every frame from UIHost's update.
function dropdown.update()
    local manager = Menu ~= nil and Menu.GetManager ~= nil and Menu:GetManager() or nil
    local open = manager ~= nil and manager:GetOpenMenu() or nil
    if open == dropdown.frame then
        return
    end
    if dropdown.stack ~= nil then
        WowVision.graphHost:close(dropdown.stack)
        dropdown.stack = nil
    end
    dropdown.frame = open
    if open ~= nil then
        local menuFrame = open
        dropdown.stack = WowVision.graphHost:open({
            key = "dropdown",
            render = function(builder)
                renderMenu(builder, menuFrame)
            end,
        })
    else
        dropdown.active = nil
    end
end
