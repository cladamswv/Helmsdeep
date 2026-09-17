# The Ironroot Horde — 0.3.0

This update follows playtesting through wave 44: the siege felt too easy, attackers lacked a clear fantasy-enemy identity, and the screen occasionally flashed.

## Enemy identity and combat

Six original skinned enemy models replace the previous human attackers and extend the roster. Orc Marauders carry hooked axes and rough shields; Hunters carry war bows; Impalers carry hooked spears; Ironshields carry large strapped tower shields; Warg Riders ride fanged wolf-like mounts; Siege Ogres carry oversized iron-banded clubs. Distinct jaws, ears, tusks, exposed arms, armor and mounts make the faction recognizable independently of red/green color coding. There is no gore.

Ironshields reduce arrow damage by 45% in addition to ordinary armor, while melee bypasses that arrow resistance. Ogres deal 2.5 times base damage to structures; a club can also damage two additional nearby ground defenders at 45% strength and push them slightly. Its 0.85-second windup matches the midpoint of the 1.7-second animation, including follow-through. Spearmen keep their double damage against cavalry, including wargs.

Defender target preferences now reflect these threats. Archers prioritize ogres within range and account for shield resistance when reserving incoming damage. Swordsmen favor shielded enemies. Knights favor hunters and approach them along a flank. Their pursuit limit increases from 12 to 20 metres so they can reach hunters firing from behind the front line; they still turn back before the deployment road. Priorities remain soft preferences with target hysteresis.

Reinforcements arrive in pairs early and five-unit formations from wave 10. Shielded orcs start at wave 5, wargs at 8 and the first ogre at 12. Ogre assaults grow to a pair from wave 40, retaining five-wave spacing. Ordinary assault timing remains 10–15 seconds followed by 3–5-second gaps. Existing troops continue fighting through gaps. See BALANCE.md for the final numbers and validation evidence for measured policy outcomes.

## Flashing and shimmer changes

A concrete particle reuse bug was found: dust appeared for its first frame at full opacity and full base size before the following frame applied its smaller size and fade. Dust now starts transparent at its actual initial size and fades in smoothly. Warm, non-emissive sparks replace bright emissive flashes, with fewer simultaneous sparks and dust puffs.

The battlefield camera uses a 0.4–140 m depth range instead of the much broader defaults. Animated characters and banners have extra culling margins. Directional shadows use two blended cascades; static sky radiance uses quality processing. Fine ground and cloth patterns fade when smaller than a pixel, stone normal strength is reduced, and main-view MSAA increases to 4×. These changes target likely popping and shimmer sources without removing the authored castle or character detail.

The Android flashing itself was not reproduced on a physical device here. The particle state and rendering configuration are verified locally; GPU appearance, shader behavior and frame rate still need phone testing. If flashing remains, a short recording distinguishing full-screen flashes from individual surfaces would guide the next device-specific fix.

## Saves and delivery

Existing enemy IDs remain valid, with their art replaced by the new horde. The version 2 campaign checkpoint schema adds an optional formation-size field. Old checkpoints default to their original one-at-a-time reinforcement cadence for the saved interval; subsequent waves use the new formations. Ogres and Ironshields validate and restore in the same save format. Music preferences remain independent.

The source patch does not erase game saves. Android installation still depends on signing: the existing workflow creates a fresh debug key, so a signing mismatch may require an uninstall, which does erase local progress. A persistent distribution signing key remains a separate setup step; do not assume source-level save compatibility bypasses Android signing.

All original art sources, runtime assets, tests and prior updates are included in the cumulative ZIP. The six-panel preview is a CPU inspection of the actual models, with approximate lighting and individually framed views; it is not a phone screenshot. No Android APK was exported locally.
