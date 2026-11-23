-- WowVision's keys are secure buttons whose macro text is a /run line
-- (core/ui/input/bindings.lua and actions.lua). The game runs /run only when
-- its "allow custom scripts" setting is on. With it off, a key press brings up
-- the game's own question and nothing else happens. That question is no way
-- out: pressing its Yes button taints and throws an error.
--
-- An addon cannot turn the setting on: SetAllowDangerousScripts is refused for
-- addon code. The installer writes it into the account's config-cache.wtf, but
-- only when the account folder exists, which is after the first login. So a
-- player who installs before that login starts the game with dead keys and no
-- word about why (reported 2026-11-23). This says why, once per session, a few
-- seconds after entering the world.
local check = { said = false }
WowVision.scriptsCheck = check

local L = WowVision:getLocale()

-- Seconds after entering the world, so the message is not lost in the login.
check.DELAY = 5

-- true or false; nil when the client cannot be asked. ask defaults to the
-- game's own function.
function check.allowed(ask)
    if ask == nil then
        ask = AreDangerousScriptsAllowed
    end
    if type(ask) ~= "function" then
        return nil
    end
    local ok, allowed = pcall(ask)
    if not ok or type(allowed) ~= "boolean" then
        return nil
    end
    return allowed
end

function check.message()
    return L["WowVision's keys do not work yet, because the game is not set to run custom scripts. Close the game, run the WowVision Updater, then start the game again."]
end

-- Says it when scripts are off, once per session. True when it spoke. say
-- defaults to a message of the addon.
function check.run(ask, say)
    if check.said or check.allowed(ask) ~= false then
        return false
    end
    check.said = true
    if say == nil then
        WowVision:notify(check.message())
    else
        say(check.message())
    end
    return true
end

-- Called once from WowVision:OnEnable, which runs at login, before the
-- world is entered.
function check.start()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        C_Timer.After(check.DELAY, function()
            check.run()
        end)
    end)
end
