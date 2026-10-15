-- Prints the group health readback simulation (tools/groupHealthSim.lua):
-- party of 5 and raid of 10; strong hits on one member, slow changes on
-- two, a healer hovering at a line, strong hits with frequent stops of all
-- speech; at 60 and at 30 frames per second.
--
-- Usage, from the repo root:
--   luajit tools/group-health-sim.lua [fps]

tinsert = table.insert
tremove = table.remove

local namespace = {}
local function loadAddonFile(path)
    local chunk, err = loadfile(path)
    if chunk == nil then
        error(err)
    end
    return chunk("WowVision", namespace)
end

loadAddonFile("core/Class.lua")
WowVision = { Class = namespace.Class, classes = namespace.classes }
loadAddonFile("retail/groupHealth/logic.lua")
loadAddonFile("retail/groupHealth/voices.lua")
loadAddonFile("retail/groupHealth/readback.lua")
loadAddonFile("retail/groupHealth/checks.lua")
local Sim = loadAddonFile("tools/groupHealthSim.lua")

local fpsList = { 60, 30 }
if arg[1] ~= nil then
    fpsList = { tonumber(arg[1]) }
end

for _, fps in ipairs(fpsList) do
    for _, kind in ipairs(Sim.KINDS) do
        for _, size in ipairs({ 5, 10 }) do
            local result = Sim.run(Sim.scenario(kind, size, fps))
            for _, line in ipairs(Sim.report(result)) do
                print(line)
            end
            print("")
        end
    end
end
