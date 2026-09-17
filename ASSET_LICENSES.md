# Asset and engine provenance

| Path / dependency | Origin | License / permission |
|---|---|---|
| assets/characters/*.gltf, *.bin | Original geometry, colors, rig and animation authored by tools/build_characters.py for this project | No third-party asset license; user may use/modify commercially |
| Character portraits | Runtime renders of the same original glTF | Same as character assets |
| Horde character geometry and animation, including orc_guard and ogre | Original models authored by tools/build_horde.py using the project's glTF authoring code | No downloaded geometry, scans or external art pack; user may use/modify commercially |
| Ogre warthog rider and fire shaman | Original geometry, rigs and animation from tools/build_ogre_elites.py | No third-party models; user may use/modify commercially |
| Castle and environment | Original geometry in world_builder.gd and fortress_architecture.gd | No third-party asset dependency |
| assets/audio/*.wav | Original deterministic synthesis by tools/build_audio.py and tools/build_ogre_audio.py | No third-party samples; user may use/modify commercially |
| assets/audio/music/valley_watch.ogg | The Valley Watch: original written composition and instrument synthesis by tools/build_music.py | No downloaded music, samples or soundfonts; user may use/modify commercially |
| assets/ui/volume_knob.svg | Original vector slider control authored for this project | No third-party asset dependency |
| Combat effect geometry | Original project code | No third-party asset dependency |
| assets/materials/*_albedo.png, *_normal.png, contact_shadow.png, dust_soft.png | Original deterministic surface-noise and analytic alpha fields from tools/build_surface_maps.py | No photographs or downloaded textures; user may use/modify commercially |
| assets/characters/medieval_orm.png | Original legacy 64² material lookup retained for source compatibility | No third-party asset dependency |
| assets/characters/fieldcraft_*.png | Three original deterministic 512² surface atlases from tools/build_character_surfaces.py | No photographs or downloaded textures; user may use/modify commercially |
| assets/audio/voices/*.wav | Nine original source-filter synthesized defeat clips from tools/build_defeat_voices.py | No actors, external recordings or third-party samples; user may use/modify commercially |
| banner_cloth.gdshader and cloth_banner.gd | Original grid, procedural heraldry and wind animation | No third-party asset dependency |
| ember_fire.gdshader and staff/fireball meshes | Original procedural flame shader and project code | No downloaded textures or VFX pack |
| Godot 4.7.2 | Godot Engine contributors | MIT; actual engine license and third-party notices exposed through Credits using Engine APIs |
| Default Godot font | Bundled engine dependency | Engine third-party notices available in Credits |

No paid asset library, proprietary engine, external art pack, music sample or network service is required. Generated original content is not a representation that copyright protection or exclusivity is legally guaranteed. The source has not been assigned a public open-source license on the user's behalf.

Godot licensing: https://godotengine.org/license/
Full engine text is included at runtime through Engine.get_license_text(); dependency notices through Engine.get_license_info(). Preserve these in distributed builds. The runtime engine is not included in the source ZIP.

Fortress update: `fortress_architecture.gd`, the original bevel/arch/roof authoring functions, and `battle_camera.gd` were created for this project without external assets. `fortress-review.png` is an inspection rendering of that geometry. Optional CPU review scripts use NumPy/Pillow locally; these libraries are not bundled into the game runtime.

Continuous Siege update: all eight medieval glTF assets, their 24/36-bone rigs, horse meshes, animations and new radial sandstone geometry are authored by this project. No additional third-party assets were introduced. Review PNGs are CPU renders of project geometry with locally rendered labels; their renderer is not the Android game.

Forged in the Valley 0.2.1: all sculpting, smooth-normal authoring, folded cloth, convex shields, slate shingles, texture maps, shader heraldry, feathered arrows and pooled dust/sparks were created for this project. No new external art dependencies. The fortress CPU preview samples actual albedo maps and geometry-derived shadows, with approximate lighting; it does not reproduce the runtime normal-map, cloth or sky shaders.

The Valley Watch 0.2.2: an original 32-bar melody and accompaniment in 6/8, rendered as an 80-second loop with synthesized lute, recorder, dulcimer, bowed drone and light frame percussion. The MP3 preview is an encoding of the same original composition. NumPy, SciPy and FFmpeg are optional authoring tools and are not bundled into the game. Runtime decoding uses Godot's included audio support, covered by the engine notices in Credits.

The Ironroot Horde 0.3.0: six original enemy designs, tusked faces, pointed ears, rough shields, salvaged armor, warg anatomy and ogre club animations were authored specifically for Castlehold. No third-party monster assets or music were added. `orc-horde-review.png` is a CPU rendering of the actual meshes and poses, not a separate concept illustration or an Android screenshot.

Tusk & Ember 0.3.1: the giant warthog anatomy, armored ogre rider, antler-crowned shaman, ember staff, rigs, animations, cast/impact synthesis and flame shader are original project work. `tusk-and-ember-review.png` renders the actual posed geometry at a shared scale, with approximate CPU lighting and no runtime fire shader. No third-party assets were introduced.


Siege Bosses 0.4.0: `tools/build_bosses.py` authors the four boss meshes, one-eyed face, maul, reptile anatomy, jaws/tails, saddle armor, crowns, robes, banners, rigs and animations. `tools/build_boss_audio.py` synthesizes the giant roar and maul impact without external samples. `boss_combat.gd` authors the reusable warning ring; `siege-bosses-review.png` is a CPU inspection of actual project meshes. These introduce no third-party game assets. The earlier generated concept board was an art-direction reference, not a model file or imported runtime texture.

Stone & Steel 0.4.1: fine weave, linked mail, grain, forged-metal response and skin surface variation are generated by the project. New layered armor, hands, ogre anatomy, facial details, gate heraldry, corbels and masonry are original geometry. Human/orc/ogre defeat sounds are brief synthesized source-filter vocalizations, not actor performances. The shared atlases and sound bank ship as offline assets; the NumPy, SciPy and Pillow authoring dependencies are not bundled into the game. `stone-and-steel-review.png` is a CPU inspection of actual geometry, authored UVs and albedo maps with approximate materials and lighting.

Warcry 0.4.2: all nine defeat clips were resynthesized by the same original project authoring tool with stronger vocal bodies, higher formants and controlled peaks for phone playback. No actors, external voice models, samples or downloaded assets were added. The audio routing, ducking and preview controls are original project code; the limiter is an included Godot audio effect covered by the engine notices already exposed in Credits.
