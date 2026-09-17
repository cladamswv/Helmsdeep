# Castlehold — fresh install

`Castlehold-Battle-Speed-Full.zip` contains the complete Warcry 0.4.3 source project, all game assets, tests and the Android build workflow. It can be extracted into an empty repository. Earlier Castlehold files are not required. You can also apply this complete package to your current Castlehold repository using the same command block.

Included: 100 nonstop waves, four giant bosses, medieval defenders, the orc/ogre horde, detailed brown castle masonry, stronger enemy attacks, defeat voices, adjustable medieval music, selectable 1× / 1.5× / 2× battle speed, pause, recruitment, repairs and finger scouting.

## 1. Create the repository

Create a **new GitHub repository**, for example `Castlehold-Fresh`. Enable **Add a README file** and use the `main` branch. Upload `Castlehold-Battle-Speed-Full.zip` into that repository's root and commit the upload. Open a Codespace for this new repository.

Keep the downloaded ZIP's name exactly as shown. If the phone adds a suffix such as `(1)`, rename the upload to `Castlehold-Battle-Speed-Full.zip` before continuing.

## 2. Paste into the Codespaces terminal

```bash
git pull --ff-only &&
unzip -o Castlehold-Battle-Speed-Full.zip &&
git add project tests docs tools .github README.md FRESH_INSTALL.md GDD.md CHARACTER_ART_BIBLE.md BALANCE.md ANDROID_BUILD.md ASSET_LICENSES.md .gitignore &&
git commit -m "Add selectable battle speed controls" &&
git push
```

The archive places `project`, `tools`, `tests`, `docs` and the workflow directly at repository root. No folder moves, old update ZIPs, local Godot install or manual Android setup are needed in Codespaces. The commands stop if a step fails.

## 3. Download the Android build

Open **Actions → Build Castlehold Android**. Select the run named **Add selectable battle speed controls**. After it succeeds, download **Castlehold-Android-debug**, extract the artifact ZIP and install `Castlehold-debug.apk` on the phone.

Uploading the source ZIP alone does not start the game build in an empty repository. The source commit above installs the workflow and triggers it.

If a build fails, open the failed job and expand its red step to see the specific error. The generic exit-code line alone does not identify the cause.

## Existing Android installation

This package retains the app ID `com.castlehold.firststand`. The workflow currently generates a debug signing key on each run. If Android rejects installation over the older app because its signature differs, uninstall the older Castlehold and install the new APK. **Uninstalling removes its saved progress.** Creating a new GitHub repository by itself does not reset the installed phone app.

This is a complete source package. GitHub Actions builds the APK using Godot 4.7.2. Current gameplay validation is in `docs/VALIDATION.md`; physical Android graphics, sound and performance still require device review.
