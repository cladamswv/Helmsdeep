# Castlehold — character art bible 0.4.1

## Readability contract

Characters must read as medieval fighters at 70–140 pixels high. The latest redesign specifically replaces the old uniform-like appearance and hidden weapons. Large weapons, heraldic shields, pointed helmets, cowl shapes, mail, articulated plate, caparisons and lances establish class and period before small details are noticed.

The models are original code-authored skinned glTF 2.0 assets. The previews show those actual meshes. The full commercial art gate remains open pending UI-free Android screenshots and device animation review; code passing tests is not visual approval.

## Shared language

Defenders are about five heads tall, with broad shoulders, clear hand shapes, shorter legs and oversized equipment. Blue cloth, warm gold trim and shaded steel define the garrison. The Ironroot Horde uses moss/olive skin, rust cloth, dark salvaged iron and ivory tusks. Orcs have wider shoulders, larger projecting jaws, angular ears and exposed muscular arms; their anatomy and equipment differ from the human defenders. The defender crest is a broad chevron over a tapered standard on shields, with crenellated tower markings on clothing and pennants. The horde uses a crude broken-fang shield mark and asymmetrical armor.

Avoid flat modern helmet brims, rifle-like weapons, camouflage, featureless uniforms, unarmed resting poses and tiny shields. Steel should separate clearly from warm leather and cloth. Enemies remain family-friendly fantasy creatures, with no blood, exposed wounds or grotesque anatomy. Silhouette and equipment identify a threat without depending only on skin color.

## Implemented silhouettes

| Class | Essential shapes | Pose / animation |
|---|---|---|
| Archer | 1.76 m curved longbow, rolled cowl, leather belt/strap, feathered quiver | Bow on the camera-facing hand; draw, hold and release |
| Swordsman | Nasal helmet, shaped gorget, layered shoulder plates, convex heater shield, wide sword | Upright ready blade, presented shield, anticipated overhead and cross cuts |
| Spearman | Tall spear, smaller heater shield, nasal helmet | Braced stance and forward spear thrust |
| Knight | Closed visored helmet, high plume, layered plate, armored horse, long lance, cloth caparison | Articulated gallop, lance thrust, automatic charge and wounded withdrawal |
| Orc Marauder | Wide tusked jaw, pointed ears, large hooked axe, round shield, single spiked pauldron | Raised cleaver, forward cuts and hunched shoulders |
| Orc Hunter | Exposed ears, leaner arms, tall war bow, feathered quiver | Draw and release; no heavy shoulder silhouette |
| Orc Impaler | Hooked long spear, horned iron cap, small shield | Braced spear thrust; anti-cavalry role |
| Ironshield Orc | Large angular tower shield, iron straps, broken-fang mark | Shield screens the body; low-damage holding role |
| Warg Rider | Orc rider over a four-legged fanged mount, pointed ears, dark mane and clawed paws | Articulated mounted gait and charging attack |
| Siege Ogre | Larger body, broad belly and jaw, long arms, bare clawless feet, iron-banded club | Slower gait; 1.7-second anticipated swing; impact at 0.85 seconds and visible follow-through |
| Ogre Warthog Rider | Huge barrel-bodied boar, upcurved ivory tusks, pink snout, cloven hooves, armored saddle and ogre with crescent axe | Articulated gallop, acceleration, 0.85-second axe/charge contact and knockback |
| Ogre Fire Shaman | Sage skin, branching antler crown, braided ivory beard, plum split robe, fang charms and tall three-pronged ember staff | Free hand gestures while staff hand casts; 1.6-second clip releases at 0.8 seconds |

## Actual budgets

| Asset | Triangles | Bones |
|---|---:|---:|
| Archer | 5,148 | 24 |
| Swordsman | 6,898 | 24 |
| Spearman | 6,652 | 24 |
| Knight, including horse | 11,170 | 36 |
| Orc Marauder | 6,394 | 24 |
| Orc Hunter | 5,018 | 24 |
| Orc Impaler | 6,418 | 24 |
| Ironshield Orc | 5,760 | 24 |
| Warg Rider, including mount | 9,392 | 36 |
| Siege Ogre | 8,738 | 24 |
| Ogre Warthog Rider, including giant mount | 14,648 | 36 |
| Ogre Fire Shaman | 10,540 | 24 |

One surface per complete archetype, including rider and mount. The 14,648-triangle rider is a limited elite with a complete giant mount; it is above the ordinary soldier budget and must be measured on device. The shaman staff adds a small bone-attached flame mesh using the shared ember shader. Three shared original 512² albedo, normal and ORM atlases now distinguish fine woven cloth, linked mail, grain, skin, iron, steel and gold without adding material surfaces. Padded 128² family tiles use explicit authored UVs; mipmapped filtering suppresses distant shimmer. Texture color multiplies faction vertex color. A modest 0.42 normal strength preserves the broad sculpted form. Vertex colors preserve faction and skin tones. Smoothed normals are welded within sculpted parts; spear/sword edges stay hard. Broad folds replace rectangular tabard and horse-cloth panels. New eye sockets, a shaped jaw/nose, cowl fringe and layered gorgets replace the old bulging features and bead-like mail.

Current meshes use rigid skin weights and have no authored LODs. Future production work includes smoother elbow deformation, more face/skin/helmet variants and lower-detail LODs. Original procedural character albedo, normal and material atlases have shipped. Hand-painted bespoke textures, modular face variations and authored LODs remain future work.

## Animation and portraits

Eleven clips per model: idle, walk, run, attack A/B, shoot, hit, block, knockback, defeat and cheer. Every clip keys all rig joints to prevent a previous attack leaving a limb stuck. Humanoid and mount bones are real Skeleton3D skins imported with AnimationPlayer/AnimationMixer. Ordinary melee contact occurs at .475 seconds; arrow release at .625. The ogre contacts at .85 seconds in a 1.7-second swing. Idle transitions respect clip length so the heavy club keeps its recovery. Reactions do not interrupt a scheduled hit. The warthog rider also contacts at .85 seconds. Shaman casting takes 1.6 seconds and releases at .8, with the projectile origin attached to the animated right hand at the staff tip. Damage from arrows and fireballs occurs at arrival. Fire is bounded orange/gold with no added scene light, emission bloom or full-screen flash; its phase pauses with gameplay.

Portrait viewports render the same model in its ready pose at 192² with 2× MSAA, warm/cool lights and a reflection sky. They update for six initial frames to settle the sky, then cache the result. The in-repository CPU review sheet uses interpolated normals and an approximate material response. It is an asset inspection, not a screenshot from the Android renderer. Only device play can verify motion, lighting, equipment overlap and phone-scale clarity in battle.

The original wizard, captain, shield guard, advanced archers, siege crews remain future art specifications from the full brief.

`tools/build_ogre_elites.py` adds the warthog rider and fire shaman. `docs/tusk-and-ember-review.png` shows their actual ready-pose geometry at a common scale; shader flames require runtime review.

`tools/build_horde.py` authors the first six enemy models from the shared glTF mesh tools. `tools/build_characters.py` regenerates both the human defenders and the horde. The old enemy asset IDs are intentionally retained for checkpoint compatibility; their production geometry is now orc/warg geometry. `docs/orc-horde-review.png` shows the actual posed assets in an approximate CPU render, with individually framed views rather than a common scale reference.


## Siege Bosses 0.4.0 — implemented art specification

The four approved boss concepts become original native skinned glTF assets, not billboard illustrations. A single giant eye, huge maul, low quadruped mount, antler-and-brazier outline, and upright two-legged tyrant make the four silhouettes distinct. Shared salvaged iron, moss skin, bronze rivets, ivory fangs and rust banners bind them to the Ironroot Horde. Ashcaller retains plum robes and braided ivory beard. Ironjaw's beast uses warm red-brown hide. The boss bodies are approximately three ordinary soldiers tall; the weapons and banners extend above that. Scales are baked into meshes and joint translations so no runtime scale trick is needed for their attachments.

| Boss | Primary silhouette | Triangles / joints | Authored contact |
|---|---|---:|---|
| Gatebreaker | Single large amber eye, massive ironbound beveled maul, stacked shoulder plates | 13,878 / 24 | Maul contact at 1.2 s of a 2.4 s swing |
| Dreadscale Rider | Wide four-legged horned lizard, armored saddle, seated crowned ogre, axe, fang pennant | 26,866 / 40 | Bite at 1.1 s; articulated tail special |
| Ashcaller | Giant antlers, ivory beard, plum folds, bronze charms, tall three-pronged fire brazier | 15,566 / 24 | Fireball release at 1.0 s; special release at 1.5 s |
| Ironjaw King | Upright tyrant dinosaur, small forearms, heavy hind legs, horned snout, ogre crown and twin standards | 26,734 / 40 | Bite/stomp at 1.1 s; open-jaw reinforcement roar |

Each boss has twelve clips including the dedicated special attack. Rider legs retain their seated pose during locomotion. Mounted rigs add a second tail joint, an articulated lower jaw and banner joints. Armored edges stay hard; skin is smoothed within sculpted parts. Broad vertex color variation and the shared original surface atlases keep each complete boss on one surface. A boss adds one reusable ground warning mesh; Ashcaller also adds one animated staff ember. No full-screen flash or extra scene light accompanies boss attacks.

The actual ready-pose geometry is shown in `docs/siege-bosses-review.png`. Contact poses were also inspected on CPU, including correction of Gatebreaker's maul so its contact reaches the ground. These assets retain the existing rigid-weight workflow; they are not a claim of sculpted AAA quality, finished LODs or Android visual approval. UI-free on-device screenshots and animation review remain the commercial character quality gate.


## Stone & Steel 0.4.1 detailing

Human shoulder armor now uses crowned overlapping plates, riveted borders and a distinct collar silhouette. Mail appears as a fine linked surface under the armor. Cloth has a restrained weave; bows and spear shafts read as wood. Hands have separated thumbs and finger forms. The swordsman's moustache and beard frame his face without covering his helmet or weapon identity.

Ogres have a shaped torso, broad pectorals and collarbones, heavier arms, segmented waist armor and riveted bracers. Cheekbones, nostrils, lips, exposed teeth, eyelids and small eye highlights improve the face. Warthog hide and fur, shaman robes, bone charms and iron fittings use separate surface responses within the same atlas. Giant bosses inherit these surface and torso improvements while retaining their unique silhouettes and twelve clips.

The fortress uses warm brown sandstone, smaller staggered courses, subtle variation and darker lower stones. Narrow mortar joints, recessed window reveals, gate relief, corbels and stringcourses establish scale. Static ember braziers add warm points at the gate without dynamic light pulses. Gate damage and controlled destruction remain part of the existing structural system. The exported fortress review contains 223,225 triangles; its many blocks are batched, but GPU cost still requires device measurement.

`docs/stone-and-steel-review.png` combines the actual current castle, four defenders and two ogre elites. The CPU renderer samples authored UVs and albedo with approximate surface response. Use it to assess geometry, palette and silhouettes, not Android shading, animation or frame rate. The ordinary foot soldiers remain about 5,000–7,000 triangles. Large mounted elites and bosses use greater budgets appropriate to their limited counts and screen size.
