# Stone & Steel — Castlehold 0.4.1

For the standalone fresh-install package, follow `FRESH_INSTALL.md` at repository root. The update instructions below describe the earlier cumulative ZIP.

This cumulative update improves the actual castle and character assets, strengthens enemy attacks and adds short defeat voices. The preview in `stone-and-steel-review.png` shows current game geometry and authored surface maps with approximate CPU lighting. It is not concept art or an Android screenshot.

## Castle

Warm brown sandstone now uses finer staggered courses, narrow mortar gaps and subtle variation. The gatehouse has carved heraldry, corbels and recessed window trim. Slate roofs, deep openings, ironwork and controlled gate destruction remain visible parts of the fortress. Two static ember braziers frame the entrance. Surface maps use mipmaps; the braziers do not introduce pulsing lights or screen flashes.

## Soldiers and ogres

All sixteen complete units share three original 512-pixel albedo, normal and material atlases. Woven cloth, linked mail, forged steel, leather, wood, skin, fur and bone have distinct surface responses. Each complete soldier or mounted unit still uses one material surface.

Defenders gain shaped overlapping shoulder plates, rivets, clearer mail, wooden bow/spear surfaces and articulated hand shapes. Ogres gain a shaped torso, stronger arms, cheekbones, eyelids, nostrils, teeth, waist armor and heavier bracers. The warthog, shaman and four bosses retain their class-specific silhouettes, rigs and attack timing. This is an improvement to the existing original 3D models; rigid skin weights, additional face variants and authored LODs remain future art work.

## Stronger attacks, paid rebuilding

All attacker damage increases by **12%**, including arrows, fireballs, charges, physical splash and boss specials. Friendly damage and HP do not change. Ordinary enemy wave scaling still applies to basic attacks; charges receive the 12% increase without accidental extra wave scaling. Boss stats remain curated without ordinary wave growth.

Interval gold changes from `95 + 6 × wave` to `95 + 8 × wave`. Defeat bounties become 750 / 1,250 / 2,000 / 2,500 gold for the four bosses. These adjustments fund real replacement purchases under the stronger attacks; they do not resurrect casualties or repair the castle automatically. The existing five-wave ogre cadence, enemy counts, wave timing and force caps remain unchanged.

The unchanged mixed purchase policy completes 100 waves with 228 recorded casualties, compared with 214 in the preceding release. This demonstrates one affordable winning policy, not a guarantee about every human strategy. Detailed results and the archer-only comparison are in `VALIDATION.md`.

## Defeat voices

Men make a brief oof, orcs a rough exhalation, and ogres a deeper grunt. Each group has three original synthesized variants with slight pitch variation. Clips last about 0.34–0.57 seconds and start with the fall animation. They contain no spoken dialogue, prolonged screaming, gore or third-party recordings.

At most two defeat voices overlap. Dense casualties are throttled without a delayed queue, so cries stay connected to visible falls. A defender voice can take precedence over a creature voice. All nine clips are preloaded and together occupy about 193 kB of source WAV data. Voices respect **Sound effects**, master mute, pause and app backgrounding. Music remains at the existing adjustable 35% default.

## Apply from the existing Codespace

Upload `Castlehold-Graphics-and-Sound-Update.zip` to the repository root, then paste:

```bash
git pull --ff-only &&
unzip -o Castlehold-Graphics-and-Sound-Update.zip &&
git add project tests docs tools .github README.md GDD.md CHARACTER_ART_BIBLE.md BALANCE.md ANDROID_BUILD.md ASSET_LICENSES.md .gitignore &&
git commit -m "Improve castle and troops, strengthen attacks and add defeat voices" &&
git push
```

Download `Castlehold-Android-debug` from the successful Actions run for that source commit. Uploading the ZIP alone does not apply it. Version code 10 retains the package ID and version 2 saves. The existing CI debug-signing limitation is documented in `ANDROID_BUILD.md`.

Headless tests and actual-asset inspection do not verify Android frame rate, lighting or speaker balance. Review fine-detail shimmer, dense battles, giant attack readability, touch scouting and death sounds on the phone after the APK builds.
