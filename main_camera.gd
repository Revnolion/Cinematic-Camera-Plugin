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

@export_group("1. Core Target Setup")
## The Node3D the camera will follow. Must be in the 'player' group for triggers.
@export var player_target: Node3D
# --- 
## If true, the camera will search the scene for a node in the 'player' group and assign it.
@export var auto_find_player: bool = false

## --- 
@export_group("2. Movement & Offset")
## The default smoothing speed for the camera.
@export var follow_speed: float = 2.0
# --- 
## The default 'Simple Follow' offset from the player.
@export var camera_offset: Vector3 = Vector3(0, 4, 10)
## --- 

@export_group("3. Camera Aim")
# --- 
## The vertical offset from the player's origin to look at (e.g., 1.0 for torso).
@export var player_look_at_offset: Vector3 = Vector3(0, 1.0, 0)

@export_group("4. Debugging & Monitoring")
# --- 
## If true, displays the on-screen debug label at runtime.
@export var show_debug_info: bool = false

# --- DEBUG MONITOR EXPORTS ---
## (Read-only) Shows the current offset used for following the player.
@export var current_target_offset_monitor: Vector3:
    get = _get_current_target_offset
# ---
## (Read-only) Shows the Node3D the camera is currently locked to.
@export var fixed_target_node_monitor: Node3D:
    get = _get_fixed_target_node_monitor
# ---
## (Read-only) Shows if the camera is currently executing Path Tracking mode.
@export var is_in_path_mode_monitor: bool = false:
    get = _get_is_in_path_mode

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

func _physics_process(delta):
    if not is_instance_valid(player_target):
        return
    
    var target_transform: Transform3D
    
    # --- CAMERA LOGIC (Runs in order of priority) ---
    if is_instance_valid(fixed_target_node):
        # MODE 2: Fixed
        var fixed_position = fixed_target_node.global_position
        target_transform = Transform3D(global_transform.basis, fixed_position)
        
    elif is_in_path_mode and is_instance_valid(path_curve):
        # --- MODE 3: PATH TRACKING ---
        
        # 1. Get player's position on the tracking axis
        var player_pos_on_axis = player_target.global_position[path_data.track_axis]
        
        # 2. Calculate the player's "progress" (a 0.0-1.0 value)
        var progress = 0.0 # Default to 0%
        var track_length = path_data.track_end - path_data.track_start
        
        # --- SAFETY CHECK ---
        # Only calculate progress if the track length is not zero
        if track_length != 0.0:
            progress = (player_pos_on_axis - path_data.track_start) / track_length
        
        progress = clamp(progress, 0.0, 1.0)
        
        # 3. Get total length of the camera's path
        var path_length = path_curve.get_baked_length()
        
        # 4. Find the position on the path that matches the player's progress
        var camera_distance_on_path = progress * path_length
        
        # 5. Get the 3D position (and rotation) from the curve
        # We get the full transform to handle path rotation
        var path_local_transform = path_curve.sample_baked_with_rotation(camera_distance_on_path, true, true)
        
        # 6. Convert the path's local transform to a global transform
        target_transform = path_node.global_transform * path_local_transform
    
    else:
        # MODE 1: Simple Follow
        var target_position = player_target.global_position + current_target_offset
        target_transform = Transform3D(global_transform.basis, target_position)
    
    # --- DEBUG LABEL ---
    if is_instance_valid(debug_label):
        var mode = "Simple Follow"
        if is_instance_valid(fixed_target_node):
            mode = "Fixed Position"
        elif is_in_path_mode:
            mode = "Path Tracking"
        
        debug_label.text = "Camera Debug:\n"
        debug_label.text += "Mode: %s\n" % mode
        debug_label.text += "Speed: %s" % current_follow_speed

    # --- SMOOTHING --- 
    global_transform = global_transform.interpolate_with(target_transform, current_follow_speed * delta)
    
    # --- AIMING ---
    # If we are in path mode AND 'always_look_at_player' is true, OR
    # if we are in any other non-path mode, look at the player.
    if (is_in_path_mode and path_data.look_at_player) or not is_in_path_mode:
        look_at(player_target.global_position + player_look_at_offset)
    # Otherwise, the camera will use the rotation from the path itself.

# --- PUBLIC FUNCTIONS ---

## Reverts the camera to its default offset and speed.
func revert_to_default():
    set_follow_target(default_offset, default_speed)

## Sets camera to "Simple Follow" mode.
func set_follow_target(new_offset: Vector3, new_speed: float):
    is_in_path_mode = false # Turn off path mode
    fixed_target_node = null
    
    current_target_offset = new_offset
    current_follow_speed = new_speed

## Sets camera to "Fixed Position" mode.
func set_fixed_target(new_target_node: Node3D, new_speed: float):
    is_in_path_mode = false # Turn off path mode
    fixed_target_node = new_target_node
    
    current_follow_speed = new_speed

## Sets camera to "Path Tracking" mode.
func set_path_target(data: Dictionary, new_speed: float):
    is_in_path_mode = true # Turn on path mode
    fixed_target_node = null
    
    path_data = data
    current_follow_speed = new_speed
    
    # Store the node and its curve for faster access in _physics_process
    path_node = data.path_node
    path_curve = path_node.curve
