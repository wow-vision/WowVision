local module = WowVision.base.windows.popups:createModule("guildInvite")
local L = module.L
module:setLabel(L["Guild Invitation"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The guild invitation window (GuildInviteFrame) on clients that load it
-- (Retail and WoW: Forever; Vanilla and TBC ask with the GUILD_INVITE
-- popup, which the popups window reads). It is its own window, shown with
-- StaticPopupSpecial_Show, so the popups window never sees it: who invites,
-- the invitation line, the guild, its achievement points where the game
-- shows them, the reputation warning when there is one, then Join Guild and
-- Decline.
--
-- Closing the window declines (its OnHide declines unless Join was
-- pressed), so Escape declines, as in the game; the game also closes it
-- after a minute.

local fontText = nodes.fontText

local function addLine(builder, key, fontString)
    if fontString ~= nil and fontString:IsShown() and nodes.plainText(fontString:GetText()) ~= nil then
        builder:addItem(ControlId.structural("guildInvite:" .. key), nodes.text({ label = fontText(fontString) }))
    end
end

local function render(builder, screen)
    local frame = GuildInviteFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("guildInvite", L["Guild Invitation"])

    builder:beginStop("text")
    addLine(builder, "inviter", GuildInviteFrameInviterName)
    addLine(builder, "invite", GuildInviteFrameInviteText)
    addLine(builder, "guild", GuildInviteFrameGuildName)
    local points = frame.Points
    if points ~= nil and points:IsShown() and points.Title ~= nil and points.Text ~= nil then
        builder:addItem(
            ControlId.structural("guildInvite:points"),
            nodes.text({
                label = function()
                    return nodes.joinLabel(
                        nodes.plainText(points.Title:GetText()),
                        nodes.plainText(points.Text:GetText())
                    )
                end,
            })
        )
    end
    addLine(builder, "warning", GuildInviteFrameWarningText)

    for _, button in ipairs({ GuildInviteFrameJoinButton, GuildInviteFrameDeclineButton }) do
        builder:beginStop()
        builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "GuildInvite",
    frameName = "GuildInviteFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
