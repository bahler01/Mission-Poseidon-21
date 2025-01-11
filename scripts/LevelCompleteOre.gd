extends StaticBody2D


@export var ores: Array = [
	{"ore_type": "Quarz", "yield_amount": 14, "drill_time": 1.0},
	{"ore_type": "Phosphat", "yield_amount": 7, "drill_time": 1.0},
	{"ore_type": "Magnetite", "yield_amount": 7, "drill_time": 1.0},
	{"ore_type": "Platinum", "yield_amount": 8, "drill_time": 1.0},
	{"ore_type": "Rhodium", "yield_amount": 8, "drill_time": 1.0}
]

func _ready() -> void:
	
	set_meta("ores", ores)



func _process(_delta: float) -> void:
	pass
