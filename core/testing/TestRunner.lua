local TestRunner = WowVision.Class("TestRunner")

function TestRunner:initialize()
    self.suites = {}
    self.output = {}
    self.passed = 0
    self.failed = 0
end

function TestRunner:addSuite(name, suite)
    self.suites[name] = suite
end

function TestRunner:log(message)
    tinsert(self.output, message)
end

function TestRunner:run(filterSuite, verbose)
    self.output = {}
    self.passed = 0
    self.failed = 0

    for suiteName, suite in pairs(self.suites) do
        if not filterSuite or suiteName == filterSuite then
            local suitePassed = 0
            local suiteFailed = 0
            local suiteFailures = {}

            for testName, testFunc in pairs(suite) do
                local success, err = pcall(testFunc, self)
                if success then
                    self.passed = self.passed + 1
                    suitePassed = suitePassed + 1
                else
                    self.failed = self.failed + 1
                    suiteFailed = suiteFailed + 1
                    tinsert(suiteFailures, { name = testName, err = err })
                end
            end

            -- Build suite header with counts
            local suiteHeader = "Suite: " .. suiteName .. " (" .. suitePassed .. " passed"
            if suiteFailed > 0 then
                suiteHeader = suiteHeader .. ", " .. suiteFailed .. " failed)"
            else
                suiteHeader = suiteHeader .. ")"
            end
            self:log(suiteHeader)

            -- Show individual results only if verbose or there are failures
            if verbose or suiteFailed > 0 then
                for testName, testFunc in pairs(suite) do
                    -- Check if this test failed
                    local failed = false
                    local failErr = nil
                    for _, failure in ipairs(suiteFailures) do
                        if failure.name == testName then
                            failed = true
                            failErr = failure.err
                            break
                        end
                    end

                    if failed then
                        self:log("  FAIL: " .. testName)
                        self:log("    " .. tostring(failErr))
                    elseif verbose then
                        self:log("  PASS: " .. testName)
                    end
                end
            end
        end
    end

    self:log("")
    self:log("Results: " .. self.passed .. " passed, " .. self.failed .. " failed")
    return table.concat(self.output, "\n")
end

-- Assertions

function TestRunner:assertEqual(a, b, message)
    if a ~= b then
        error((message or "assertEqual") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
    end
end

function TestRunner:assertNotEqual(a, b, message)
    if a == b then
        error((message or "assertNotEqual") .. ": expected values to differ, both are " .. tostring(a))
    end
end

function TestRunner:assertTrue(value, message)
    if not value then
        error((message or "assertTrue") .. ": expected true, got " .. tostring(value))
    end
end

function TestRunner:assertFalse(value, message)
    if value then
        error((message or "assertFalse") .. ": expected false, got " .. tostring(value))
    end
end

function TestRunner:assertNil(value, message)
    if value ~= nil then
        error((message or "assertNil") .. ": expected nil, got " .. tostring(value))
    end
end

function TestRunner:assertNotNil(value, message)
    if value == nil then
        error((message or "assertNotNil") .. ": expected non-nil value")
    end
end

function TestRunner:assertType(value, expectedType, message)
    local actualType = type(value)
    if actualType ~= expectedType then
        error((message or "assertType") .. ": expected type " .. expectedType .. ", got " .. actualType)
    end
end

function TestRunner:assertError(func, message)
    local success, err = pcall(func)
    if success then
        error((message or "assertError") .. ": expected function to error, but it succeeded")
    end
end

-- Namespace
local testing = {
    TestRunner = TestRunner,
    testRunner = TestRunner:new(),
}

-- Results display frame (created on demand)
local resultsFrame = nil

function testing.showResults(text)
    if not resultsFrame then
        resultsFrame = CreateFrame("Frame", "WowVisionTestResults", UIParent, "BackdropTemplate")
        resultsFrame:SetSize(600, 400)
        resultsFrame:SetPoint("CENTER")
        resultsFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        resultsFrame:SetBackdropColor(0, 0, 0, 0.9)
        resultsFrame:EnableKeyboard(true)
        resultsFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:Hide()
            end
        end)
        resultsFrame:SetFrameStrata("DIALOG")

        local scrollFrame = CreateFrame("ScrollFrame", nil, resultsFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -10)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(GameFontHighlight)
        editBox:SetWidth(scrollFrame:GetWidth())
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function()
            resultsFrame:Hide()
        end)

        scrollFrame:SetScrollChild(editBox)
        resultsFrame.editBox = editBox
    end

    resultsFrame.editBox:SetText(text)
    resultsFrame.editBox:HighlightText()
    resultsFrame.editBox:SetFocus()
    resultsFrame:Show()
end

function testing.runAndShow(args)
    -- Parse args for suite name and verbose flag
    local filterSuite = nil
    local verbose = false

    if args and args ~= "" then
        for word in string.gmatch(args, "%S+") do
            if word == "--verbose" or word == "--full" or word == "-v" then
                verbose = true
            else
                filterSuite = word
            end
        end
    end

    local results = testing.testRunner:run(filterSuite, verbose)
    testing.showResults(results)
    WowVision.base.speech:speak(results)
end

WowVision.testing = testing
