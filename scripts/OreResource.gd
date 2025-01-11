extends StaticBody2D

# This script represents a universal object for all types of materials that can be drilled.
# It encapsulates properties like ore type, yield amount, and the time required to drill the ore.

# ------------------- EXPORT VARIABLES -------------------
# The type of ore this node represents (e.g., Iron, Gold, etc.).
@export var ore_type: String = "Iron"
# The amount of yield obtained when drilling this ore.
@export var yield_amount: int = 1
# The time it takes to drill through this ore.
@export var drill_time: float = 3.0

##
# Called when the node is added to the scene.
# Initializes and stores ore data in the node's metadata for universal access by other scripts.
##
func _ready() -> void:
	# Create an array of ores based on the current node settings.
	var ores = [
		{"ore_type": ore_type, "yield_amount": yield_amount, "drill_time": drill_time}
	]
	
	# Store the array of ores in the node's metadata, making it accessible for drilling scripts.
	set_meta("ores", ores)
