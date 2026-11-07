-- The trainer window (core/windows/training.lua) on Retail and WoW: Forever.
local module = WowVision.base.windows.training

-- WoW: Forever turns Train on only while it draws the selected row, so on
-- opening the window the first learnable service can be selected (or the
-- frame can have no selection at all) while Train stays off until that row
-- is clicked. One frame after the window opens, and after each purchase,
-- this finishes the game's own selection: a learnable selected row gets the
-- game's row click; no selection, or one that is no longer learnable after
-- a purchase, goes to the game's own nearest learnable service. Then Train
-- works straight away, and pressing it again and again learns them all.
local purchasePending = false
local hookedTrainButton = nil

local function selectedRow(frame)
    local selected = frame.selectedService
    if selected == 0 then
        return frame.skillStepButton
    end
    return frame.ScrollBox:FindFrameByPredicate(function(row, elementData)
        elementData = module.servicePayload(elementData)
        return elementData ~= nil and elementData.displayIndex == selected
    end)
end

local function finishSelection(afterPurchase)
    local frame = ClassTrainerFrame
    if frame == nil or not frame:IsShown() or frame.ScrollBox == nil then
        return
    end
    local trainButton = frame.TrainButton
    if trainButton == nil or trainButton:IsEnabled() then
        return
    end
    local row = frame.selectedService ~= nil and selectedRow(frame) or nil
    if row ~= nil and row.isAvailable then
        row:Click("LeftButton")
    elseif (frame.selectedService == nil or afterPurchase) and ClassTrainer_SelectNearestLearnableSkill ~= nil then
        ClassTrainer_SelectNearestLearnableSkill()
    end
end

module:registerEvent("event", "TRAINER_SHOW")
module:registerEvent("event", "TRAINER_UPDATE")

function module:onEvent(event)
    if event == "TRAINER_SHOW" then
        purchasePending = false
        C_Timer.After(0, function()
            local trainButton = ClassTrainerFrame ~= nil and ClassTrainerFrame.TrainButton or nil
            if trainButton ~= nil and hookedTrainButton ~= trainButton then
                hookedTrainButton = trainButton
                trainButton:HookScript("OnClick", function()
                    purchasePending = true
                end)
            end
            finishSelection(false)
        end)
    elseif event == "TRAINER_UPDATE" then
        local afterPurchase = purchasePending
        purchasePending = false
        C_Timer.After(0, function()
            finishSelection(afterPurchase)
        end)
    end
end
