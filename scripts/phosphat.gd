extends StaticBody2D

@export var ores: Array = [
	{"ore_type": "Phosphat", "yield_amount": 1, "drill_time": 4.0}
]

func _ready() -> void:
	
	set_meta("ores", ores)



func _process(_delta: float) -> void:
	pass
