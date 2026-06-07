local module = WowVision.base.targeting:createModule("focus")
local L = module.L
module:setLabel(L["Virtual Focus"])

local NUM_FOCUS = 5

local focusFrames = {}

for i = 1, NUM_FOCUS do
    local focus = {
        frame = CreateFrame("Button", "WowVisionFocus" .. i, UIParent, "SecureActionButtonTemplate"),
    }
    focus.frame:SetAttribute("type", "macro")
    -- The Click binding forwards delegate:Click(button) as a single up/complete
    -- click. SecureActionButton gates the macro on key-down vs key-up, and with
    -- "cast on key down" enabled the delegate would otherwise ignore that click.
    -- Pin it to key-up so the /target macro fires regardless of the cvar.
    focus.frame:SetAttribute("useOnKeyDown", false)
    tinsert(focusFrames, focus)
    module:registerCommand({
        name = "focus" .. i,
        description = "Set focus " .. i .. " to specified unit or target if no args passed.",
        scope = "Global",
        conflictingAddons = { "Sku" },
        func = function(args)
            if InCombatLockdown() then
                print("Cannot set virtual focus while in combat.")
                return
            end
            local id = args
            if (args == nil or args == "") and UnitExists("target") then
                id = UnitName("target")
            end
            module:setFocus(i, id)
            print("focus " .. i .. " set to " .. id .. ".")
        end,
    })
    module:registerBinding({
        type = "Click",
        key = "focus" .. i,
        label = L["Target Focus"] .. " " .. i,
        targetFrame = focus.frame,
        -- The Click chain forwards delegate:Click(button); the button only
        -- propagates if a valid mouse-button string is supplied here. Without it
        -- the secure click is dropped and the /target macro never fires.
        emulatedKey = "LeftButton",
        conflictingAddons = { "Sku" },
    })
end

function module:onEnable()
    self.focus = focusFrames
end

function module:setFocus(index, id)
    if index < 1 or index > NUM_FOCUS then
        error("Focus out of range")
    end
    local focus = self.focus[index]
    focus.id = id
    focus.frame:SetAttribute("macrotext", "/target " .. id)
end
