extends CharacterBody2D

# -------------------- MOVEMENT AND BEHAVIOR PARAMETERS --------------------
@export var max_hp: int = 100

@export var move_speed: float = 8.0       # Normal speed of the shark
@export var detection_range: float = 40.0  # Range within which the shark can detect the player
@export var attack_range: float = 16.0     # Range within which the shark will attempt to bite
@export var attack_cooldown: float = 2.0   # Time between consecutive attacks
@export var bite_damage: int = 13          # Damage dealt by a bite attack

@export var path_follow_node_path: NodePath = NodePath("..")  # Path to a PathFollow2D node for patrol movement
@export var ping_pong_patrol: bool = true                   # Whether the shark should reverse direction at ends of the path

# Slowing down (halt) after biting to give player a chance to escape
@export var post_bite_slow_duration: float = 0.5

# -------------------- STUN PARAMETERS --------------------
@export var stun_duration: float = 1.5             # Duration of stun state
@export var stun_knockback_strength: float = 5.0   # Strength of knockback when stunned

# -------------------- DEATH AND ASCENT PARAMETERS --------------------
@export var death_rise_acceleration: float = 5.0   # Acceleration as the shark rises when dead
@export var max_death_rise_speed: float = 3.0      # Maximum speed when rising after death
@export var vanish_time_after_death: float = 8.0   # Time until the shark vanishes after death if not hitting ceiling
@export var time_to_disappear_after_ceiling: float = 8.0  # Time after contacting the ceiling to disappear

# -------------------- INTERNAL VARIABLES --------------------
var current_hp: int                          
var current_state: String = "IDLE"           # Current state of the shark's state machine

var vanish_timer: float = 0.0                # Timer for vanishing after death
var attack_cooldown_timer: float = 0.0       # Timer to track cooldown between attacks

# For patrolling behavior
var path_follow: PathFollow2D                # Reference to the PathFollow2D node for patrol path
var direction_forward: bool = true           # Direction along the path (forward or backward)

# References to other nodes
@onready var player: CharacterBody2D = $"../../../Player"     
@onready var sonar: Node2D = $"../../../Player/Sonar"        

# Timers for various state transitions and effects
var _bite_recovery_timer: float = 0.0        # Timer for post-bite slowdown
var _stun_timer: float = 0.0                 # Timer for stun duration

# When shark is dead and rising, track time since hitting the ceiling
var _ceiling_timer: float = -1.0

func _ready() -> void:
	current_hp = max_hp

	# Initialize path_follow if the node path is set
	if not path_follow_node_path.is_empty():
		path_follow = get_node(path_follow_node_path) as PathFollow2D

	# Connect to sonar's mode_changed signal if available
	if sonar and sonar.has_signal("mode_changed"):
		sonar.connect("mode_changed", Callable(self, "_on_sonar_mode_changed"))

func _physics_process(delta: float) -> void:
	# State machine update: calls the appropriate state handler based on current_state
	match current_state:
		"IDLE":
			_state_idle(delta)
		"PATROL":
			_state_patrol(delta)
		"CHASE":
			_state_chase(delta)
		"BITE_RECOVERY":
			_state_bite_recovery(delta)
		"STUN":
			_state_stun(delta)
		"DEAD":
			_state_dead(delta)


	if current_state != "DEAD":
		move_and_slide()

#
# -------------------- STATE MACHINE --------------------
#
func set_state(new_state: String) -> void:
	# Change state if new_state is different from current_state
	if new_state == current_state:
		return
	_exit_state(current_state)
	current_state = new_state
	_enter_state(new_state)

func _enter_state(state_name: String) -> void:
	# Actions to perform when entering a new state
	match state_name:
		"IDLE":
			print("[SHARK] Enter IDLE")
		"PATROL":
			print("[SHARK] Enter PATROL")
		"CHASE":
			print("[SHARK] Enter CHASE")
		"BITE_RECOVERY":
			print("[SHARK] Enter BITE_RECOVERY")
			_bite_recovery_timer = post_bite_slow_duration
		"STUN":
			print("[SHARK] Enter STUN")
			_stun_timer = stun_duration
			_apply_stun_knockback()
		"DEAD":
			print("[SHARK] Enter DEAD")
			vanish_timer = vanish_time_after_death
			_ceiling_timer = -1.0
			velocity = Vector2.ZERO  # Reset velocity to start ascending in DEAD state

func _exit_state(state_name: String) -> void:
	# Actions to perform when exiting a state; currently none defined
	match state_name:
		_:
			pass

#
# -------------------- STATE HANDLERS --------------------
#
func _state_idle(_delta: float) -> void:
	# Immediately switch to patrol state for demonstration
	set_state("PATROL")

func _state_patrol(delta: float) -> void:
	if path_follow:
		# Move along the path based on move_speed and delta time
		var dist = path_follow.progress
		var step = move_speed * delta
		if direction_forward:
			dist += step
		else:
			dist -= step
		path_follow.progress = dist

		# If ping-pong patrol is enabled and path isn't looping, reverse at ends
		if ping_pong_patrol and not path_follow.loop:
			if path_follow.progress >= path_follow.get_curve().get_baked_length():
				direction_forward = false
			elif path_follow.progress <= 0:
				direction_forward = true

		global_position = path_follow.global_position
		rotation = path_follow.rotation
	else:
		# Fallback behavior: move left if no path_follow is set
		velocity = Vector2(-move_speed, 0)

	# Transition to CHASE state if player is within detection range or sonar detects player
	if player and global_position.distance_to(player.global_position) <= detection_range:
		set_state("CHASE")
		return

	if _check_sonar_detected():
		set_state("CHASE")

func _state_chase(delta: float) -> void:
	if player == null:
		set_state("PATROL")
		return

	attack_cooldown_timer += delta

	var dist_to_player = global_position.distance_to(player.global_position)

	# If player is too far, return to patrol
	if dist_to_player > detection_range * 2.5:
		set_state("PATROL")
		return

	# Move towards the player
	var dir_to_player = (player.global_position - global_position).normalized()
	velocity = dir_to_player * move_speed
	rotation = dir_to_player.angle()

	# Attempt to bite if in range and cooldown has passed
	if dist_to_player <= attack_range and attack_cooldown_timer >= attack_cooldown:
		_bite_player()
		attack_cooldown_timer = 0.0

func _state_bite_recovery(delta: float) -> void:
	# Wait for post-bite slow duration
	_bite_recovery_timer -= delta
	velocity = Vector2.ZERO  # Shark remains stationary during recovery

	if _bite_recovery_timer <= 0.0:
		# After recovery, decide next state based on player's proximity
		if player and global_position.distance_to(player.global_position) <= detection_range:
			set_state("CHASE")
		else:
			set_state("PATROL")

func _state_stun(delta: float) -> void:
	# Handle stunned state: reduce timers and slow down movement gradually
	_stun_timer -= delta

	# Grace period after stun before beginning to slow down
	var knockback_grace = 0.3

	if _stun_timer < (stun_duration - knockback_grace):
		# Begin reducing velocity after grace period
		velocity = velocity.move_toward(Vector2.ZERO, 30 * delta)

	# When stun duration ends, transition to CHASE or PATROL based on player distance
	if _stun_timer <= 0.0:
		if player and global_position.distance_to(player.global_position) <= detection_range:
			set_state("CHASE")
		else:
			set_state("PATROL")

func _state_dead(delta: float) -> void:
	# In DEAD state, shark slowly rises upward
	var desired_velocity = Vector2(0, -max_death_rise_speed)
	velocity = velocity.move_toward(desired_velocity, death_rise_acceleration * delta)

	move_and_slide()

	# If shark hits a wall or ceiling, start ceiling timer
	if is_on_wall() or is_on_ceiling():
		if _ceiling_timer < 0.0:
			_ceiling_timer = 0.0
		else:
			_ceiling_timer += delta

		# If time on ceiling exceeds threshold, remove shark from scene
		if _ceiling_timer >= time_to_disappear_after_ceiling:
			queue_free()
	else:
		# If not on ceiling, count down vanish timer until removal
		vanish_timer -= delta
		if vanish_timer <= 0:
			queue_free()

#
# -------------------- DAMAGE / DEATH HANDLING --------------------
#
func take_damage(amount: int, source: String = "") -> void:
	current_hp -= amount
	print("[SHARK] take_damage =", amount, " => HP =", current_hp, "; source =", source)

	if current_hp <= 0:
		die()
	else:
		# If damage comes from a torpedo, stun the shark
		set_state("STUN")

func die() -> void:
	set_state("DEAD")

#
# -------------------- BITE ATTACK --------------------
#
func _bite_player() -> void:
	# Cause damage to the player if possible and enter bite recovery state
	if player and player.has_method("apply_damage"):
		player.apply_damage(bite_damage)
		player.play_impact_sound()
		# After biting, enter a short recovery period
		set_state("BITE_RECOVERY")

#
# -------------------- SONAR DETECTION --------------------
#
func _check_sonar_detected() -> bool:
	# Check if the sonar has detected the player via active or directed modes
	if sonar == null:
		return false

	if sonar.sonar_mode == "active" and sonar.ring_active:
		var ring_r = sonar.get_active_sonar_radius()
		var distance = global_position.distance_to(player.global_position)
		if distance <= ring_r:
			return true

	if sonar.sonar_mode == "directed" and sonar.directed_wave_active:
		var wave_r = sonar.get_directed_sonar_radius()
		var distance2 = global_position.distance_to(player.global_position)
		if distance2 <= wave_r:
			return true

	return false

func _on_sonar_mode_changed(new_mode: String) -> void:
	# If in CHASE state and sonar switches to passive, check distance to player
	if current_state == "CHASE" and new_mode == "passive":
		var dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player > detection_range:
			set_state("PATROL")

#
# -------------------- APPLY STUN KNOCKBACK --------------------
#
func _apply_stun_knockback() -> void:
	# Apply a knockback effect when the shark is stunned
	var dir = velocity.normalized()
	if dir.length() > 0.01:
		# Push the shark back in the opposite direction of its movement
		velocity = -dir * stun_knockback_strength
	else:
		# If velocity is near zero, no knockback is applied
		pass

func get_sonar_ping_settings() -> Dictionary:
	# Provide sonar ping visual settings for different modes (active, passive, directed)
	return {
		"active": {
			"ellipse_color": Color(1, 0, 0),
			"ellipse_size": Vector2(2.0, 1.0),

			"glow_enabled": true,
			"glow_color": Color(1, 0.3, 0.3),
			"glow_size_factor": 3.5,

			"tail_enabled": false,
			"tail_steps": 5,
			"tail_step_distance": 4.0,
			"tail_size_factor": 0.1,
			"tail_alpha_factor": 0.7,
			"tail_brightness_factor": 0.6,
			"tail_fade_duration": 2.0,
			"tail_life_duration": 1.5,
			"tail_size_shrink_duration": 0.001,

			"tail_glow_enabled": false,
			"tail_glow_color": Color(1, 0.3, 0.3),
			"tail_glow_size_factor": 2.5,
			"tail_glow_alpha_factor": 0.5,
			"tail_glow_life_duration": 2.0,
			"tail_glow_size_shrink_duration": 2.0,
		},
		"passive": {
			"ellipse_color": Color(1, 0, 0),
			"ellipse_size": Vector2(3, 1.2),

			"glow_enabled": true,
			"glow_color": Color(0.8, 1.0, 0.8),
			"glow_size_factor": 2.0,

			"tail_enabled": false,  # Disable tail for passive mode
		},
		"directed": {
			"ellipse_color": Color(1, 0, 0),
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
