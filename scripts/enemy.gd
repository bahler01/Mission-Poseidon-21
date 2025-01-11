extends Area2D

@export var max_hp: int = 100
var current_hp: int

func _ready() -> void:
	current_hp = max_hp
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))

func take_damage(amount: float) -> void:
	current_hp -= int(amount)
	print("Enemy took ", amount, " damage, HP = ", current_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	# Здесь можно добавить анимацию, звук и т.д.
	queue_free()

func _on_body_entered(_body: Node) -> void:
	# Если враг сам хочет реагировать на физ.столкновение
	# (но торпеда сама взрывается, так что в Enemy можно не делать explode())
	pass

func _on_area_entered(_area: Area2D) -> void:
	# Аналогично, если нужна реакция
	pass
