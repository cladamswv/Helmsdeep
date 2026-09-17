# Android build

## Warcry 0.4.3

The Android workflow now uses `android-actions/setup-android@v4` and runs `tests/battle_speed.gd` in addition to the existing integration, graphics, audio and siege suites. The exported debug APK includes the selectable 1× / 1.5× / 2× battle-speed preference.

Current game: **0.4.3 Warcry**, version code 12. `Castlehold-Battle-Speed-Full.zip` contains the entire source tree and assets for your current repository or a new one. Use **FRESH_INSTALL.md** or the command block in README.md. Run `git pull --ff-only` before extraction so Codespaces receives the uploaded ZIP.

Engine pinned: Godot 4.7.2 stable, standard GDScript edition. Android preset: arm64, landscape, immersive, offline, debug package `com.castlehold.firststand`. No C# or Gradle plugin is required for the supplied APK preset.

The download hotfix forces HTTP/1.1 for both the editor and template archives. It retries all transfer errors up to five times, with three seconds between retries and a 30-second connection timeout. This addresses the reported curl exit 92 (cancelled HTTP/2 stream) before the game tests ran. HTTPS certificate verification and pinned engine URLs remain enabled. A cancelled or truncated download is restarted into the regular output file; extraction only runs after curl succeeds. The existing 25-minute job timeout still bounds the overall build.

If a workflow run is named **Add files via upload**, it may be the run triggered by uploading the ZIP alone. Extract the ZIP in Codespaces, commit the source changes, and use the subsequent source commit's run to build the update.

## Fresh repository from a phone

1. Create a new GitHub repository, for example `Castlehold-Fresh`, with a README and the `main` branch.
2. Upload `Castlehold-Battle-Speed-Full.zip` to its root and open its Codespace.
3. Paste the command block from FRESH_INSTALL.md. It pulls the upload, extracts the full project, commits the source and pushes it.
4. In Actions, select **Build Castlehold Android → Add selectable battle speed controls**.
5. After success, download `Castlehold-Android-debug`, extract it and install `Castlehold-debug.apk`.

The complete source ZIP has no wrapper folder and needs no previous game files. Uploading the ZIP alone leaves its files archived; the source commit installs and triggers the workflow.

Earlier builds were installed by the user. This new update has been validated locally with the pinned engine; its GitHub Actions run and Android installation still need to be confirmed. A debug APK is for testing, not a Play Store release. Its signing key is regenerated on each CI run; updates from different runs may require uninstall/reinstall, which removes local progress. Before repeated distribution, store one persistent private debug key in GitHub Actions secrets and load it in the workflow. Never commit a release key.

## Local export
Install Godot's matching export templates, OpenJDK 17 and Android SDK. Configure Editor Settings → Export → Android with SDK and Java paths. The included workflow pins platform 35 and build-tools 35.0.1; verify these requirements against the engine when changing versions. For non-Gradle APK export, the prebuilt templates supply native code. Custom native/Gradle builds require the additional NDK/CMake dependencies described by Godot.

Run `godot --headless --path project --editor --import`, then `godot --headless --path project --export-debug Android ../build/Castlehold-debug.apk` with a configured debug keystore. `tools/configure_android.py` sets SDK paths in Linux CI after the editor has created its settings file. It is not needed when you set paths through the editor.

## Required device verification
Test one midrange arm64 phone with Vulkan and at least one wide/notched display. Check launch, safe areas, taps, sound, suspend/resume, process-kill recovery, victory, gate breach, retry, and frame-time spikes. Target 60 fps with 30 fps fallback remains a target, not a measured claim. For compatibility testing launch the project with `--rendering-method gl_compatibility`; an in-game renderer selector is not yet implemented.

Reference: [Godot Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)

## Graphics update 0.2.1

Android version code is 5; package ID and save format are unchanged. All new maps are included as Resources with ETC2/ASTC import enabled. CI also runs `tests/graphics.gd` to check material imports and paused effects. Install the APK from the run for the applied graphics-source commit, not the earlier ZIP-upload commit. Debug signing behavior remains as documented above.

## Music update 0.2.2

Android version code is 6. The same package ID and campaign save format are retained. The soundtrack is a bundled stereo Ogg Vorbis resource; playback works offline and does not request a network permission. A separate versioned preferences file stores music/effects levels and mute. CI includes `tests/audio_settings.gd`. Check speaker balance at the 35% default, slider response, hardware volume interaction, and Home/return behavior on a physical phone. Download the APK from the run for the applied music-source commit.

## Horde update 0.3.0

Version code is 7; package ID, version 2 checkpoints and audio preferences remain compatible. Six original enemy models are included as glTF 2.0 assets. CI now checks horde mechanics, pooled-dust initialization, animated mesh bounds, old reinforcement snapshots and contrasting recruitment policies. The source ZIP is cumulative and contains paths relative to the repository root, without a wrapper folder.

No 0.3.0 APK was exported locally. Download the artifact from the successful run for the commit that extracts this update. Check the reported flashing during dense battles and finger scouting on the same phone; also inspect the orc silhouettes, ogre attack timing and late-wave pressure.

## Previous Tusk & Ember update 0.3.1

Version code 8 retains the package ID, version 2 checkpoints and audio preferences. Two new glTF enemies, a bone-attached staff effect, 16-slot fireball pool and two synthesized sound effects are included. CI runs `tests/ogre_elites.gd` for animation contact, flight/impact, pause, splash, charge counters and restore.

The APK must still be built by Actions and reviewed on a phone. Inspect shamans at wave 18 and warthog riders at wave 25, including the visible staff-tip launch, readable flame size, hooves/tusks, charge timing, pause and dense fights. Check both effects at your preferred sound level. Download the successful artifact for the commit that extracts the source update, rather than the ZIP-upload commit. Signing behavior and possible uninstall/save loss remain as described above.

The Siege Bosses source includes the HTTP/1.1 retry fix for interrupted engine/template downloads. Its CI also runs the boss attack, pause, save, reinforcement and final-victory checks before APK export.

## Stone & Steel 0.4.1

Version code 10 retains the package ID, version 2 campaign checkpoints and separate audio preferences. The three shared 512² character atlases use the existing Android texture imports. Nine short mono 24 kHz defeat clips are preloaded into a two-player pool on the Effects bus; CI includes `tests/defeat_voices.gd`. Test device speaker clarity and crowd overlap, warmer castle surfaces, fine armor shimmer, giant silhouettes and pause/background behavior. No local Android APK was exported for this update.

## Warcry 0.4.3

Version code 11 retains the package ID and checkpoint/settings formats. The full package can update the current source repository or populate an empty one. Defeat audio now has separate human/orc/ogre playback slots, higher vocal-body gain, a Voices bus routed through Effects, brief music/impact ducking and a native final-output hard limiter. Settings offers three real death previews. The core suite now includes final mixed-audio capture and simultaneous-voice headroom checks in addition to sample decoding. Verify those preview buttons on the phone at the preferred Effects level, then listen in a crowded battle. No local APK export is claimed; install the artifact from the successful source-commit Actions run.
