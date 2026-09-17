# Castlehold architecture — continuous siege

GameManager coordinates the scene, army ownership, checkpoints and UI. WaveDirector independently schedules 100 timed assault/gap intervals and queues formations. The next wave does not depend on clearing live enemies. Backpressure at 84 enemies preserves pending attackers; final completion waits for the queue and battlefield to empty.

EconomyManager owns purchases and interval rewards. UnitData Resources contain stats, counter multipliers, capacity category, spacing and model references. UnitController owns movement, combat, animations and damage. Friendly recruitment adds one unit in an unused category slot; it never recreates the garrison. Death removes the unit from active lists immediately and frees its scene after the fall animation.

TargetingSystem builds local crowd buckets at 10 Hz. Movers inspect nine cells instead of every soldier. Target choice uses lock hysteresis and soft class priorities. Incoming arrows, fireballs and ranged windups reserve post-mitigation target damage, distinguishing arrow shields from magic, so ranged units distribute volleys. ProjectilePool contains the existing 128 arrows plus a 16-slot FireballPool child, stepped by the same process callback. ShamanFocus attaches the flame and projectile muzzle to the actual animated hand via BoneAttachment3D. Fireball impacts apply bounded nearby splash and use VFXPool; all flames update an explicit pausable shader phase instead of TIME. ProjectilePool and VFXPool retain bounded slots. This improves scaling, but it does not substitute for Android frame-time measurements.

CastleController holds independent CastleStructure nodes and paid repair accounting. FortressArchitecture batches original geometry by structure/material; curved ashlar wedges form turrets, smaller beveled courses face walls and keep. The timber gate and portcullis remain animated damage pieces. Gate restoration kills old collapse tweens before rebuilding. Walls/tower currently remain structure-state scaffolding for future siege mechanics.

The scene tree pauses gameplay, projectiles, animation and destruction tweens. The HUD processes while paused so Resume, purchases and repairs remain usable. Credits restores prior pause state. App focus loss pauses. BattleCamera keeps bounded one-finger scouting, ignores HUD-origin gestures and returns home through Castle.

SaveManager validates version 2 checkpoints, writes atomically and retains a known-good backup. Wave-start checkpoints include live units, health, positions, queue state, economy and repair usage. Restore begins paused. Projectiles and cosmetic debris are transient. Legacy v1 garrison/gold/castle data can seed wave 1 of continuous mode without deleting the old save.


BossData is an optional Resource on UnitData; ordinary troops keep their existing behavior. BossCombat owns special attack timing, a reusable warning ring, recovery and consumed summon thresholds. UnitController continues to own normal contact/charge attacks; giant body radii and impact heights adapt targeting to the actual model size. Boss stats use curated strengths without ordinary wave scaling. A shared data-driven attacker multiplier applies to every enemy attack, charge and boss special. Bosses also apply the configured boss multiplier to all their damage paths. Ordinary wave growth additionally applies to regular enemy attack damage, but not to a fixed charge bonus or curated boss stats. Ashcaller advances into a configured firing line before casting. FireballPool supports fixed-area projectiles as well as tracked primary targets. Only projectile arrival triggers firestorm damage.

WaveDirector reads the four boss milestones from siege.json and inserts one extra unit in their first formation. Roars add ordinary entries to the same queue, so they inherit its deployment edge, save format and active cap. The HUD selects the oldest living boss for its compact health display and notes overlapping bosses. BossData/Combat are optional in old snapshots; SaveManager validates new state while retaining previous version-two reads.

The mesh exporter places each external buffer's SHA-256 in glTF asset extras. Regenerating only a binary animation track therefore changes the source JSON fingerprint too, preventing stale imported poses in editor caches. Clean imports still load conventional glTF 2.0 assets.


## Stone & Steel surfaces and defeat audio

Sixteen original complete unit meshes share the same 512² albedo, normal and ORM textures. The authoring layer records a semantic surface family and padded UVs for every vertex. Rigid skin weights, animation tracks and one material surface per whole unit/mount are retained. CharacterPresentation explicitly enables mipmapped linear filtering. Castle geometry remains batched by owning structure and material; added stone courses do not create a node per block.

UnitData.defeat_voice selects human, orc or ogre. UnitController calls the audio manager once when HP first reaches zero, in the same branch that starts the fall animation. AudioManager preloads nine mono clips and three dedicated AudioStreamPlayers, one slot per family. No other family's casualty can suppress or replace an ogre's voice. The manager never restarts an occupied slot or queues delayed voices. Three variants rotate with small private-RNG pitch variation; audio never consumes combat randomness.

## Warcry audio mix

The Voices and Combat buses feed the existing Effects bus, so the Effects slider and master mute retain their meaning. Voice players use -2 dB gain instead of the previous -9/-10 dB, and the source-filter clips have a higher sustained level and stronger upper formants. While a voice is audible, combat impacts duck by up to 9 dB and music by up to 5 dB, with fast attack and a short release. These temporary gains do not change or save the player's volume preferences. The Master bus has one native hard limiter with a -0.6 dB ceiling.

Settings previews use the same clips, voice players and mix while gameplay is paused. An explicit preview flag permits only that audition to play during the pause; backgrounding still suspends it. Closing the panel stops previews and restores the previous pause state. Actual battle voices pause normally. The Settings buttons show a short explanation if Effects is zero or audio is muted. The final-audio tests capture the Master mix for a single voice and simultaneous families, verifying an audible output level and the ceiling.
