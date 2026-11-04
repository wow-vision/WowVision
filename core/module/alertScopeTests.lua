local testRunner = WowVision.testing.testRunner

-- A module with one alert and one output, bound the way the addon binds it:
-- both trees come from the module's own defaults.
local function bound()
    local module = WowVision.Module:new("alertScopeTest")
    module:setLabel("alertScopeTest")
    local alert = module:addAlert({ key = "falling", label = "Falling" })
    local output = alert:addOutput({ type = "TTS", key = "tts", label = "TTS" })
    local db = module:getDefaultDBRecursive()
    local globalDB = module:getDefaultGlobalDBRecursive()
    module:setDBObj(db, globalDB)
    return module, alert, output, db, globalDB
end

local function disable(alert)
    alert.parameters:setFieldValue("enabled", false)
end

testRunner:addSuite("Alert scope", {
    ["the account tree holds the alerts"] = function(t)
        local _, _, _, _, globalDB = bound()
        t:assertNotNil(globalDB.alerts.falling)
    end,

    ["an alert is account-wide by default"] = function(t)
        local module, alert, _, db, globalDB = bound()
        t:assertEqual(module:getAlertScope("falling"), "global")
        disable(alert)
        t:assertEqual(globalDB.alerts.falling.enabled, false)
        t:assertEqual(db.alerts.falling.enabled, true)
    end,

    ["an output setting follows its alert to the account"] = function(t)
        local _, _, output, db, globalDB = bound()
        output.parameters:setFieldValue("enabled", false)
        t:assertEqual(globalDB.alerts.falling.outputs.tts.enabled, false)
        t:assertEqual(db.alerts.falling.outputs.tts.enabled, true)
    end,

    ["a second character reads what the first one set"] = function(t)
        local _, alert, _, _, globalDB = bound()
        disable(alert)
        local other = WowVision.Module:new("alertScopeTest")
        local otherAlert = other:addAlert({ key = "falling", label = "Falling" })
        otherAlert:addOutput({ type = "TTS", key = "tts", label = "TTS" })
        other:setDBObj(other:getDefaultDBRecursive(), globalDB)
        t:assertEqual(otherAlert:getEnabled(), false)
    end,

    ["seeding takes the character's alerts and their submodules"] = function(t)
        local parent = WowVision.Module:new("alertScopeParent")
        parent:addAlert({ key = "top", label = "Top" })
        local child = parent:createModule("child")
        child:addAlert({ key = "falling", label = "Falling" })
        local db = parent:getDefaultDBRecursive()
        local globalDB = parent:getDefaultGlobalDBRecursive()
        db.alerts.top.enabled = false
        db.submodules.child.alerts.falling.enabled = false
        parent:seedGlobalAlerts(db, globalDB)
        t:assertEqual(globalDB.alerts.top.enabled, false)
        t:assertEqual(globalDB.submodules.child.alerts.falling.enabled, false)
        -- A copy: the account's alert must not write into the character's.
        t:assertTrue(globalDB.alerts.top ~= db.alerts.top)
    end,

    ["switching to the character keeps the value and stops sharing"] = function(t)
        local module, alert, _, db, globalDB = bound()
        disable(alert)
        t:assertTrue(module:setAlertScope("falling", "char"))
        t:assertEqual(module:getAlertScope("falling"), "char")
        t:assertEqual(alert:getEnabled(), false)
        alert.parameters:setFieldValue("enabled", true)
        t:assertEqual(db.alerts.falling.enabled, true)
        t:assertEqual(globalDB.alerts.falling.enabled, false)
    end,

    ["the character's choice survives a rebind"] = function(t)
        local module, alert, _, db, globalDB = bound()
        module:setAlertScope("falling", "char")
        disable(alert)
        module:setDBObj(db, globalDB)
        t:assertEqual(module:getAlertScope("falling"), "char")
        t:assertEqual(alert:getEnabled(), false)
        t:assertEqual(globalDB.alerts.falling.enabled, true)
    end,

    ["switching back joins the account value"] = function(t)
        local module, alert, _, _, globalDB = bound()
        module:setAlertScope("falling", "char")
        disable(alert)
        module:setAlertScope("falling", "global")
        t:assertEqual(alert:getEnabled(), true)
        disable(alert)
        t:assertEqual(globalDB.alerts.falling.enabled, false)
    end,

    ["an alert alone gives a module a scope"] = function(t)
        local module = bound()
        t:assertTrue(module:hasScope())
        t:assertEqual(module:getScope(), "global")
    end,

    ["the module's scope moves its alerts"] = function(t)
        local module = bound()
        module:setScope("char")
        t:assertEqual(module:getAlertScope("falling"), "char")
        t:assertEqual(module:getScope(), "char")
    end,

    ["one alert on the character makes the module mixed"] = function(t)
        local module = bound()
        module:addAlert({ key = "second", label = "Second" })
        local db = module:getDefaultDBRecursive()
        local globalDB = module:getDefaultGlobalDBRecursive()
        module:setDBObj(db, globalDB)
        module:setAlertScope("falling", "char")
        t:assertNil(module:getScope())
    end,

    ["without an account store alerts stay on the character"] = function(t)
        local module = WowVision.Module:new("alertScopeTest")
        local alert = module:addAlert({ key = "falling", label = "Falling" })
        local db = module:getDefaultDBRecursive()
        module:setDBObj(db, nil)
        t:assertEqual(module:getAlertScope("falling"), "char")
        t:assertEqual(module:setAlertScope("falling", "global"), false)
        disable(alert)
        t:assertEqual(db.alerts.falling.enabled, false)
    end,
})
