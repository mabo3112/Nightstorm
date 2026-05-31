class_name ZombieLowLevelServer extends Node3D

const MAX_ENEMIES: int = 10000 
const CELL_SIZE: float = 3.0
const SEPARATION_RADIUS_SQ: float = 0.64 # 0.8m diameter squared (capsule radius * 2)
const MAX_SEPARATION_CHECKS: int = 4 # Kept low for extreme performance
@export var speed: float = 5.0

# Pure Data Arrays (No Physics RIDs)
var positions: Array[Vector3] = [] 
var is_dead: Array[bool] = []
var grid: Dictionary = {}

# MultiMesh RIDs
var multimesh_instance: RID
var multimesh_base: RID

var scenario: RID
var space: RID
var mesh_rid: RID

var player: CharacterBody3D
var multimesh_buffer := PackedFloat32Array()

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	scenario = get_world_3d().scenario
	space = get_world_3d().space
	add_to_group("zombie_manager")
	
	mesh_rid = preload("uid://0umfr34n4wrw").get_rid()
	
	positions.resize(MAX_ENEMIES) 
	is_dead.resize(MAX_ENEMIES)
	multimesh_buffer.resize(MAX_ENEMIES * 12)
	
	# Initialize Low-Level MultiMesh
	multimesh_base = RenderingServer.multimesh_create()
	RenderingServer.multimesh_allocate_data(multimesh_base, MAX_ENEMIES, RenderingServer.MULTIMESH_TRANSFORM_3D)
	RenderingServer.multimesh_set_mesh(multimesh_base, mesh_rid)
	
	multimesh_instance = RenderingServer.instance_create()
	RenderingServer.instance_set_base(multimesh_instance, multimesh_base)
	RenderingServer.instance_set_scenario(multimesh_instance, scenario)
	
	# Square Grid Spawn Layout
	var grid_side: int = ceili(sqrt(MAX_ENEMIES))
	var spacing: float = 1.5 
	var half_grid_width: float = (grid_side - 1) * spacing * 0.5
	var spawned_count: int = 0
	
	for x in grid_side:
		for z in grid_side:
			if spawned_count >= MAX_ENEMIES: break
				
			# Spawn flat on the y-plane (or snap to floor height immediately)
			var pos = Vector3((x * spacing) - half_grid_width, 0.0, (z * spacing) - half_grid_width)
			
			positions[spawned_count] = pos 
			is_dead[spawned_count] = false
			
			_write_transform_to_buffer(spawned_count, Transform3D(Basis(), pos))
			spawned_count += 1
		if spawned_count >= MAX_ENEMIES: break

	RenderingServer.multimesh_set_buffer(multimesh_base, multimesh_buffer)

func _process(delta: float) -> void:
	if not player: return
	var player_pos = player.global_position
	
	# Local variable caching for extreme loop acceleration
	var local_positions = positions
	var local_is_dead = is_dead
	var local_grid = grid
	var c_size = CELL_SIZE
	
	# --- STEP 1: REBUILD THE CUSTOM SPATIAL HASH GRID ---
	local_grid.clear()
	for i in MAX_ENEMIES:
		if local_is_dead[i]: continue
		var pos = local_positions[i]
		var cell_key = Vector2i(floori(pos.x / c_size), floori(pos.z / c_size))
		if not local_grid.has(cell_key):
			local_grid[cell_key] = []
		local_grid[cell_key].append(i)
		
	# --- STEP 2: POSITION STEERING & SEPARATION PASS ---
	var radius_sq = SEPARATION_RADIUS_SQ
	var radius = 0.8 # Push boundary diameter
	
	for i in MAX_ENEMIES:
		if local_is_dead[i]: continue
		
		var pos_i = local_positions[i]
		var dir_to_player = (player_pos - pos_i).normalized()
		
		# Find neighbor keys
		var center_cell = Vector2i(floori(pos_i.x / c_size), floori(pos_i.z / c_size))
		var separation_force := Vector3.ZERO
		var checks_count := 0
		
		# Inner grid neighborhood lookup loops
		for x_offset in range(-1, 2):
			for z_offset in range(-1, 2):
				var neighbor_cell = center_cell + Vector2i(x_offset, z_offset)
				if not local_grid.has(neighbor_cell): continue
				
				var cell_members = local_grid[neighbor_cell]
				for j in cell_members:
					if i == j: continue
					
					var to_neighbor = pos_i - local_positions[j]
					var dist_sq = to_neighbor.length_squared()
					
					if dist_sq < radius_sq and dist_sq > 0.0001:
						var dist = sqrt(dist_sq)
						separation_force += (to_neighbor / dist) * (radius - dist)
						checks_count += 1
						if checks_count >= MAX_SEPARATION_CHECKS: break
				if checks_count >= MAX_SEPARATION_CHECKS: break
		
		# Combine target steering vector with crowd separation push values
		var final_dir = (dir_to_player + separation_force * 2.5).normalized()
		
		# Apply movement translation directly to coordinates
		var new_pos = pos_i + (final_dir * speed * delta)
		
		# --- OPTIONAL OPTIMIZATION LAYER: HEIGHT MAP SNAP ---
		# If your map floor isn't perfectly flat at Y=0, you can sample its Y height here
		# e.g., new_pos.y = terrain_system.get_height_at(new_pos.x, new_pos.z)
		new_pos.y = 0.0 # Set flat for standard grid testing
		
		local_positions[i] = new_pos
		
		# --- STEP 3: CONSTRUCT TRANSFORMS FOR MULTIMESH BUFFER ---
		var flat_move = Vector3(dir_to_player.x, 0, dir_to_player.z)
		if flat_move.length_squared() > 0.001:
			var visual_t = Transform3D(Basis().looking_at(-flat_move.normalized(), Vector3.UP), new_pos)
			_write_transform_to_buffer(i, visual_t)
		else:
			_write_transform_to_buffer(i, Transform3D(Basis(), new_pos))

	# Flush entire positional chunk data array into VRAM instantly
	RenderingServer.multimesh_set_buffer(multimesh_base, multimesh_buffer)

# Fast Packing: Transforms packed sequentially into native float blocks
func _write_transform_to_buffer(idx: int, t: Transform3D) -> void:
	var offset: int = idx * 12
	var b = t.basis
	var o = t.origin
	
	multimesh_buffer[offset]     = b.x.x
	multimesh_buffer[offset + 1] = b.y.x
	multimesh_buffer[offset + 2] = b.z.x
	multimesh_buffer[offset + 3] = o.x
	multimesh_buffer[offset + 4] = b.x.y
	multimesh_buffer[offset + 5] = b.y.y
	multimesh_buffer[offset + 6] = b.z.y
	multimesh_buffer[offset + 7] = o.y
	multimesh_buffer[offset + 8] = b.x.z
	multimesh_buffer[offset + 9] = b.y.z
	multimesh_buffer[offset + 10] = b.z.z
	multimesh_buffer[offset + 11] = o.z

# --- PUBLIC HELPER METHODS ---
func get_positions() -> Array[Vector3]:
	return positions
	
func _get_position(index: int) -> Vector3:
	return positions[index] + Vector3(0, 1.0, 0)

func get_nearest_enemy(from: Vector3) -> int:
	var nearest_index: int = -1
	var nearest_dist_sq: float = INF
	var local_positions = positions
	var local_is_dead = is_dead
	
	for i in MAX_ENEMIES:
		if local_is_dead[i]: continue
		var dist_sq = from.distance_squared_to(local_positions[i])
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest_index = i
	return nearest_index

func damage_enemy(index: int, amount: float) -> void:
	if is_dead[index]: return
	kill_enemy(index)

func kill_enemy(index: int) -> void:
	is_dead[index] = true
	if GameManager.has_method("enemy_count_change"):
		GameManager.enemy_count_change(-1)
	_write_transform_to_buffer(index, Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -1000, 0)))

func _exit_tree() -> void:
	if multimesh_instance.is_valid(): RenderingServer.free_rid(multimesh_instance)
	if multimesh_base.is_valid(): RenderingServer.free_rid(multimesh_base)


#second version:

#class_name ZombieLowLevelServer extends Node3D
#
#const MAX_ENEMIES: int = 5000
#@export var speed: float = 5.0
#
#var instances: Array[RID] = []
#var bodies: Array[RID] = []
#var positions: Array[Vector3] = [] 
#var is_dead: Array[bool] = []
#
#var scenario: RID
#var space: RID
#var mesh_rid: RID
#var shape_rid: RID
#
#var player: CharacterBody3D
#
#func _ready() -> void:
	#player = get_tree().get_first_node_in_group("player")
	#scenario = get_world_3d().scenario
	#space = get_world_3d().space
	#add_to_group("zombie_manager")
	#
	#mesh_rid = preload("uid://0umfr34n4wrw").get_rid()
	#shape_rid = PhysicsServer3D.capsule_shape_create()
	#PhysicsServer3D.shape_set_data(shape_rid, {"radius": 1.0, "height": 2.0})
	#
	#instances.resize(MAX_ENEMIES)
	#bodies.resize(MAX_ENEMIES)
	#positions.resize(MAX_ENEMIES) 
	#is_dead.resize(MAX_ENEMIES)
	#
	## --- NEW SQUARE GRID SPAWN CONFIGURATION ---
	## Calculate the size of the square grid side (e.g., for 1000 total zombies, side is ~31)
	#var grid_side: int = ceili(sqrt(MAX_ENEMIES))
	#var spacing: float = 5.0 # Total distance between each zombie in meters
	#
	## Center the square spawn group so it isn't offset from the manager node's origin
	#var half_grid_width: float = (grid_side - 1) * spacing * 0.5
	#
	#var spawned_count: int = 0
	#
	#for x in grid_side:
		#for z in grid_side:
			## Safety break in case your MAX_ENEMIES doesn't make a perfect square
			#if spawned_count >= MAX_ENEMIES:
				#break
				#
			## Compute individual coordinate positions based on loop indices
			#var pos_x: float = (x * spacing) - half_grid_width
			#var pos_z: float = (z * spacing) - half_grid_width
			#var pos = Vector3(pos_x, 3.0, pos_z)
			#
			## Visual Setup
			#var instance = RenderingServer.instance_create()
			#RenderingServer.instance_set_base(instance, mesh_rid)
			#RenderingServer.instance_set_scenario(instance, scenario)
			#RenderingServer.instance_set_transform(instance, Transform3D(Basis(), pos))
			#instances[spawned_count] = instance
			#
			## Rigid Body Setup
			#var body = PhysicsServer3D.body_create()
			#PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_RIGID)
			#
			#PhysicsServer3D.body_set_axis_lock(body, PhysicsServer3D.BODY_AXIS_ANGULAR_X, true)
			#PhysicsServer3D.body_set_axis_lock(body, PhysicsServer3D.BODY_AXIS_ANGULAR_Y, true)
			#PhysicsServer3D.body_set_axis_lock(body, PhysicsServer3D.BODY_AXIS_ANGULAR_Z, true)
			#
			#PhysicsServer3D.body_set_collision_layer(body, 1)
			#PhysicsServer3D.body_set_collision_mask(body, 1) 
			#PhysicsServer3D.body_add_shape(body, shape_rid)
			#PhysicsServer3D.body_set_space(body, space)
			#PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), pos))
			#
			## Hook up to your thread-safe physics callback
			#PhysicsServer3D.body_set_omit_force_integration(body, false)
			#PhysicsServer3D.body_set_force_integration_callback(body, _on_body_physics_update, spawned_count)
			#
			#bodies[spawned_count] = body
			#positions[spawned_count] = pos 
			#is_dead[spawned_count] = false
			#
			#spawned_count += 1
		#if spawned_count >= MAX_ENEMIES:
			#break
#
## --- RUNNING SAFELY ON THE MAIN/RENDER THREAD ---
#func _process(_delta: float) -> void:
	#if not player: return
	#var player_pos = player.global_position
	#
	## Cache locally for speed
	#var local_positions = positions
	#var local_instances = instances
	#var local_is_dead = is_dead
	#
	#for i in MAX_ENEMIES:
		#if local_is_dead[i]: continue
		#
		#var current_pos = local_positions[i]
		#var dir_to_player = (player_pos - current_pos).normalized()
		#var flat_move = Vector3(dir_to_player.x, 0, dir_to_player.z)
		#
		#if flat_move.length_squared() > 0.001:
			#var visual_pos = current_pos - Vector3(0, 0.8, 0)
			#var visual_t = Transform3D(Basis().looking_at(-flat_move.normalized(), Vector3.UP), visual_pos)
			#RenderingServer.instance_set_transform(local_instances[i], visual_t)
#
## --- RUNNING ISOLATED ON THE PHYSICS THREAD ---
#func _on_body_physics_update(body_state: PhysicsDirectBodyState3D, index: int) -> void:
	#if is_dead[index] or not player: 
		#return
		#
	#var current_transform: Transform3D = body_state.transform
	#var current_pos: Vector3 = current_transform.origin
	#
	## Pass the transform update over cleanly to our tracking array
	#positions[index] = current_pos
	#
	#var dir_to_player: Vector3 = (player.global_position - current_pos).normalized()
	#var current_vel = body_state.linear_velocity
	#
	## Inject velocities completely independent of the rendering loop
	#var target_vel = Vector3(dir_to_player.x * speed, current_vel.y, dir_to_player.z * speed)
	#body_state.linear_velocity = target_vel
#
## --- PUBLIC HELPER METHODS ---
#
#func get_positions() -> Array[Vector3]:
	#return positions
	#
#func _get_position(index: int) -> Vector3:
	#return positions[index] + Vector3(0, 2.0, 0)
#
#func get_nearest_enemy(from: Vector3) -> int:
	#var nearest_index: int = -1
	#var nearest_dist_sq: float = INF
	#
	#var local_positions = positions
	#var local_is_dead = is_dead
	#
	#for i in MAX_ENEMIES:
		#if local_is_dead[i]: continue
		#var dist_sq = from.distance_squared_to(local_positions[i] + Vector3(0, 2.0, 0))
		#if dist_sq < nearest_dist_sq:
			#nearest_dist_sq = dist_sq
			#nearest_index = i
	#
	#return nearest_index
#
## --- LIFECYCLE MANAGEMENT ---
#
#func damage_enemy(index: int, amount: float) -> void:
	#if is_dead[index]: return
	#kill_enemy(index)
#
#func kill_enemy(index: int) -> void:
	#is_dead[index] = true
	#if GameManager.has_method("enemy_count_change"):
		#GameManager.enemy_count_change(-1)
		#
	#var hidden_t = Transform3D(Basis(), Vector3(0, -1000, 0))
	#RenderingServer.instance_set_transform(instances[index], hidden_t)
	#PhysicsServer3D.body_set_space(bodies[index], RID())
#
#func _exit_tree() -> void:
	#for instance in instances:
		#if instance.is_valid(): RenderingServer.free_rid(instance)
	#for body in bodies:
		#if body.is_valid(): PhysicsServer3D.free_rid(body)
	#if shape_rid.is_valid(): PhysicsServer3D.free_rid(shape_rid)
	
	
#first version:	
	
#class_name ZombieManager extends Node3D
#
#const MAX_ENEMIES: int = 10000
#const CELL_SIZE: float = 4.0
#const SEPARATION_RADIUS_SQ: float = 4.0
#const MAX_SEPARATION_CHECKS: int = 10
#const HEIGHT: float = 4.0
#@export var speed: float = 5.0
#
#var instances: Array[RID] = []
#var bodies: Array[RID] = []
#var positions: Array[Vector3] = []
#var moves: Array[Vector3] = []
#var healths: Array[float] = []
#var is_dead: Array[bool] = []
#
#var grid: Dictionary = {}
#var scenario: RID
#var space: RID
#var mesh_rid: RID
#var shape_rid: RID
#
#var player: CharacterBody3D
#var frames: int = 0
#func _ready():
	#player = get_tree().get_first_node_in_group("player")
	#scenario = get_world_3d().scenario
	#space = get_world_3d().space
	#add_to_group("zombie_manager")
	## create shared mesh and shape (one for all enemies)
	#mesh_rid = preload("uid://0umfr34n4wrw").get_rid()
	#shape_rid = PhysicsServer3D.capsule_shape_create()
	#PhysicsServer3D.shape_set_data(shape_rid, {"radius": 0.4, "height": 1.6})
	#
	#for i in MAX_ENEMIES:
		#var angle = (float(i) / MAX_ENEMIES) * TAU
		#var pos = Vector3(cos(angle) * 20, 3, sin(angle) * 20)
		#
		## rendering
		#var instance = RenderingServer.instance_create()
		#RenderingServer.instance_set_base(instance, mesh_rid)
		#RenderingServer.instance_set_scenario(instance, scenario)
		#RenderingServer.instance_set_transform(instance, Transform3D(Basis(), pos))
		#instances.append(instance)
		#
		## physics
		#var body = PhysicsServer3D.body_create()
		#PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_KINEMATIC)
		#PhysicsServer3D.body_set_collision_layer(body, 1)
		#PhysicsServer3D.body_set_collision_mask(body, 1)
		#PhysicsServer3D.body_add_shape(body, shape_rid)
		#PhysicsServer3D.body_set_space(body, space)
		#var shape_count = PhysicsServer3D.body_get_shape_count(body)
		#PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), pos))
		#PhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_GRAVITY_SCALE, 1.0)
		#print("Body space: ", PhysicsServer3D.body_get_space(body))
		#print("Body shape: ", PhysicsServer3D.body_get_shape_count(body))
		#print("Body mode: ", PhysicsServer3D.body_get_mode(body))
		#print("Space: ", space)
		#bodies.append(body)
		#
		## data
		#positions.append(pos)
		#moves.append(Vector3.ZERO)
		#healths.append(100.0)
		#is_dead.append(false)
		#
#func _process(delta: float) -> void:
	#if frames < 400:
		#var t = PhysicsServer3D.body_get_state(bodies[0], PhysicsServer3D.BODY_STATE_TRANSFORM)
		#print("frame ", Engine.get_process_frames(), " y: ", t.origin.y)
		#frames += 1
	#var player_pos: Vector3 = player.global_position
	#
	#for i in MAX_ENEMIES:
		#if is_dead[i]:
			#continue
		#
		## read current position from physics engine
		#var t: Transform3D = PhysicsServer3D.body_get_state(bodies[i], PhysicsServer3D.BODY_STATE_TRANSFORM)
		#positions[i] = t.origin
		#
		#var dir: Vector3 = (player_pos - t.origin).normalized()
		#var current_vel = PhysicsServer3D.body_get_state(bodies[i], PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY)
		#var new_vel = Vector3(dir.x * speed, current_vel.y, dir.z * speed)
		## push toward player
		#PhysicsServer3D.body_set_state(bodies[i], PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, new_vel)
		#
		## update visual to match physics
		## update visual to match physics
		#var flat_move = Vector3(dir.x, 0, dir.z)  # ignore Y axis for rotation
		#if flat_move.length_squared() > 0.001:
			#var visual_pos = t.origin - Vector3(0, 0.8, 0)
			#var visual_t = Transform3D(Basis().looking_at(-flat_move.normalized(), Vector3.UP), visual_pos)
			#RenderingServer.instance_set_transform(instances[i], visual_t)
		#else:
			#RenderingServer.instance_set_transform(instances[i], Transform3D(Basis(), t.origin))
			#
#func damage_enemy(index: int, amount: float) -> void:
	#if is_dead[index]:
		#return
	#healths[index] -= amount
	#if healths[index] <= 0.0:
		#kill_enemy(index)
#
#func kill_enemy(index: int) -> void:
	#is_dead[index] = true
	#GameManager.enemy_count_change(-1)
	## hide far below world
	#var t = Transform3D(Basis(), Vector3(0, -1000, 0))
	#RenderingServer.instance_set_transform(instances[index], t)
	#PhysicsServer3D.body_set_state(bodies[index], PhysicsServer3D.BODY_STATE_TRANSFORM, t)
#
#func get_positions() -> Array[Vector3]:
	#return positions
	#
#func _get_position(index: int) -> Vector3:
	#return positions[index] + Vector3(0, 2.0, 0)
	#
#
#func get_nearest_enemy(from: Vector3) -> int:
	#var nearest_index: int = -1
	#var nearest_dist_sq: float = INF
	#
	#for i in MAX_ENEMIES:
		#if is_dead[i]:
			#continue
		#var dist_sq = from.distance_squared_to(positions[i] + Vector3(0, 2.0, 0))
		#if dist_sq < nearest_dist_sq:
			#nearest_dist_sq = dist_sq
			#nearest_index = i
	#
	#return nearest_index  # returns -1 if no enemies alive
#
#
#func _exit_tree():
	#for instance in instances:
		#RenderingServer.free_rid(instance)
	#for body in bodies:
		#PhysicsServer3D.free_rid(body)
	#PhysicsServer3D.free_rid(shape_rid)
