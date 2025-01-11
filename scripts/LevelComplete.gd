extends Control

func _ready() -> void:
	# For example, connect signals via code or from the Editor
	$VBoxContainer/ButtonNextLevel.connect("pressed", Callable(self, "_on_button_next_level_pressed"))
	$VBoxContainer/ButtonExitMenu.connect("pressed", Callable(self, "_on_button_exit_menu_pressed"))
	$VBoxContainer/ButtonRestartLevel.connect("pressed", Callable(self, "_on_button_restart_level_pressed"))



func _on_button_next_level_pressed() -> void:
	# Load the next level scene:
	pass

func _on_button_exit_menu_pressed() -> void:
	# Suppose your main menu is "res://scenes/MainMenu.tscn"
	pass

func _on_button_restart_level_pressed() -> void:
	# If you store the current level path in a global or something, you can just reload it
	get_tree().change_scene_to_file("res://scenes/main.tscn")
