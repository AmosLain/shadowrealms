# Development progress

Starting point is the published perf/wave-spawns tree. It includes the illustrated shoulder charge, directional knockback, focus recovery and shared animation banks. Existing campaign regression runs cover Orra, Vessa and Edrin.

## Raider pressure

The opening pair can now take turns winding up while the second raider moves out of the active lane. raider_pressure.gd passed seven checks, including both approaches and road edges. All three hero campaigns reached victory and boss phase two.

## Hook warning

The raider lowers its stance before its anti-air hook. A rising glint follows the upward line, distinct from the jab's circular counter cue. The graphical comparison used identical actors, camera and windup times. All 16 air_combat checks passed.

## Thumbstick precision

A thumb displaced six pixels from center previously changed facing and moved the hero. The stick now remaps its inner eight pixels to rest and ramps continuously to full speed. Viewport-dispatched touch tests passed 5/5, resume passed 4/4 and shoulder controls passed 17/17.

## Checkpoint score

Continue now restores the timed counters banked at the last cleared gate. Retrying discards counters from the failed attempt. New runs start at zero, and an existing two-field checkpoint still loads. The fresh-scene regression failed on resume and retry beforehand and passed all five checks afterward.

## Wind Gallery

Gate five now alternates two crosswind lanes. A 1.25-second floor warning precedes a half-second gust. Players can jump or enter the sheltered lane, and grounded mobile enemies can be pushed. The hazard ends on clearing or restarting the encounter. All 21 hazard checks passed.

## Controls help

Pause shows instructions for the device control scheme and selected hero. Orra's charge explains the center-and-push gesture, and each hero has a different aerial attack description. The six hero/device combinations passed 36 assertions including bounds and resume-button clearance.

## Integrated checkpoint, 2026-11-23

Godot 4.7.2 imported the integrated worktree. Eleven behavior suites passed 150 assertions including a writable disposable disk slot. All three six-gate campaigns reached victory and boss phase two (Orra 3045 ticks, Vessa 2354 and Edrin 3153). A separate pair of processes saved and resumed Vessa at The Broken Choir with one earned counter; all five checks passed. A 495-tick opening-wave capture showed alternating windups with residual sprite overlap at the handoff. OpenGL captures cover the raider cues, formation, touch stick, controls help and gallery gust. Touch input was simulated on Windows. ADB was unavailable here.

The next cycle addresses raider handoff readability. Recurring runs await owner approval.

## Combat clarity and encounter outcomes, 2026-11-24

A foreground marker follows the raider currently winding up. The original hook trajectory and timed-counter signal still show the attack type. Captured the handoff in the center and at both lane edges at 480 by 270. In the Bell Crown, illuminated lines connect each surviving seal to the cantor and the HUD changes when the first seal falls. Captured two, one and zero sources. The four ordinary/final-gate defeat assertions failed before the fix and now pass. A dead hero cannot claim the gate or its rewards while the death animation runs.

The integrated Godot run passed 157 assertions and all three complete six-encounter campaigns. Physical Android playtesting remains open.

## Orra's stagger throw

The second cut opens a short grab window on a surviving grounded raider. A green cue and contextual control hint appear in reach. A directional third Strike clinches, lifts and launches the victim. One same-lane collision can knock down a second enemy. Neutral Strike keeps the cleave. New atlas poses cover grip, release and tumble. Sixteen regression assertions cover both directions, exact secondary impact count, cross-lane miss, touch input and interruption. All 173 behavior assertions and three hero campaigns passed. A graphical recording verified a second raider taking 12 damage.
