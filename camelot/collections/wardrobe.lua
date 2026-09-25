local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The WoW: Forever appearances tab (WardrobeCollectionFrame, journal side,
-- not the transmogrifier): the Items / Sets sub-tabs, search, filter, the
-- class filter, then the active view.
--   Items: the slot buttons, the weapon type dropdown on weapon slots, the
--   current page of appearances (eighteen models), and the page controls.
--   Forever lists collected appearances only.
--   Sets: the set list and the selected set's details.

local function renderSubTabs(builder, frame)
    builder:beginStop("wardrobeTabs")
    builder:pushContext("wardrobeTabs", L["Tabs"])
    builder:startRow()
    for i = 1, 2 do
        local tab = _G["WardrobeCollectionFrameTab" .. i]
        if tab ~= nil and tab:IsShown() then
            local tabID = tab:GetID()
            local vtable = nodes.proxyButton({ target = tab, hover = false })
            tinsert(vtable.announcements, {
                text = function()
                    return frame.selectedCollectionTab == tabID and L["selected"] or nil
                end,
                kind = kinds.selected,
            })
            builder:addItem(ControlId.forObject(tab), vtable)
        end
    end
    builder:endRow()
    builder:popContext()
end

-- ---- Items ----

local function slotLabel(button)
    local name = button.slot ~= nil and _G[button.slot] or nil
    if button.transmogLocation ~= nil and button.transmogLocation:IsIllusion() then
        return module.joinLabel({ name, WEAPON_ENCHANTMENT })
    end
    return name
end

-- Slot buttons as a vertical list, like the character window's equipment;
-- the active slot reads selected.
local function renderSlots(builder, items)
    local slots = items.SlotsFrame ~= nil and items.SlotsFrame.Buttons or nil
    if slots == nil then
        return
    end
    builder:beginStop("wardrobeSlots")
    builder:pushContext("wardrobeSlots", L["Items"])
    for _, button in ipairs(slots) do
        if button:IsShown() then
            local captured = button
            local vtable = nodes.proxyButton({
                target = captured,
                hover = false,
                label = function()
                    return slotLabel(captured)
                end,
            })
            tinsert(vtable.announcements, {
                text = function()
                    return captured.SelectedTexture ~= nil and captured.SelectedTexture:IsShown() and L["selected"] or nil
                end,
                kind = kinds.selected,
            })
            builder:addItem(ControlId.forObject(captured), vtable)
        end
    end
    builder:popContext()
end

-- The model showing this appearance (by visual id), or nil.
local function findModel(items, visualID)
    for _, model in ipairs(items.Models or {}) do
        if model:IsShown() and model.visualInfo ~= nil and model.visualInfo.visualID == visualID then
            return model
        end
    end
    return nil
end

-- The appearance's sources (the items that grant it), best first.
local function appearanceSources(items, visualID)
    if CollectionWardrobeUtil == nil or CollectionWardrobeUtil.GetSortedAppearanceSources == nil then
        return {}
    end
    return CollectionWardrobeUtil.GetSortedAppearanceSources(
        visualID,
        items:GetActiveCategory(),
        items:GetTransmogLocation()
    ) or {}
end

local function isIllusionView(items)
    local location = items:GetTransmogLocation()
    return location ~= nil and location:IsIllusion()
end

-- An appearance's label: the name of its first source item (or the
-- illusion's name), then not collected or favorite.
local function appearanceLabel(items, model)
    local info = model.visualInfo
    local name
    if isIllusionView(items) and info.sourceID ~= nil then
        name = C_TransmogCollection.GetIllusionStrings(info.sourceID)
    else
        local source = appearanceSources(items, info.visualID)[1]
        name = source ~= nil and source.name or nil
    end
    return module.joinLabel({
        name or tostring(info.visualID),
        not info.isCollected and NOT_COLLECTED or nil,
        info.isFavorite and FAVORITE or nil,
    })
end

-- An appearance: the models are not buttons and a plain click does nothing
-- in the journal, so the only action is the right-click menu (favorite,
-- transmogrify-as source), opened by running the model's own mouse
-- handlers as a right button press and release.
local function appearanceNode(items, visualID)
    local function find()
        return findModel(items, visualID)
    end
    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    local model = find()
                    return model ~= nil and appearanceLabel(items, model) or nil
                end,
                kind = kinds.label,
            },
        },
        bindings = {
            {
                binding = "rightClick",
                type = "Function",
                func = function()
                    local model = find()
                    if model == nil then
                        return
                    end
                    local down = model:GetScript("OnMouseDown")
                    if down ~= nil then
                        down(model, "RightButton")
                    end
                    local up = model:GetScript("OnMouseUp")
                    if up ~= nil then
                        up(model, "RightButton")
                    end
                end,
            },
        },
        tooltipFrame = find,
        tooltip = {
            type = "Game",
            mode = "immediate",
            populate = function(tooltip)
                local model = find()
                if model == nil then
                    return
                end
                if isIllusionView(items) then
                    tooltip:SetText(appearanceLabel(items, model))
                    return
                end
                local source = appearanceSources(items, visualID)[1]
                if source ~= nil and source.itemID ~= nil then
                    tooltip:SetItemByID(source.itemID)
                end
            end,
        },
    }
end

local function renderItems(builder, items)
    renderSlots(builder, items)

    if items.WeaponDropdown ~= nil and items.WeaponDropdown:IsShown() then
        builder:beginStop("wardrobeWeapon")
        builder:addItem(ControlId.forObject(items.WeaponDropdown), module.namedDropdown(items.WeaponDropdown, L["Type"]))
    end

    builder:beginStop("appearances")
    builder:pushContext("appearances", L["Appearances"])
    local emitted = 0
    for _, model in ipairs(items.Models or {}) do
        local info = model.visualInfo
        if model:IsShown() and info ~= nil and info.visualID ~= nil then
            builder:addItem(
                ControlId.structural("appearance:" .. info.visualID),
                appearanceNode(items, info.visualID)
            )
            emitted = emitted + 1
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("appearancesEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    module.renderPaging(builder, "wardrobe", items.PagingFrame)
end

-- ---- Sets ----

-- A set's label: name, its label (the set's group, e.g. a raid tier),
-- and collected pieces out of all.
local function setLabel(data)
    local collected, total = 0, 0
    for _, appearance in ipairs(C_TransmogSets.GetSetPrimaryAppearances(data.setID) or {}) do
        total = total + 1
        if appearance.collected then
            collected = collected + 1
        end
    end
    return module.joinLabel({
        data.name,
        data.label,
        total > 0 and (collected .. "/" .. total) or nil,
        data.favorite and FAVORITE or nil,
    })
end

local function setRow(sets)
    return function(data, index, helpers)
        return {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        return setLabel(data)
                    end,
                    kind = kinds.label,
                },
                {
                    text = function()
                        return sets:GetSelectedSetID() == data.setID and L["selected"] or nil
                    end,
                    kind = kinds.selected,
                },
            },
            bindings = {
                -- Left selects the set (its details follow); right opens the
                -- favorite menu.
                { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
            },
            onFocus = helpers.onFocus,
            onFocusTick = helpers.onFocusTick,
            onUnfocus = helpers.onUnfocus,
        }
    end
end

-- The selected set's details: its name and group, the variant dropdown,
-- and each piece with whether it is collected, in layout order.
local function renderSetDetails(builder, sets)
    local details = sets.DetailsFrame
    if details == nil or not details:IsShown() or sets:GetSelectedSetID() == nil then
        return
    end
    builder:beginStop("setDetails")
    builder:pushContext("setDetails", L["Details"])
    builder:addItem(
        ControlId.structural("setDetailsName"),
        nodes.text({
            label = function()
                return module.joinLabel({
                    module.shownText(details.Name) or module.shownText(details.LongName),
                    module.shownText(details.Label),
                })
            end,
        })
    )
    if details.itemFramesPool ~= nil then
        local pieces = {}
        for piece in details.itemFramesPool:EnumerateActive() do
            if piece.sourceID ~= nil then
                tinsert(pieces, piece)
            end
        end
        table.sort(pieces, function(a, b)
            return (a:GetLeft() or 0) < (b:GetLeft() or 0)
        end)
        for _, piece in ipairs(pieces) do
            local sourceID, collected = piece.sourceID, piece.collected
            local info = C_TransmogCollection.GetSourceInfo(sourceID)
            builder:addItem(
                ControlId.structural("setPiece:" .. sourceID),
                nodes.text({
                    label = module.joinLabel({
                        info ~= nil and info.name or tostring(sourceID),
                        collected and COLLECTED or NOT_COLLECTED,
                    }),
                })
            )
        end
    end
    builder:popContext()

    if details.VariantSetsDropdown ~= nil and details.VariantSetsDropdown:IsShown() then
        builder:beginStop("setVariants")
        builder:addItem(
            ControlId.forObject(details.VariantSetsDropdown),
            nodes.proxyDropdown({ target = details.VariantSetsDropdown })
        )
    end
end

local function renderSets(builder, sets)
    builder:beginStop("sets")
    nodes.scrollBoxList(builder, {
        scrollBox = sets.ListContainer.ScrollBox,
        key = "sets",
        label = WARDROBE_SETS,
        id = function(data, index)
            return ControlId.structural("set:" .. tostring(data.setID))
        end,
        row = setRow(sets),
    })
    renderSetDetails(builder, sets)
end

function module.renderWardrobe(builder)
    local frame = WardrobeCollectionFrame
    renderSubTabs(builder, frame)
    module.renderSearchAndFilter(builder, "wardrobe", frame.SearchBox, frame.FilterButton)
    if frame.ClassDropdown ~= nil and frame.ClassDropdown:IsShown() then
        builder:beginStop("wardrobeClass")
        builder:addItem(ControlId.forObject(frame.ClassDropdown), module.namedDropdown(frame.ClassDropdown, CLASS))
    end

    local items, sets = frame.ItemsCollectionFrame, frame.SetsCollectionFrame
    if items ~= nil and items:IsShown() then
        renderItems(builder, items)
    elseif sets ~= nil and sets:IsShown() then
        renderSets(builder, sets)
    end
end
