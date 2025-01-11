extends CharacterBody2D

# ------------------- SIGNALS -------------------
# Emitted on various crash, mayday, and friction related events.
signal crash_message(message: String, color: String)
signal mayday_message(message: String, color: String)
signal friction_damage(message: String, color: String)

#
# ------------------- MOVEMENT PARAMETERS -------------------
#
@export var max_speed: float = 10.0      # Maximum speed of the submarine.
@export var acceleration: float = 3.5    # Acceleration rate when increasing speed.
@export var deceleration: float = 2.0    # Deceleration rate when no movement command is given.

#
# ------------------- HEALTH PARAMETERS -------------------
#
@export var max_hp: int = 150            # Maximum health points.
var current_hp: int                       # Current health points, initialized in _ready().

#
# ------------------- COLLISION DAMAGE PARAMETERS -------------------
#
@export var impact_threshold: float = 0.5      # Dot product threshold for severe impact detection.
@export var impact_multiplier: float = 2.0     # Damage multiplier for impact collisions.
@export var friction_multiplier: float = 0.1   # Damage multiplier for friction collisions.
@export var min_damage: int = 1                # Minimum damage inflicted on collision.
@export var friction_min_speed: float = 1.0    # Minimum speed required to incur friction damage.
@export var friction_damage_interval: float = 0.5  # Interval between successive friction damage events in seconds.

#
# ------------------- AUDIO SETTINGS -------------------
#
@export var impact_sound_1: AudioStream = null  # First impact sound.
@export var impact_sound_2: AudioStream = null  # Second impact sound.
@export var friction_sound: AudioStream = null  # Sound for friction noise.

#
# ------------------- MOVEMENT STATE VARIABLES -------------------
#
var target_direction: Vector2 = Vector2.ZERO  # Direction vector for desired movement.
var target_speed: float = 0.0                 # Target speed to achieve.

var last_direction: Vector2 = Vector2.ZERO    # Last known direction before stopping.
var last_speed_percent: float = 50.0          # Last set speed percentage.

#
# ------------------- SPEED ARROW DISPLAY PARAMETERS -------------------
#
@export var max_arrow_length: float = 25.0    # Maximum length of the speed indicator arrow.
var arrow_thickness: float = 0.5              # Thickness of the arrow line.
var white_ratio: float = 0.75                 # Ratio of arrow that should be white before turning red.
var arrow_z_index = 10                        # Z-index for drawing arrow above other elements.

#
# ------------------- GREEN HORIZONTAL LINE PARAMETERS -------------------
#
var LINE_LENGTH = 4            # Length of the green line drawn above the submarine.
var LINE_THICKNESS = 1         # Thickness of the green line.
var LINE_OFFSET_Y = 7          # Vertical offset of the green line from submarine's center.

#
# ------------------- UI ELEMENTS -------------------
#
@onready var status_label: Label = $UI/StatusLabel         # Label node for displaying HP and speed.
@export var mission_target_position: Vector2 = Vector2(540, 600)  # Initial mission target position.
@onready var position_label: Label = $UI/PositionLabel     # Label node for displaying position info.

#
# ------------------- INTERNAL STATE VARIABLES -------------------
#
var is_dead: bool = false        # Flag indicating if the submarine is dead; disables control.
var collisions_info: Dictionary = {}  # Stores collision data for current contacts.
var is_friction_active: bool = false  # Indicates if friction damage should be applied.
var use_alternate_impact: bool = false  # Toggle to alternate between two impact sounds.

#
# ------------------- AUDIO PLAYERS -------------------
#
var impact_player: AudioStreamPlayer2D   # Player node for impact sounds.
var friction_player: AudioStreamPlayer2D # Player node for friction sound.

#
# ------------------- FRICTION SOUND FADE PARAMETERS -------------------
#
var friction_fade_duration: float = 1.0      # Duration for friction sound fade-in/out.
var friction_fade_timer: float = 0.0         # Timer tracking the fade progress.
var friction_is_fading_in: bool = false      # Flag indicating fade-in in progress.
var friction_is_fading_out: bool = false     # Flag indicating fade-out in progress.
var friction_fade_start_volume: float = 0.0  # Starting volume for fade transition.
var friction_fade_end_volume: float = 0.0    # Target volume for fade transition.

#
# ------------------- _READY -------------------
#
func _ready() -> void:
	z_index = 10                          # Set draw order priority.
	current_hp = max_hp                   # Initialize current health.

	# Create and add audio players for impact and friction sounds.
	impact_player = AudioStreamPlayer2D.new()
	add_child(impact_player)

	friction_player = AudioStreamPlayer2D.new()
	add_child(friction_player)

	# Initialize friction player settings for fade in/out.
	friction_player.volume_db = -60.0
	friction_player.autoplay = false
	friction_player.stream_paused = true

	queue_redraw()            # Schedule a redraw of visual elements.
	update_status_label()     # Initialize status label text.
	update_position_label()   # Initialize position label text.

#
# ------------------- PHYSICS PROCESSING -------------------
#
func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 1) Update velocity based on target direction and speed.
	if target_direction != Vector2.ZERO:
		var desired_velocity = target_direction.normalized() * target_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

	# 2) Store velocity before movement for collision damage calculations.
	var pre_move_velocity = velocity

	# 3) Move and slide considering collisions.
	move_and_slide()

	# 4) Handle collisions post-movement.
	handle_collisions(pre_move_velocity)

	# 5) Remove collision entries that are outdated.
	cleanup_collisions()

	# 6) Update UI labels for HP/speed and position.
	update_status_label()
	update_position_label()

	# 7) Manage friction sound based on current friction state.
	manage_friction_sound(delta)

#
# ------------------- COLLISION HANDLING -------------------
#
func handle_collisions(pre_move_velocity: Vector2) -> void:
	is_friction_active = false  # Reset friction flag for this frame.

	var collision_count = get_slide_collision_count()
	if collision_count == 0:
		return

	var speed_val = pre_move_velocity.length()
	var current_frame = Engine.get_physics_frames()

	# Iterate over each collision detected during move_and_slide().
	for i in range(collision_count):
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision == null:
			continue

		var collider = collision.get_collider()
		if collider == null:
			continue

		# Only handle collisions with objects in the "Environment" group.
		if not collider.is_in_group("Environment"):
			continue

		var normal = collision.get_normal()
		# Dot product of velocity and collision normal.
		var normal_v = pre_move_velocity.dot(normal)
		var collider_id = collider.get_instance_id()

		# Initialize collision info if first time colliding with this collider.
		if not collisions_info.has(collider_id):
			collisions_info[collider_id] = {
				"impacted": false,
				"last_frame": current_frame,
				"last_friction_damage_time": 0
			}

			# Check for severe impact based on threshold.
			if normal_v < -impact_threshold:
				var dmg = int(round(speed_val * impact_multiplier))
				if dmg < min_damage:
					dmg = min_damage

				# Play impact sound and emit crash/mayday signals.
				play_impact_sound()
				emit_signal("crash_message", "The submarine has damaged!", "#FF0000")
				emit_signal("mayday_message", "Mayday!", "#FF0000")
				apply_damage(dmg)
				collisions_info[collider_id]["impacted"] = true
			else:
				# Apply friction damage if speed is above threshold.
				if speed_val > friction_min_speed:
					var current_time = Time.get_ticks_msec()
					var last_friction_time = collisions_info[collider_id]["last_friction_damage_time"]
					var time_since_last_friction = (current_time - last_friction_time) / 1000.0

					is_friction_active = true

					# Apply friction damage at defined intervals.
					if time_since_last_friction >= friction_damage_interval:
						var friction_dmg = int(round(speed_val * friction_multiplier))
						if friction_dmg < min_damage:
							friction_dmg = min_damage

						
						apply_damage(friction_dmg)
						collisions_info[collider_id]["last_friction_damage_time"] = current_time

		else:
			# Update collision info for ongoing collisions.
			collisions_info[collider_id]["last_frame"] = current_frame

			if speed_val > friction_min_speed and normal_v < 0:
				is_friction_active = true

				var current_time = Time.get_ticks_msec()
				var last_friction_time = collisions_info[collider_id]["last_friction_damage_time"]
				var time_since_last_friction = (current_time - last_friction_time) / 1000.0

				if time_since_last_friction >= friction_damage_interval:
					var friction_dmg = int(round(speed_val * friction_multiplier))
					if friction_dmg < min_damage:
						friction_dmg = min_damage

					emit_signal("friction_damage", "Friction damage: %d" % friction_dmg, "#FFA500")
					apply_damage(friction_dmg)
					collisions_info[collider_id]["last_friction_damage_time"] = current_time

#
# ------------------- ALTERNATE IMPACT SOUND PLAYBACK -------------------
#
func play_impact_sound() -> void:
	if impact_player == null:
		return

	# Ensure at least one impact sound is set.
	if impact_sound_1 == null and impact_sound_2 == null:
		return

	var chosen_sound: AudioStream = null

	# Alternate between two sounds if both are provided.
	if impact_sound_1 and impact_sound_2:
		if use_alternate_impact:
			chosen_sound = impact_sound_2
		else:
			chosen_sound = impact_sound_1

		use_alternate_impact = not use_alternate_impact
	else:
		# Use whichever sound is available.
		if impact_sound_1 != null:
			chosen_sound = impact_sound_1
		elif impact_sound_2 != null:
			chosen_sound = impact_sound_2

	if chosen_sound:
		impact_player.stream = chosen_sound
		impact_player.play()

#
# ------------------- CLEANUP OLD COLLISIONS -------------------
#
func cleanup_collisions() -> void:
	var current_frame = Engine.get_physics_frames()
	var keys_to_remove = []

	# Collect collider IDs that haven't been updated in the current frame.
	for collider_id in collisions_info.keys():
		var info = collisions_info[collider_id]
		if info["last_frame"] < current_frame:
			keys_to_remove.append(collider_id)

	# Remove outdated collision entries.
	for k in keys_to_remove:
		collisions_info.erase(k)

#
# ------------------- MANAGE FRICTION SOUND FADE -------------------
#
func manage_friction_sound(delta: float) -> void:
	if friction_sound == null or friction_player == null:
		return

	# If friction is active, handle fade-in of friction sound.
	if is_friction_active:
		# Cancel fade-out if currently fading out.
		if friction_is_fading_out:
			friction_is_fading_out = false
			friction_fade_timer = 0.0

		# Start playing friction sound with fade-in if not already playing.
		if not friction_player.playing or friction_player.stream_paused:
			friction_player.stream = friction_sound
			friction_player.play()
			friction_player.stream_paused = false

			# Begin fade-in from silent volume.
			friction_player.volume_db = -60.0
			friction_is_fading_in = true
			friction_fade_timer = 0.0
			friction_fade_start_volume = friction_player.volume_db
			friction_fade_end_volume = 0.0

		# Continue fade-in process.
		if friction_is_fading_in:
			friction_fade_timer += delta
			var ratio_in = friction_fade_timer / friction_fade_duration
			friction_player.volume_db = lerp(friction_fade_start_volume, friction_fade_end_volume, ratio_in)

			if ratio_in >= 1.0:
				friction_player.volume_db = friction_fade_end_volume
				friction_is_fading_in = false

	# If no friction, handle fade-out of friction sound.
	else:
		# Stop any ongoing fade-in if friction ceases.
		if friction_is_fading_in:
			friction_is_fading_in = false
			friction_fade_timer = 0.0

		# Initiate fade-out if sound is playing and not already fading out.
		if friction_player.playing and not friction_player.stream_paused and not friction_is_fading_out:
			friction_is_fading_out = true
			friction_fade_timer = 0.0
			friction_fade_start_volume = friction_player.volume_db
			friction_fade_end_volume = -60.0

		# Continue fade-out process.
		if friction_is_fading_out:
			friction_fade_timer += delta
			var ratio_out = friction_fade_timer / friction_fade_duration
			friction_player.volume_db = lerp(friction_fade_start_volume, friction_fade_end_volume, ratio_out)

			if ratio_out >= 1.0:
				friction_player.volume_db = friction_fade_end_volume
				# Pause the friction sound when completely faded out.
				friction_player.stream_paused = true
				friction_is_fading_out = false

#
# ------------------- MOVEMENT CONTROL METHODS -------------------
#
func move_in_direction(angle_degrees: float, speed_percent: float) -> void:
	# Set target movement direction and speed based on input angle and percentage.
	if is_dead:
		return
	speed_percent = clamp(speed_percent, 0, 100)
	var angle_radians = deg_to_rad(angle_degrees - 90)  # Adjust angle so 0° is upward.
	target_direction = Vector2(cos(angle_radians), sin(angle_radians))
	target_speed = max_speed * (speed_percent / 100.0)
	last_direction = target_direction
	last_speed_percent = speed_percent

func stop_movement() -> void:
	# Cease movement by zeroing target direction and speed.
	if is_dead:
		return
	target_direction = Vector2.ZERO
	target_speed = 0.0

func set_speed(speed_percent: float) -> void:
	# Adjust current speed without altering direction if possible.
	if is_dead:
		return
	speed_percent = clamp(speed_percent, 0, 100)
	if target_direction != Vector2.ZERO:
		target_speed = max_speed * (speed_percent / 100.0)
		last_speed_percent = speed_percent
	else:
		# If no current direction, use last known direction to set speed.
		if last_direction != Vector2.ZERO:
			target_direction = last_direction
			target_speed = max_speed * (speed_percent / 100.0)
			last_speed_percent = speed_percent

func is_stopped() -> bool:
	# Check if the submarine's velocity is effectively zero.
	return velocity.length() < 0.01

#
# ------------------- HEALTH, DAMAGE, AND DEATH MANAGEMENT -------------------
#
func apply_damage(amount: int) -> void:
	# Deduct HP and check for death condition.
	current_hp -= amount
	if current_hp < 0:
		current_hp = 0
	update_status_label()

	if current_hp <= 0 and not is_dead:
		die()

func die() -> void:
	# Handle submarine death: set dead flag, emit signals, and reload scene after delay.
	is_dead = true
	for i in range(3):
		emit_signal("crash_message", "The submarine has crashed!", "#FF0000")
		emit_signal("mayday_message", "Mayday!", "#FF0000")

	var death_timer: Timer = Timer.new()
	death_timer.wait_time = 3.0
	death_timer.one_shot = true
	death_timer.connect("timeout", Callable(self, "_on_death_timer_timeout"))
	add_child(death_timer)
	death_timer.start()

func _on_death_timer_timeout() -> void:
	# Reload the current scene after death timer expires.
	get_tree().reload_current_scene()

#
# ------------------- DRAWING AND VISUALIZATION -------------------
#
func _process(_delta: float) -> void:
	queue_redraw()  # Request redraw every frame for dynamic visuals.

func _draw() -> void:
	# 1) Draw a green horizontal line above the submarine.
	var half_len = float(LINE_LENGTH) / 2.0
	var start_point = Vector2(-half_len, -LINE_OFFSET_Y)
	var end_point = Vector2(half_len, -LINE_OFFSET_Y)
	draw_line(start_point, end_point, Color(0, 1, 0), LINE_THICKNESS)

	# 2) Draw the speed arrow indicating current velocity.
	var current_speed_val = velocity.length()
	if current_speed_val <= 0.01:
		return  # Skip drawing if nearly stationary.

	var speed_fraction = current_speed_val / max_speed
	var arrow_length = speed_fraction * max_arrow_length
	arrow_length = clamp(arrow_length, 0, max_arrow_length)

	var direction = velocity.normalized()
	var end_arrow_point = direction * arrow_length

	var white_length = max_arrow_length * white_ratio
	var has_red_section = arrow_length > white_length

	var white_color = Color(1, 1, 1)
	var red_color = Color(1, 0, 0)

	# Draw arrow in white and red segments based on speed.
	if has_red_section:
		var white_end_point = direction * white_length
		draw_line(Vector2.ZERO, white_end_point, white_color, arrow_thickness)
		draw_line(white_end_point, end_arrow_point, red_color, arrow_thickness)
	else:
		draw_line(Vector2.ZERO, end_arrow_point, white_color, arrow_thickness)

#
# ------------------- UI LABEL UPDATES -------------------
#
func update_status_label() -> void:
	if not status_label:
		return

	# Calculate HP percentage.
	var hp_percent = float(current_hp) / float(max_hp) * 100.0

	# Change label color if HP is below 30%.
	if hp_percent < 30.0:
		status_label.modulate = Color(1, 0, 0)  # Red color.
	else:
		status_label.modulate = Color(1, 1, 1)  # White color.

	var current_speed_int = int(velocity.length())
	var txt = "HP\n%d%%\nSPEED:\n%d km/h" % [int(hp_percent), current_speed_int]
	status_label.text = txt

func update_position_label() -> void:
	if not position_label:
		return

	# Submarine's current coordinates.
	var sub_x = int(global_position.x)
	var sub_y = int(global_position.y)

	# Mission target coordinates.
	var target_x = int(mission_target_position.x)
	var target_y = int(mission_target_position.y)

	# Distance from submarine to mission target.
	var distance_to_target = int(global_position.distance_to(mission_target_position))

	var text = "POSITION\n%d %d\n\nTARGET\n%d %d\n\nDISTANCE\n%d" % [
		sub_x,
		sub_y,
		target_x,
		target_y,
		distance_to_target
	]
	position_label.text = text

#
# ------------------- SET NEW MISSION TARGET -------------------
#
func set_mission_target_position(new_pos: Vector2) -> void:
	# Update mission target position and refresh label.
	mission_target_position = new_pos
	update_position_label()
