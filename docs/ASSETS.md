# Asset sources and replacement guide

| Source | Use |
| --- | --- |
| art/cinder_keep.jpg | Original ImageGen panorama generated for this project. The sky, ruins, mountains, haze and pavement share a single atlas. The renderer scrolls the skyline and street at different speeds. |
| scripts/rig.gd | Original articulated character art, armor facets, cape, weapons and pose animation. Status, facing, movement phase and attack time drive the rig. |
| art/actors/cast.jpg | Canonical lineup rendered from the actual game. Left to right are Orra, Edrin, Vessa, raider, brute, cultist and headsman. |
| scripts/landscape.gd and effect.gd | Original road dressing, moving pennants, braziers, fire, dust, sparks and spell strokes. |
| scripts/sound.gd | Original seeded synthesis for wind, strike, weapon swing, spell and pickup. A small pool reuses the generated PCM buffers. |
| docs/combat.jpg | Godot viewport capture, staged with two live enemies using tests/capture.gd. |

For replacement animation, author right-facing transparent frames on a 192 × 176 canvas with the boot pivot at (96, 156). Preserve silhouette, costume palette and hand placement against the cast reference. Import frames into a Godot SpriteFrames resource at the per-role path listed in manifest.json. Use its clip names. The rig can display individual replacement clips as they become available. Gameplay collision, team masks, damage and foot positions remain on the actor.

The seven designs share a stylized faceted rig. A production art pass should focus on individual faces, limb overlap, two-hand grip through each swing, distinct enemy costumes, authored death poses and an independently animated fog layer. Future voice and creature Foley recordings need a source and license entry here.

