local testRunner = WowVision.testing.testRunner

-- A fake UnitPosition: positions[unit] = { x, y, map }.
local function game(positions)
    return {
        UnitPosition = function(unit)
            local p = positions[unit]
            if p == nil then
                return nil
            end
            return p[1], p[2], 0, p[3]
        end,
    }
end

testRunner:addSuite("UnitPosition", {
    ["a member on the player's map is where the game says"] = function(t)
        local x, y = WowVision.unitPosition("party1", game({ player = { 0, 0, 1 }, party1 = { 10, 20, 1 } }))
        t:assertEqual(x, 10)
        t:assertEqual(y, 20)
    end,

    ["a member on another map has no position here"] = function(t)
        t:assertNil(WowVision.unitPosition("party1", game({ player = { 0, 0, 1 }, party1 = { 10, 20, 2 } })))
    end,

    ["no map from the game is no reason to drop the position"] = function(t)
        local x = WowVision.unitPosition("party1", game({ player = { 0, 0 }, party1 = { 10, 20 } }))
        t:assertEqual(x, 10)
    end,

    ["no position, a refused read or no finite number is no position"] = function(t)
        t:assertNil(WowVision.unitPosition("party1", game({ player = { 0, 0, 1 } })))
        t:assertNil(WowVision.unitPosition("party1", {
            UnitPosition = function()
                error("refused")
            end,
        }))
        t:assertNil(WowVision.unitPosition("party1", game({ party1 = { 0 / 0, 20, 1 } })))
        t:assertNil(WowVision.unitPosition("party1", game({ party1 = { math.huge, 20, 1 } })))
        t:assertNil(WowVision.unitPosition("party1", {}))
    end,
})
