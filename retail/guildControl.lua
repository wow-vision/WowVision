local module = WowVision.base.windows:createModule("guildControl")
local L = module.L
module:setLabel(L["Guild Control"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Guild control (GuildControlUI, Blizzard_GuildControlUI): opened by the
-- Guild Control button on the guild window's roster, for the guild master
-- and officers. A dropdown on top picks the page:
-- - Guild Ranks: each rank's name box (the game saves a new name when the
--   box loses focus), move up, move down, delete; Add Rank.
-- - Rank Permissions: the rank dropdown, then the permission check boxes
--   and the gold a rank may withdraw a day.
-- - Guild Bank Tab Permissions: the rank dropdown, then per bank tab view,
--   deposit and the item withdrawals a day; the next tab to buy.
-- - Discord: read as its texts and controls.
-- Every control is the game's own box, button or check box.

local plainText = nodes.plainText
local fontText = nodes.fontText

local function addProxy(builder, button, stopKey, label)
    if button == nil then
        return
    end
    local vtable = nodes.proxyButton({ target = button, label = label })
    if vtable ~= nil then
        if stopKey ~= nil then
            builder:beginStop(stopKey)
        end
        builder:addItem(ControlId.forObject(button), vtable)
    end
end

local function addCheck(builder, check, label, scrollFrame)
    if check == nil or not check:IsShown() then
        return
    end
    local vtable = nodes.proxyCheckButton({ target = check, label = label or fontText(check.text or check.Text) })
    if vtable ~= nil then
        if scrollFrame ~= nil then
            nodes.attachScrollFrame(vtable, scrollFrame, check)
        end
        builder:addItem(ControlId.forObject(check), vtable)
    end
end

-- An amount box the game greys out with a mask frame over it: a line while
-- masked, the real box otherwise.
local function addAmountBox(builder, editBox, label, scrollFrame)
    if editBox == nil or not editBox:IsShown() then
        return
    end
    if editBox.mask ~= nil and editBox.mask:IsShown() then
        builder:addItem(
            ControlId.forObject(editBox),
            nodes.text({
                label = function()
                    return nodes.joinLabel(label, editBox:GetText(), L["Disabled"])
                end,
            })
        )
        return
    end
    local vtable = nodes.proxyEditBox({ editBox = editBox, label = label })
    if vtable ~= nil then
        if scrollFrame ~= nil then
            nodes.attachScrollFrame(vtable, scrollFrame, editBox)
        end
        builder:addItem(ControlId.forObject(editBox), vtable)
    end
end

-- The rank dropdown of the permission pages, with the rank it shows.
local function addRankDropdown(builder, dropdown)
    if dropdown == nil then
        return
    end
    local vtable = nodes.proxyDropdown({
        target = dropdown,
        label = function()
            local rank = GuildControlUI.currentRank
            return nodes.joinLabel(GUILDCONTROL_SELECTRANK, rank ~= nil and GuildControlGetRankName(rank) or nil)
        end,
    })
    if vtable ~= nil then
        builder:beginStop("rank")
        builder:addItem(ControlId.forObject(dropdown), vtable)
    end
end

-- Guild Ranks page.
local function renderRankOrder(builder, page)
    builder:beginStop("ranks")
    builder:pushContext("ranks", GUILDCONTROL_GUILDRANKS)
    for index = 1, GuildControlGetNumRanks() do
        local rank = _G["GuildControlUIRankOrderFrameRank" .. index]
        if rank ~= nil and rank:IsShown() then
            local label = fontText(rank.rankLabel)
            builder:startRow("rank")
            local nameBox = nodes.proxyEditBox({ editBox = rank.nameBox, label = label })
            if nameBox ~= nil then
                builder:addItem(ControlId.forObject(rank.nameBox), nameBox)
            end
            -- Icon buttons, named by their tooltips.
            addProxy(builder, rank.upButton, nil, GUILD_RAISERANK_BUTTON_TOOLTIP)
            addProxy(builder, rank.downButton, nil, GUILD_LOWERRANK_BUTTON_TOOLTIP)
            addProxy(builder, rank.deleteButton, nil, GUILDREMOVERANK_BUTTON_TOOLTIP)
            builder:endRow()
        end
    end
    builder:popContext()
    -- No Duplicate Rank: Blizzard never shows page.dupButton (its Show is
    -- commented out in Blizzard_GuildControlUI.lua).
    addProxy(builder, page.newButton, "newRank")
end

-- Rank Permissions page: the check boxes in the order the page shows them
-- (by their ids), the officer permissions text after the officer box, the
-- gold a day with the bank permissions.
local PERMISSION_ORDER = { 5, 7, 6, 8, 2, 21 }
local BANK_PERMISSION_ORDER = { 15, 19, 16 }

local function renderRankPermissions(builder, page)
    addRankDropdown(builder, page.dropdown)
    local pageName = page:GetName()
    local prefix = pageName .. "Checkbox"

    builder:beginStop("officer")
    addCheck(builder, page.OfficerCheckbox)
    if page.OfficerPermissions ~= nil and page.OfficerPermissions:IsShown() then
        builder:addItem(
            ControlId.structural("officerPermissions"),
            nodes.text({
                label = function()
                    local text = page.OfficerPermissions:GetText()
                    return text ~= nil and plainText(text:gsub("|n", ", ")) or nil
                end,
            })
        )
    end

    builder:beginStop("permissions")
    builder:pushContext("permissions", GUILDCONTROL_RANK_PERMISSIONS)
    for _, id in ipairs(PERMISSION_ORDER) do
        addCheck(builder, _G[prefix .. id])
    end
    builder:popContext()

    local bankLabel = _G[pageName .. "BankLabel"]
    if bankLabel ~= nil and bankLabel:IsShown() then
        builder:beginStop("bankPermissions")
        builder:pushContext("bankPermissions", plainText(bankLabel:GetText()) or GUILD_BANK)
        for _, id in ipairs(BANK_PERMISSION_ORDER) do
            addCheck(builder, _G[prefix .. id])
        end
        addAmountBox(builder, page.goldBox, GOLD_PER_DAY)
        builder:popContext()
    end

    -- Authenticator required: greyed out for the last rank and for a rank
    -- in use (its reason is the tooltip).
    builder:beginStop("authenticator")
    addCheck(builder, _G[prefix .. "18"])
end

-- Guild Bank Tab Permissions page.
local function renderBankTabs(builder, page)
    addRankDropdown(builder, page.dropdown)
    local scrollFrame = page.scrollFrame
    for index = 1, MAX_GUILDBANK_TABS or 8 do
        local tab = _G["GuildControlBankTab" .. index]
        if tab == nil then
            break
        end
        if tab:IsShown() then
            local key = "bankTab:" .. index
            local owned, buy = tab.owned, tab.buy
            if owned ~= nil and owned:IsShown() then
                builder:beginStop(key)
                builder:pushContext(key, fontText(owned.tabName))
                addCheck(builder, owned.viewCB, nil, scrollFrame)
                addCheck(builder, owned.depositCB, nil, scrollFrame)
                addAmountBox(builder, owned.editBox, GUILDCONTROL_WITHDRAW_ITEMS, scrollFrame)
                builder:popContext()
            elseif buy ~= nil and buy:IsShown() then
                builder:beginStop(key)
                builder:pushContext(key, PURCHASE_TAB_TEXT)
                builder:addItem(
                    ControlId.structural(key .. ":cost"),
                    nodes.text({
                        label = function()
                            return nodes.joinLabel(COSTS_LABEL, GetMoneyString(GetGuildBankTabCost() or 0))
                        end,
                    })
                )
                addProxy(builder, buy.button)
                builder:popContext()
            end
        end
    end
end

-- Discord page: its texts and controls in order (the parts the game shows
-- change with the link state).
local function renderDiscord(builder, page)
    local index = 0
    local function walk(frame)
        for _, region in ipairs({ frame:GetRegions() }) do
            local isText = region:GetObjectType() == "FontString" and region:IsVisible()
            if isText and plainText(region:GetText()) ~= nil then
                index = index + 1
                builder:addItem(ControlId.structural("discord:text:" .. index), nodes.text({ label = fontText(region) }))
            end
        end
        for _, child in ipairs({ frame:GetChildren() }) do
            if child:IsVisible() then
                if child:IsObjectType("CheckButton") then
                    local label = child.Label or child.text or child.Text
                    if label == nil and child:GetParent() ~= nil then
                        label = child:GetParent().Label
                    end
                    addCheck(builder, child, label ~= nil and fontText(label) or nil)
                elseif child.OpenMenu ~= nil then
                    local vtable = nodes.proxyDropdown({ target = child })
                    if vtable ~= nil then
                        builder:addItem(ControlId.forObject(child), vtable)
                    end
                elseif child:IsObjectType("Button") then
                    addProxy(builder, child)
                else
                    walk(child)
                end
            end
        end
    end
    builder:beginStop("discord")
    walk(page)
end

local function render(builder, screen)
    local frame = GuildControlUI
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("guildControl", fontText(GuildControlUITitle))

    local navigation = frame.dropdown
    if navigation ~= nil then
        local vtable = nodes.proxyDropdown({ target = navigation })
        if vtable ~= nil then
            builder:beginStop("page")
            builder:addItem(ControlId.forObject(navigation), vtable)
        end
    end

    if frame.orderFrame ~= nil and frame.orderFrame:IsShown() then
        renderRankOrder(builder, frame.orderFrame)
    elseif frame.rankPermFrame ~= nil and frame.rankPermFrame:IsShown() then
        renderRankPermissions(builder, frame.rankPermFrame)
    elseif frame.bankTabFrame ~= nil and frame.bankTabFrame:IsShown() then
        renderBankTabs(builder, frame.bankTabFrame)
    elseif frame.discordFrame ~= nil and frame.discordFrame:IsShown() then
        renderDiscord(builder, frame.discordFrame)
    end

    addProxy(builder, frame.CloseButton, "close", CLOSE)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "GuildControlUI",
    frameName = "GuildControlUI",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
