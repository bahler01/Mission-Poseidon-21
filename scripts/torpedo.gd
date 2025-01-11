extends Area2D

#
# ----------------------------------------------------------------------
#   TORPEDO PARAMETERS: MOVEMENT, DAMAGE, EXPLOSION ON COLLISION
# ----------------------------------------------------------------------
#
@export var torpedo_speed: float = 100.0           # Speed at which the torpedo travels
@export var damage_on_hit: float = 50.0            # Damage inflicted on impact
@export var collision_explosion: bool = true       # Whether the torpedo should explode on collision
@export var explosion_passive_radius: float = 50.0 # Radius of passive explosion effect for sonar detection
@export var torpedo_lifetime: float = 3.0          # Time in seconds before the torpedo self-destructs

#
# ----------------------------------------------------------------------
#   "PING" ELLIPSE PARAMETERS
# ----------------------------------------------------------------------
#
@export var ping_interval: float = 0.3             # Interval in seconds between generating new pings

# The following parameters are passed to the ping instance, matching those in torpedo_ping.gd
@export var fade_duration: float = 1.0
@export var brightness_fade_duration: float = 0.5
@export var ellipse_size: Vector2 = Vector2(3, 1.2)
@export var ellipse_color: Color = Color(1, 0.65, 0)
@export var glow_enabled: bool = true
@export var glow_color: Color = Color(1, 1, 1)
@export var glow_size_factor: float = 2
@export var glow_alpha_factor: float = 0.2
@export var glow_life_duration: float = 0.6
@export var glow_size_shrink_duration: float = 0.6

#
# ----------------------------------------------------------------------
#   INTERNAL VARIABLES
# ----------------------------------------------------------------------
#
var is_active: bool = true            # Indicates if the torpedo is active
var lifetime_counter: float = 0.0     # Tracks elapsed time since torpedo launched
var ping_accumulator: float = 0.0     # Accumulator for ping interval timing

@onready var collision_shape: CollisionShape2D = $CollisionShape2D  # Reference to torpedo's collision shape

# Preload the ping scene to instantiate "ping" ellipses during flight
var ping_scene = preload("res://scenes/torpedo_ping.tscn")  # Make sure the path is correct!

func _ready() -> void:
	lifetime_counter = 0.0
	ping_accumulator = 0.0
	
	# Spawn an initial ping immediately on launch
	_spawn_ping()

	# Connect collision signals to respective handlers
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))

func _physics_process(delta: float) -> void:
	if not is_active:
		# If the torpedo is inactive, skip processing movement and pings
		return

	# 1) Move the torpedo forward along its current rotation
	var direction = Vector2(cos(rotation), sin(rotation))
	var velocity = direction * torpedo_speed
	position += velocity * delta

	# 2) Periodically spawn a new ping ellipse based on the ping_interval
	ping_accumulator += delta
	if ping_accumulator >= ping_interval:
		ping_accumulator = 0.0
		_spawn_ping()

	# 3) Track lifetime and self-destruct if torpedo has existed longer than torpedo_lifetime
	lifetime_counter += delta
	if lifetime_counter >= torpedo_lifetime:
		explode()
		return

	# 4) Optionally adjust torpedo rotation to face the player
	_turn_towards_player()

	# 5) Request a redraw for any visual updates
	queue_redraw()

#
# ----------------------------------------------------------------------
#   SPAWN "PING" ELLIPSE
# ----------------------------------------------------------------------
#
func _spawn_ping() -> void:
	# Instantiate a new ping from the preloaded scene
	var ping = ping_scene.instantiate()
	# Position the ping at the torpedo's current global position
	ping.global_position = global_position
	# Rotate the ping so that its orientation matches the torpedo's heading, adjusted by 90 degrees
	ping.rotation = rotation + deg_to_rad(90)

	# Pass along configuration parameters to the ping instance
	ping.fade_duration = fade_duration
	ping.brightness_fade_duration = brightness_fade_duration
	ping.ellipse_size = ellipse_size
	ping.ellipse_color = ellipse_color
	ping.glow_enabled = glow_enabled
	ping.glow_color = glow_color
	ping.glow_size_factor = glow_size_factor
	ping.glow_alpha_factor = glow_alpha_factor
	ping.glow_life_duration = glow_life_duration
	ping.glow_size_shrink_duration = glow_size_shrink_duration

	# Add the ping to the root of the scene tree so it can be rendered independently
	get_tree().root.add_child(ping)

#
# ----------------------------------------------------------------------
#   COLLISION HANDLERS
# ----------------------------------------------------------------------
#
func _on_body_entered(_body: Node) -> void:
	if not is_active:
		return

	# Do not explode if colliding with the player
	if _body.is_in_group("player"):
		return

	# Trigger explosion on collision if enabled
	if collision_explosion:
		explode()

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return

	# Do not explode if the area belongs to the player
	if area.is_in_group("player"):
		return

	print(">>> Torpedo: _on_area_entered with area =", area)
	if collision_explosion:
		explode()

#
# ----------------------------------------------------------------------
#   EXPLOSION AND DAMAGE
# ----------------------------------------------------------------------
#
func explode() -> void:
	if not is_active:
		return

	is_active = false  # Deactivate torpedo to prevent multiple explosions

	# Trigger passive explosion noise for sonar detection if possible
	var sonar = _find_sonar_node()
	if sonar and sonar.has_method("add_passive_explosion_noise"):
		sonar.add_passive_explosion_noise(global_position, explosion_passive_radius)

	var space_state = get_world_2d().direct_space_state
	var shape = collision_shape.shape

	# Prepare shape query parameters for detecting nearby bodies to apply damage
	var shape_transform = global_transform

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = shape_transform
	query.collision_mask = collision_layer | collision_mask
	
	query.collide_with_areas = true
	query.collide_with_bodies = true  # Also check for Body2D collisions if necessary

	var results = space_state.intersect_shape(query)
	if results.size() == 0:
		print(">>> Torpedo: No intersect_shape hits. Nobody took damage.")
	else:
		print(">>> Torpedo: intersect_shape found ", results.size(), " colliders.")
		for result in results:
			if result.collider and result.collider.has_method("take_damage"):
				print(">>> Torpedo: Hitting collider = ", result.collider, " -> take_damage(", damage_on_hit, ")")
				result.collider.take_damage(damage_on_hit)

	# Remove the torpedo from the scene after explosion
	queue_free()

#
# ----------------------------------------------------------------------
#   TURN TOWARDS PLAYER
# ----------------------------------------------------------------------
#
func _turn_towards_player() -> void:
	# Adjust torpedo's rotation to point towards the player if found
	var player_node: Node2D = _find_player_node()
	if player_node:
		var to_player = player_node.global_position - global_position
		rotation = to_player.angle()

#
# ----------------------------------------------------------------------
#   FIND SONAR NODE
# ----------------------------------------------------------------------
#
func _find_sonar_node() -> Node:
	# Attempt to find the sonar node at the expected path "/root/Main/Player/Sonar"
	var root_node = get_tree().root
	if root_node.has_node("Main/Player/Sonar"):
		return root_node.get_node("Main/Player/Sonar")
	return null

#
# ----------------------------------------------------------------------
#   FIND PLAYER NODE
# ----------------------------------------------------------------------
#
func _find_player_node() -> Node2D:
	# Search for the player node in common paths
	var root = get_tree().root
	if root.has_node("Root/Player"):
		return root.get_node("Root/Player")
	if root.has_node("Player"):
		return root.get_node("Player")
	return null
