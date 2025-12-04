local Profiler = WowVision.Class("Profiler")

function Profiler:initialize()
    self.enabled = false
    self.timers = {} -- Active timers: key -> start time
    self.stats = {} -- Accumulated stats: key -> {total, count, min, max}
    self.frameStart = nil
    self.frameStats = {} -- Per-frame totals for current frame
end

function Profiler:enable()
    self.enabled = true
    self:reset()
end

function Profiler:disable()
    self.enabled = false
end

function Profiler:reset()
    self.timers = {}
    self.stats = {}
    self.frameStats = {}
end

function Profiler:start(key)
    if not self.enabled then
        return
    end
    self.timers[key] = debugprofilestop()
end

function Profiler:stop(key)
    if not self.enabled then
        return
    end
    local startTime = self.timers[key]
    if not startTime then
        return
    end

    local elapsed = debugprofilestop() - startTime
    self.timers[key] = nil

    -- Update accumulated stats
    local stat = self.stats[key]
    if not stat then
        stat = { total = 0, count = 0, min = math.huge, max = 0 }
        self.stats[key] = stat
    end
    stat.total = stat.total + elapsed
    stat.count = stat.count + 1
    stat.min = math.min(stat.min, elapsed)
    stat.max = math.max(stat.max, elapsed)

    -- Track per-frame
    self.frameStats[key] = (self.frameStats[key] or 0) + elapsed

    return elapsed
end

function Profiler:beginFrame()
    if not self.enabled then
        return
    end
    self.frameStart = debugprofilestop()
    self.frameStats = {}
end

function Profiler:endFrame()
    if not self.enabled then
        return
    end
    if self.frameStart then
        local elapsed = debugprofilestop() - self.frameStart
        local stat = self.stats["_frame"]
        if not stat then
            stat = { total = 0, count = 0, min = math.huge, max = 0 }
            self.stats["_frame"] = stat
        end
        stat.total = stat.total + elapsed
        stat.count = stat.count + 1
        stat.min = math.min(stat.min, elapsed)
        stat.max = math.max(stat.max, elapsed)
    end
    self.frameStart = nil
end

function Profiler:getStats(key)
    local stat = self.stats[key]
    if not stat or stat.count == 0 then
        return nil
    end
    return {
        total = stat.total,
        count = stat.count,
        avg = stat.total / stat.count,
        min = stat.min,
        max = stat.max,
    }
end

function Profiler:getAllStats()
    local results = {}
    for key, _ in pairs(self.stats) do
        results[key] = self:getStats(key)
    end
    return results
end

function Profiler:report()
    if not self.enabled then
        print("Profiler is disabled")
        return
    end

    -- Sort keys by total time descending
    local keys = {}
    for key, _ in pairs(self.stats) do
        if key ~= "_frame" then
            tinsert(keys, key)
        end
    end
    table.sort(keys, function(a, b)
        return self.stats[a].total > self.stats[b].total
    end)

    print("=== Profiler Report ===")
    local frameStats = self:getStats("_frame")
    if frameStats then
        print(
            string.format(
                "Frames: %d, Avg: %.3fms, Min: %.3fms, Max: %.3fms",
                frameStats.count,
                frameStats.avg,
                frameStats.min,
                frameStats.max
            )
        )
    end
    print("-----------------------")
    for _, key in ipairs(keys) do
        local stat = self:getStats(key)
        print(
            string.format(
                "%-20s: Avg: %.3fms, Min: %.3fms, Max: %.3fms, Calls: %d",
                key,
                stat.avg,
                stat.min,
                stat.max,
                stat.count
            )
        )
    end
    print("=======================")
end

WowVision.Profiler = Profiler
