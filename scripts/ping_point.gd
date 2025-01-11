extends RefCounted
class_name PingPoint

# Thickness of the collision; used to determine if a tail should be rendered
var collision_thickness: float = 1.0

# Position of the ping point in the game world
var position: Vector2

# Distance from the origin point to this ping point
var distance: float

# Direction vector from the origin to this ping point
var direction: Vector2

# Time remaining before the ping point fades out
var time_left: float

# Time remaining before the brightness of the ping point fades
var brightness_time_left: float

# Color of the ping point
var color: Color

# Visibility status of the ping point; initially not visible
var visible: bool = false

# Time elapsed since the ping point became visible
var visible_time_elapsed: float = 0.0

# Mode of the ping point: "active", "passive", or "directed"
var mode: String = "active"

# Duration for the ping point to fade out (original purpose: for alpha calculations)
var created_fade_duration: float

# Duration for the brightness to fade (original purpose: for alpha calculations)
var created_brightness_duration: float

# Dictionary containing settings that override default configurations
var ping_settings: Dictionary = {}

# Flag indicating whether the ping point should have a tail
var ignore_tail: bool = false


func _init(
	_position: Vector2,
	_distance: float,
	_direction: Vector2,
	_time_left: float,                # fade_duration
	_brightness_time_left: float,     # brightness_fade
	_color: Color,
	_ping_settings: Dictionary = {}
) -> void:
	# Initializes a new PingPoint with the given parameters
	position = _position
	distance = _distance
	direction = _direction
	time_left = _time_left
	brightness_time_left = _brightness_time_left
	color = _color

	created_fade_duration = _time_left
	created_brightness_duration = _brightness_time_left

	ping_settings = _ping_settings
