extends GridMap

@export var grid_size: int = 20
@export var hilliness: float = 0.20
var grid: Dictionary = {}
var spawn_order: Array[Vector2i] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate()
	
	
func generate() -> void:
	var start = Vector2i(randi() % grid_size, randi() % grid_size)
	_spawn_chain(start)
	
	while spawn_order.size() < grid_size * grid_size:
		var next_start = _find_block_with_free_neighbor()
		if next_start == null:
			break
		_spawn_chain(next_start)
	
	_build_grid()
			
func _get_random_free_neighbor(pos: Vector2i):
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	directions.shuffle()
	for dir in directions:
		var next = pos + dir
		if _is_valid(next) and next not in grid:
			return next
	return null 
	
func _find_block_with_free_neighbor():
	for pos in spawn_order:
		if _get_random_free_neighbor(pos) != null:
			return pos 
	return null
	
func _spawn_chain(start: Vector2i) -> void:
	if start not in grid:
		grid[start] = {"height": 0, "slope_dir": null}
		spawn_order.append(start)
	
	var current = start
	while true:
		var neighbor = _get_random_free_neighbor(current)
		if neighbor == null:
			break	
	
		var new_height = grid[current]["height"]
		var slope_dir = null
		
		if randf() < hilliness / 2.0:
			new_height += 1
			slope_dir = current - neighbor
	
		grid[neighbor] = {"height": new_height, "slope_dir": slope_dir}
		spawn_order.append(neighbor)
		current = neighbor 
	
	
	
func _is_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size
	

func _build_grid() -> void:
	for pos in grid:
		var data = grid[pos]
		var height = data["height"]
		var slope_dir = data["slope_dir"]
		
		for y in range(height ):
			set_cell_item(Vector3i(pos.x, y, pos.y), 0)

		if slope_dir != null:
			var orientation = _dir_to_orientation(slope_dir)
			set_cell_item(Vector3i(pos.x, height, pos.y), 1, orientation)
		else:
			set_cell_item(Vector3i(pos.x, height, pos.y), 0)
			
func _dir_to_orientation(dir: Vector2i) -> int:
	var angle = atan2(dir.y, dir.x)
	var basiss = Basis(Vector3.UP, -angle)
	return get_orthogonal_index_from_basis(basiss)

#extends Node3D
#
#@export var grid_size: int = 20
#@export var hilliness: float = 0.15  # 0.0 flat, 1.0 mountain
#@export var block_scene: PackedScene
#@export var slope_scene: PackedScene
#
#var grid: Dictionary = {}  # Vector2i -> height
#var spawn_order: Array[Vector2i] = []
#
#func generate():
	#var start = Vector2i(randi() % grid_size, randi() % grid_size)
	#_spawn_chain(start)
	#
	## find next chain start
	#while spawn_order.size() < grid_size * grid_size:
		#var next_start = _find_block_with_free_neighbor()
		#if next_start == null:
			#break
		#var neighbor = _get_random_free_neighbor(next_start)
		#if neighbor != null:
			#grid[neighbor] = grid[next_start]  # same height as chain start
			#spawn_order.append(neighbor)
			#_spawn_chain(neighbor)
	#
	#_build_meshes()
#
#func _spawn_chain(start: Vector2i):
	#if start not in grid:
		#grid[start] = 0
		#spawn_order.append(start)
	#
	#var current = start
	#while true:
		#var neighbor = _get_random_free_neighbor(current)
		#if neighbor == null:
			#break
		#
		## randomly raise elevation
		#var new_height = grid[current]
		#var is_slope = false
		#if randf() < hilliness / 2.0:
			#new_height += 1
			#is_slope = true
		#
		#grid[neighbor] = new_height
		#spawn_order.append(neighbor)
		#current = neighbor
#
#func _get_random_free_neighbor(pos: Vector2i):
	#var directions = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	#directions.shuffle()
	#for dir in directions:
		#var next = pos + dir
		#if _is_valid(next) and next not in grid:
			#return next
	#return null
#
#func _find_block_with_free_neighbor():
	#for pos in spawn_order:
		#if _get_random_free_neighbor(pos) != null:
			#return pos
	#return null
#
#func _is_valid(pos: Vector2i) -> bool:
	#return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size
#
#func _build_meshes():
	#for pos in grid:
		#var height = grid[pos]
		## spawn block at (pos.x, height, pos.y)
		## spawn additional blocks below to fill gaps if height > 0
		#for y in range(height + 1):
			#var block = block_scene.instantiate()
			#add_child(block)
			#block.position = Vector3(pos.x, y, pos.y)
