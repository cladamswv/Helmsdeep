# Castlehold 0.2.0 — Medieval Siege

This cumulative source update applies over First Stand or either earlier update. It includes the Android texture-import correction, rebuilt fortress and finger camera. Extract it at the repository root; there is no wrapper folder.

Medieval longbows, quivers, swords, shields, spears, nasal helmets, visored knights, plumes, horses and lances replace the old indistinct troop designs. The fortress uses warmer sandstone, smaller courses, narrow mortar joints and curved tower stones. The gate and portcullis retain animated destruction/repair.

The siege starts after four seconds. Each of 100 waves sends reinforcements for 10–15 seconds, with a 3–5-second gap before the next wave. Existing combat continues. No manual Begin button or inter-wave victory interruption remains. Clear the last attackers after wave 100 to win.

Pause freezes combat and its clock while allowing recruitment and paid Gate/Keep repairs. Resume continues the same wave. Finger scouting and the Castle return button remain. Survivors heal at wave starts without being recreated; defeated troops stay lost. A Keep defeat offers a saved-wave retry, paused for planning.

Upload Castlehold-Medieval-Siege-Update.zip to your GitHub repository and run the install commands in README.md. The initial `git pull --ff-only` brings a ZIP uploaded through the GitHub website into an already-open Codespace. Extract, commit and push to start the APK workflow. Download Castlehold-Android-debug from the successful run's Artifacts, extract it, and install the APK.

Local evidence: 66 passing checks and full-siege simulation. The asset previews are CPU inspections, not Android screenshots. Device appearance/performance and the new APK build still need confirmation. ANDROID_BUILD.md documents per-run debug signing and installation behavior.
