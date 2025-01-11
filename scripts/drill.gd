extends Node2D

# ------------------- SIGNALS -------------------
# Signal to display a message related to drilling, with text and color.
signal drill_message(text: String, color: String)
# Signal emitted when drilling is finished, providing item types and yield amounts.
signal drilling_finished(item_types: Array, yield_amounts: Array)
# Signal to update the drill progress percentage.
signal drill_progress_update(progress_percentage: float)

# ------------------- STATES -------------------
# Indicates if the drill is currently extending.
var is_extending: bool = false
# Indicates if the drill is currently drilling.
var is_drilling: bool = false
# Indicates if the drill is currently retracting.
var is_retracting: bool = false

# ------------------- PARAMETERS -------------------
# Angle at which the drill operates (adjusted by -90° for upward direction).
var drill_angle: float = 0.0          
# Speed of drill extension in pixels per second.
var extension_speed: float = 10.0     
# Time required for the drill to fully extend.
var extension_time: float = 1.0       
# Progress of drill extension in percentage [0..100].
var extension_progress: float = 0.0   
# Maximum distance the drill can extend.
var drill_max_distance: float = 40.0

# Progress of the drilling process in percentage [0..100].
var drill_progress: float = 0.0       
# Duration required to complete the drilling.
var drill_duration: float = 3.0

# ------------------- COLLISION INFO -------------------
# Indicates if the drill has collided with something.
var has_collision: bool = false
# Indicates if the collision is with an item that can be drilled.
var collision_is_item: bool = false
# The node that the drill has collided with (if any).
var current_item_node: Node = null
# List of current items encountered by the drill.
var current_items: Array = []
# List of durations required to drill each item.
var drill_durations: Array = []

# ------------------- TIMERS -------------------
@onready var extension_timer: Timer = Timer.new()
@onready var drill_timer: Timer = Timer.new()

##
# Called when the node is added to the scene.
# Initializes timers for extension and drilling processes.
##
func _ready() -> void:
	# Initialize extension timer with a 0.1 second interval.
	extension_timer.wait_time = 0.1
	extension_timer.one_shot = false
	extension_timer.connect("timeout", Callable(self, "_on_extension_timer_timeout"))
	add_child(extension_timer)

	# Initialize drill timer with a 0.1 second interval.
	drill_timer.wait_time = 0.1
	drill_timer.one_shot = false
	drill_timer.connect("timeout", Callable(self, "_on_drill_timer_timeout"))
	add_child(drill_timer)

##
# Process callback called every frame.
# If the drill is active (extending, drilling, or retracting), request redraw.
##
func _process(delta: float) -> void:
	if is_extending or is_drilling or is_retracting:
		queue_redraw()

#
# ------------------------- PUBLIC METHOD: START DRILLING -------------------------
#
##
# Initiates the drilling process.
#
# @param angle The angle at which to start drilling.
# @param speed The speed of drill extension.
# @param space_state The physics space state used for raycasting.
##
func start_drill(angle: float, speed: float, space_state: PhysicsDirectSpaceState2D) -> void:
	# If the drill is already active in any state, notify and abort.
	if is_extending or is_drilling or is_retracting:
		emit_signal("drill_message", "Drill is busy right now.", "#FF0000")
		return

	# Adjust the drilling angle by -90° so that 0° points upwards.
	drill_angle = angle - 90.0
	extension_speed = speed
	drill_max_distance = 40.0  # Reset to base value
	
	# Reset state flags and progress indicators.
	is_extending = false
	is_drilling = false
	is_retracting = false
	extension_progress = 0.0
	drill_progress = 0.0
	current_items = []
	drill_durations = []
	current_item_node = null

	# Determine start and end points for the raycast.
	var start_pos = global_position
	var dir = Vector2(cos(deg_to_rad(drill_angle)), sin(deg_to_rad(drill_angle)))
	var end_pos = start_pos + dir * drill_max_distance

	# Perform a raycast to detect collisions along the drill path.
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	var result = space_state.intersect_ray(query)

	has_collision = false
	collision_is_item = false

	# If the raycast hits something, process collision information.
	if result.size() > 0:
		has_collision = true
		var collider = result.collider
		var collision_point = result.position
		var collision_dist = start_pos.distance_to(collision_point)

		# Set the maximum drill distance to the collision distance.
		drill_max_distance = collision_dist

		# Check if the collided object has metadata indicating it contains ores.
		if collider.has_meta("ores"):
			collision_is_item = true
			current_item_node = collider
			current_items = collider.get_meta("ores")
			drill_durations = []
			# Gather the drilling time required for each item.
			for itm in current_items:
				var drill_time = itm.get("drill_time", 3.0)
				drill_durations.append(drill_time)
			# Determine the longest drill time among items.
			drill_duration = 0.0
			for dt in drill_durations:
				if dt > drill_duration:
					drill_duration = dt
		else:
			collision_is_item = false
	else:
		# No collision detected; reset collision flags and distance.
		has_collision = false
		collision_is_item = false
		drill_max_distance = 40.0

	# Calculate the time needed for the drill to extend fully.
	extension_time = drill_max_distance / extension_speed

	# Notify the player that the drill is extending.
	emit_signal("drill_message", "Extending drill...", "#00FF66")
	
	# Begin extension process.
	is_extending = true
	extension_timer.start()

#
# ------------------------- EMERGENCY STOP -------------------------
#
##
# Immediately stops drilling operations and begins retracting the drill.
##
func emergency_stop() -> void:
	drill_timer.stop()
	extension_timer.stop()

	is_extending = false
	is_drilling = false
	is_retracting = true

	emit_signal("drill_message", "Emergency stop! Retracting the drill...", "#00FF66")
	extension_timer.start()

#
# ------------------------- EXTENSION/RETRACTION LOGIC -------------------------
#
##
# Timer callback for handling drill extension and retraction progress.
##
func _on_extension_timer_timeout() -> void:
	# Calculate the step percentage based on timer interval and total extension time.
	var step = (extension_timer.wait_time / extension_time) * 100.0

	# Handle extension logic if currently extending and not retracting.
	if is_extending and not is_retracting:
		extension_progress += step
		# Once fully extended, stop the timer and change states accordingly.
		if extension_progress >= 100.0:
			extension_progress = 100.0
			extension_timer.stop()
			is_extending = false

			# After extension, decide next action based on collision info.
			if has_collision:
				if collision_is_item:
					_start_drilling()
				else:
					emit_signal("drill_message", "No collectible items here. Retracting...", "#FF0000")
					_start_retracting()
			else:
				emit_signal("drill_message", "Nothing found. Retracting...", "#00FF66")
				_start_retracting()

	# Handle retraction logic.
	elif is_retracting:
		extension_progress -= step
		# Once fully retracted, stop the timer and reset state.
		if extension_progress <= 0.0:
			extension_progress = 0.0
			extension_timer.stop()
			is_retracting = false
			emit_signal("drill_message", "Drill is fully retracted.", "#00FF66")

##
# Starts the retraction process for the drill.
##
func _start_retracting() -> void:
	is_extending = false
	is_drilling = false
	is_retracting = true
	extension_timer.start()

#
# ------------------------- DRILLING LOGIC -------------------------
#
##
# Begins the drilling process after the drill has fully extended onto an item.
##
func _start_drilling() -> void:
	is_drilling = true
	drill_progress = 0.0

	# Inform the player that drilling is starting and how many items were found.
	var item_count = current_items.size()
	emit_signal("drill_message", "Starting to drill. Found %d item(s)..." % item_count, "#00FF66")

	# Start the drilling timer.
	drill_timer.start()

##
# Timer callback for updating drilling progress.
##
func _on_drill_timer_timeout() -> void:
	# If drilling has been stopped externally, do nothing.
	if not is_drilling:
		return

	# Calculate the step percentage based on timer interval and total drill duration.
	var step = (drill_timer.wait_time / drill_duration) * 100.0
	drill_progress += step
	if drill_progress > 100.0:
		drill_progress = 100.0

	# Emit the current drilling progress percentage.
	emit_signal("drill_progress_update", drill_progress)

	# If drilling is complete, finalize the process.
	if drill_progress >= 100.0:
		_finish_drilling()

#
# ------------------------- COMPLETING DRILLING -------------------------
#
##
# Finalizes the drilling process, collects items (except ice), and starts retraction.
##
func _finish_drilling() -> void:
	is_drilling = false
	drill_timer.stop()

	# Prepare lists to store collected item types and their yields, ignoring ice.
	var final_item_types = []
	var final_yield_amounts = []
	var found_ice = false

	# Process each item encountered during drilling.
	for itm in current_items:
		var item_type = itm.get("ore_type", "Unknown")
		var yield_amount = itm.get("yield_amount", 1)

		# Skip ice items.
		if item_type.to_lower() == "ice":
			found_ice = true
		else:
			final_item_types.append(item_type)
			final_yield_amounts.append(yield_amount)

	# Provide feedback based on what was found.
	if found_ice:
		emit_signal("drill_message", "Ice destroyed! Retracting the drill...", "#00FF66")
	elif final_item_types.size() > 0:
		emit_signal("drill_message", "Drilling complete! Retracting the drill...", "#00FF66")
	else:
		emit_signal("drill_message", "No items collected. Retracting the drill...", "#00FF66")

	# If any valid items were collected, emit a signal with the results.
	if final_item_types.size() > 0:
		emit_signal("drilling_finished", final_item_types, final_yield_amounts)

	# If a collider node was involved, free it from the scene.
	if current_item_node:
		current_item_node.queue_free()

	# Reset collision-related variables.
	current_item_node = null
	current_items = []
	drill_durations = []

	# Begin retracting the drill after finishing drilling.
	_start_retracting()

#
# ------------------------- DRAWING THE DRILL -------------------------
#
##
# Custom draw function to visualize the drill during extension, drilling, or retraction.
##
func _draw() -> void:
	# Only draw if the drill is active in some state.
	if is_extending or is_drilling or is_retracting:
		var start_pos = Vector2.ZERO
		# Determine direction vector based on current drill angle.
		var dir = Vector2(cos(deg_to_rad(drill_angle)), sin(deg_to_rad(drill_angle)))

		# Calculate the current extension distance based on progress.
		var extension_dist = (extension_progress / 100.0) * drill_max_distance
		extension_dist = clamp(extension_dist, 0.0, drill_max_distance)

		# If drilling and fully extended, use full drill length.
		if is_drilling and extension_progress >= 100.0:
			extension_dist = drill_max_distance

		# Draw the drill shaft in segments.
		var segment_length = 4.0
		# Offset for alternating colors effect.
		var offset = int(Time.get_ticks_msec() / 150)
		# Determine how many segments to draw based on extension distance.
		var num_segments = int(extension_dist / segment_length)

		# Draw each segment of the drill.
		for i in range(num_segments + 1):
			var seg_start_dist = i * segment_length
			var seg_end_dist   = (i + 1) * segment_length

			if seg_end_dist > extension_dist:
				seg_end_dist = extension_dist
			if seg_start_dist > extension_dist:
				break

			var seg_start = start_pos + dir * seg_start_dist
			var seg_end   = start_pos + dir * seg_end_dist

			# Alternate segment colors for visual effect.
			var color_switch = (i + offset) % 2
			var segment_color = Color(0.6, 0.6, 0.6)
			if color_switch == 0:
				segment_color = Color(1,1,1)

			draw_line(seg_start, seg_end, segment_color, 1.0)

		# Draw the drill tip at the end of the extension.
		if extension_dist > 0.0:
			var tip_length = 3.0
			var tip_width  = 1.0
			var tip_start = start_pos + dir * extension_dist
			var tip_end   = tip_start + dir * tip_length

			# Calculate perpendicular vector for tip width.
			var perp = Vector2(-dir.y, dir.x) * tip_width
			# Define triangle points for the drill tip.
			var triangle_points = [
				tip_start + perp,
				tip_start - perp,
				tip_end
			]
			var triangle_color = Color(0.8, 0.8, 0.8)
			draw_polygon(triangle_points, [triangle_color, triangle_color, triangle_color])
