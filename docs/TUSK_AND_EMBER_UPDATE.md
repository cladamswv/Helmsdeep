# Tusk & Ember — Castlehold 0.3.1

Two original animated enemies join the Ironroot Horde. This cumulative update also includes the earlier fortress, medieval defenders, 100 continuous waves, touch scouting, music/settings and orc redesign.

## Ogre Warthog Rider

An armored ogre axeman rides a giant bristled warthog with a broad snout, upcurved tusks, plated saddle and articulated cloven hooves. Its gait accelerates into a charge; the axe and impact land after an anticipated 0.85-second windup. A successful charge adds damage and pushes the defender back. It needs room to charge and cannot repeat the bonus for 12 seconds. Spearmen deal their full anti-cavalry bonus against it.

The first rider arrives at wave 25. It replaces one foot ogre every ten waves through wave 55, then every fifth wave from 60. Regular ogres remain part of later assaults.

## Ogre Fire Shaman

A sage-green ogre with an antler crown, braided beard, fang charms, plum robe and tall ember staff. The free hand gestures while the staff charges; a fireball launches from the animated staff tip after 0.8 seconds. The orange/gold projectile travels across the field and damages on impact, with a small blast that can hit at most two secondary defenders.

Shamans start at wave 18 and return every six waves, replacing hunters. From wave 60 those assaults can carry two. Knights can pursue the casters; leaving shamans behind the frontline lets them keep firing.

Fireballs respect armor, bypass arrow-only shield resistance and cannot splash allies or ground-to-battlement through the wall. There is no stacking burn. A projectile already launched continues after its caster falls. The effects use a fixed pool, local flame geometry and restrained orange sparks/dust without an extra scene light or full-screen flash. Original synthesized cast and impact sounds follow the Sound effects setting.

## Pause and saves

Pause freezes the charge, cast animation, staff flame phase and projectile flight. Resume continues from that point. Version 2 checkpoints and older enemy IDs remain compatible. Retry restores elite health and charge state and clears transient projectiles. The package ID and audio preferences are unchanged; Android signing/install behavior is explained in ANDROID_BUILD.md.

## Validation and review

145 headless checks passed in Godot 4.7.2, including 31 new elite checks and two full-siege recruitment policies. The mixed army completed wave 100; an archer-only purchase policy lost at wave 73. These are automated regression results, not a guarantee of difficulty for every player.

`tusk-and-ember-review.png` shows the actual posed 3D assets with approximate CPU material lighting at a shared scale. It is not an Android screenshot. Rider plus mount: 11,424 triangles and 36 bones; shaman: 7,604 triangles and 24 bones. Each has eleven skeletal clips and one main mesh surface.

The Android APK must be built by GitHub Actions after extracting and committing the source ZIP. Device rendering, the previously reported intermittent flashing, phone speaker balance and late-wave frame time still require hands-on review. See README.md for the exact phone/Codespaces commands and VALIDATION.md for test evidence.
