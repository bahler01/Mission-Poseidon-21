extends Node2D

# -------------------- EXPORTED PARAMETERS FOR PING VISUALS --------------------
@export var fade_duration: float = 1.5              # Total duration for the ping to fade out
@export var brightness_fade_duration: float = 2.0   # Duration over which the ping's brightness fades

@export var ellipse_size: Vector2 = Vector2(5, 2)   # Base size of the ellipse representing the ping
@export var ellipse_color: Color = Color(1, 0.647, 0)  # Base color of the ellipse

@export var glow_enabled: bool = true               # Toggle for enabling glow effect around the ellipse
@export var glow_color: Color = Color(1, 1, 0.5)    # Color of the glow effect
@export var glow_size_factor: float = 2             # Factor by which the ellipse size is increased for the glow
@export var glow_alpha_factor: float = 0.6          # Transparency factor for the glow
@export var glow_life_duration: float = 1.0         # Duration over which the glow effect is visible
@export var glow_size_shrink_duration: float = 1.0  # Time over which the glow shrinks to normal size

# -------------------- CONSTANTS --------------------
# Number of segments used to approximate the ellipse as a polygon
const ELLIPSE_SEGMENTS: int = 8

# -------------------- INTERNAL STATE VARIABLES --------------------
var time_left: float                   # Remaining time for the ping before it fades out completely
var brightness_time_left: float        # Remaining time for the brightness to fade out
var visible_time_elapsed: float = 0.0  # Total time since the ping became visible

func _ready() -> void:
	# Initialize timers for fading and brightness
	time_left = fade_duration
	brightness_time_left = brightness_fade_duration
	# Enable processing so that _process() is called every frame
	set_process(true)

func _process(delta: float) -> void:
	# Decrease remaining life and brightness times based on elapsed time
	time_left -= delta
	brightness_time_left = max(brightness_time_left - delta, 0.0)
	visible_time_elapsed += delta

	# If the ping has fully faded out, remove it from the scene
	if time_left <= 0.0:
		queue_free()

	# Request a redraw to update the visual appearance each frame
	queue_redraw()

func _draw() -> void:
	# Calculate current transparency (alpha) based on remaining life
	var alpha = clamp(time_left / fade_duration, 0, 1)
	# Calculate brightness factor 't' based on remaining brightness time
	var t = brightness_time_left / brightness_fade_duration

	# Interpolate the ellipse color towards a lighter color based on brightness factor
	var col = ellipse_color.lerp(Color(0.8, 0.8, 0.8), t)
	col.a = alpha

	# Draw the ellipse at the node's origin with no additional rotation (0.0) using calculated color
	draw_polygon_ellipse(Vector2.ZERO, ellipse_size, 0.0, col)

	# If glow effect is enabled, draw the glow around the ellipse
	if glow_enabled:
		_draw_glow(alpha)

#
# -------------------- DRAW GLOW EFFECT --------------------
#
func _draw_glow(alpha: float) -> void:
	# Get the time elapsed since the ping became visible
	var vte = visible_time_elapsed
	var glow_alpha = 0.0
	var glow_current_size_factor = 1.0

	# Calculate glow transparency and size factor while within its life duration
	if vte <= glow_life_duration:
		glow_alpha = (1.0 - (vte / glow_life_duration)) * glow_alpha_factor * alpha
		var glow_progress = min(vte / glow_size_shrink_duration, 1.0)
		# Interpolate glow size factor from specified factor to 1.0 as time progresses
		glow_current_size_factor = lerp(glow_size_factor, 1.0, glow_progress)

	# Only draw glow if it is still visible
	if glow_alpha > 0.0:
		var gcol = glow_color
		gcol.a = glow_alpha
		# Adjust ellipse size for glow based on current size factor
		var glow_ellipse_size = ellipse_size * glow_current_size_factor
		draw_polygon_ellipse(Vector2.ZERO, glow_ellipse_size, 0.0, gcol)

#
# -------------------- DRAW POLYGON ELLIPSE --------------------
#
func draw_polygon_ellipse(pos: Vector2, size: Vector2, rot: float, color: Color) -> void:
	# Generate points approximating an ellipse using a polygon
	var points = []
	for i in range(ELLIPSE_SEGMENTS):
		# Calculate angle for current segment
		var angle = i * TAU / float(ELLIPSE_SEGMENTS)
		# Compute point on ellipse perimeter, apply rotation and position offset
		var p = Vector2(cos(angle), sin(angle)) * size
		p = p.rotated(rot) + pos
		points.append(p)
	# Create a polygon from the points and draw it with the given color
	var polygon = PackedVector2Array(points)
	draw_polygon(polygon, [color])
