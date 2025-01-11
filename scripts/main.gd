extends Node2D

# -------------------------------------------------
#          SUBMARINE MISSION CONTROLLER
# -------------------------------------------------
#  This script handles:
#   • Narrative dialogues (3 phases):
#       1) Intro
#       2) Black Box found
#       3) Final (end station)
#   • Mission logic (collect Black Box & resources)
#   • Docking, Undocking, Inventory, Commands
#   • Torpedo firing, Drilling, etc.
#   • The final dialogue now ends the game when the
#     user types 'bye' in chat.
# -------------------------------------------------

# ------------------------- SETTINGS -------------------------
var skip_narrative := false          # Whether to skip narrative dialogs at start FOR DEV
var skip_undock_requirement := false # Whether we require 'undock' before moving FOR DEV

@onready var command_input: LineEdit = $Player/Terminal/Rows/PanelContainer2/HBoxContainer/CommandInput
@onready var player = $Player
@onready var default_speed_label: Label = $Player/UI/DefaultSpeedLabel
@onready var terminal_output: RichTextLabel = $Player/Terminal/Rows/PanelContainer/MarginContainer/TerminalOutput

@onready var drill_node := $Player/Drill
var parser = load("res://scripts/CommandParser.gd").new()

var default_speed_percent: float = 50.0

# Console history
var command_history: Array = []
var history_index: int = 0
var console_buffer: Array = []

# Inventory
var inventory: Dictionary = {}

# Docking system
var is_docked: bool = true
var commands_blocked: bool = true

# Index for showing drill progress in console
var drilling_progress_line_index: int = -1

# Required resources
const REQUIRED_QUARZ = 14
const REQUIRED_MAGNETITE = 7
const REQUIRED_PHOSPHAT = 7
const REQUIRED_PLATINUM = 8
const REQUIRED_RHODIUM = 8

# --------------------------------------------------
#                NARRATIVE DIALOGS
# --------------------------------------------------

# 1) Intro
var intro_messages: Array = [
# ---- Intro Part 1 ----
"""--- Transmission from Headquarters ---

Captain, welcome to the depths beneath Antarctica. We’ve discovered a network of massive ice caves below the frozen surface. One of our research submarines ventured here and went missing a week ago. We believe it has sunk.

Your first mission objectives:
1) Recover the submarine’s Black Box.
2) Gather certain valuable resources found in these caves. 
   Specifically:
   • Quarz (need 14)
   • Magnetite (need 7)
   • Phosphat (need 7)
   • Platinum (need 8)
   • Rhodium (need 8)

These resources are incredibly rare, so collect as many as you can. 
At minimum, you must bring the listed quantities back to our end station 
to complete the mission.
""",

# ---- Intro Part 2 ----
"""We’ve equipped your submarine with a powerful drill and a fully-functional 
Directed Sonar right from the start. Some deposits, like Platinum and Rhodium, 
often appear in small cracks along cave walls. If you notice a different color 
inside a wall indentation on your sonar, it might be a hidden mineral deposit. 
Use your Directed Sonar to examine such cracks more closely.

You also have torpedoes at your disposal (use the 'attack' command with an angle). Enemies will be marked as red dots on your sonar—be cautious, as they can spot you at any moment. If you prefer to evade them rather than fight, consider switching to passive sonar and moving in the opposite direction from the creature. Keep in mind that creatures are more likely to detect you when active sonar is in use.

Before you dive deeper to Target Posion coordinates(look at the upper-left corner), we recommend practicing how to call the 'drill' and 'attack' commands in these safer zones. Good luck, Captain.
"""
]

# 2) Black Box Found Narrative
#   => We'll mention the Dead Pocket (1200,1000)
#      and that the target is changed to (945,-200).
#      Also mention "mission" command.
var black_box_messages: Array = [
"""--- Transmission from Headquarters ---

Captain, we have analyzed the data from the Black Box you recovered. 
It reveals the sunken submarine encountered a massive creature in these caves.

Their logs refer to a zone they called the 'Dead Pocket'—a strangely warmer 
chamber at coordinates (1200, 1000), where no living creatures ever seem to leave. 
Their small defensive torpedoes were insufficient against this large predator. 
The submarine sustained critical damage escaping the Dead Pocket, then crashed 
here in the ice biome.

We’ve updated your target coordinates to the End Station at (945, -200). 
Once you gather all required resources, you can head there. Remember, you can 
use the 'mission' command anytime to check your progress.

Given your submarine carries high-speed torpedoes, we now urge you to neutralize 
this threat. Investigate the Dead Pocket if possible and eliminate that creature 
so we can safely continue our research.
"""
]

# 3) Final Narrative (end station) - user must type "bye" to exit
var end_station_messages: Array = [
"""--- Transmission from Headquarters ---

Captain, thank you for completing this mission. It wasn’t easy, but you succeeded against all odds. 
Our research team is grateful for your courage and skill.

You’ve proven yourself a valuable ally. HQ would be glad to see you take on further expeditions under the ice, 
but for now, this concludes your current assignment.

Until we meet again, safe travels. When you’re ready to finalize and return to the surface, please type 'bye' .
"""
]

var story_messages: Array = []
var current_message_index: int = 0

var is_in_narrative: bool = false
var is_typing: bool = false
var is_waiting_for_input: bool = false
var typing_speed: float = 0.02
var time_since_last_char: float = 0.0
var message_char_index: int = 0
var typed_text: String = ""

var black_box_message_shown: bool = false
var current_narrative_phase: String = ""


func _ready() -> void:
	terminal_output.bbcode_enabled = true
	update_default_speed_label()

	# Connect signals from the Drill
	drill_node.connect("drill_message", Callable(self, "_on_drill_message"))
	drill_node.connect("drilling_finished", Callable(self, "_on_drilling_finished"))
	drill_node.connect("drill_progress_update", Callable(self, "_on_drill_progress_update"))

	# Connect signals from Player
	if player.has_signal("crash_message"):
		player.connect("crash_message", Callable(self, "_on_submarine_crash"))
	if player.has_signal("mayday_message"):
		player.connect("mayday_message", Callable(self, "_on_submarine_mayday"))
	if player.has_signal("friction_damage"):
		player.connect("friction_damage", Callable(self, "_on_friction_damage"))

	# If skipping narrative, go straight to normal game console
	if skip_narrative:
		end_narrative()
	else:
		start_intro_narrative()


func _process(delta: float) -> void:
	# Typewriter effect for narrative
	if is_in_narrative and is_typing:
		time_since_last_char += delta
		if time_since_last_char >= typing_speed:
			time_since_last_char = 0.0
			var full_text = story_messages[current_message_index]
			if message_char_index < full_text.length():
				typed_text += full_text[message_char_index]
				message_char_index += 1
				if console_buffer.size() > 0:
					console_buffer[console_buffer.size() - 1]["text"] = typed_text
					_update_terminal()
			else:
				# Done typing
				is_typing = false
				is_waiting_for_input = true
				if current_narrative_phase == "end_station":
					add_to_terminal_output("\n[Type 'bye' to exit the game]", "#8888ff")
				else:
					add_to_terminal_output("\n[Please type anything to continue]", "#8888ff")


# ----------------------------------------------------------------------------
#                             NARRATIVE STARTERS
# ----------------------------------------------------------------------------
func start_intro_narrative() -> void:
	current_narrative_phase = "intro"
	story_messages = intro_messages
	is_in_narrative = true
	commands_blocked = true
	current_message_index = 0
	show_next_message()


func start_blackbox_narrative() -> void:
	current_narrative_phase = "black_box"
	story_messages = black_box_messages
	is_in_narrative = true
	commands_blocked = true
	current_message_index = 0
	show_next_message()


func start_end_station_narrative() -> void:
	current_narrative_phase = "end_station"
	story_messages = end_station_messages
	is_in_narrative = true
	commands_blocked = true
	current_message_index = 0
	show_next_message()


func show_next_message() -> void:
	if current_message_index >= story_messages.size():
		end_narrative()
		return

	typed_text = ""
	message_char_index = 0
	time_since_last_char = 0.0
	is_typing = true
	is_waiting_for_input = false

	console_buffer.append({"text": "", "color": "white"})
	_update_terminal()


func end_narrative() -> void:
	is_in_narrative = false
	is_typing = false
	is_waiting_for_input = false

	var was_phase = current_narrative_phase
	current_narrative_phase = ""

	if was_phase == "end_station":
		# This is truly the end of the game
		# We won't force close the game automatically; user must type 'bye'.
		pass
	else:
		# After finishing "intro" or "black_box" narrative:
		if was_phase == "black_box":
			# Unlock commands, sub is considered undocked
			is_docked = false
			commands_blocked = false
		else:
			# If skip_undock_requirement is true, sub starts undocked
			if skip_undock_requirement:
				is_docked = false
				commands_blocked = false
			else:
				is_docked = true
				commands_blocked = true

		# Show the normal console prompt
		handle_help_command()


func init_game_console() -> void:
	add_success("Welcome aboard, Captain. The mission is active.")
	
	add_success(
"""
Commands:
  move/m [d|degree] <angle_or_clock> [speed%]
  stop/s
  speed/sp <value>
  sonar <active/a|passive/p|directed/d|off> [angle]
  drill <angle>
  inventory
  attack/a <angle_degrees>
  dock
  undock
  mission
  help
  clear
"""
	)
	add_success("Type 'undock' to begin your journey.")


# ----------------------------------------------------------------------------
#                      SIGNALS FROM PLAYER
# ----------------------------------------------------------------------------
func _on_submarine_crash(message: String, _color: String) -> void:
	if is_in_narrative:
		return
	add_error(message)

func _on_submarine_mayday(_message: String, _color: String) -> void:
	if is_in_narrative:
		return
	pass

func _on_friction_damage(_message: String, _color: String) -> void:
	if is_in_narrative:
		return
	pass


# ----------------------------------------------------------------------------
#                      SIGNALS FROM DRILL
# ----------------------------------------------------------------------------
func _on_drill_message(text: String, color: String) -> void:
	if is_in_narrative:
		return
	add_to_terminal_output(text, color)
	drilling_progress_line_index = -1


func _on_drilling_finished(item_types: Array, yield_amounts: Array) -> void:
	for i in range(item_types.size()):
		var it = item_types[i]
		var amt = yield_amounts[i]
		if not inventory.has(it):
			inventory[it] = 0
		inventory[it] += amt

		if not is_in_narrative:
			add_success("Received: %s x%d" % [it, amt])

	# Check if Black Box is now present:
	check_inventory_for_black_box()


func check_inventory_for_black_box() -> void:
	if not black_box_message_shown:
		if inventory.has("Black Box"):
			black_box_message_shown = true
			# Immediately set mission target to end station (945, -200)
			player.set_mission_target_position(Vector2(945, -200))
			start_blackbox_narrative()


func check_resources_collected() -> bool:
	return (
		inventory.has("Quarz") and inventory["Quarz"] >= REQUIRED_QUARZ and
		inventory.has("Magnetite") and inventory["Magnetite"] >= REQUIRED_MAGNETITE and
		inventory.has("Phosphat") and inventory["Phosphat"] >= REQUIRED_PHOSPHAT and
		inventory.has("Platinum") and inventory["Platinum"] >= REQUIRED_PLATINUM and
		inventory.has("Rhodium") and inventory["Rhodium"] >= REQUIRED_RHODIUM
	)


func _on_drill_progress_update(progress_percentage: float) -> void:
	if is_in_narrative:
		return

	var progress_int = int(progress_percentage)
	var progress_text = "Drilling in progress: %d%%" % progress_int

	if drilling_progress_line_index < 0:
		console_buffer.append({"text": progress_text, "color": "#00FF66"})
		drilling_progress_line_index = console_buffer.size() - 1
	else:
		console_buffer[drilling_progress_line_index]["text"] = progress_text

	_update_terminal()


# ----------------------------------------------------------------------------
#                    TERMINAL INPUT
# ----------------------------------------------------------------------------
func _on_CommandInput_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_UP:
			if command_history.is_empty():
				return
			history_index = max(history_index - 1, 0)
			command_input.text = command_history[history_index]
			command_input.set_caret_column(command_input.text.length())
		elif event.keycode == KEY_DOWN:
			if command_history.is_empty():
				return
			history_index = min(history_index + 1, command_history.size())
			if history_index == command_history.size():
				command_input.text = ""
			else:
				command_input.text = command_history[history_index]
			command_input.set_caret_column(command_input.text.length())


func _on_CommandInput_text_submitted(text: String) -> void:
	var user_input = text.strip_edges()
	if user_input.length() == 0:
		add_error("No command entered.")
		return

	command_history.append(user_input)
	history_index = command_history.size()

	add_to_terminal_output("> " + user_input, "white")
	command_input.text = ""

	var input_lower = user_input.to_lower()

	# --------------- Narrative Handling ---------------
	if is_in_narrative:
		# If we're in the final phase (end_station), we only want the user to type 'bye'
		if current_narrative_phase == "end_station":
			if input_lower == "bye":
				# Close the game
				add_success("Exiting the game. Farewell, Captain!")
				get_tree().quit()
				return
			else:
				# Remind them to type bye
				add_error("Please type 'bye' to exit the game.")
				return

		# Otherwise, if the message is still typing
		if is_typing:
			# We simply fast-forward the typing
			var full_text = story_messages[current_message_index]
			typed_text = full_text
			message_char_index = full_text.length()
			if console_buffer.size() > 0:
				console_buffer[console_buffer.size() - 1]["text"] = typed_text
				_update_terminal()

			current_message_index += 1
			show_next_message()
			return
		else:
			# If waiting for input after the text is done
			if is_waiting_for_input:
				current_message_index += 1
				show_next_message()
			else:
				add_error("Please wait for the text to finish typing...")
		return
	# ------------ End of Narrative Handling ------------

	# If commands are blocked => only 'undock' is allowed
	if commands_blocked:
		if input_lower == "undock":
			handle_undock()
		else:
			add_error("Commands are blocked! Please 'undock' first.")
		return

	# If docked (and we do not skip undock requirement), we must undock
	if is_docked and not skip_undock_requirement:
		if input_lower == "undock":
			handle_undock()
		else:
			add_error("Submarine is docked. Use 'undock' first.")
		return

	# Parse the user command
	var result = parser.parse_command(user_input)
	if not result:
		add_error("Command parsing failed.")
		return

	var command = result.command
	var args = result.args

	match command:
		"help":
			handle_help_command()
		"clear":
			handle_clear_command()
		"move", "m":
			handle_move_command(args)
		"stop", "s":
			if drill_node.is_extending or drill_node.is_drilling or drill_node.is_retracting:
				drill_node.emergency_stop()
			else:
				player.stop_movement()
				add_success("Stopped.")
		"speed", "sp":
			handle_speed_command(args)
		"sonar":
			handle_sonar_command(args)
		"inventory":
			handle_inventory_command()
		"drill":
			handle_drill_command(args)
		"attack", "a":
			handle_attack_command(args)
		"dock":
			handle_dock()
		"undock":
			handle_undock()
		"mission":
			handle_mission_command()
		_:
			add_error("Unknown command: %s" % command)


# ----------------------------------------------------------------------------
#                    TERMINAL OUTPUT
# ----------------------------------------------------------------------------
func add_to_terminal_output(text: String, color: String = "white") -> void:
	console_buffer.append({"text": text, "color": color})
	_update_terminal()

func _update_terminal() -> void:
	if not terminal_output:
		return
	terminal_output.clear()

	for entry in console_buffer:
		terminal_output.push_color(Color(entry.color))
		terminal_output.add_text(entry.text + "\n")
		terminal_output.pop()

	terminal_output.queue_redraw()
	terminal_output.scroll_to_line(terminal_output.get_line_count())

func add_success(text: String) -> void:
	add_to_terminal_output(text, "#00FF66")

func add_error(text: String) -> void:
	add_to_terminal_output(text, "#FF0000")


# ----------------------------------------------------------------------------
#                          HELP / CLEAR
# ----------------------------------------------------------------------------
func handle_help_command() -> void:
	add_success(
"""Available commands:
  move/m [d|degree] <angle_or_clock> [speed%]
  stop/s
  speed/sp <value>
  sonar <active/a|passive/p|directed/d|off> [angle]
  drill <angle>
  inventory
  attack/a <angle_degrees>
  dock
  undock
  mission
  help
  clear
"""
	)

func handle_clear_command() -> void:
	console_buffer.clear()
	_update_terminal()
	add_success("Terminal cleared.")


# ----------------------------------------------------------------------------
#                MOVE / STOP / SPEED COMMANDS
# ----------------------------------------------------------------------------
func handle_move_command(args: Array) -> void:
	if args.size() < 1:
		add_error("Need to specify direction (angle or clock).")
		return

	if (drill_node.is_extending or drill_node.is_drilling or drill_node.is_retracting) \
			and (drill_node.extension_progress > 20.0):
		add_error("Cannot move: drill is extended more than 20%. Wait for retraction!")
		return

	var first_arg = args[0]
	var angle = 0.0
	var is_clock = false
	var speed_for_move = default_speed_percent
	var speed_arg_index = 1

	if first_arg.to_lower() in ["d", "degree"]:
		if args.size() < 2:
			add_error("Need to specify angle after 'd' or 'degree'.")
			return
		var degree_str = args[1]
		if degree_str.is_valid_float():
			angle = float(degree_str)
			speed_arg_index = 2
		else:
			add_error("Angle must be a number.")
			return
	else:
		if first_arg.is_valid_float():
			var value = float(first_arg)
			if value >= 0.0 and value <= 12.5:
				var clock_angle = parse_clock_input(value)
				if clock_angle == -1.0:
					return
				angle = clock_angle
				is_clock = true
			else:
				angle = value
		else:
			add_error("Angle (or clock) must be a number.")
			return

	if args.size() > speed_arg_index:
		var speed_str = args[speed_arg_index]
		if speed_str.is_valid_float():
			speed_for_move = check_speed_value(float(speed_str))
			default_speed_percent = speed_for_move
			update_default_speed_label()
		else:
			add_error("Speed must be a number! Using default value.")

	player.move_in_direction(angle, speed_for_move)

	var direction_text = ""
	if is_clock:
		direction_text = "%s° (clock)" % str(angle)
	else:
		direction_text = "%s°" % str(angle)

	add_success("Moving in direction %s at speed %d%%" % [direction_text, int(speed_for_move)])


func handle_speed_command(args: Array) -> void:
	if args.size() == 1 and args[0].is_valid_float():
		var sp_val = float(args[0])
		sp_val = check_speed_value(sp_val)
		player.set_speed(sp_val)
		default_speed_percent = sp_val
		update_default_speed_label()
		add_success("Speed changed to %d%%" % int(sp_val))
	else:
		add_error("You need to specify a valid speed value.")


# ----------------------------------------------------------------------------
#                  SONAR COMMAND
# ----------------------------------------------------------------------------
func handle_sonar_command(args: Array) -> void:
	if args.size() < 1:
		add_error("Specify 'active', 'passive', 'directed' or 'off' (optionally with angle).")
		return

	var sonar_node: Node = null
	if player.has_node("Sonar"):
		sonar_node = player.get_node("Sonar")

	if not sonar_node:
		add_error("Sonar node not found.")
		return

	var mode = args[0].to_lower()

	match mode:
		"active", "a":
			sonar_node.is_enabled = true
			sonar_node.set_sonar_mode("active")
			add_success("Sonar switched to ACTIVE mode.")
		"passive", "p":
			sonar_node.is_enabled = true
			sonar_node.set_sonar_mode("passive")
			add_success("Sonar switched to PASSIVE mode.")
		"directed", "d":
			sonar_node.is_enabled = true
			if args.size() >= 2:
				var angle_str = args[1]
				if angle_str.is_valid_float():
					var val = float(angle_str)
					var angle_dir = val
					if val >= 0.0 and val <= 12.5:
						var clock_angle = parse_clock_input(val)
						if clock_angle == -1.0:
							return
						angle_dir = clock_angle
					sonar_node.directed_angle_default = angle_dir
					add_success("Sonar switched to DIRECTED mode, angle=%.2f" % sonar_node.directed_angle_default)
				else:
					add_error("Angle must be a number. Using default=%.2f" % sonar_node.directed_angle_default)
			else:
				add_success("Sonar switched to DIRECTED mode, default angle=%.2f" % sonar_node.directed_angle_default)
			sonar_node.set_sonar_mode("directed")
		"off":
			sonar_node.is_enabled = false
			sonar_node.set_sonar_mode("active")
			sonar_node._update_sonar_timers()
			add_success("Sonar turned OFF.")
		_:
			add_error("Unknown sonar mode: %s" % mode)


# ----------------------------------------------------------------------------
#                  INVENTORY COMMAND
# ----------------------------------------------------------------------------
func handle_inventory_command() -> void:
	var keys_arr = inventory.keys()
	if keys_arr.size() == 0:
		add_success("Inventory is empty.")
		return

	add_success("Inventory content:")
	for k in keys_arr:
		var val = inventory[k]
		add_to_terminal_output("  %s: %d" % [k, val], "white")


# ----------------------------------------------------------------------------
#                   DRILL COMMAND
# ----------------------------------------------------------------------------
func handle_drill_command(args: Array) -> void:
	if not player.is_stopped():
		add_error("Cannot start drilling: submarine is not stopped!")
		return

	if args.size() < 1 or not args[0].is_valid_float():
		add_error("Usage: drill <angle> [extension_speed_px_sec]")
		return

	var angle_input = float(args[0])
	var angle = angle_input
	if angle_input >= 0.0 and angle_input <= 12.5:
		var clock_angle = parse_clock_input(angle_input)
		if clock_angle == -1.0:
			return
		angle = clock_angle

	var speed = 10.0
	if args.size() >= 2 and args[1].is_valid_float():
		speed = float(args[1])

	drill_node.start_drill(angle, speed, get_viewport().get_world_2d().direct_space_state)


# ----------------------------------------------------------------------------
#                   ATTACK (TORPEDO) COMMAND
# ----------------------------------------------------------------------------
func handle_attack_command(args: Array) -> void:
	if args.size() < 1:
		add_error("Usage: attack/a <angle_degrees>")
		return

	var angle_input = args[0]
	if not angle_input.is_valid_float():
		add_error("Angle must be a number.")
		return

	var value = float(angle_input)
	var angle_degrees = value
	if value >= 0.0 and value <= 12.5:
		var clock_angle = parse_clock_input(value)
		if clock_angle == -1.0:
			return
		angle_degrees = clock_angle

	if angle_degrees == int(angle_degrees):
		add_success("Fired a torpedo at angle %d degrees!" % int(angle_degrees))
	else:
		add_success("Fired a torpedo at angle %.2f degrees!" % angle_degrees)

	var torpedo_scene = load("res://scenes/torpedo.tscn")
	if torpedo_scene == null:
		add_error("Torpedo scene not found at res://scenes/torpedo.tscn!")
		return

	var torpedo_instance = torpedo_scene.instantiate()
	torpedo_instance.position = player.position
	torpedo_instance.rotation_degrees = angle_degrees - 90.0

	if torpedo_instance.has_method("set_launch_angle"):
		torpedo_instance.set_launch_angle(angle_degrees)

	get_parent().add_child(torpedo_instance)


# ----------------------------------------------------------------------------
#                    MISSION COMMAND
# ----------------------------------------------------------------------------
func handle_mission_command() -> void:
	# 1) If no Black Box:
	if not inventory.has("Black Box"):
		add_success("""Current Mission:
  1) Recover the Black Box.
  2) Collect resources:
	 - 14 Quarz
	 - 7 Magnetite
	 - 7 Phosphat
	 - 8 Platinum
	 - 8 Rhodium
""")
		return

	# 2) If Black Box but incomplete resources:
	if not check_resources_collected():
		add_success("""Current Mission:
  Black Box recovered.
  Still need enough resources:
	- 14 Quarz
	- 7 Magnetite
	- 7 Phosphat
	- 8 Platinum
	- 8 Rhodium
	
Once you have all, head to (945, -200) — End Station.""")
		return

	# 3) If resources are all gathered too:
	add_success("All required items collected! Dock at End Station (945, -200) to complete the mission.")


# ----------------------------------------------------------------------------
#                     DOCK / UNDOCK
# ----------------------------------------------------------------------------
func handle_undock() -> void:
	if not is_docked:
		add_error("Already undocked!")
		return
	is_docked = false
	commands_blocked = false
	add_success("Undocking complete. You are free to move.\nHint: 'sonar active/a' to see environment.")

func handle_dock() -> void:
	var station_node := _find_nearest_station()
	if station_node == null:
		add_error("No station nearby to dock!")
		return

	if station_node.is_start_station:
		add_error("You cannot dock to the start station again.")
		return

	if not _check_lines_alignment(station_node):
		add_error("Lines do not align! Move closer to the station.")
		return

	if station_node.is_end_station:
		if not inventory.has("Black Box"):
			add_error("You cannot dock yet. Black Box missing.")
			return
		if not check_resources_collected():
			add_error("You cannot dock. Required resources not yet collected.")
			return

		add_success("Docking complete. Initiating final briefing from HQ...")
		is_docked = true
		start_end_station_narrative()
	else:
		add_success("Docking complete. Submarine is now docked.")
		is_docked = true


func _find_nearest_station() -> Station:
	var stations = get_tree().get_nodes_in_group("StationGroup")
	var nearest_station: Station = null
	var nearest_dist = 999999.0

	for s in stations:
		if s is Station:
			var dist = s.global_position.distance_to(player.global_position)
			if dist < nearest_dist:
				nearest_station = s
				nearest_dist = dist

	return nearest_station


func _check_lines_alignment(station_node: Station) -> bool:
	var submarine_line_y = player.global_position.y - 7
	var station_line_y = station_node.global_position.y
	var threshold = station_node.docking_threshold
	var diff = abs(submarine_line_y - station_line_y)
	return diff <= threshold


# ----------------------------------------------------------------------------
#                 UTILITY & FORMAT
# ----------------------------------------------------------------------------
func update_default_speed_label() -> void:
	default_speed_label.text = "DEFAULT SPEED: %d%%" % int(default_speed_percent)

func check_speed_value(speed_val: float) -> float:
	if speed_val > 100:
		add_error("Speed cannot exceed 100%. Set to 100%.")
		return 100.0
	if speed_val < 0:
		add_error("Speed cannot be negative. Set to 0%.")
		return 0.0
	return speed_val

func parse_clock_input(input: float) -> float:
	var hours = int(input)
	var decimal = input - float(hours)
	var minutes = int(round(decimal * 100))

	if hours < 0 or hours > 12:
		add_error("Hour must be between 0 and 12.")
		return -1.0
	if hours == 0:
		hours = 12
	if minutes >= 60:
		add_error("Minutes must be less than 60. You entered: %d" % minutes)
		return -1.0

	# each hour is 30°, each minute is 0.5°
	return float((hours % 12) * 30) + float(minutes) * 0.5
