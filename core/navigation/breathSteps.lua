-- Breath bar steps, pure and headless-tested. The game's timer bars (breath
-- underwater, fatigue in deep water, feign death) only show how full they
-- are, so the alert speaks that fill in percent, one line per step down
-- (90, 80, ...). A bar that fills again (surfacing) re-arms the steps
-- silently, so the next dive is announced from its new level.

local breathSteps = {}
WowVision.breathSteps = breathSteps

-- How full the bar is, 0..100 (whole percent, rounded down). progress and
-- maxValue are the game's milliseconds; progress dips just below 0 when the
-- bar runs out, and can never be more than full.
function breathSteps.percent(progress, maxValue)
    if progress == nil or maxValue == nil or maxValue <= 0 then
        return nil
    end
    if progress < 0 then
        progress = 0
    elseif progress > maxValue then
        progress = maxValue
    end
    return math.floor(progress * 100 / maxValue)
end

-- The lowest step the fill has reached: 87 percent with steps of 10 is
-- step 90, so "80" is said once the bar is down to 80, not at 89.
function breathSteps.bucket(percent, stepSize)
    return math.ceil(percent / stepSize) * stepSize
end

-- A new tracked bar, seeded at its current fill, so a bar that is already
-- half empty (after a reload) is not announced at once.
function breathSteps.new(progress, maxValue, stepSize)
    local percent = breathSteps.percent(progress, maxValue) or 100
    return { maxValue = maxValue, level = breathSteps.bucket(percent, stepSize) }
end

-- Feed a fresh progress reading. Returns the step to announce when the bar
-- dropped into a lower step, nil otherwise. Going up moves the level along
-- without a word.
function breathSteps.update(state, progress, stepSize)
    local percent = breathSteps.percent(progress, state.maxValue)
    if percent == nil then
        return nil
    end
    local bucket = breathSteps.bucket(percent, stepSize)
    if bucket < state.level then
        state.level = bucket
        return bucket
    end
    if bucket > state.level then
        state.level = bucket
    end
    return nil
end
