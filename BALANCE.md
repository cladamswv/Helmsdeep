# Castlehold — Warcry balance 0.4.3

The active mode is 100 automatic assaults. Runtime values live in `project/resources/waves/siege.json` and UnitData Resources. The original preparation rounds and 30-wave schedule have been superseded by the user's continuous-siege instruction. The unused `slice.json` is retained for historical source compatibility.

## Pacing and economy

| Rule | Current value |
|---|---|
| Assault duration | Deterministic varied 10–15 seconds |
| Reinforcement gap | 3, 4 or 5 seconds; existing enemies keep fighting |
| First countdown | 4 seconds |
| Number of waves | 100, then clear all remaining enemies |
| Starting force / gold | 6 archers, 6 swordsmen / 500 gold |
| Attackers per wave | `7 + floor(0.16 × wave)`, plus 4 every fifth wave and 1 boss every 25th |
| Arrival groups | Pairs before wave 10; five-lane formations thereafter |
| HP scaling | +0.3% of base per wave after 10 |
| Ordinary attack strength | All ordinary enemy attacks ×1.12, including charge bonuses |
| Boss attack strength | ×1.12 ×1.15 = ×1.288, including specials and charge bonuses |
| Ordinary damage scaling | An additional +0.2% of base per wave after 10; charge bonuses do not receive this growth |
| Gold grant | `floor(95 + 7.5 × wave)`, once per completed assault interval |
| Clean bonus | 15% when no casualties or net gate damage occurred |
| Casualty relief | 15% purchase value, capped at `25 + wave` |
| Friendly cap | 30 wall archers, 36 shared infantry, 8 knights |
| Active enemy cap | 84; queued troops are deferred, not discarded |

Pressure comes from shield screens, support archers, pikes, warg riders and ogre assaults. Wave 44 contains 14 attackers across five roles; the previous build had 13 human attackers across four roles. Every fifth assault adds four troops. Ordinary stats grow modestly because there are no defender stat upgrades in this build. The higher interval grant funds real replacement costs under the stronger mixed attacks; it does not refill the army automatically.

The grant is paid for surviving an assault interval, even when enemies remain. Casualties during a gap count toward the following interval. Relief never replaces the lost soldier's whole purchase value, so clean defense produces more net army wealth than intentional losses.

Surviving defenders regain full HP at each new assault while retaining identity, position and combat. Castle structures do not heal automatically. Gate and Keep repairs each have a cumulative 35%-of-maximum allowance per wave. Four HP costs one gold, rounded up. A rebuilt gate does not force intruders already in the courtyard back outside.

## Recruitable units

| Unit | Cost | HP | Damage / interval | Range | Role |
|---|---:|---:|---|---:|---|
| Archer | 60 | 85 | 21 / 1.25 s | 15 m | Wall fire; prioritizes ogres in range and shares incoming-damage reservations |
| Swordsman | 75 | 280 | 34 / .95 s | 1.55 m | Durable front line, 15% armor; favors shielded enemies |
| Spearman | 85 | 240 | 30 / 1.05 s | 2.5 m | Double damage against cavalry, 5% armor; supports the front line |
| Mounted Knight | 260 | 600 | 64 / 1.25 s | 2.7 m | 25% armor; 150 charge damage after 3.5 m movement, 12 s recovery |

Knights favor hunters and shamans, approach along a wing and can pursue targets up to battlefield X=20. Ground infantry retain X=5 pursuit bounds. Wounded knights withdraw toward the gate below 30% HP and may still be caught. Charges are automatic; manual charge orders remain future work.

## Horde roster

The tables show editable **base** damage. Runtime regular attack damage is `base × 1.12 × (1 + max(0, source_wave − 10) × 0.002)`. Enemy charges use `charge_base × 1.12`; friendly values are unchanged. Splash and structure multipliers apply to the strengthened attack as appropriate.

| Unit | Base HP | Damage / interval | Introduction | Special |
|---|---:|---|---:|---|
| Orc Marauder | 155 | 24 / 1.1 s | 1 | Fast axe-and-shield infantry |
| Orc Hunter | 95 | 19 / 1.55 s | 3 | Bow attacks from 11 m; a target for mounted defenders |
| Ironshield Orc | 360 | 25 / 1.3 s | 5 | 12% armor and a separate 45% arrow reduction; melee bypasses the arrow reduction |
| Orc Impaler | 235 | 30 / 1.2 s | 6 | 2.5 m reach; double damage against cavalry |
| Warg Rider | 335 | 44 / 1.2 s | 8 | 10% armor; 100 charge damage; prefers ranged targets |
| Siege Ogre | 800 | 64 / 2.15 s | 12 | 10% armor; 2.5× structure damage; anticipated heavy club swing |
| Ogre Warthog Rider | 850 | 60 / 2.1 s | 25 | 15% armor; 130 charge damage; 1.35× charge speed; 0.65 m push |
| Ogre Fire Shaman | 360 | 52 / 3.2 s | 18 | 5% armor; 11 m range; traveling fireballs and limited splash |

Shield count grows from one by `1 + floor(wave / 16)`, capped at six. The first ogre arrives on wave 12, then ogres appear every fifth wave. From wave 40 those assaults carry two, capped at two per wave. The optional later cadence also remains five waves in this build. Warthogs replace one ogre in their scheduled assaults.

An ogre's club lands 0.85 seconds into its 1.7-second animation. It can damage at most two additional nearby ground defenders within 1.75 m for 45% base attack strength, plus a small 0.38 m push. Secondary splash does not inherit the structure multiplier. Ranged defenders are excluded from secondary ground splash.

## Tusk & Ember introductions and counters

Shamans replace one hunter at wave 18 and every six waves thereafter. From wave 60 these attacks replace up to two hunters. One warthog rider replaces a foot ogre at wave 25, then 35, 45 and 55; from wave 60 it appears every fifth wave. The director uses existing formation slots, so total attackers per wave do not increase. All cadence values are editable in siege.json.

The warthog has 2.4 m reach and 2.5 m/s base speed. Moving 3.5 m builds the charge; speed rises toward 3.375 m/s, impact adds 145.6 damage (130 base × 1.12), and recovery is 12 seconds. Its axe/charge hits at 0.85 seconds. It receives normal double anti-cavalry damage from spearmen. Structure damage is 1.25× its scaled regular attack, plus the strengthened charge bonus if ready.

The shaman visibly prepares for 0.8 seconds before releasing from the staff tip. Fireballs travel at approximately 12 m/s, track their selected target and damage on arrival. A blast hits the primary target for scaled 52-base damage and at most two nearby opposing units within 1.3 m for 35% damage each. Height separation prevents ground splash reaching archers on battlements. Armor applies; arrow-only shield reduction does not. There is no stacking burn or damage over time. An already launched fireball survives caster death; retry clears all projectiles. The fixed pool holds 16 fireballs, separate from 128 arrows.

## Balance verification

The automated mixed policy establishes archers and a front line, maintains six spearmen, grows mounted support and replaces losses. It buys units and repairs with earned gold, without test-only health, damage or currency boosts. A separate policy purchases only archers after the starting garrison. Both drive actual combat with a fixed simulation step. Cosmetic VFX and audio use their own random generators, so visual/audio random draws do not alter combat target-lock timing.

The final policy results are recorded in `docs/VALIDATION.md`. These are regression checks and a calibration reference, not a claim of perfect human balance. Phone playtesting should assess whether the first ogre reads clearly, five-wave assaults feel significant, and recruitment/repair choices remain affordable through late waves.


## Curated milestone bosses

Bosses arrive at the right deployment road in the first group of waves 25, 50, 75 and 100. Each is an additional combatant; the ordinary formation remains intact. Regular waves continue even if a boss survives. Bosses retain authored HP and receive the common 1.12 attack multiplier plus the 1.15 boss multiplier, without ordinary per-wave growth. Boss table attack values are base values before the combined 1.288 multiplier. A 384-base gate strike now deals 494.592 before any structure mitigation. Bounties below are final reward values, not scaled.

| Wave | Boss | HP / armor | Primary attack | Special / bounty |
|---|---|---|---|---|
| 25 | Gatebreaker | 6,200 / 20% | 160 every 2.6 s; 384 to structures; up to 3 secondary ground targets at 45% | 165-damage quake, radius 3.2 m, up to 5 troops, 320 to the active structure; 10 s cooldown; 750 gold |
| 50 | Dreadscale Rider | 9,600 / 24% | 160 every 2.6 s; 280 initial charge bonus; 1.5× charge speed | 150-damage tail sweep, radius 4.6 m, up to 5 troops, 1.2 m push; 9 s cooldown; 1,250 gold |
| 75 | Ashcaller | 6,500 / 20% | 115 fireball every 3 s; up to 3 secondary targets at 45% within 2.6 m | 170-damage firestorm, radius 3 m, up to 5 troops, 220 structure damage; 11 s cooldown; 2,000 gold |
| 100 | Ironjaw King | 16,000 / 25% | 240 every 2.7 s; 504 to structures; up to 4 secondary ground targets at 55% | Roars at 70% and 35% HP, each summoning 4 support troops; 2,500 gold |

Heavy specials have a 1.2 s windup and recovery; firestorm has a 1.5 s windup, then a visible projectile must arrive before damage occurs. The marked firestorm location is fixed at the start of the warning. Area damage respects faction, range, height and target caps. Physical area hits do not apply the structure multiplier to soldiers. Only the active Gate/Keep strategic target can receive special structure damage.

Ashcaller advances to X=8 before establishing his firing position. This prevents an off-road stalemate against knights who have a bounded pursuit distance, and exposes him to the castle battery. Knights favor ranged casters. Spearmen retain double damage against Dreadscale's cavalry category. The other giant bosses are heavy units; archers' heavy-target preference helps focus them.

Ironjaw summons one Ironshield, one giant warthog rider, one fire shaman and one impaler per roar. They are queued at the normal deployment road, obey the shared 84-enemy cap, and persist across checkpoints. The two consumed thresholds cannot repeat after retry. The final victory check requires all bosses, support troops and pending reinforcements to be cleared. Boss rewards occur once on actual defeat, separately from interval income; retry rolls back both the reward and combat state together.

## Previous 0.4.1 calibration

The 0.4.1 boss bounties are 750 / 1,250 / 2,000 / 2,500 gold (previously 500 / 750 / 1,000 / 1,500). They fund paid rebuilding after stronger boss attacks. Reward does not depend on casualties, and relief remains capped at 15% of lost purchase value. No troop HP, friendly damage, recruitment price, wave timer or army capacity was changed.

Interval income changes from `95 + 6 × wave` to `95 + 8 × wave` in 0.4.1. This funds replacement soldiers under stronger attacks without changing survivor healing or automatic repairs. The fixed mixed policy failed late in the campaign with the old income and the 12% attack increase, so the new campaign was verified with normal earned income and the unchanged purchase policy.

## Warcry 0.4.3 battle-speed revision

`boss_damage_multiplier = 1.15` applies to every boss damage path, including normal attacks, cavalry impact bonuses, ground splash and area firestorm. Boss HP, contact timing and warnings are unchanged. Ordinary enemy damage stays at the 0.4.1 level. Income is now `floor(95 + 7.5 × wave)` instead of `95 + 8 × wave`: 845 base gold on wave 100 instead of 895. Boss bounties stay at 750 / 1,250 / 2,000 / 2,500, with no extra reward increase to offset the stronger attacks.

In the fixed mixed-policy run, casualties rise from 228 to 268 and minimum gate HP falls from 2,200 to 979.28. At Ironjaw's defeat, the army has 26 archers and no infantry or cavalry remaining; the full siege is still winnable through normal purchases and repairs. The reference purchase policy and victory requirement were not changed. The archer-only policy loses at wave 55. These are calibration results, not a claim that all human strategies have been balanced.
