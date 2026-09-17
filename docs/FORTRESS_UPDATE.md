# Castlehold 0.1.2 — Fortress and scouting camera

A cumulative update for the original First Stand source or the previous visual fix.

## Fortress reconstruction
Original generated architecture replaces the old castle builder: a genuine segmented stone arch, recessed timber doors, iron portcullis, twin round gate towers, buttressed curtain walls, battlement walkways, arrow slits, a taller keep with slate roof courses, a corner watchtower, a lower adjoining hall, blue/gold swallowtail banners, side ramparts, paved courtyard, stairs and supply barrels. Beveled masonry edges and alternating stone courses add depth. Static parts are merged by material and structure to avoid a separate draw call for every stone.

Gate boards, braces, rivets and portcullis bars remain independent animated damage pieces. Gate repair cancels outstanding collapse tweens before restoring saved transforms. Archer slots are moved clear of the larger gate towers while retaining the original battlement foot height.

The supplied `fortress-review.png` is a CPU rendering of actual game geometry exported by Godot. It is explicitly NOT an Android gameplay screenshot. Final lighting, shadows, performance and phone-scale readability must be verified on the target device.

## Finger controls
Drag an empty part of the battlefield with one finger. The camera tracks the ground plane with smoothing, bounded horizontal scouting and modest depth movement. A short drag threshold suppresses tap jitter. Starting on UI cannot drag the map; releasing over UI correctly ends an existing gesture. Synthetic duplicate mouse events and second-finger takeover are ignored. The CASTLE button returns home. Opening Credits blocks camera input; closing it restores interaction. Preparation and breaches also return focus to the fortress. Desktop left-button dragging is supported.

Enemies enter farther down the road, beyond the maximum scouting view, giving the player a useful opportunity to see approaching formations. This increases approach time in the three test encounters. No new campaign or roster is claimed.

## Verification
Godot 4.7.2 imports the project. Nineteen existing integration checks plus fifteen new camera/fortress checks pass (34 total). New checks inject real viewport touch events and cover drag direction, jitter rejection, second touch, release over HUD, limits, UI isolation, modal blocking, recenter, offscreen spawning at normal/wide aspect ratios, gate debris and repair restoration. Test output is included in this folder.

No updated APK was exported locally and no physical Android device was available to verify the new appearance/touch feel. The commercial visual-quality gate remains open. The original brief remains the full production target.

## Install source update from Codespaces
Upload `Castlehold-Fortress-Update.zip` to the existing repository root. Run:

```bash
unzip -o Castlehold-Fortress-Update.zip &&
git add project tests docs tools .github README.md .gitignore ASSET_LICENSES.md &&
git commit -m "Redesign fortress and add touch scouting camera" &&
git push
```

Files are at repository-relative paths, with no extra Castlehold wrapper directory. Earlier character-color, map and Android ETC2/ASTC fixes are included. This does not require applying the earlier visual-fix ZIP first. Download the APK from the resulting GitHub Actions run. The existing debug workflow generates a fresh key per run; Android may require uninstalling the old debug app before installing the new one, which removes its saved progress.
