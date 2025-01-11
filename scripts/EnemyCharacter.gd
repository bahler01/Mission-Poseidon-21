extends CharacterBody2D

@export var max_hp: int = 100
var current_hp: int

@export var move_speed: float = 50.0

func _ready() -> void:
	current_hp = max_hp

func _physics_process(_delta: float) -> void:
	# Сброс вектора перед каждым кадром
	var temp_vel = Vector2.ZERO
	
	# Допустим, враг ходит влево
	temp_vel.x = -move_speed

	# Присваиваем temp_vel встроенной переменной velocity
	self.velocity = temp_vel
	
	# Вызываем move_and_slide() БЕЗ параметров
	move_and_slide()

func take_damage(amount: float) -> void:
	current_hp -= int(amount)
	print("Enemy took ", amount, " damage, HP = ", current_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	queue_free()
