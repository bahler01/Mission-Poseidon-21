extends StaticBody2D


@export var ores: Array = [
	{"ore_type": "Black Box", "yield_amount": 1, "drill_time": 9.0},
]

func _ready() -> void:
	
	set_meta("ores", ores)



func _process(_delta: float) -> void:
	pass
