# Siege Bosses — Castlehold 0.4.0

Historical introduction notes. Stone & Steel 0.4.1 adds shared character surface/detail improvements, 12% stronger attacks and higher boss bounties. See BALANCE.md and GRAPHICS_AND_SOUND_UPDATE.md for current values.

This update implements four original animated 3D bosses from the approved concept direction. The illustration is not used as a sprite or billboard. The real meshes can be inspected in `siege-bosses-review.png` and regenerated with `tools/build_bosses.py`.

| Wave | Boss | What changes in the fight |
|---|---|---|
| 25 | The Gatebreaker | Huge single-eyed ogre with an ironbound stone maul. Slow strikes crush infantry groups and deal 384 damage to the gate. A marked quake threatens five nearby defenders. |
| 50 | Dreadscale Rider | Crowned ogre on a giant four-legged armored lizard. Accelerating charge and broad tail sweep. Spearmen remain an effective counter. |
| 75 | The Ashcaller | Antler-crowned giant shaman with a brazier staff, beard and plum robes. Advances into the visible battlefield, launches fireballs and warns a fixed area before a larger firestorm. |
| 100 | The Ironjaw King | Ogre king riding an upright horned tyrant dinosaur. Heavy bite/stomp attacks and two health-triggered reinforcement roars. Clear him and all supporting enemies for victory. |

Every boss joins a regular assault. The 10–15 second waves and 3–5 second gaps continue throughout; no preparation round or forced pause is added. Surviving defenders still heal at wave starts. Boss fights can span several waves, and their health is never reset at a wave boundary. A narrow named health display appears below the top bar and identifies an impending special attack. The battlefield remains draggable through that display.

Bosses have visible windups, followed by contact or projectile arrival, then recovery. A segmented amber ground ring shows special attack areas. Effects stay local: dust, sparks, embers and original synthesized roar/maul sounds. There are no full-screen flashes or new dynamic lights. Music retains its 35% default and the independent Music/Sound effects settings.

Boss defeat grants 500, 750, 1,000 or 1,500 gold. These fixed rewards help rebuild the garrison after the fight. They do not refund casualties, so preserving soldiers remains the better financial result. Ironjaw's final reward is included in the completed-save score/economy; it does not imply an implemented endless mode.

## Existing installations and checkpoints

Use the existing repository and app package. The cumulative ZIP contains all previous updates, including brown detailed masonry, medieval defenders, orcs, giant warthog riders, fire shamans, music, scouting and the HTTP/1.1 download retry fix. Unzip the new source in Codespaces, commit and push; Actions then builds the APK.

Earlier version-two checkpoints remain readable. Boss health, special cooldowns, warnings and consumed roar thresholds now persist. An old in-progress wave uses its saved reinforcement queue; earlier boss waves are not spawned retroactively. To see the full new boss sequence after beating the previous build, choose **Play Again** for a new run. In-flight projectiles remain transient and are cleared on retry, consistent with previous releases.

Pause freezes boss movement, skeletal animation, special attack timing, warning effects and fireball travel. Recruitment, repair and settings remain available while paused. A retry restores the last wave-start checkpoint and pauses for planning. The usual Android signing caveat still applies: an APK signed with a different debug key cannot replace the installed app in place; uninstalling deletes its local progress. See ANDROID_BUILD.md.

## Scope and review

All four bosses use native glTF skins and AnimationPlayer clips. Giant meshes have 11,374–23,722 triangles and 24–40 joints, with one material surface per rider-and-mount asset. Each boss creates one reusable warning ring. The existing 128-arrow, 16-fireball and 96-effect pools remain fixed. Reinforcements use the normal right-edge queue and shared 84-enemy limit.

The engine import, real-scene combat tests and accelerated siege simulations are recorded in VALIDATION.md. CPU art review checks actual geometry and contact poses; it does not reproduce Android lighting or frame time. This source update still needs APK installation and device review for visual polish, the previously reported intermittent flashing, touch feel and late-wave performance.
