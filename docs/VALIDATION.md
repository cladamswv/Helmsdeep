# Warcry 0.4.3 — validation

Pinned runtime: Godot 4.7.2.stable.official.ed1daf0bf, Linux headless. Native import completed without script/resource errors. The final tests use the shipped Resources, without diagnostic balance overrides.

| Test group | Passing checks |
|---|---:|
| Core combat, purchases, repairs and persistence | 35 |
| Camera, safe input and fortress | 15 |
| Graphics resources, actual mipmaps and bounded effects | 10 |
| Music, settings and voice preview buttons | 20 |
| Battle-speed persistence, HUD, pause and clock scaling | 11 |
| Defeat voices, captured audio mix and attacker scaling | 23 |
| Orc horde mechanics and restore | 20 |
| Warthog rider and fire shaman | 31 |
| Giant bosses, contact, warnings, saves and final victory | 42 |
| Continuous 100-wave pacing and pause | 15 |
| Full mixed-army siege | 1 |
| Archer-only policy failure before wave 100 | 1 |
| Total | 224 |

The adjacent `*-output.txt` files contain the final production-configuration results, including `battle-speed-tests.log`.

## Difficulty calibration

Bosses deal 15% more damage than in 0.4.1. Their configured multiplier is 1.12 × 1.15 = 1.288, including charges and special attacks. Ordinary attackers retain their 1.12 multiplier. Base interval income is now floor(95 + 7.5 × wave), reduced from 95 + 8 × wave. Boss bounties remain 750 / 1,250 / 2,000 / 2,500. No compensating gold increase accompanies this revision.

The unchanged mixed purchase policy completes wave 100 in 1,714.75 simulated seconds, about 28.6 minutes. It records 268 defender casualties, up from 228 in 0.4.1. The Gate falls to 979.28 of 2,200 HP (44.5%), and the policy spends 193 gold on repairs; the previous run needed none. Peak active combatants are 115, with 128 unit nodes between accelerated cleanup passes.

At Ironjaw's defeat, the mixed defense has 26 archers and no surviving swordsmen, spearmen or knights. The final boss's normal 2,500-gold bounty allows it to rebuild before clearing the remaining support troops. At final victory it has 30 archers, 30 swordsmen, six spearmen, seven knights and 167 gold, versus 5,633 gold in the previous release's final state. The Keep survives undamaged. The Gate is damaged but not breached in this winning run.

The contrasting policy buys only archers after the starting garrison. It loses at wave 55 after 902.85 simulated seconds, with 181 casualties and 4,211 gold spent on repairs. Peak active combatants are 76, with 87 unit nodes. Dreadscale still has 4,636.44 HP at defeat.

Both policies step actual game AI, projectiles, economy and waves at 0.05 seconds, without injected gold, healing or damage advantages. Their purchase rules and the mixed policy's win-at-100 requirement are unchanged. Cosmetic random generators are separate. Expired corpses are removed periodically during accelerated runs; real-time fall cleanup is covered by integration tests. These are not Android frame-time measurements.

This is evidence of greater pressure and an affordable winning composition, not a measurement of every player's experience. Troop prices, friendly stats, force caps, five-wave ordinary ogre cadence, enemy composition, wave timing and full survivor healing are unchanged. Human play should assess how often purchases, repairs and boss counters are necessary.

## Audible defeat cues

The nine original synthesized clips now have fuller sustained envelopes and more upper-frequency content, with a 170 Hz high-pass filter and controlled source peaks. They are mono 24 kHz, 16-bit WAVs, lasting 0.44–0.63 seconds and totaling 227,196 bytes. The source peak is approximately 0.88; see `defeat-voice-report.json`. No actors, external recordings, samples or TTS are used.

Playback gain is −2 dB, up from −9 dB for humans and −10 dB for creatures. Combined with the revised source envelope, representative played clips have approximately 14 dB greater RMS amplitude than 0.4.1. This describes signal level, not a guarantee of perceived loudness on every speaker.

Human, orc and ogre each own one voice slot. A crowded family cannot consume another family's slot; same-family overlap is bounded without delayed cries. Voices route through a separate child of the Effects bus. Music ducks by up to 5 dB and combat effects by up to 9 dB during cries, then recover smoothly. A native Godot hard limiter caps final output at −0.6 dB. Sliders and mute still apply to the whole intended category.

Tests capture the actual Master-bus audio after mixing, rather than only checking whether `play()` was called. A representative human capture contained 8,192 frames with RMS 0.319 and peak 0.699. Assertions also check that three simultaneous voice families remain audible without clipping. Other checks cover nonfatal hits, one fatal cue, family identity, sample variation, routing, ducking/recovery, pause, background suspension, mute, zero volume and normal/charge damage scaling.

Settings tests press all three actual Test human / Test orc / Test ogre buttons and verify that the correct family plays while battle simulation stays paused. Closing Settings stops previews without unexpectedly resuming a previously paused game. The panel fits the 1280 × 720 reference layout. Physical Android speaker listening remains necessary to judge the timbre and balance in play.

## Retained graphics and mechanics

The sixteen original character models, textured brown castle, pooled effects, music and scouting camera are unchanged by Warcry. Graphics checks verify model resources, material dependencies and actual mip levels. The retained CPU preview samples actual geometry, authored UVs and albedo maps; it does not reproduce Mobile-renderer lighting or normal-map detail.

Ordinary human/orc foot soldiers use about 5,000–7,000 triangles. The giant warthog rider uses 14,648 including its mount; bosses range from 13,878 to 26,866. Complete rigs use 24–40 meaningful joints. The castle review export contains 223,225 triangles, batched by structure/material. Rigid skin weights and missing authored LODs remain limitations. UI-free on-device visual review remains the commercial character quality gate.

The retained suite checks gate break/repair, intruders inside a repaired gate, paid repair allowances, survivor healing, casualty relief, purchases during pause, checkpoint retry/backup, legacy saves and all 100 assault/gap intervals. Elite and boss tests verify animation/contact timing, charges, firestorm flight and damage on arrival, faction/height-aware splash, health displays, warning freeze, queued summons, consumed thresholds after restore, one bounty per defeat and clearing all final support before victory. Boss expectations include both configured multipliers; normal wave growth does not apply to curated bosses.

## Package, build and device limits

`Castlehold-Battle-Speed-Full.zip` contains the complete tracked source tree directly at repository root. It can populate an empty repository or update the existing one. The package is checked by extracting into an empty directory, comparing every archived file with the committed source, performing a clean import and rerunning focused audio/settings and boss checks. Earlier source archives and import caches are not required.

Android version code is 12 and version name is 0.4.3-battle-speed. The package ID and version 2 checkpoint format are unchanged. The HTTP/1.1 download/retry fix remains in the Actions workflow. No local APK export or successful remote Actions run is claimed for this release; the included workflow performs that build.

Physical Android review is still needed for speaker audibility, fine-detail shimmer, the previously reported intermittent flashes, lighting, animation, touch scouting, safe-area layout, background/resume and late-wave frame rate. Headless checks and CPU previews cannot establish 60 fps or commercial visual readiness.
