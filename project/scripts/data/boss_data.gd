class_name BossData
extends Resource
## Authored encounters, separate from the regular horde's budget and stat growth.
@export var special_kind := "quake"
@export var warning := "MAUL SLAM"
@export var special_interval := 10.0
@export var special_windup := 1.2
@export var special_duration := 2.4
@export var special_damage := 130.0
@export var structure_damage := 250.0
@export var radius := 3.2
@export var target_limit := 5
@export var knockback := 0.8
@export var bounty := 150
@export var firing_line := 8.0
@export var summon_thresholds := PackedFloat32Array([])
@export var summon_ids := PackedStringArray([])
