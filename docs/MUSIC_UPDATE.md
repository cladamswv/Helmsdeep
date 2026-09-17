# The Valley Watch — music update 0.2.2

The game now has an original medieval instrumental with lute plucks, recorder melody, dulcimer, a low bowed drone and restrained frame percussion. Its 32-bar, 6/8 arrangement develops over 80 seconds and repeats without a silent gap. It contains no vocals, downloaded samples, external music service or runtime synthesis.

## Player controls

- Music defaults to **35%**, with a quiet master mix underneath combat.
- Settings contains separate Music and Sound effects sliders, Mute all audio, and Test effects. Both sliders respond immediately.
- Opening Settings pauses the battle and blocks map dragging. Music continues so adjustments can be heard. Closing the panel restores the prior pause state.
- Leaving the app suspends music and effects and pauses the battle. Returning restores music while leaving the battle paused until Resume.
- Levels and mute save separately from campaign checkpoints. Retrying a wave keeps these choices.

## Implementation

`AudioManager` creates dedicated music and effects buses, one looping music player, eight pooled battle players and a separate interface/preview player. Battle pause suspends existing battle voices and suppresses new combat cues; interface previews remain available. Settings writes are debounced for 0.4 seconds and flushed on panel close, backgrounding and normal scene exit.

`SettingsManager` uses a versioned ConfigFile with atomic temporary-file replacement. Missing or malformed preferences fall back to defaults; numeric levels are clamped. A failed settings save displays a message if the panel is open. Automated tests use isolated preference files and do not modify a player's campaign.

The bundled track is stereo Ogg Vorbis at 44.1 kHz, about 0.93 MB. Both its import settings and runtime resource enable looping. Release tails and room reflections wrap around the composition; a short bridge smooths the sample boundary. The game decodes the pre-rendered track instead of synthesizing instruments during play.

## Rebuilding the score

Install NumPy, SciPy and FFmpeg in the authoring environment, then run `python3 tools/build_music.py` from the repository root. It regenerates the Ogg, a full MP3 preview alongside the repository, and `docs/music-render-report.json`. The written pitches, rhythm, arrangement and instrument synthesis are editable in that script. No authoring tools are required to build or play the included project.

Measured compressed-track loudness is **−18.0 LUFS**, with **−7.1 dBFS true peak**. The 35% default bus adds approximately −9.1 dB gain reduction. These measurements establish headroom and a restrained starting level; phone speaker balance still needs listening on the target device.

The cumulative source ZIP includes all previous graphics, medieval troop, fortress, touch-scrolling and continuous-wave updates. Android build number is 6, version 0.2.2. See VALIDATION.md for checks and README.md for phone/Codespaces installation.
