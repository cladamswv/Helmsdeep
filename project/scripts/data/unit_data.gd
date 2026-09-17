class_name UnitData
extends Resource
@export var id: String
@export var title: String
@export var cost: int = 0
@export var hp: float = 100
@export var damage: float = 18
@export var interval: float = 1.25
@export var attack_range: float = 1.25
@export var speed: float = 1.4
@export var armor: float = 0
@export var ranged: bool = false
@export var category: String = "infantry"
@export_enum("human", "orc", "ogre") var defeat_voice: String = "human"
@export var spacing: float = 0.88
@export var anti_cavalry: float = 1.0
@export var charge_damage: float = 0.0
@export var ranged_resistance: float = 0.0
@export var hit_time: float = -1.0
@export var structure_damage_multiplier: float = 1.0
@export var splash_radius: float = 0.0
@export var splash_fraction: float = 0.45
@export var splash_targets: int = 2
@export var knockback: float = 0.0
@export var visual_scale: float = 1.06
@export var ranged_target_bias: float = 1.0
@export var heavy_target_bias: float = 1.0
@export var shield_target_bias: float = 1.0
@export var pursuit_limit: float = 5.0
@export var projectile_kind: String = "arrow"
@export var projectile_speed: float = 12.0
@export var projectile_splash_radius: float = 0.0
@export var projectile_splash_fraction: float = 0.35
@export var projectile_splash_targets: int = 2
@export var charge_speed_multiplier: float = 1.0
@export var charge_knockback: float = 0.0
@export var body_radius: float = 0.0
@export var impact_height: float = 1.2
@export var staff_tip: float = 1.68
@export var focus_scale: float = 1.0
@export var boss: BossData
@export var model: PackedScene
