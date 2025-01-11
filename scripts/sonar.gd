extends Node2D

# Number of segments used when drawing an ellipse with draw_polygon()
const ELLIPSE_SEGMENTS: int = 6

# Emitted when the sonar mode changes to a new mode
signal mode_changed(new_mode: String)

# The desired initial sonar mode: can be "active", "passive", "directed", or "off"
@export var start_sonar_mode: String = "off"

@export_category("General")
@export var is_enabled: bool = true
@export var sonar_mode: String = "active"  # "active" / "passive" / "directed"
@export var min_distance_between_points: float = 3.0

@export_category("Thickness Settings")
@export var collision_thickness_threshold: float = 20.0

# ---------------------------
# Active Sonar - Main
# ---------------------------
@export_category("Active Sonar - Main")
@export var ping_distance: float = 160.0
@export var ping_interval: float = 3.0
@export var active_fade_duration: float = 4.0
@export var ring_expansion_speed: float = 90.0
@export var rays_count_active: int = 144

# ---------------------------
# Active Sonar - Tail & Glow
# ---------------------------
@export var active_tail_enabled: bool = true
@export var active_trail_steps: int = 5
@export var active_trail_step_distance: float = 3.5
@export var active_trail_size_factor: float = 0.07
@export var active_trail_alpha_factor: float = 0.8
@export var active_trail_fade_duration: float = 1.5

@export var active_brightness_fade_duration: float = 1.0
@export var active_tail_brightness_factor: float = 0.6

@export var active_glow_enabled: bool = true
@export var active_glow_color: Color = Color(1, 1, 1)
@export var active_glow_size_factor: float = 2.0
@export var active_glow_alpha_factor: float = 0.4
@export var active_glow_life_duration: float = 3.0
@export var active_glow_size_shrink_duration: float = 3.0

@export var active_tail_life_duration: float = 0.7
@export var active_tail_size_shrink_duration: float = 0.001

@export var active_tail_glow_enabled: bool = true
@export var active_tail_glow_color: Color = Color(1, 1, 1)
@export var active_tail_glow_size_factor: float = 2.0
@export var active_tail_glow_alpha_factor: float = 0.4
@export var active_tail_glow_life_duration: float = 0.7
@export var active_tail_glow_size_shrink_duration: float = 0.7


# ---------------------------
# Directed Sonar - Main
# ---------------------------
@export_category("Directed Sonar - Main")
@export var directed_angle_default: float = 90.0
@export var directed_distance: float = 120.0
@export var directed_fade_duration: float = 2.5
@export var directed_brightness_fade_duration: float = 1.0
@export var rays_count_directed: int = 144
@export var min_distance_between_points_directed: float = 1.5
@export var directed_fov: float = 60.0

@export_category("Directed Sonar - Beam Size & Quality")
@export var directed_ellipse_size: Vector2 = Vector2(1.5, 0.6)

# ---------------------------
# Directed Sonar - Tail & Glow
# ---------------------------
@export var directed_tail_enabled: bool = true
@export var directed_trail_steps: int = 8
@export var directed_trail_step_distance: float = 2.0
@export var directed_trail_size_factor: float = 0.05
@export var directed_trail_alpha_factor: float = 0.9
@export var directed_trail_fade_duration: float = 2.0

@export var directed_tail_brightness_factor: float = 0.8

@export var directed_glow_enabled: bool = true
@export var directed_glow_color: Color = Color(1.0, 1.0, 0.9)
@export var directed_glow_size_factor: float = 1.5
@export var directed_glow_alpha_factor: float = 0.6
@export var directed_glow_life_duration: float = 3.5
@export var directed_glow_size_shrink_duration: float = 3.0

@export var directed_tail_life_duration: float = 2.0
@export var directed_tail_size_shrink_duration: float = 0.5

@export var directed_tail_glow_enabled: bool = false
@export var directed_tail_glow_color: Color = Color(1.0, 1.0, 0.6)
@export var directed_tail_glow_size_factor: float = 1.8
@export var directed_tail_glow_alpha_factor: float = 0.5
@export var directed_tail_glow_life_duration: float = 3.0
@export var directed_tail_glow_size_shrink_duration: float = 1.5

@export var directed_ring_expansion_speed: float = 90.0
@export var directed_update_interval: float = 2.5

@export var directed_center_line_color: Color = Color(1.0, 1.0, 1.0, 0.2)
@export var directed_center_line_thickness: float = 0.5

@export var directed_side_line_color: Color = Color(1.0, 1.0, 1.0, 0.2)
@export var directed_side_line_thickness: float = 1.0

# ---------------------------
# Passive Sonar - Main
# ---------------------------
@export_category("Passive Sonar - Main")
@export var passive_enabled: bool = true
@export var passive_radius: float = 80.0
@export var passive_sensitivity: float = 1.0
@export var passive_reflection_distance: float = 80.0
@export var passive_update_interval: float = 1.0
@export var passive_fade_duration: float = 2
@export var rays_count_passive_reflection: int = 100

# ---------------------------
# Passive Sonar - Tail & Glow
# ---------------------------
@export var passive_tail_enabled: bool = false
@export var passive_trail_steps: int = 3
@export var passive_trail_step_distance: float = 2.0
@export var passive_trail_size_factor: float = 0.05
@export var passive_trail_alpha_factor: float = 0.5
@export var passive_trail_fade_duration: float = 1.3

@export var passive_brightness_fade_duration: float = 1.7
@export var passive_tail_brightness_factor: float = 0.4

@export var passive_glow_enabled: bool = true
@export var passive_glow_color: Color = Color(0.8, 1.0, 0.8)
@export var passive_glow_size_factor: float = 2
@export var passive_glow_alpha_factor: float = 0.4
@export var passive_glow_life_duration: float = 1.7
@export var passive_glow_size_shrink_duration: float = 1.7

@export var passive_tail_life_duration: float = 1.7
@export var passive_tail_size_shrink_duration: float = 1.0

@export var passive_tail_glow_enabled: bool = false
@export var passive_tail_glow_color: Color = Color(0.5, 1.0, 0.5)
@export var passive_tail_glow_size_factor: float = 2.0
@export var passive_tail_glow_alpha_factor: float = 0.4
@export var passive_tail_glow_life_duration: float = 3.0
@export var passive_tail_glow_size_shrink_duration: float = 2.0

# Dictionary of group names mapped to their respective colors for the sonar
var GROUP_COLORS: Dictionary = {
	"RockGroup": Color(0, 0.5, 1),
	"IceGroup": Color(0.5, 1.0, 1.0),
	"QuarzGroup": Color(1.0, 1.0, 1.0),
	"Phosphats": Color(0.0, 1.0, 0.3),
	"RostedMetal": Color(0.72, 0.25, 0.05),
	"MissionItem": Color(1.0, 0.84, 0.0),
	"MagnetiteGroup": Color(0.33, 0.33, 0.33),
	"CorralsGroup": Color(1.0, 0.5, 0.40),
	"RhodiumGroup": Color(0.75, 0.45, 1.0),
	"PlatinumGroup": Color(1.0, 0.75, 0.8)
}

@onready var player = get_parent()
var space_state: PhysicsDirectSpaceState2D
var hit_points: Array[PingPoint] = []

# Variables controlling active sonar ring animation
var ring_radius: float = 0.0
var ring_active: bool = false
var ping_timer: Timer

# Variables controlling passive sonar updates
var passive_timer: Timer

# Variables controlling directed sonar wave animation
var directed_timer: Timer
var directed_wave_radius: float = 0.0
var directed_wave_active: bool = false
var directed_wave_angle_deg: float = 0.0

# Audio resources for different sonar pings and an explosion
@export var sonar_ping_sound_active: AudioStream = null
@export var sonar_ping_sound_directed: AudioStream = null
@export var explosion_sound: AudioStream = null

@onready var ping_player_active: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var ping_player_directed: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var explosion_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()


func set_directed_update_time(new_time: float) -> void:
	# Updates the wait_time of the directed sonar timer
	directed_update_interval = new_time
	directed_timer.wait_time = new_time


func _ready() -> void:
	# Initialize the physics space state (used for ray queries)
	space_state = get_world_2d().direct_space_state

	# Add audio stream players to the scene
	add_child(ping_player_active)
	add_child(ping_player_directed)
	add_child(explosion_player)

	# Timer setup for active sonar
	ping_timer = Timer.new()
	ping_timer.wait_time = ping_interval
	ping_timer.one_shot = false
	ping_timer.connect("timeout", Callable(self, "_on_active_ping_timeout"))
	add_child(ping_timer)

	# Timer setup for passive sonar
	passive_timer = Timer.new()
	passive_timer.wait_time = passive_update_interval
	passive_timer.one_shot = false
	passive_timer.connect("timeout", Callable(self, "_on_passive_update_timeout"))
	add_child(passive_timer)

	# Timer setup for directed sonar
	directed_timer = Timer.new()
	directed_timer.wait_time = directed_update_interval
	directed_timer.one_shot = false
	directed_timer.connect("timeout", Callable(self, "_on_directed_ping_timeout"))
	add_child(directed_timer)

	# If sonar is disabled from the start, stop the timers and disable processing
	if not is_enabled:
		ping_timer.stop()
		passive_timer.stop()
		directed_timer.stop()
		set_process(false)
		return

	# Validate the starting sonar mode; if it is invalid, switch to "off"
	var lower_mode = start_sonar_mode.to_lower()
	if not ["active", "passive", "directed", "off"].has(lower_mode):
		lower_mode = "off"
	
	# Assign the valid mode and initialize timers based on that mode
	set_sonar_mode(lower_mode)


func set_sonar_mode(mode: String) -> void:
	# Changes the sonar_mode if a different one is requested, then updates timers
	if sonar_mode != mode:
		sonar_mode = mode
		emit_signal("mode_changed", sonar_mode)
	_update_sonar_timers()


func _update_sonar_timers() -> void:
	# Handles starting or stopping relevant timers depending on sonar mode and enable state
	if not is_enabled:
		ping_timer.stop()
		passive_timer.stop()
		directed_timer.stop()
		return

	match sonar_mode:
		"active":
			ping_timer.stop()
			passive_timer.stop()
			directed_timer.stop()
			ping_timer.start()
			# Immediately trigger an active ping
			_on_active_ping_timeout()
		"passive":
			ping_timer.stop()
			passive_timer.stop()
			directed_timer.stop()
			passive_timer.start()
			_on_passive_update_timeout()
		"directed":
			ping_timer.stop()
			passive_timer.stop()
			directed_timer.stop()
			directed_timer.start()
			_on_directed_ping_timeout()
		_:
			# For "off" or any other unexpected mode, turn off all timers
			ping_timer.stop()
			passive_timer.stop()
			directed_timer.stop()


# ----------------------------------------------------------------------
#   ACTIVE (OMNI) SONAR
# ----------------------------------------------------------------------
func _on_active_ping_timeout() -> void:
	# Called by ping_timer; triggers an omni-directional active sonar ping if in correct mode
	if is_enabled and sonar_mode == "active":
		if sonar_ping_sound_active:
			ping_player_active.stream = sonar_ping_sound_active
			ping_player_active.play()
		emit_ping_omni()


func emit_ping_omni() -> void:
	# Performs an omni-directional raycast to gather collision data for the active sonar
	if not player:
		return

	ring_radius = 0.0
	ring_active = true
	var origin = player.global_position
	var angle_step = 360.0 / float(rays_count_active)
	var new_points: Array[PingPoint] = []

	for i in range(rays_count_active):
		var angle_degrees = i * angle_step
		var angle_radians = deg_to_rad(angle_degrees)
		var direction = Vector2(cos(angle_radians), sin(angle_radians))

		var current_origin = origin + direction * 1.0
		var remaining_distance = ping_distance

		while remaining_distance > 0:
			var target = current_origin + direction * remaining_distance
			var query = PhysicsRayQueryParameters2D.new()
			query.from = current_origin
			query.to = target
			var result = space_state.intersect_ray(query)

			if result.has("position"):
				var hit_pos = result.position
				var dist = origin.distance_to(hit_pos)

				var can_add = true
				for existing_point in new_points:
					if existing_point.position.distance_to(hit_pos) < min_distance_between_points:
						can_add = false
						break

				if can_add:
					var collider = result.collider
					var group_color = get_group_color(collider)

					var ping_settings_dict: Dictionary = {}
					if collider and collider.has_method("get_sonar_ping_settings"):
						ping_settings_dict = collider.get_sonar_ping_settings()

					var p = PingPoint.new(
						hit_pos,
						dist,
						direction,
						active_fade_duration,
						active_brightness_fade_duration,
						group_color,
						ping_settings_dict
					)
					p.mode = "active"
					p.visible = false
					p.collision_thickness = measure_collision_thickness(hit_pos, direction, collider)

					new_points.append(p)

					# If the collision seems thin enough, also mark a point behind it
					if p.collision_thickness < collision_thickness_threshold:
						var back_pos = hit_pos + direction.normalized() * p.collision_thickness
						var back_dist = origin.distance_to(back_pos)

						var can_add_back = true
						for existing_point in new_points:
							if existing_point.position.distance_to(back_pos) < min_distance_between_points:
								can_add_back = false
								break

						if can_add_back:
							var back_p = PingPoint.new(
								back_pos,
								back_dist,
								direction,
								active_fade_duration,
								active_brightness_fade_duration,
								group_color,
								ping_settings_dict
							)
							back_p.mode = "active"
							back_p.visible = false
							back_p.collision_thickness = p.collision_thickness
							back_p.ignore_tail = true
							new_points.append(back_p)

				# If collider is not in the "Transperent" group, break out of the loop
				if not (result.collider and result.collider.is_in_group("Transperent")):
					break

				var penetration_offset = 0.1
				current_origin = hit_pos + direction * penetration_offset
				if origin.distance_to(current_origin) < ping_distance:
					remaining_distance = ping_distance - origin.distance_to(current_origin)
				else:
					remaining_distance = 0
			else:
				break

	hit_points += new_points
	set_process(true)
	queue_redraw()


# ----------------------------------------------------------------------
#   PASSIVE (OMNI) SONAR
# ----------------------------------------------------------------------
func _on_passive_update_timeout() -> void:
	# Called periodically by passive_timer; triggers passive sonar detection if enabled
	if not (is_enabled and sonar_mode == "passive" and passive_enabled):
		return
	emit_passive_noise(passive_reflection_distance)


func emit_passive_noise(radius: float) -> void:
	# Rays to detect collisions around the player for passive sonar
	var origin = player.global_position
	var new_points: Array[PingPoint] = []
	var angle_step = 360.0 / float(rays_count_passive_reflection)

	for i in range(rays_count_passive_reflection):
		var angle_deg = i * angle_step
		var angle_rad = deg_to_rad(angle_deg)
		var dir = Vector2(cos(angle_rad), sin(angle_rad))

		var start_pos = origin + dir * 1.0
		var target = origin + dir * radius
		var query = PhysicsRayQueryParameters2D.new()
		query.from = start_pos
		query.to = target
		var result = space_state.intersect_ray(query)

		if result.has("position"):
			var dist = origin.distance_to(result.position)
			if dist > 1.0:
				var collider = result.collider
				var group_color = get_group_color(collider)

				var can_add = true
				for existing_point in new_points:
					if existing_point.position.distance_to(result.position) < min_distance_between_points:
						can_add = false
						break

				if can_add:
					var ping_settings_dict: Dictionary = {}
					if collider and collider.has_method("get_sonar_ping_settings"):
						ping_settings_dict = collider.get_sonar_ping_settings()

					var p = PingPoint.new(
						result.position,
						dist,
						dir,
						passive_fade_duration,
						passive_brightness_fade_duration,
						group_color,
						ping_settings_dict
					)
					p.mode = "passive"
					p.visible = false
					p.collision_thickness = measure_collision_thickness(result.position, dir, collider)
					if p.collision_thickness < collision_thickness_threshold:
						p.ignore_tail = true

					new_points.append(p)

	hit_points += new_points
	queue_redraw()
	set_process(true)


# ----------------------------------------------------------------------
#   PASSIVE NOISE FROM AN EXPLOSION
# ----------------------------------------------------------------------
func add_passive_explosion_noise(explosion_position: Vector2, explosion_radius: float) -> void:
	# Generates passive sonar noise after an explosion, creating PingPoints for collisions
	if not is_enabled:
		return
	if not passive_enabled:
		return

	# Play explosion sound if available
	if explosion_sound and explosion_player:
		explosion_player.stream = explosion_sound
		explosion_player.play()

	var new_points: Array[PingPoint] = []
	var origin = explosion_position
	var angle_step = 360.0 / float(rays_count_passive_reflection)

	for i in range(rays_count_passive_reflection):
		var angle_deg = i * angle_step
		var angle_rad = deg_to_rad(angle_deg)
		var dir = Vector2(cos(angle_rad), sin(angle_rad))

		var start_pos = origin + dir * 1.0
		var target = origin + dir * explosion_radius
		var query = PhysicsRayQueryParameters2D.new()
		query.from = start_pos
		query.to = target
		var result = space_state.intersect_ray(query)

		if result.has("position"):
			var dist = origin.distance_to(result.position)
			if dist > 0.5:
				var collider = result.collider
				var group_color = get_group_color(collider)
				var can_add = true
				for existing_point in new_points:
					if existing_point.position.distance_to(result.position) < min_distance_between_points:
						can_add = false
						break

				if can_add:
					var ping_settings_dict: Dictionary = {}
					if collider and collider.has_method("get_sonar_ping_settings"):
						ping_settings_dict = collider.get_sonar_ping_settings()

					var p = PingPoint.new(
						result.position,
						dist,
						dir,
						passive_fade_duration,
						passive_brightness_fade_duration,
						group_color,
						ping_settings_dict
					)
					p.mode = "passive"
					p.visible = false
					p.collision_thickness = measure_collision_thickness(result.position, dir, collider)
					if p.collision_thickness < collision_thickness_threshold:
						p.ignore_tail = true

					new_points.append(p)

	hit_points += new_points
	queue_redraw()
	set_process(true)


# ----------------------------------------------------------------------
#   DIRECTED SONAR
# ----------------------------------------------------------------------
func _on_directed_ping_timeout() -> void:
	# Called by directed_timer; triggers a directed sonar ping if in correct mode
	if is_enabled and sonar_mode == "directed":
		if sonar_ping_sound_directed:
			ping_player_directed.stream = sonar_ping_sound_directed
			ping_player_directed.play()
		emit_ping_directed()


func emit_ping_directed() -> void:
	# Performs a raycast within a certain FOV to simulate a directed sonar
	if not player:
		return

	var origin = player.global_position
	var angle_deg = directed_angle_default - 90.0
	var local_fov = directed_fov
	var half_fov = local_fov * 0.5
	var local_rays_count = rays_count_directed
	var step = local_fov / float(local_rays_count - 1)

	var new_points: Array[PingPoint] = []

	for i in range(local_rays_count):
		var offset_deg = -half_fov + i * step
		var current_deg = angle_deg + offset_deg
		var rad = deg_to_rad(current_deg)
		var direction = Vector2(cos(rad), sin(rad))

		var current_origin = origin + direction * 1.0
		var remaining_distance = directed_distance

		while remaining_distance > 0:
			var target = current_origin + direction * remaining_distance
			var query = PhysicsRayQueryParameters2D.new()
			query.from = current_origin
			query.to = target
			var result = space_state.intersect_ray(query)

			if result.has("position"):
				var hit_pos = result.position
				var dist = origin.distance_to(hit_pos)

				var can_add = true
				for existing_point in new_points:
					if existing_point.position.distance_to(hit_pos) < min_distance_between_points_directed:
						can_add = false
						break

				if can_add:
					var collider = result.collider
					var group_color = get_group_color(collider)

					var ping_settings_dict: Dictionary = {}
					if collider and collider.has_method("get_sonar_ping_settings"):
						ping_settings_dict = collider.get_sonar_ping_settings()

					var p = PingPoint.new(
						hit_pos,
						dist,
						direction,
						directed_fade_duration,
						directed_brightness_fade_duration,
						group_color,
						ping_settings_dict
					)
					p.mode = "directed"
					p.visible = false
					p.collision_thickness = measure_collision_thickness(hit_pos, direction, collider)
					new_points.append(p)

					# If the collision is thin enough, place a point behind it
					if p.collision_thickness < collision_thickness_threshold:
						var back_pos = hit_pos + direction.normalized() * p.collision_thickness
						var back_dist = origin.distance_to(back_pos)

						var can_add_back = true
						for existing_point in new_points:
							if existing_point.position.distance_to(back_pos) < min_distance_between_points_directed:
								can_add_back = false
								break

						if can_add_back:
							var back_p = PingPoint.new(
								back_pos,
								back_dist,
								direction,
								directed_fade_duration,
								directed_brightness_fade_duration,
								group_color,
								ping_settings_dict
							)
							back_p.mode = "directed"
							back_p.visible = false
							back_p.collision_thickness = p.collision_thickness
							back_p.ignore_tail = true
							new_points.append(back_p)

				# If collider is not in the "Transperent" group, end this ray
				if not (result.collider and result.collider.is_in_group("Transperent")):
					break

				var penetration_offset = 0.1
				current_origin = hit_pos + direction * penetration_offset

				if origin.distance_to(current_origin) < directed_distance:
					remaining_distance = directed_distance - origin.distance_to(current_origin)
				else:
					remaining_distance = 0
			else:
				break

	hit_points += new_points

	directed_wave_radius = 0.0
	directed_wave_active = true
	directed_wave_angle_deg = angle_deg

	queue_redraw()
	set_process(true)


# ----------------------------------------------------------------------
#   UTILITY METHODS
# ----------------------------------------------------------------------
func get_group_color(collider: Object) -> Color:
	# Returns a color based on the group's name, or a default color if no group is found
	if collider == null:
		return GROUP_COLORS["RockGroup"]

	for group_name in GROUP_COLORS.keys():
		if collider.is_in_group(group_name):
			return GROUP_COLORS[group_name]

	return GROUP_COLORS["RockGroup"]


func _process(delta: float) -> void:
	# Animate the expanding ring for the active sonar
	if ring_active:
		ring_radius += ring_expansion_speed * delta
		if ring_radius >= ping_distance:
			ring_radius = ping_distance
			ring_active = false

	# Animate the expanding arc for the directed sonar
	if directed_wave_active:
		directed_wave_radius += directed_ring_expansion_speed * delta
		if directed_wave_radius >= directed_distance:
			directed_wave_radius = directed_distance
			directed_wave_active = false

	# Update each PingPoint's timers and visibility
	for point in hit_points:
		match point.mode:
			"active":
				if not point.visible:
					# Make the point visible once the ring passes its distance
					if ring_active:
						if ring_radius >= point.distance:
							point.visible = true
							point.brightness_time_left = active_brightness_fade_duration
							point.visible_time_elapsed = 0.0
					else:
						if ring_radius >= point.distance:
							point.visible = true
							point.brightness_time_left = active_brightness_fade_duration
							point.visible_time_elapsed = 0.0

				if point.visible:
					point.time_left -= delta
					point.brightness_time_left = max(point.brightness_time_left - delta, 0.0)
					point.visible_time_elapsed += delta

			"passive":
				if not point.visible:
					# Passive points become visible immediately
					point.visible = true
					point.brightness_time_left = passive_brightness_fade_duration
					point.visible_time_elapsed = 0.0

				point.time_left -= delta
				point.brightness_time_left = max(point.brightness_time_left - delta, 0.0)
				point.visible_time_elapsed += delta

			"directed":
				if not point.visible:
					# Make the point visible once the directed wave passes its distance
					if directed_wave_active:
						if directed_wave_radius >= point.distance:
							point.visible = true
							point.brightness_time_left = directed_brightness_fade_duration
							point.visible_time_elapsed = 0.0
					else:
						if directed_wave_radius >= point.distance:
							point.visible = true
							point.brightness_time_left = directed_brightness_fade_duration
							point.visible_time_elapsed = 0.0

				if point.visible:
					point.time_left -= delta
					point.brightness_time_left = max(point.brightness_time_left - delta, 0.0)
					point.visible_time_elapsed += delta

			_:
				point.visible = true
				point.time_left -= delta
				point.brightness_time_left = max(point.brightness_time_left - delta, 0.0)
				point.visible_time_elapsed += delta

	# Remove points that have fully faded out
	hit_points = hit_points.filter(func(p: PingPoint):
		return p.time_left > 0
	)

	# If the sonar is disabled and no points remain, disable _process
	if not is_enabled and hit_points.is_empty():
		set_process(false)

	queue_redraw()


func _draw() -> void:
	# Draws the active sonar ring, directed sonar arc, FOV borders, and all current PingPoints
	var origin = to_local(player.global_position)

	# Active sonar ring
	if ring_active:
		draw_ring(origin)

	# Directed sonar arc
	if directed_wave_active:
		draw_directed_arc(origin)

	# Draw directional sonar boundaries if in "directed" mode
	if sonar_mode == "directed":
		draw_directed_sonar_borders(origin)

	# Draw all ping points
	draw_points(origin)


func draw_ring(origin: Vector2) -> void:
	# Draws the ring that represents the expanding wave of the active sonar
	var ring_color = Color(1.0, 1.0, 1.0, 0.5)
	draw_arc(origin, ring_radius, 0, TAU, 64, ring_color, 1)


func draw_directed_arc(origin: Vector2) -> void:
	# Draws the arc that represents the directed sonar wave
	var fov_rad = deg_to_rad(directed_fov)
	var half_fov = fov_rad * 0.5
	var center_angle_rad = deg_to_rad(directed_wave_angle_deg)
	var arc_start = center_angle_rad - half_fov
	var arc_end   = center_angle_rad + half_fov

	var arc_color = Color(1.0, 1.0, 1.0, 0.5)
	var ring_width = 1
	draw_arc(origin, directed_wave_radius, arc_start, arc_end, 64, arc_color, ring_width)


func draw_directed_sonar_borders(origin: Vector2) -> void:
	# Draws the FOV borders and center line for the directed sonar
	var dist = directed_distance
	var center_angle_rad = deg_to_rad(directed_wave_angle_deg)
	var half_fov_rad = deg_to_rad(directed_fov * 0.5)
	var angle_left = center_angle_rad - half_fov_rad
	var angle_right = center_angle_rad + half_fov_rad

	# Center line
	draw_line(
		origin,
		origin + Vector2(cos(center_angle_rad), sin(center_angle_rad)) * dist,
		directed_center_line_color,
		directed_center_line_thickness
	)

	# Left boundary
	draw_line(
		origin,
		origin + Vector2(cos(angle_left), sin(angle_left)) * dist,
		directed_side_line_color,
		directed_side_line_thickness
	)

	# Right boundary
	draw_line(
		origin,
		origin + Vector2(cos(angle_right), sin(angle_right)) * dist,
		directed_side_line_color,
		directed_side_line_thickness
	)


func draw_points(origin: Vector2) -> void:
	# Iterates through all PingPoints and draws each visible point
	for point in hit_points:
		if point.visible:
			draw_point(point, origin)


func draw_point(point: PingPoint, _origin: Vector2) -> void:
	# Draws the ellipse for the ping point, its glow, and optionally its tail
	var alpha = 0.0
	var t = 0.0
	var ellipse_size = Vector2(3, 1.2)

	match point.mode:
		"active":
			alpha = clamp(point.time_left / point.created_fade_duration, 0, 1)
			t = point.brightness_time_left / point.created_brightness_duration
			ellipse_size = Vector2(3, 1.2)
		"passive":
			alpha = clamp(point.time_left / passive_fade_duration, 0, 1)
			t = point.brightness_time_left / passive_brightness_fade_duration
			ellipse_size = Vector2(3, 1.2)
		"directed":
			alpha = clamp(point.time_left / directed_fade_duration, 0, 1)
			t = point.brightness_time_left / directed_brightness_fade_duration
			ellipse_size = directed_ellipse_size
		_:
			alpha = clamp(point.time_left / point.created_fade_duration, 0, 1)
			t = point.brightness_time_left / point.created_brightness_duration
			ellipse_size = Vector2(3, 1.2)

	var mode_settings: Dictionary = {}
	if point.mode in point.ping_settings:
		mode_settings = point.ping_settings[point.mode]
	else:
		mode_settings = point.ping_settings

	if "ellipse_size" in mode_settings:
		ellipse_size = mode_settings["ellipse_size"]

	var point_color = point.color
	if "ellipse_color" in mode_settings:
		point_color = mode_settings["ellipse_color"]

	point_color.a = alpha

	var local_pos = to_local(point.position)
	var direction = point.direction
	var angle = direction.angle() + PI / 2
	var vte = point.visible_time_elapsed

	# Glow effect
	draw_point_glow(point, local_pos, ellipse_size, angle, alpha, mode_settings)

	# Draw the point's ellipse
	draw_polygon_ellipse(local_pos, ellipse_size, angle, point_color)

	# Draw tail if needed
	draw_point_tail(point, local_pos, direction, angle, alpha, t, ellipse_size, vte, mode_settings)


func draw_point_glow(point: PingPoint, local_pos: Vector2, ellipse_size: Vector2, angle: float, alpha: float, mode_settings: Dictionary) -> void:
	# Draws a glow around the point based on the current sonar mode and timing
	if "glow_enabled" in mode_settings and mode_settings["glow_enabled"] == false:
		return

	match point.mode:
		"active":
			# Handle glow for active sonar
			if not active_glow_enabled:
				return
			var vte = point.visible_time_elapsed
			var glow_alpha_a = 0.0
			var glow_progress_a = 0.0
			if vte <= active_glow_life_duration:
				glow_alpha_a = (1.0 - (vte / active_glow_life_duration)) * active_glow_alpha_factor * alpha
				glow_progress_a = min(vte / active_glow_size_shrink_duration, 1.0)

			if glow_alpha_a > 0:
				var glow_col_a = active_glow_color
				if "glow_color" in mode_settings:
					glow_col_a = mode_settings["glow_color"]
				glow_col_a.a = glow_alpha_a

				var local_size_factor_a = active_glow_size_factor
				if "glow_size_factor" in mode_settings:
					local_size_factor_a = mode_settings["glow_size_factor"]

				var glow_ellipse_size_a = ellipse_size * lerp(local_size_factor_a, 1.0, glow_progress_a)
				draw_polygon_ellipse(local_pos, glow_ellipse_size_a, angle, glow_col_a)

		"passive":
			# Handle glow for passive sonar
			if not passive_glow_enabled:
				return
			var vte_p = point.visible_time_elapsed
			var glow_alpha_p = 0.0
			var glow_progress_p = 0.0
			if vte_p <= passive_glow_life_duration:
				glow_alpha_p = (1.0 - (vte_p / passive_glow_life_duration)) * passive_glow_alpha_factor * alpha
				glow_progress_p = min(vte_p / passive_glow_size_shrink_duration, 1.0)

			if glow_alpha_p > 0:
				var glow_col_p = passive_glow_color
				if "glow_color" in mode_settings:
					glow_col_p = mode_settings["glow_color"]
				glow_col_p.a = glow_alpha_p

				var local_size_factor_p = passive_glow_size_factor
				if "glow_size_factor" in mode_settings:
					local_size_factor_p = mode_settings["glow_size_factor"]

				var glow_ellipse_size_p = ellipse_size * lerp(local_size_factor_p, 1.0, glow_progress_p)
				draw_polygon_ellipse(local_pos, glow_ellipse_size_p, angle, glow_col_p)

		"directed":
			# Handle glow for directed sonar
			if not directed_glow_enabled:
				return
			var vte_d = point.visible_time_elapsed
			var glow_alpha_d = 0.0
			var glow_progress_d = 0.0
			if vte_d <= directed_glow_life_duration:
				glow_alpha_d = (1.0 - (vte_d / directed_glow_life_duration)) * directed_glow_alpha_factor * alpha
				glow_progress_d = min(vte_d / directed_glow_size_shrink_duration, 1.0)

			if glow_alpha_d > 0:
				var glow_col_d = directed_glow_color
				if "glow_color" in mode_settings:
					glow_col_d = mode_settings["glow_color"]
				glow_col_d.a = glow_alpha_d

				var local_size_factor_d = directed_glow_size_factor
				if "glow_size_factor" in mode_settings:
					local_size_factor_d = mode_settings["glow_size_factor"]

				var glow_ellipse_size_d = ellipse_size * lerp(local_size_factor_d, 1.0, glow_progress_d)
				draw_polygon_ellipse(local_pos, glow_ellipse_size_d, angle, glow_col_d)

		_:
			pass


func draw_point_tail(
	point: PingPoint,
	local_pos: Vector2,
	direction: Vector2,
	angle: float,
	alpha: float,
	t: float,
	ellipse_size: Vector2,
	vte: float,
	mode_settings: Dictionary
) -> void:
	# Draws the tail (small repeated ellipses) behind the ping point, if enabled and not ignored
	if point.ignore_tail:
		return

	if "tail_enabled" in mode_settings and mode_settings["tail_enabled"] == false:
		return

	var thickness = point.collision_thickness

	match point.mode:
		"active":
			# Tail logic for active sonar
			if not active_tail_enabled:
				return
			var scale = 0.2
			var final_steps = clamp(int(ceil(thickness * scale)), 1, 5)

			var trail_step_distance = active_trail_step_distance
			var trail_size_factor = active_trail_size_factor
			var trail_alpha_factor = active_trail_alpha_factor
			var trail_fade_duration = active_trail_fade_duration
			var tail_life_duration = active_tail_life_duration
			var tail_size_shrink_duration = active_tail_size_shrink_duration
			var tail_glow_enabled = active_tail_glow_enabled
			var tail_brightness_factor = active_tail_brightness_factor

			if "tail_step_distance" in mode_settings:
				trail_step_distance = mode_settings["tail_step_distance"]
			if "tail_size_factor" in mode_settings:
				trail_size_factor = mode_settings["tail_size_factor"]
			if "tail_alpha_factor" in mode_settings:
				trail_alpha_factor = mode_settings["tail_alpha_factor"]
			if "tail_fade_duration" in mode_settings:
				trail_fade_duration = mode_settings["tail_fade_duration"]
			if "tail_life_duration" in mode_settings:
				tail_life_duration = mode_settings["tail_life_duration"]
			if "tail_size_shrink_duration" in mode_settings:
				tail_size_shrink_duration = mode_settings["tail_size_shrink_duration"]
			if "tail_glow_enabled" in mode_settings:
				tail_glow_enabled = mode_settings["tail_glow_enabled"]
			if "tail_brightness_factor" in mode_settings:
				tail_brightness_factor = mode_settings["tail_brightness_factor"]

			var tail_alpha = 0.0
			if vte <= tail_life_duration:
				tail_alpha = trail_alpha_factor * alpha
			else:
				var tail_fade_time = vte - tail_life_duration
				if tail_fade_time < trail_fade_duration:
					tail_alpha = trail_alpha_factor * alpha * (1.0 - tail_fade_time / trail_fade_duration)
				else:
					tail_alpha = 0.0

			var tail_size_progress = 0.0
			if tail_size_shrink_duration > 0:
				tail_size_progress = min(vte / tail_size_shrink_duration, 1.0)

			if tail_alpha > 0:
				for i in range(1, final_steps + 1):
					var trail_pos = local_pos + direction * (i * trail_step_distance)
					var trail_sub_alpha = tail_alpha * (1.0 - float(i) / float(final_steps + 1))

					var trail_whiteness = t * pow(tail_brightness_factor, i)
					var trail_color = point.color.lerp(Color(1, 1, 1), trail_whiteness)
					trail_color.a = trail_sub_alpha

					var start_trail_size = ellipse_size
					var end_trail_size = ellipse_size * (1.0 - float(i) * trail_size_factor)
					var current_trail_size = start_trail_size.lerp(end_trail_size, tail_size_progress)

					if tail_glow_enabled:
						draw_tail_glow("active", vte, trail_sub_alpha, current_trail_size, trail_pos, angle, mode_settings)

					draw_polygon_ellipse(trail_pos, current_trail_size, angle, trail_color)

		"passive":
			# Tail logic for passive sonar
			if not passive_tail_enabled:
				return
			var scale_p = 0.2
			var final_steps_p = clamp(int(ceil(thickness * scale_p)), 1, 5)

			var trail_step_distance_p = passive_trail_step_distance
			var trail_size_factor_p = passive_trail_size_factor
			var trail_alpha_factor_p = passive_trail_alpha_factor
			var trail_fade_duration_p = passive_trail_fade_duration
			var tail_life_duration_p = passive_tail_life_duration
			var tail_size_shrink_duration_p = passive_tail_size_shrink_duration
			var tail_glow_enabled_p = passive_tail_glow_enabled
			var tail_brightness_factor_p = passive_tail_brightness_factor

			if "tail_step_distance" in mode_settings:
				trail_step_distance_p = mode_settings["tail_step_distance"]
			if "tail_size_factor" in mode_settings:
				trail_size_factor_p = mode_settings["tail_size_factor"]
			if "tail_alpha_factor" in mode_settings:
				trail_alpha_factor_p = mode_settings["tail_alpha_factor"]
			if "tail_fade_duration" in mode_settings:
				trail_fade_duration_p = mode_settings["tail_fade_duration"]
			if "tail_life_duration" in mode_settings:
				tail_life_duration_p = mode_settings["tail_life_duration"]
			if "tail_size_shrink_duration" in mode_settings:
				tail_size_shrink_duration_p = mode_settings["tail_size_shrink_duration"]
			if "tail_glow_enabled" in mode_settings:
				tail_glow_enabled_p = mode_settings["tail_glow_enabled"]
			if "tail_brightness_factor" in mode_settings:
				tail_brightness_factor_p = mode_settings["tail_brightness_factor"]

			var tail_alpha_p = 0.0
			if vte <= tail_life_duration_p:
				tail_alpha_p = trail_alpha_factor_p * alpha
			else:
				var tail_fade_time_p = vte - tail_life_duration_p
				if tail_fade_time_p < trail_fade_duration_p:
					tail_alpha_p = trail_alpha_factor_p * alpha * (1.0 - tail_fade_time_p / trail_fade_duration_p)
				else:
					tail_alpha_p = 0.0

			var tail_size_progress_p = 0.0
			if tail_size_shrink_duration_p > 0:
				tail_size_progress_p = min(vte / tail_size_shrink_duration_p, 1.0)

			if tail_alpha_p > 0:
				for i in range(1, final_steps_p + 1):
					var trail_pos_p = local_pos + direction * (i * trail_step_distance_p)
					var trail_sub_alpha_p = tail_alpha_p * (1.0 - float(i) / float(final_steps_p + 1))

					var trail_whiteness_p = t * pow(tail_brightness_factor_p, i)
					var trail_color_p = point.color.lerp(Color(1, 1, 1), trail_whiteness_p)
					trail_color_p.a = trail_sub_alpha_p

					var start_trail_size_p = ellipse_size
					var end_trail_size_p = ellipse_size * (1.0 - float(i) * trail_size_factor_p)
					var current_trail_size_p = start_trail_size_p.lerp(end_trail_size_p, tail_size_progress_p)

					if tail_glow_enabled_p:
						draw_tail_glow("passive", vte, trail_sub_alpha_p, current_trail_size_p, trail_pos_p, angle, mode_settings)

					draw_polygon_ellipse(trail_pos_p, current_trail_size_p, angle, trail_color_p)

		"directed":
			# Tail logic for directed sonar
			if not directed_tail_enabled:
				return
			var final_steps_d = compute_directed_tail_steps(thickness, ellipse_size)

			var trail_step_distance_d = directed_trail_step_distance
			var trail_size_factor_d = directed_trail_size_factor
			var trail_alpha_factor_d = directed_trail_alpha_factor
			var trail_fade_duration_d = directed_trail_fade_duration
			var tail_life_duration_d = directed_tail_life_duration
			var tail_size_shrink_duration_d = directed_tail_size_shrink_duration
			var tail_glow_enabled_d = directed_tail_glow_enabled
			var tail_brightness_factor_d = directed_tail_brightness_factor

			if "tail_step_distance" in mode_settings:
				trail_step_distance_d = mode_settings["tail_step_distance"]
			if "tail_size_factor" in mode_settings:
				trail_size_factor_d = mode_settings["tail_size_factor"]
			if "tail_alpha_factor" in mode_settings:
				trail_alpha_factor_d = mode_settings["tail_alpha_factor"]
			if "tail_fade_duration" in mode_settings:
				trail_fade_duration_d = mode_settings["trail_fade_duration"]
			if "tail_life_duration" in mode_settings:
				tail_life_duration_d = mode_settings["tail_life_duration"]
			if "tail_size_shrink_duration" in mode_settings:
				tail_size_shrink_duration_d = mode_settings["tail_size_shrink_duration"]
			if "tail_glow_enabled" in mode_settings:
				tail_glow_enabled_d = mode_settings["tail_glow_enabled"]
			if "tail_brightness_factor" in mode_settings:
				tail_brightness_factor_d = mode_settings["tail_brightness_factor"]

			var tail_alpha_d = 0.0
			if vte <= tail_life_duration_d:
				tail_alpha_d = trail_alpha_factor_d * alpha
			else:
				var tail_fade_time_d = vte - tail_life_duration_d
				if tail_fade_time_d < trail_fade_duration_d:
					tail_alpha_d = trail_alpha_factor_d * alpha * (1.0 - tail_fade_time_d / trail_fade_duration_d)
				else:
					tail_alpha_d = 0.0

			var tail_size_progress_d = 0.0
			if tail_size_shrink_duration_d > 0:
				tail_size_progress_d = min(vte / tail_size_shrink_duration_d, 1.0)

			if tail_alpha_d > 0:
				for i in range(1, final_steps_d + 1):
					var trail_pos_d = local_pos + direction * (i * trail_step_distance_d)
					var trail_sub_alpha_d = tail_alpha_d * (1.0 - float(i) / float(final_steps_d + 1))

					var trail_whiteness_d = t * pow(tail_brightness_factor_d, i)
					var trail_color_d = point.color.lerp(Color(1, 1, 1), trail_whiteness_d)
					trail_color_d.a = trail_sub_alpha_d

					var start_trail_size_d = ellipse_size
					var end_trail_size_d = ellipse_size * (1.0 - float(i) * trail_size_factor_d)
					var current_trail_size_d = start_trail_size_d.lerp(end_trail_size_d, tail_size_progress_d)

					if tail_glow_enabled_d:
						draw_tail_glow("directed", vte, trail_sub_alpha_d, current_trail_size_d, trail_pos_d, angle, mode_settings)

					draw_polygon_ellipse(trail_pos_d, current_trail_size_d, angle, trail_color_d)

		_:
			pass


func compute_directed_tail_steps(thickness: float, ellipse_size: Vector2) -> int:
	# Determines how many tail segments to draw for directed sonar based on thickness and ellipse size
	var ellipse_factor = (ellipse_size.x + ellipse_size.y) * 0.5
	ellipse_factor = clamp(ellipse_factor, 0.05, 999.0)

	var base_scale = 0.5
	var _scale = base_scale / ellipse_factor

	var raw_steps = thickness * _scale
	var final_steps = clamp(int(ceil(raw_steps)), 1, 8)

	return final_steps


func draw_tail_glow(
	mode: String,
	vte: float,
	trail_sub_alpha: float,
	current_trail_size: Vector2,
	trail_pos: Vector2,
	angle: float,
	mode_settings: Dictionary
) -> void:
	# Draws an additional glow ellipse behind each tail segment, depending on mode
	match mode:
		"active":
			if not active_tail_glow_enabled:
				return
			if "tail_glow_enabled" in mode_settings and not mode_settings["tail_glow_enabled"]:
				return

			if vte <= active_tail_glow_life_duration:
				var tail_glow_alpha_val = (1.0 - (vte / active_tail_glow_life_duration)) * active_tail_glow_alpha_factor * trail_sub_alpha
				if tail_glow_alpha_val > 0.0:
					var tg_progress = 0.0
					if active_tail_glow_size_shrink_duration > 0:
						tg_progress = min(vte / active_tail_glow_size_shrink_duration, 1.0)

					var start_tail_glow_size = current_trail_size
					var tail_glow_size = start_tail_glow_size.lerp(current_trail_size, tg_progress)

					var tg_color = active_tail_glow_color
					if "tail_glow_color" in mode_settings:
						tg_color = mode_settings["tail_glow_color"]
					tg_color.a = tail_glow_alpha_val

					var local_glow_size_factor = active_tail_glow_size_factor
					if "tail_glow_size_factor" in mode_settings:
						local_glow_size_factor = mode_settings["tail_glow_size_factor"]

					tail_glow_size *= local_glow_size_factor
					draw_polygon_ellipse(trail_pos, tail_glow_size, angle, tg_color)

		"passive":
			if not passive_tail_glow_enabled:
				return
			if "tail_glow_enabled" in mode_settings and not mode_settings["tail_glow_enabled"]:
				return
			# Glow effect for passive tail can be implemented similarly

		"directed":
			if not directed_tail_glow_enabled:
				return
			if "tail_glow_enabled" in mode_settings and not mode_settings["tail_glow_enabled"]:
				return
			# Glow effect for directed tail can be implemented similarly

		_:
			pass


func draw_polygon_ellipse(pos: Vector2, size: Vector2, rot: float, color: Color) -> void:
	# Draws an ellipse as a polygon using ELLIPSE_SEGMENTS
	var points = []
	for i in range(ELLIPSE_SEGMENTS):
		var a = i * 2.0 * PI / float(ELLIPSE_SEGMENTS)
		var rotated = Vector2(cos(a), sin(a)) * size
		rotated = rotated.rotated(rot)
		points.append(pos + rotated)

	var polygon = PackedVector2Array(points)
	draw_polygon(polygon, [color])


func get_active_sonar_radius() -> float:
	# Returns the current radius of the expanding active sonar ring, or 0 if inactive
	if ring_active:
		return ring_radius
	return 0.0


func get_directed_sonar_radius() -> float:
	# Returns the current radius of the directed sonar wave arc, or 0 if inactive
	if directed_wave_active:
		return directed_wave_radius
	return 0.0


func measure_collision_thickness(intersection_pos: Vector2, direction: Vector2, collider: Object) -> float:
	# Attempts to measure the thickness of the collided object by continuing a small offset in the direction
	if collider == null:
		return 1.0

	var step_size = 2.0
	var max_distance = 50.0
	var distance_traveled = 0.0
	var current_pos = intersection_pos
	var norm_dir = direction.normalized()

	while distance_traveled < max_distance:
		current_pos += norm_dir * step_size
		distance_traveled += step_size

		var point_query = PhysicsPointQueryParameters2D.new()
		point_query.position = current_pos
		point_query.collide_with_areas = true
		point_query.collide_with_bodies = true

		var result = space_state.intersect_point(point_query)

		var inside_same_collider = false
		for res in result:
			if res.collider == collider:
				inside_same_collider = true
				break

		if not inside_same_collider:
			break

	return distance_traveled
