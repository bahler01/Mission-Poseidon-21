extends RefCounted
class_name PingGrid

var cell_size: float
var grid: Dictionary = {}

func _init(p_cell_size: float) -> void:
	cell_size = p_cell_size

func get_cell_coords(pos: Vector2) -> Vector2i:
	var x = int(floor(pos.x / cell_size))
	var y = int(floor(pos.y / cell_size))
	return Vector2i(x, y)

func add_point(point):
	var cell_coords = get_cell_coords(point.position)
	var cell_key = [cell_coords.x, cell_coords.y]
	if not grid.has(cell_key):
		grid[cell_key] = []
	grid[cell_key].append(point)

func can_place_point(pos: Vector2, min_distance: float) -> bool:
	var cell_coords = get_cell_coords(pos)
	# Проверяем соседние ячейки, включая текущую
	for nx in range(cell_coords.x - 1, cell_coords.x + 2):
		for ny in range(cell_coords.y - 1, cell_coords.y + 2):
			var n_key = [nx, ny]
			if grid.has(n_key):
				for p in grid[n_key]:
					# Проверяем расстояние до каждой точки в соседних ячейках
					if p.position.distance_to(pos) < min_distance:
						return false
	return true
