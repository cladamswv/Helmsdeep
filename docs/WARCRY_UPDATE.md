# Warcry 0.4.2

This update addresses hard-to-hear defeat sounds and an overly forgiving siege economy. It contains the complete game source and can be applied to the current Castlehold repository.

## Death sounds

- Fuller, louder human oofs, orc exhalations and ogre grunts, with three variants each.
- A reserved playback slot for each family, so an ogre grunt can be heard during a burst of other casualties.
- Music and combat impacts briefly lower during cries, with controlled final output peaks.
- **Settings → Test human / Test orc / Test ogre** previews the actual sounds while battle stays paused. Use **Sound effects** to adjust them and disable **Mute all audio** to hear them.

These remain original synthesized, family-friendly cues. The software test captures audible output from the actual final mix; phone-speaker timbre and in-battle balance still need device listening.

## Harder siege

Boss attacks, charges and specials are 15% stronger than in 0.4.1. Base interval gold changes from 95 + 8 × wave to floor(95 + 7.5 × wave); boss bounties are unchanged. Ordinary attackers retain the previous 12% damage increase.

The unchanged mixed purchase test still wins at wave 100, but loses 268 defenders instead of 228. Its gate falls below half HP. At the final boss's defeat it has archers left but no infantry or cavalry; the boss bounty funds rebuilding before the last supporting troops are cleared. Archer-only defense loses at wave 55. See **VALIDATION.md** for the full results and limits of automated playtesting.

The 100-wave pacing, pause, recruiting and repair controls, survivor healing, touch scouting, medieval music, detailed fortress and existing characters are retained. This release changes sound and difficulty, not character art.

## Apply the complete package

Upload **Castlehold-Warcry-Full.zip** to the root of your current Castlehold repository. In its Codespaces terminal, paste:

```bash
git pull --ff-only &&
unzip -o Castlehold-Warcry-Full.zip &&
git add project tests docs tools .github README.md FRESH_INSTALL.md GDD.md CHARACTER_ART_BIBLE.md BALANCE.md ANDROID_BUILD.md ASSET_LICENSES.md .gitignore &&
git commit -m "Make death voices audible and strengthen the siege" &&
git push
```

After the corresponding **Build Castlehold Android** run succeeds, download **Castlehold-Android-debug**, extract it and install `Castlehold-debug.apk`. Open **Credits** to confirm **Warcry 0.4.2**. The source ZIP is not itself an APK.

The full archive also works in an empty repository; see **FRESH_INSTALL.md** at repository root. Earlier version 2 saves and audio preferences remain compatible. Debug signing may prevent installing over a differently signed old APK; see **ANDROID_BUILD.md** before uninstalling, which removes local progress.
