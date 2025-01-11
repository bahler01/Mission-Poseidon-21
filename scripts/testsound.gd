extends StaticBody2D


var base_noise_level: float = 1.0

func _ready() -> void:
	add_to_group("SoundEmitter")

func get_noise_level() -> float:
	# Здесь может быть сложная логика, зависящая от состояния объекта.
	# Пока просто возвращаем base_noise_level.
	return base_noise_level
