# Forged in the Valley — graphics update 0.2.1

This is a cumulative source update over First Stand, the fortress update or Continuous Siege. The file belongs at the root of the existing Castlehold repository; extract it there, commit the extracted files and push. The README contains phone/Codespaces commands. The ZIP itself is not an APK.

## Visible changes

- Smoother sculpted faces, jaw/nose/eye shapes, cowl fringe, shaped gorgets and shoulder plates.
- Broad folds in tabards and horse caparisons; curved shield faces and clear metal rims.
- Distinct cloth, leather, skin, steel and gold finishes using one mesh surface and a shared material atlas.
- Brown sandstone with fine albedo/normal detail, oak grain and many smaller slate shingles.
- Warm valley sun, gradient sky, reflected sky light on armor, richer road ruts/grit and deeper tree canopies.
- Small animated heraldic pennants. Wind freezes while paused.
- Soft troop contact shadows; shared feathered arrows; short sparks, tumbling chips and expanding dust.
- Sharper matching portraits with warm/cool light, cached after initialization; restrained button feedback and improved text contrast.

The assault schedule, gold/stat resources, army limits, save version, touch-camera bounds, recruitment, repairs and pause rules retain their 0.2.0 behavior. The visual effects pool remains fixed at 96 slots, arrows at 128. Soldier meshes remain one surface per archetype. Ordinary troop mesh budgets decrease for swordsmen, spearmen and raiders; mounted rider/horse combinations increase to 10,298 triangles. The fortress grows from 176,390 to 181,568 triangles.

## Verification limits

See VALIDATION.md for headless engine checks and the complete siege simulation. The two review PNGs inspect actual project assets with approximate CPU lighting. They are not Android screenshots. No local APK export, physical-device frame-rate measurement or commercial visual sign-off is claimed. Review the new GitHub-built APK on the phone before treating its final appearance as approved.
