# Prioritized backlog

| Priority | Next playable outcome | Evidence and acceptance |
| --- | --- | --- |
| 1 | Read the second raider's attack during the handoff | Opening-wave captures show partial sprite overlap even though windups alternate. Reproduce the handoff at both road edges and in the center. Improve spacing or telegraph placement. At 480 by 270 the active threat must stay visible, both raiders must still attack and all three heroes must still win. |
| 2 | Make the Bell Crown's shield source readable in combat | The current HUD explains the two seals and the cantor draws a protective ring. Review new-player footage for the path from the ring to a live seal. Test the transition with two, one and zero seals. |
| 3 | Verify a sustained Android session on actual hardware | The shared frame banks reduce spawn work on Windows. Collect cold start, memory use, wave-transition frame times, sleep/resume and two-thumb input traces on a reachable Android device. Record hardware and refresh rate. |
| 4 | Check end-of-encounter outcome when both sides fall | The arena checks defeat after the death animation delay while an empty encounter can advance sooner. Reproduce a late projectile or hazard striking the hero as the last enemy disappears. Use the observed result to define the fix. |

Each run starts with the first reproducible item it can validate. Record an unavailable device as a blocker for that item and continue independent work.
