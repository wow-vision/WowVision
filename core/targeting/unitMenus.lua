local module = WowVision.base.targeting
local L = module.L

-- The target's menu (Copy Character Name, Whisper, Invite and the rest; with
-- yourself targeted, Reset All Instances, loot and difficulty), opened by a
-- secure button of our own with the "togglemenu" action, which Blizzard keeps
-- for addons (SecureTemplates.lua). It opens the same menu as a right click on
-- the target frame (UnitPopup_OpenMenu, the kind of menu chosen from the unit)
-- and the dropdown reader (core/graph/dropdownMenu.lua) reads it.
--
-- Not a click on TargetFrame (the CLICK TargetFrame:RightButton binding): the
-- target frame acts on the key's release only, and SecureUnitButton_OnClick
-- asks the click-binding system about the button with the modifiers held at
-- that moment. Alt plus right click is not its menu, so Alt-T worked only when
-- Alt came up before T. This button acts like the virtual focus buttons
-- (focus.lua): the Click binding forwards a key-up click, pinned with
-- useOnKeyDown, and no modifier is asked. Without a target nothing opens.
local button = CreateFrame("Button", "WowVisionTargetMenu", UIParent, "SecureActionButtonTemplate")
button:SetAttribute("type", "togglemenu")
button:SetAttribute("unit", "target")
button:SetAttribute("useOnKeyDown", false)

module:registerBinding({
    type = "Click",
    key = "targetMenu",
    label = L["Open Target Menu"],
    inputs = { "ALT-T" },
    targetFrame = button,
    -- the Click chain forwards delegate:Click(button); without a mouse button
    -- string the secure click is dropped (see focus.lua)
    emulatedKey = "LeftButton",
})
