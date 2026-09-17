# Visual correction 0.1.1

Based on the user's Android screenshot of 0.1.0.

## Confirmed root cause
Godot imported the original glTF vertex-color arrays (10,116 entries on the archer) but the imported material had `vertex_color_use_as_albedo=false`. This made every character white. CharacterPresentation now enables authored vertex colors on shared material overrides, used by both battlefield characters and portrait models. A regression test verifies the flag and the color data.

## Other corrections
- Lower camera angle and tighter framing; adaptive aspect expansion replaces fixed 16:9 letterboxing on wide phones.
- Lower, irregular layered ridgelines replace pointed mountain cones.
- Asymmetric broadleaf tree canopies replace oversized conical foliage; tall foreground vegetation is removed.
- Continuous ground shader adds varied grass, an irregular dirt path, and subtle wagon ruts.
- Lower directional/ambient brightness, deeper masonry palette, tower masonry bands and keep facade trim.
- Dark status panel and two-line status text improve contrast and fit.
- Preserve the Android ETC2/ASTC import fix and increment debug build version to 2.

## Verification and limits
Godot 4.7.2 headless import passes. All 19 integration checks pass, including the two new character-color checks. The new camera, terrain shader, lighting and UI have not been rendered on Android in this environment. This is a targeted visual correction, not a declaration that the commercial character-quality gate has passed. The 30-wave campaign and advanced units remain unfinished.

## Apply this update
Upload Castlehold-Visual-Fix.zip into the existing Codespace repository root and run:

```
unzip -o Castlehold-Visual-Fix.zip
git add project tests docs README.md
git commit -m "Fix character colors and improve battlefield presentation"
git push
```

This is an update archive: it contains changed/new files at repository-relative paths. It does not create an extra Castlehold directory. The next GitHub Actions run builds version 0.1.1. The existing workflow generates a new debug signing key each run, so Android may require uninstalling the previous debug app before installing this build; uninstalling removes that app's saved progress.
