# Navigation

## Turn to Waypoint

Press `I` while following a route to face its current waypoint. The turn takes a few frames and lands within about two degrees, standing or on the move. While you move, it aims at where the waypoint will be when the turn lands, so you do not circle waypoints you are about to reach. Nothing is spoken: if you already face the waypoint, the press does nothing. A press while a turn is still running is ignored, and the turn keys stop a turn.

Turning needs the camera following style "Always adjust camera". WowVision sets it once on each character's first login and says so in chat; if you change it back, turning to waypoints lands in the wrong places. WowVision also uses saved camera view 5 for turning, so anything you saved there is overwritten.

`/wv turnlog` lists the last turns with their error, also in chat.

## Pitch Lock

While you swim or fly, the pitch lock keeps your character level, so turns no longer make you slowly dive. Space and X still move you up and down. The lock lets go on land and on taxis, and is never used while flying on Retail, where skyriding steers by pitch. When the game has tilted you anyway (walking you to an NPC across water), opening the NPC's window, pressing Space or X, or pressing `I` while already facing the waypoint levels you again. Turn the Pitch Lock module off under Navigation if you want to dive by pitch.
