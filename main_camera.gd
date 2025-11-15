# MainCamera.gd
extends Camera3D

# --- PUBLIC GETTER FUNCTIONS ---
func _get_current_target_offset():
	return current_target_offset
func _get_fixed_target_node_monitor():
	return fixed_target_node
func _get_is_in_path_mode():
	return is_in_path_mode

# --- EXPORT VARIABLES ---
## The Node3D the camera will follow. Must be in the 'player' group for triggers.
@export var player_target: Node3D
## If true, the camera will search the scene for a node in the 'player' group and assign it.
@export var auto_find_player: bool = false
## The default smoothing speed for the camera.
@export var follow_speed: float = 2.0
## The default 'Simple Follow' offset from the player.
@export var camera_offset: Vector3 = Vector3(0, 4, 10)
## The vertical offset from the player's origin to look at (e.g., 1.0 for torso).
@export var player_look_at_offset: Vector3 = Vector3(0, 1.0, 0)
## If true, displays the on-screen debug label at runtime.
@export var show_debug_info: bool = false

# --- DEBUG MONITOR EXPORTS ---
## (Read-only) Shows the current offset used for following the player.
@export var current_target_offset_monitor: Vector3:
	get = _get_current_target_offset
## (Read-only) Shows the Node3D the camera is currently locked to.
@export var fixed_target_node_monitor: Node3D:
	get = _get_fixed_target_node_monitor
## (Read-only) Shows if the camera is currently executing Path Tracking mode.
@export var is_in_path_mode_monitor: bool = false:
	get = _get_is_in_path_mode

# --- TRANSITION/BLEND VARIABLES (V2.5) ---
var blend_duration: float = 0.8  # Default blend time for mode transitions
var blend_time: float = 0.0      # Current elapsed time since blend started
var blending: bool = false
var blend_start_transform: Transform3D

# --- CAMERA SHAKE VARIABLES (V2.5) ---
var shake_noise: FastNoiseLite = FastNoiseLite.new()
var shake_time: float = 0.0
var current_shake_intensity: float = 0.0
var shake_duration: float = 0.0

# --- PRIVATE VARIABLES ---
var current_target_offset: Vector3
var current_follow_speed: float
var fixed_target_node: Node3D = null

# --- NEW PATH MODE VARIABLES ---
var is_in_path_mode: bool = false
var path_data: Dictionary = {}
var path_curve: Curve3D = null # Store the curve for speed
var path_node: Path3D = null # Store the path node

# --- DEBUGGING VARIABLES ---
var default_offset: Vector3
var default_speed: float
var debug_label: Label = null

func _ready():
	
	# V2.3: AUTO-FIND PLAYER LOGIC 
	if auto_find_player and not is_instance_valid(player_target) and not Engine.is_editor_hint():
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player is Node3D:
			player_target = player
		else:
			push_warning("MainCamera: Auto-find player failed. Check if a node is in the 'player' group.")
	
	if not Engine.is_editor_hint() and not is_instance_valid(player_target):
		push_warning("MainCamera: 'Player Target' is not assigned. Camera will not function.")
		
	default_offset = camera_offset
	default_speed = follow_speed
	current_target_offset = default_offset
	current_follow_speed = default_speed

	if show_debug_info and not Engine.is_editor_hint():
		var canvas = CanvasLayer.new()
		add_child(canvas)
		debug_label = Label.new()
		debug_label.position = Vector2(10, 10)
		canvas.add_child(debug_label)

## V2.5 Feature: Runs the visual shake effect at max frame rate.
func _process(delta):
	# Increment shake time (used to scroll the noise pattern)
	shake_time += delta
	
	if shake_duration > 0.0:
		# 1. Calculate Intensity Falloff: Reduces the shake over the duration
		var shake_falloff = 1.0 - (shake_time / shake_duration)
		
		# 2. Generate Noise Offset: Creates unique offsets for X and Y using the noise generator
		var noise_x = shake_noise.get_noise_1d(shake_time * 5.0) * current_shake_intensity * shake_falloff
		var noise_y = shake_noise.get_noise_1d(shake_time * 10.0) * current_shake_intensity * shake_falloff
		
		# 3. Apply the shake to the camera's local rotation
		rotation_degrees.x += noise_y * 0.5
		rotation_degrees.y += noise_x * 0.5
		
		# 4. Decrease duration
		shake_duration -= delta
		
		# Reset when done
		if shake_duration <= 0.0:
			rotation_degrees.x = 0
			rotation_degrees.y = 0

func _physics_process(delta):
	if not is_instance_valid(player_target):
		return
	
	var target_transform: Transform3D
	
	# --- 1. CAMERA LOGIC: Determine the target position (T2) ---
	if is_instance_valid(fixed_target_node):
		# MODE 2: Fixed
		var fixed_position = fixed_target_node.global_position
		target_transform = Transform3D(global_transform.basis, fixed_position)
		
	elif is_in_path_mode and is_instance_valid(path_curve):
		# --- MODE 3: PATH TRACKING ---
		
		var player_pos_on_axis = player_target.global_position[path_data.track_axis]
		
		# V2.3 Safety Check: Prevent Division by Zero
		var progress = 0.0
		var track_length = path_data.track_end - path_data.track_start
		
		if track_length != 0.0:
			progress = (player_pos_on_axis - path_data.track_start) / track_length
		
		progress = clamp(progress, 0.0, 1.0)
		
		var path_length = path_curve.get_baked_length()
		var camera_distance_on_path = progress * path_length
		
		var path_local_transform = path_curve.sample_baked_with_rotation(camera_distance_on_path, true, true)
		
		target_transform = path_node.global_transform * path_local_transform
	
	else:
		# MODE 1: Simple Follow
		var target_position = player_target.global_position + current_target_offset
		target_transform = Transform3D(global_transform.basis, target_position)
	
	# --- 2. DEBUG LABEL UPDATE ---
	if is_instance_valid(debug_label):
		var mode = "Simple Follow"
		if is_instance_valid(fixed_target_node):
			mode = "Fixed Position"
		elif is_in_path_mode:
			mode = "Path Tracking"
		
		debug_label.text = "Camera Debug:\n"
		debug_label.text += "Mode: %s\n" % mode
		debug_label.text += "Speed: %s" % current_follow_speed

	# --- 3. APPLY MOVEMENT: V2.5 CINEMATIC BLENDING ---
	if blending:
		blend_time += delta
		var blend_ratio = blend_time / blend_duration
		
		if blend_ratio >= 1.0:
			blending = false
			blend_ratio = 1.0
			
		# Apply cinematic ease (smoothstep)
		var eased_ratio = smoothstep(0.0, 1.0, blend_ratio)
		
		# Interpolate from the start position of the blend (blend_start_transform) 
		# toward the current calculated target (target_transform)
		global_transform = blend_start_transform.interpolate_with(target_transform, eased_ratio)
		
	else:
		# Smoothing Fallback (Runs if no blend is active)
		global_transform = global_transform.interpolate_with(target_transform, current_follow_speed * delta)
	
	# --- 4. APPLY AIMING ---
	if (is_in_path_mode and path_data.look_at_player) or not is_in_path_mode:
		look_at(player_target.global_position + player_look_at_offset)

# --- V2.5 BLEND HELPER FUNCTION ---
## V2.5 Feature: Initiates the cinematic blend. 
func _start_blend(new_duration: float = 0.8):
	# We capture the camera's current state (global_transform) to start the blend from.
	blend_start_transform = global_transform
	blend_duration = new_duration
	blend_time = 0.0
	blending = true

# --- PUBLIC FUNCTIONS ---

## V2.5 Public Function: Starts a procedural camera shake effect.
func start_shake(duration: float, intensity: float):
	shake_duration = duration
	current_shake_intensity = intensity
	shake_time = 0.0
	
	# Set noise properties for a good shake feel
	shake_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	shake_noise.frequency = 0.5

## Reverts the camera to its default offset and speed.
func revert_to_default():
	set_follow_target(default_offset, default_speed)
	_start_blend(0.8) # <-- V2.5 Blend Start

## Sets camera to "Simple Follow" mode.
func set_follow_target(new_offset: Vector3, new_speed: float):
	is_in_path_mode = false # Turn off path mode
	fixed_target_node = null
	
	current_target_offset = new_offset
	current_follow_speed = new_speed
	
	_start_blend(0.8) # <-- V2.5 Blend Start

## Sets camera to "Fixed Position" mode.
func set_fixed_target(new_target_node: Node3D, new_speed: float):
	is_in_path_mode = false # Turn off path mode
	fixed_target_node = new_target_node
	current_follow_speed = new_speed
	
	_start_blend(0.8) # <-- V2.5 Blend Start

## Sets camera to "Path Tracking" mode.
func set_path_target(data: Dictionary, new_speed: float):
	is_in_path_mode = true # Turn on path mode
	fixed_target_node = null
	
	path_data = data
	current_follow_speed = new_speed
	
	# Store the node and its curve for faster access in _physics_process
	path_node = data.path_node
	path_curve = path_node.curve
	
	_start_blend(0.8) # <-- V2.5 Blend Start
