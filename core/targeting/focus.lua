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
