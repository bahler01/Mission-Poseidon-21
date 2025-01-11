extends Resource

# Stores the last base command that was processed.
var last_base_command: String = ""
# Stores the last sonar mode used.
var last_sonar_mode: String = ""
# Stores the arguments of the last 'move' command for future reference.
var last_move_args: Array = []  

# List of commands that expect numeric arguments.
const COMMANDS_WITH_NUMERIC_ARGS = [
	"move",
	"speed",
	"sonar",
	"drill",
	"attack"
]

# A dictionary mapping various command inputs and aliases to their recognized canonical form.
const RECOGNIZED_COMMANDS: Dictionary = {
	"help":       "help",
	"clear":      "clear",
	"stop":       "stop",
	"s":          "stop",
	"move":       "move",
	"m":          "move",
	"speed":      "speed",
	"sp":         "speed",
	"sonar":      "sonar",
	"drill":      "drill",
	"inv":        "inventory",
	"inventory":  "inventory",
	"attack":     "attack",
	"a":          "attack",
	"dock":       "dock",
	"undock":     "undock",
	"mission":    "mission"
}

# List of recognized sonar modes and their aliases.
var RECOGNIZED_SONAR_MODES: Array = [
	"active", "a",
	"passive", "p",
	"directed", "d",
	"off"
]

##
# Parses an input text command and returns a dictionary with the recognized command 
# and its arguments.
# 
# @param text The input command string from the user.
# @return A dictionary with keys "command" (String) and "args" (Array) representing 
#         the parsed command and its arguments.
##
func parse_command(text: String) -> Dictionary:
	# Split the input text into tokens by spaces after trimming edges.
	var tokens = text.strip_edges().split(" ", false)
	
	# If no tokens found, return empty command and arguments.
	if tokens.is_empty():
		return {"command": "", "args": []}

	# Convert the first token to lowercase for case-insensitive matching.
	var first_token = tokens[0].to_lower()

	# If the first token length > 1, not a number, and not a recognized command,
	# try to find the closest known command.
	if first_token.length() > 1 and not first_token.is_valid_float() and not RECOGNIZED_COMMANDS.has(first_token):
		var closest = _find_closest_command(first_token)
		if closest != "":
			first_token = closest

	# Check if the first token is a known command or alias.
	if RECOGNIZED_COMMANDS.has(first_token):
		# Map to the recognized canonical command.
		var recognized_cmd = RECOGNIZED_COMMANDS[first_token]
		# Slice out the arguments from the tokens.
		var args = tokens.slice(1, tokens.size())

		# If the command expects numeric arguments, store relevant data.
		if recognized_cmd in COMMANDS_WITH_NUMERIC_ARGS:
			last_base_command = recognized_cmd
			# Special handling for "move" command: store its arguments.
			if recognized_cmd == "move":
				last_move_args = args.duplicate()  # Save a copy of the arguments.
			# Special handling for "sonar" command: check for sonar mode.
			if recognized_cmd == "sonar" and args.size() > 0:
				var maybe_mode = args[0].to_lower()
				if maybe_mode in RECOGNIZED_SONAR_MODES:
					last_sonar_mode = maybe_mode
		else:
			# Reset sonar mode if the command is not related to numeric arguments.
			last_sonar_mode = ""

		# Return the recognized command and its arguments.
		return {"command": recognized_cmd, "args": args}

	# If all tokens are numeric, it might be a continuation of a previous command.
	if _is_all_numeric(tokens):
		# Special case for "move" command when expecting a new direction but reusing speed.
		if last_base_command == "move" and last_move_args.size() >= 2 and tokens.size() == 1:
			var new_direction = tokens[0]
			var current_speed = last_move_args[1]
			return {"command": "move", "args": [new_direction, current_speed]}
		
		# For other commands that accept numeric arguments.
		if last_base_command in COMMANDS_WITH_NUMERIC_ARGS:
			if last_base_command == "sonar":
				# If sonar mode was previously recognized, prepend it to numeric arguments.
				if last_sonar_mode != "":
					var numeric_args = Array(tokens)
					var sonar_args = [last_sonar_mode] + numeric_args
					return {"command": "sonar", "args": sonar_args}
				else:
					# If no mode was set, just pass numeric arguments.
					return {"command": "sonar", "args": tokens}
			else:
				return {"command": last_base_command, "args": tokens}
		else:
			return {"command": "", "args": []}

	# If command is not recognized and not purely numeric, return empty.
	return {"command": "", "args": []}


##
# Checks if all tokens in the array are numeric (valid floats).
# 
# @param tokens An array of string tokens.
# @return True if every token represents a valid float number, false otherwise.
##
func _is_all_numeric(tokens: Array) -> bool:
	for t in tokens:
		if not t.is_valid_float():
			return false
	return true


##
# Finds the closest recognized command to the given input using one-edit distance.
# 
# @param input_cmd The input command string to compare.
# @return The recognized command string if found, otherwise an empty string.
##
func _find_closest_command(input_cmd: String) -> String:
	for key in RECOGNIZED_COMMANDS.keys():
		if _is_one_edit_distance(input_cmd, key):
			return key
	return ""


##
# Checks if two strings are one edit (insert, remove, or substitute) away from each other.
# 
# @param s First string.
# @param t Second string.
# @return True if strings s and t are one edit distance apart, false otherwise.
##
func _is_one_edit_distance(s: String, t: String) -> bool:
	var len_s = s.length()
	var len_t = t.length()

	# If length difference is more than 1, cannot be one edit distance.
	if abs(len_s - len_t) > 1:
		return false

	var diff_count = 0
	var i = 0
	var j = 0

	# Iterate through both strings comparing characters.
	while i < len_s and j < len_t:
		if s[i] != t[j]:
			diff_count += 1
			# More than one difference means not one edit distance.
			if diff_count > 1:
				return false
			# Move pointers appropriately based on string lengths.
			if len_s > len_t:
				i += 1
			elif len_s < len_t:
				j += 1
			else:
				i += 1
				j += 1
		else:
			i += 1
			j += 1

	# Account for any extra characters at the end of either string.
	if i < len_s or j < len_t:
		diff_count += 1

	# Return true only if exactly one edit was found.
	return diff_count == 1
