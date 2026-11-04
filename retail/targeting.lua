-- No target health monitor on Retail and WoW: Forever: the health is secret in
-- combat, so no step can be measured when it matters, and a readout that goes
-- quiet in a fight looks broken. The game's Combat Audio Alerts say a target's
-- health, in combat too.
WowVision.base.targeting:removeTargetHealth()
