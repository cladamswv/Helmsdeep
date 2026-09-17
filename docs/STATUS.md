# Castlehold status — Warcry 0.4.3

Version 0.4.3 adds a persistent 1× / 1.5× / 2× battle-speed selector in the HUD and Settings. The global clock scales live combat while pause and management screens remain at normal UI speed. Automated speed coverage is included alongside the existing audio and siege checks.

Warcry makes defeat sounds substantially more prominent: fuller voice clips, one playback slot per family, a separate voice mix, temporary music/impact ducking and an output ceiling. Settings has Test human / Test orc / Test ogre buttons that work while paused. Boss attacks gain a further 15% over 0.4.1, while interval gold is reduced to floor(95 + 7.5 × wave). The unchanged mixed policy wins with 268 casualties and a gate reduced to 979.28 HP; its entire infantry and cavalry force is gone at Ironjaw's defeat. All 224 current checks pass, including actual mixed-audio capture. Device listening and frame-rate review are still required.

The complete source package is Castlehold-Battle-Speed-Full.zip. It can update the current repository or populate an empty one; FRESH_INSTALL.md includes the matching Codespaces commands.

The following describes the retained art and gameplay systems.

The castle and all sixteen character assets use finer original surfaces and geometry. Brown sandstone courses, gate relief, recessed openings and static braziers improve the fortress. Soldiers have layered plate, textured mail/cloth and clearer hands; ogres have shaped torsos, face detail and armor. Three shared 512² surface atlases retain one surface per complete unit. See GRAPHICS_AND_SOUND_UPDATE.md and stone-and-steel-review.png for this retained art, and WARCRY_UPDATE.md for the current audio revision.

Ordinary attacker damage retains the previous 12% increase, while bosses multiply that by a further 1.15. Interval income and boss bounties support paid rebuilding. Ordinary ogres retain five-wave spacing. Wave timing, troop prices, friendly stats, capacities and save format are unchanged. The previous release's 228-casualty mixed run is compared with the current 268-casualty run in VALIDATION.md. Android export and physical device review remain outstanding.

Four giant bosses are now implemented at waves 25, 50, 75 and 100: Gatebreaker, Dreadscale Rider, Ashcaller and Ironjaw King. They have original skinned geometry, articulated weapons/mounts, twelve clips each, named health displays, anticipated heavy attacks, limited splash and persistent combat state. Ironjaw's two roars queue supporting troops at the enemy road. They supplement regular formations without interrupting nonstop pacing. Boss death awards a fixed rebuilding bounty. See SIEGE_BOSSES_UPDATE.md and the actual-model CPU preview, siege-bosses-review.png.

The horde now includes an ogre axeman on a giant armored warthog and an antler-crowned ogre fire shaman. The mount has a full articulated gait, tusks, cloven hooves, charge acceleration and impact knockback. The shaman has an animated ember staff with bone-attached flame, a timed cast, pooled traveling fireballs and original cast/impact sounds. Small blasts hit at most two secondary opponents, respect height and armor, and bypass arrow-only shield resistance. The new units replace formation slots from waves 25 and 18; late assaults can combine them. Checkpoint restoration and real pause/resume cover both enemies.

Six original animated enemy models now form a distinct fantasy faction: Orc Marauder, Orc Hunter, Orc Impaler, Ironshield Orc, Warg Rider and Siege Ogre. Tusks, pointed ears, rough armor, larger shields, wolf mounts and heavy clubs give them recognizable silhouettes. Defenders remain medieval archers, swordsmen, spearmen and mounted knights.

Horde mechanics include arrow-resistant shields, anticipated ogre club strikes, bounded nearby splash damage, extra structure damage, staged introductions and five-lane reinforcements. Swordsmen favor shields, archers focus on ogres and mounted defenders pursue hunters along the wings. Cavalry pursuit reaches hunters outside the old 12-metre cutoff while staying inside the deployment road.

The reported flashing prompted a fix to pooled dust's first-frame opacity/size, softer non-emissive sparks, greater animated culling bounds, a tighter camera depth range, blended shadow cascades, filtered fine shader patterns and 4× main-view MSAA. These changes require physical Android confirmation; no claim is made that every device-specific flash has been reproduced or eliminated.

The warm sandstone fortress, finer slate roofs, original material maps, animated heraldry, soft contact shadows and portrait rendering remain included. The original 80-second medieval instrumental starts at 35%, with independent live music/effects sliders, mute, persistent preferences and background suspension.

The active mode has 100 automatic 10–15-second assaults and 3–5-second reinforcement gaps. Existing enemies keep fighting. Recruitment and Gate/Keep repairs remain available during combat and pause. Survivors recover at wave starts; casualties stay lost and castle damage persists. Version 2 checkpoints support old enemy IDs, saved reinforcement cadence, paused restore/retry and legacy garrison migration.

Combat uses local crowd buckets, ranged damage reservations, soft counters, mounted charges and wounded-knight withdrawal. Active force limits and pooled projectiles/effects bound ordinary runtime growth. Headless mechanics and full-siege policy evidence is recorded in VALIDATION.md; human balance and device performance still require playtesting.

The original brief's wizard/spells, captain abilities, ladders, rams, catapults, siege towers, wall-collapse routes, expanded upgrades, tutorial, layered crowd/horse audio and actor-recorded voice performances, adaptive boss music, graphics/accessibility settings and art variants remain future work. Wall/Mage Tower HP is scaffolding. This update does not claim the full commercial production brief is complete.
