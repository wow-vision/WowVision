-- No new tracked buffers on Retail and WoW: Forever: nearly everything worth
-- tracking is secret or refused there. Auras have the Aura buffer, cooldowns
-- the Spell Cooldowns monitor, and the single facts read the same from a
-- static buffer. A tracked buffer someone already made keeps working.
local groupTypes = WowVision.buffers.groupTypes
for i = #groupTypes, 1, -1 do
    if groupTypes[i].key == "Tracked" then
        table.remove(groupTypes, i)
    end
end
