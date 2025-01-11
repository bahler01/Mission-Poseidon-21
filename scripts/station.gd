extends Node2D
class_name Station

# -------------------- EXPORT VARIABLES --------------------
@export var is_start_station: bool = false    # Flag indicating if this station is the starting station
@export var is_end_station: bool = false      # Flag indicating if this station is the ending station
@export var docking_threshold: float = 5.0    # Distance threshold for docking procedures

# -------------------- CONSTANTS --------------------
const LINE_LENGTH = 10     # Length of the visual line indicator
const LINE_THICKNESS = 3   # Thickness of the visual line indicator

func _ready() -> void:
	
	add_to_group("StationGroup")
	# Request an immediate redraw of the node's visuals
	queue_redraw()

func _draw() -> void:
	# Draw a green horizontal line at the station's position for visualization
	
	# Calculate half the length of the line for centered drawing
	var half_len = float(LINE_LENGTH) / 2.0
	# Define the start and end points of the line relative to the node's origin
	var start_point = Vector2(-half_len, 0)
	var end_point = Vector2(half_len, 0)
	
	# Draw the line with specified color and thickness
	draw_line(start_point, end_point, Color(0, 1, 0), LINE_THICKNESS)

func force_redraw() -> void:
	#  Method to manually trigger a redraw of the station's visuals
	queue_redraw()
