# Warcry 0.4.3 — Battle speed

The live siege now supports three player-selectable clock rates: 1×, 1.5× and 2×. The HUD Speed button cycles the options beside Pause, while Settings presents the same choices as a radio row.

Speed changes affect the simulation clock as one system, keeping movement, attack contact timing, projectiles, skeletal animation and the 10–15 second assault / 3–5 second gap cadence in step. Music playback and voice pitch remain natural. Pause, Settings, credits and result screens reset the clock to 1× so controls stay readable; resuming restores the selected speed.

The preference is stored in `user://castlehold_settings_v1.cfg` under `[battle] speed`, independently of campaign checkpoints. Unsupported or malformed values safely fall back to 1×.

Automated coverage is in `tests/battle_speed.gd` and checks persistence, labels, HUD exposure, all three rates, pause/resume behavior and invalid-value handling. Physical Android touch, audio and frame-rate review remains part of device QA.
