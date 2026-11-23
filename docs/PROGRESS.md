# Development progress

Starting point is the published perf/wave-spawns tree. It includes the illustrated shoulder charge, directional knockback, focus recovery and shared animation banks. Existing campaign regression runs cover Orra, Vessa and Edrin.

## Raider pressure

The opening pair can now take turns winding up while the second raider moves out of the active lane. raider_pressure.gd passed seven checks, including both approaches and road edges. All three hero campaigns reached victory and boss phase two.

## Hook warning

The raider lowers its stance before its anti-air hook. A rising glint follows the upward line, distinct from the jab's circular counter cue. The graphical comparison used identical actors, camera and windup times. All 16 air_combat checks passed.
