local module = WowVision.base.windows.professions
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The WoW: Forever crafting page: the other page of ProfessionsFrame, shown
-- when a profession's spell opens its crafting window. It is the retail
-- crafting page without the retail extras (no specializations, no orders):
-- the profession tabs, the rank, a search box and filter menu over a
-- collapsible recipe tree (a recipe's tooltip adds its tools and reagents),
-- the selected recipe (output, requirements, description), and the create
-- controls. The screen follows the Mists trade skill screen: search,
-- filter, recipes, details, quantity, create buttons.
--
-- Nothing here runs the page's own mouse scripts: rows, checkboxes, and
-- buttons are secure clicks on the real frames, and tooltips are filled
-- from the recipe data.

local BANK = Enum.SpellBookSpellBank.Player

-- Difficulty colors as the Mists recipe list speaks them. The retail list
-- marks only recipes that still give skill; the rest are grey.
local difficultyColors = {}
for key, color in pairs({
    Optimal = L["Orange"],
    Medium = L["Yellow"],
    Easy = L["Green"],
    Trivial = L["Grey"],
}) do
    local value = Enum.TradeskillRelativeDifficulty[key]
    if value ~= nil then
        difficultyColors[value] = color
    end
end

local function stripColors(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function gameTooltip(populate)
    return { type = "Game", mode = "immediate", populate = populate }
end

-- ---- profession tabs ----

-- The skill line the page shows (a sub skill line reports its parent, the
-- same test the tabs use for their checked state).
local function currentSkillLine()
    local info = Professions.GetProfessionInfo()
    return info.parentProfessionID or info.professionID
end

-- A tab per profession with a crafting window. The tabs switch on mouse up
-- through a custom handler that casts the profession's spell, an
-- untainted-only call, so Enter casts the spell with a secure /cast instead,
-- as the tab would. The shown profession has no binding: casting it again
-- would close the window.
local function renderProfessionTabs(builder, frame)
    local tabs = {}
    for _, tab in ipairs(frame.rightProfessionTabs) do
        if tab:IsShown() and tab.skillLine ~= nil and tab.spellOffsetIndex ~= nil then
            tinsert(tabs, tab)
        end
    end
    if #tabs == 0 then
        return
    end
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for _, captured in ipairs(tabs) do
        local info = C_SpellBook.GetSpellBookItemInfo(captured.spellOffsetIndex + 1, BANK)
        local spellName = info ~= nil and info.spellID ~= nil and C_Spell.GetSpellName(info.spellID) or nil
        local isShown = captured.skillLine == currentSkillLine()
        local bindings = {}
        if spellName ~= nil and not isShown then
            tinsert(bindings, { binding = "leftClick", type = "Script", script = "/cast " .. spellName })
        end
        builder:addItem(ControlId.structural("tab:" .. captured.skillLine), {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        return captured.tooltipText
                    end,
                    kind = kinds.label,
                },
                {
                    text = function()
                        return captured.skillLine == currentSkillLine() and L["selected"] or nil
                    end,
                    kind = kinds.selected,
                },
            },
            bindings = bindings,
        })
    end
    builder:endRow()
    builder:popContext()
end

-- ---- rank, link, and profession equipment ----

local function equipmentLabel(slot)
    local link = GetInventoryItemLink("player", slot.slotID)
    local name = link ~= nil and C_Item.GetItemInfo(link) or nil
    return name or L["Empty"]
end

-- One stop: the rank line, the link-to-chat menu, and the profession's tool
-- and gear slots (a real click picks the item up or drops the cursor item
-- in, like the character sheet).
local function renderProfession(builder, page)
    builder:beginStop("profession")
    local rankBar = page.RankBar
    if rankBar:IsShown() then
        builder:addItem(
            ControlId.structural("rank"),
            nodes.text({
                label = function()
                    return rankBar.Rank.Text:GetText() or ""
                end,
            })
        )
    end
    if page.LinkButton:IsShown() then
        builder:addItem(
            ControlId.forObject(page.LinkButton),
            nodes.proxyDropdown({ target = page.LinkButton, label = LINK_TRADESKILL_TOOLTIP or L["Link"] })
        )
    end
    for _, slot in ipairs(page.InventorySlots) do
        if slot:IsShown() then
            local captured = slot
            builder:addItem(
                ControlId.forObject(captured),
                nodes.proxyButton({
                    target = captured,
                    hover = false,
                    label = function()
                        return equipmentLabel(captured)
                    end,
                    tooltip = gameTooltip(function(tooltip)
                        tooltip:SetInventoryItem("player", captured.slotID)
                    end),
                })
            )
        end
    end
end

-- ---- recipe data ----

local function requirementsLabel(recipeID)
    local requirements = C_TradeSkillUI.GetRecipeRequirements(recipeID)
    if requirements == nil or #requirements == 0 then
        return nil
    end
    local parts = {}
    for _, requirement in ipairs(requirements) do
        local part = requirement.name
        if not requirement.met then
            part = part .. " (" .. L["Missing"] .. ")"
        end
        tinsert(parts, part)
    end
    return PROFESSIONS_REQUIRED_TOOLS:format(table.concat(parts, ", "))
end

-- An item's name may not be cached yet; asking for it loads it for the
-- next read.
local function reagentName(reagent)
    if reagent.itemID ~= nil then
        local name = C_Item.GetItemNameByID(reagent.itemID)
        if name == nil then
            C_Item.RequestLoadItemDataByID(reagent.itemID)
        end
        return name or UNKNOWN
    end
    return Professions.GetReagentName(reagent)
end

-- The recipe's tools and required reagents, added under the output item's
-- tooltip so a recipe reads what it needs without the details stop. A
-- reagent reads like the game's reagent slot, name first: "Peacebloom 3/2"
-- (have, then need), counted the way the reagent slot counts.
local function addRecipeLines(tooltip, recipeID)
    local requirements = requirementsLabel(recipeID)
    if requirements ~= nil then
        tooltip:AddLine(requirements, 1, 1, 1, true)
    end
    local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
    if schematic == nil then
        return
    end
    local lines = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics) do
        local shown = not slot.hiddenInCraftingForm and #slot.reagents > 0
        if shown and ProfessionsUtil.IsReagentSlotBasicRequired(slot) then
            local have = ProfessionsUtil.AccumulateReagentsInPossession(slot.reagents, false)
            tinsert(lines, reagentName(slot.reagents[1]) .. " " .. have .. "/" .. slot.quantityRequired)
        end
    end
    if #lines == 0 then
        return
    end
    tooltip:AddLine(PROFESSIONS_REAGENT_CONTAINER_LABEL)
    for _, line in ipairs(lines) do
        tooltip:AddLine(line, 1, 1, 1)
    end
end

local function recipeTooltip(recipeID)
    return gameTooltip(function(tooltip)
        tooltip:SetRecipeResultItem(recipeID)
        addRecipeLines(tooltip, recipeID)
        tooltip:Show()
    end)
end

-- ---- the recipe list ----

local function recipeLabel(recipeInfo)
    local info = Professions.GetHighestLearnedRecipe(recipeInfo) or recipeInfo
    local label = info.name or ""
    local count = C_TradeSkillUI.GetCraftableCount(info.recipeID)
    if count ~= nil and count > 0 then
        label = label .. " " .. count
    end
    if info.learned then
        local difficulty = info.canSkillUp and difficultyColors[info.relativeDifficulty] or L["Grey"]
        if difficulty ~= nil then
            label = label .. " (" .. difficulty .. ")"
        end
    end
    if info.disabled and info.disabledReason ~= nil then
        label = label .. ", " .. info.disabledReason
    end
    return label
end

local function rowNode(helpers, announcements, tooltip)
    return {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
        tooltip = tooltip,
    }
end

-- Rows are tree nodes: categories (a click folds them), recipes (left
-- selects, right opens the favorite menu), and the unlearned divider.
-- Spacer rows are skipped. Ids come from the recipe and category, so focus
-- stays on a recipe while searching and filtering rebuild the tree.
local function emitRecipeRow(list)
    return function(builder, node, index, helpers)
        local data = node.GetData ~= nil and node:GetData() or nil
        if type(data) ~= "table" then
            return
        end
        if data.categoryInfo ~= nil then
            local categoryInfo = data.categoryInfo
            builder:addItem(
                ControlId.structural("category:" .. tostring(categoryInfo.categoryID)),
                rowNode(helpers, {
                    { text = categoryInfo.name, kind = kinds.label },
                    {
                        text = function()
                            return node:IsCollapsed() and L["Collapsed"] or L["Expanded"]
                        end,
                        kind = kinds.value,
                    },
                })
            )
        elseif data.recipeInfo ~= nil then
            local recipeInfo = data.recipeInfo
            local key = "recipe:" .. recipeInfo.recipeID
            if recipeInfo.favoritesInstance then
                key = key .. ":favorite"
            end
            builder:addItem(
                ControlId.structural(key),
                rowNode(helpers, {
                    {
                        text = function()
                            return recipeLabel(recipeInfo)
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            return list.selectionBehavior:IsElementDataSelected(node) and L["selected"] or nil
                        end,
                        kind = kinds.selected,
                    },
                }, recipeTooltip(recipeInfo.recipeID))
            )
        elseif data.isDivider then
            builder:addItem(
                ControlId.structural("divider:" .. index),
                nodes.text({ label = PROFESSIONS_CATEGORY_UNLEARNED or "" })
            )
        end
    end
end

local function renderRecipeList(builder, list)
    builder:beginStop("filter")
    builder:addItem(ControlId.forObject(list.FilterDropdown), nodes.proxyDropdown({ target = list.FilterDropdown }))

    builder:beginStop("search")
    builder:addItem(
        ControlId.structural("search"),
        nodes.proxyEditBox({ editBox = list.SearchBox, label = L["Search"] })
    )

    -- A fresh open lands on the top of the recipes (a category heading).
    builder:beginStop("recipes")
    builder:setStartStop("recipes")
    nodes.scrollBoxList(builder, {
        scrollBox = list.ScrollBox,
        key = "recipes",
        label = L["Recipes"],
        emit = emitRecipeRow(list),
    })
end

-- ---- the selected recipe ----

local function detailText(builder, key, label)
    builder:addItem(ControlId.structural(key), nodes.text({ label = label }))
end

-- One stop reading the form top to bottom: the output item, favorite, the
-- requirement and cooldown lines, where an unlearned recipe comes from, the
-- description, and the tracking checkboxes. The reagents are left out: the
-- recipe's tooltip reads them, here and in the list.
local function renderRecipe(builder, form)
    local recipeInfo = form:GetRecipeInfo()
    if not form:IsShown() or recipeInfo == nil then
        return
    end
    local recipeID = recipeInfo.recipeID
    builder:beginStop("details")
    builder:pushContext("details", L["Details"])

    local output = form.OutputIcon
    if output:IsShown() then
        builder:addItem(
            ControlId.structural("output"),
            nodes.proxyButton({
                target = output,
                hover = false,
                label = function()
                    return nodes.joinLabel(nodes.shownText(form.OutputText), nodes.shownText(output.Count))
                end,
                tooltip = recipeTooltip(recipeID),
            })
        )
    end
    if form.FavoriteButton:IsShown() then
        builder:addItem(
            ControlId.forObject(form.FavoriteButton),
            nodes.proxyCheckButton({ target = form.FavoriteButton, label = L["Favorite"], hover = false })
        )
    end
    if form.OutputSubText:IsShown() then
        detailText(builder, "outputSubText", function()
            return nodes.shownText(form.OutputSubText)
        end)
    end
    if form.RequiredTools:IsShown() then
        detailText(builder, "requirements", function()
            return requirementsLabel(recipeID)
        end)
    end
    if form.Cooldown:IsShown() then
        detailText(builder, "cooldown", function()
            return nodes.shownText(form.Cooldown)
        end)
    end
    if form.RecipeSourceButton:IsShown() then
        -- The source itself is only in the button's hover tooltip.
        local sourceID = recipeInfo.learned and recipeInfo.nextRecipeID or recipeID
        detailText(builder, "source", function()
            return nodes.joinLabel(
                nodes.shownText(form.RecipeSourceButton.Text),
                C_TradeSkillUI.GetRecipeSourceText(sourceID)
            )
        end)
    end
    if form.FirstCraftBonus:IsShown() then
        detailText(builder, "firstCraft", function()
            return nodes.shownText(form.FirstCraftBonus.Text)
        end)
    end
    if form.Description:IsShown() then
        detailText(builder, "description", function()
            return nodes.shownText(form.Description)
        end)
    end

    -- Labels come from each checkbox's own text line, named directly.
    for _, checkbox in ipairs({ form.AllocateBestQualityCheckbox, form.TrackRecipeCheckbox }) do
        if checkbox:IsShown() then
            local captured = checkbox
            builder:addItem(
                ControlId.forObject(captured),
                nodes.proxyCheckButton({
                    target = captured,
                    hover = false,
                    label = function()
                        local text = nodes.shownText(captured.Text)
                        return text ~= nil and stripColors(text) or nil
                    end,
                })
            )
        end
    end
    builder:popContext()
end

-- ---- create controls ----

-- A create button; while disabled it also reads why (the game keeps the
-- reason in the button's tooltip text).
local function createButtonNode(button)
    local vtable = nodes.proxyButton({ target = button, hover = false })
    if vtable ~= nil then
        tinsert(vtable.announcements, {
            text = function()
                if not button:IsEnabled() then
                    return button.tooltipText
                end
                return nil
            end,
            kind = kinds.value,
        })
    end
    return vtable
end

local function renderCreateControls(builder, page)
    local quantity = page.CreateMultipleInputBox
    if quantity:IsShown() then
        builder:beginStop("quantity")
        builder:addItem(
            ControlId.structural("quantity"),
            nodes.proxyEditBox({ editBox = quantity, label = L["Quantity"] })
        )
    end
    for _, entry in ipairs({ { "create", page.CreateButton }, { "createAll", page.CreateAllButton } }) do
        local key, button = entry[1], entry[2]
        if button:IsShown() then
            builder:beginStop(key)
            builder:addItem(ControlId.forObject(button), createButtonNode(button))
        end
    end
    local guildButton = page.ViewGuildCraftersButton
    if guildButton:IsShown() then
        builder:beginStop("guildCrafters")
        builder:addItem(ControlId.forObject(guildButton), nodes.proxyButton({ target = guildButton }))
    end
end

-- The crafting page, under the window title ("Alchemy" and the like).
function module.renderCraftingPage(builder, frame)
    local page = frame.CraftingPage
    builder:pushContext("crafting", frame:GetTitleText():GetText() or L["Professions"])
    renderProfessionTabs(builder, frame)
    renderProfession(builder, page)
    if page.RecipeList:IsShown() then
        renderRecipeList(builder, page.RecipeList)
    end
    renderRecipe(builder, page.SchematicForm)
    renderCreateControls(builder, page)
    builder:popContext()
end
