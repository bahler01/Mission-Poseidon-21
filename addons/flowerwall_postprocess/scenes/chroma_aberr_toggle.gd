extends Button
@export var mytext:Label

func _ready() -> void:
	connect("toggled", flowerwall_pp_autoload._on_chromatic_aberration_enabled)
	connect("toggled", _on_value_changed)
	button_pressed = flowerwall_pp_autoload.crt_shader.get("shader_parameter/enable_chromatic_aberration")
	mytext.text = str(button_pressed)
	
func _on_value_changed(a: bool) -> void:
	mytext.text = str(a)
