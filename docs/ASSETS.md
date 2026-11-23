# Asset sources and replacement guide

| Source | Use |
| --- | --- |
| art/cinder_keep.jpg | Original ImageGen panorama generated for this project. The sky, ruins, mountains, haze and pavement share a single atlas. The renderer scrolls the skyline and street at different speeds. |
| art/actors/*/poses.webp | Original ImageGen sprites, chroma-keyed and aligned to a common foot pivot. The warden uses 16 painted poses. Each other fighter uses four distinct source poses and timed transforms. Status, facing, movement phase and attack time drive the rig. |
| art/actors/cast.jpg | Canonical lineup rendered from the actual game. Left to right are Orra, Edrin, Vessa, raider, brute, cultist headsman and cantor. |
| scripts/landscape.gd and effect.gd | Original road dressing, moving pennants, braziers, fire, dust, sparks and spell strokes. |
| scripts/sound.gd | Original seeded synthesis for wind, strike, weapon swing, spell and pickup. A small pool reuses the generated PCM buffers. |
| docs/combat.jpg | Godot viewport capture, staged with two live enemies using tests/capture.gd. |

For replacement animation, author right-facing transparent frames on a 192 × 176 canvas with the boot pivot at (96, 156). Preserve silhouette, costume palette and hand placement against the cast reference. Import frames into a Godot SpriteFrames resource at the per-role path listed in manifest.json. Use its clip names. The rig can display individual replacement clips as they become available. Gameplay collision, team masks, damage and foot positions remain on the actor.

The foundry and rooftop panoramas were generated separately with ImageGen. The arena renderer crossfades between three original paintings. The two score stems, vigil and siege, were composed and synthesized locally from an original 16-bar phrase. The percussion fades in for gated encounters. Bell and furnace effects use seeded synthesis. The chime seal uses original Godot drawing commands.

The level pacing and combat acceptance criteria were informed by the Level Designer and Team Combat workflows in [Claude Code Game Studios](https://github.com/AmosLain/Claude-Code-Game-Studios). No code or art from that repository is bundled.
