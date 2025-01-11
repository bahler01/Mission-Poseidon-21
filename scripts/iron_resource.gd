# iron_ore.gd
extends StaticBody2D

@export var ores: Array = [
	{"ore_type": "Iron", "yield_amount": 1, "drill_time": 3.0},
	{"ore_type": "Copper", "yield_amount": 2, "drill_time": 2.5}
]

func _ready() -> void:
	# Сохраняем массив руд в метаданные ноды для доступа из других скриптов
	set_meta("ores", ores)
	
func get_sonar_ping_settings() -> Dictionary:
	return {
		"active": {
			"ellipse_color": Color(1, 1, 1),
			"ellipse_size": Vector2(3.5, 3),

			"glow_enabled": true,
			"glow_color": Color(1, 0.3, 0.3),
			"glow_size_factor": 2.5,

			"tail_enabled": true,
			"tail_steps": 5,
			"tail_step_distance": 4.0,
			"tail_size_factor": 0.1,
			"tail_alpha_factor": 0.7,
			"tail_brightness_factor": 0.6,
			"tail_fade_duration": 2.0,
			"tail_life_duration": 1.5,
			"tail_size_shrink_duration": 0.001,

			"tail_glow_enabled": true,
			"tail_glow_color": Color(1, 0.3, 0.3),
			"tail_glow_size_factor": 2.5,
			"tail_glow_alpha_factor": 0.5,
			"tail_glow_life_duration": 2.0,
			"tail_glow_size_shrink_duration": 2.0,
		},
		"passive": {
			"ellipse_color": Color(0.8, 1.0, 0.8),
			"ellipse_size": Vector2(3, 1.2),

			"glow_enabled": true,
			"glow_color": Color(0.8, 1.0, 0.8),
			"glow_size_factor": 2.0,

			"tail_enabled": false,  # пассивный хвост отключим
		},
		"directed": {
			"ellipse_color": Color(1, 1, 0.4),
			"ellipse_size": Vector2(2, 0.8),

			"glow_enabled": true,
			"glow_color": Color(1, 1, 0.4),
			"glow_size_factor": 1.8,

			"tail_enabled": true,
			"tail_steps": 5,
			"tail_step_distance": 3.0,
			"tail_size_factor": 0.05,
			"tail_alpha_factor": 0.9,
			"tail_brightness_factor": 0.8,
			"tail_fade_duration": 2.0,
			"tail_life_duration": 2.0,
			"tail_size_shrink_duration": 0.5,

			"tail_glow_enabled": true,
			"tail_glow_color": Color(1, 1, 0.7),
			"tail_glow_size_factor": 1.8,
			"tail_glow_alpha_factor": 0.5,
			"tail_glow_life_duration": 3.0,
			"tail_glow_size_shrink_duration": 1.5,
		}
	}
