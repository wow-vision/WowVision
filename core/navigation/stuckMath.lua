-- Wall-detection grading, pure and headless-tested: compare how far the
-- player actually moved against how far their speed says they should have,
-- and grade the shortfall. Thresholds and severity mapping match Sku's
-- stuck system (whose graded sounds we ship): severity 1 = hard against a
-- wall, 5 = slightly impeded, nil = moving fine.

local stuckMath = {}
WowVision.stuckMath = stuckMath

-- actual: yards moved since the last check. speed: GetUnitSpeed yards/sec
-- (already reflects mounts, buffs, swimming, snares). dt: seconds since the
-- last check.
function stuckMath.severity(actual, speed, dt)
    if speed == nil or speed <= 0 or dt == nil or dt <= 0 then
        return nil
    end
    local expected = speed * dt
    local ratio = actual / expected
    if ratio < 0.25 then
        return 1
    elseif ratio < 0.45 then
        return 2
    elseif ratio < 0.60 then
        return 3
    elseif ratio < 0.85 then
        return 4
    elseif ratio < 1.00 then
        return 5
    end
    return nil
end

-- The cadence counter: impeded checks fire a sound every `period` in a row
-- (rhythmic clunks, not a machine gun); moving freely resets the rhythm.
-- Returns the severity to SOUND, or nil.
function stuckMath.newCadence(period)
    local cadence = { count = 0, period = period or 3 }
    function cadence:sample(severity)
        if severity == nil then
            self.count = 0
            return nil
        end
        self.count = self.count + 1
        if self.count >= self.period then
            self.count = 0
            return severity
        end
        return nil
    end
    return cadence
end
