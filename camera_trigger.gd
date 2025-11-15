## A trigger zone that controls the MainCamera's behavior.
## This is the primary tool for cinematic 2.5D camera control.
@tool
@icon("res://addons/cinematic_camera/icon.svg")
class_name CameraTrigger
extends Area3D

# --- Enum for Trigger Modes ---
## Defines the primary behavior of this trigger.
enum TriggerMode {
	SIMPLE_FOLLOW,
	FIXED_POSITION,
	PATH_TRACKING, 
	REVERT_TO_DEFAULT
}

# --- EXPORT VARIABLES ---
## --- MODE 0: ON START ---
@export_group("Mode 0: On Start")
## If true, this trigger will apply its settings the moment the game loads.
## (Use for cinematic opening shots).
@export var set_on_start: bool = false

# --- CAMERA SETTINGS ---
@export_group("Camera Settings")
## (Click to find and assign the node in the 'main_camera' group)
@export var auto_find_main_camera: bool = false:
	set = _auto_find_main_camera
## Tells the trigger which MainCamera node to control.
## Must be assigned, or use 'Auto Find Main Camera'.
@export var main_camera: Camera3D
## New follow speed the camera should use when entering this zone.
@export var new_follow_speed: float = 2.0
## The visual and collision size of the trigger box.
@export var trigger_size: Vector3 = Vector3(5, 3, 5): set = _set_trigger_size, get = _get_trigger_size

# --- Trigger Mode ---
@export_group("Trigger Mode")
## Defines the primary behavior of this trigger.
@export var trigger_mode: TriggerMode = TriggerMode.SIMPLE_FOLLOW:
	set(value):
		trigger_mode = value
		# Triggers color change and UI refresh when the mode is switched.
		call_deferred("_set_gizmo_color")
		call_deferred("_update_mode_description") 
		notify_property_list_changed() 

## (Read-Only) A description of the selected Trigger Mode.
@export_multiline var mode_description: String 

# --- Mode 1: Simple Follow (Conditional) ---
@export_group("Mode 1: Simple Follow", "mode_1_")
## The simple, static offset the camera will use.
@export var mode_1_new_camera_offset: Vector3 = Vector3(0, 4, 10)

# --- Mode 2: Fixed Position (Conditional) ---
@export_group("Mode 2: Fixed Position", "mode_2_")
## The Marker3D node the camera will move to and look from.
@export var mode_2_fixed_target: Node3D

# --- Mode 3: Path Tracking ---
@export_group("Mode 3: Path Tracking", "mode_3_")
## The Path3D node the camera will follow.
@export var mode_3_camera_path: NodePath
## The axis the PLAYER moves along (e.g., X-Axis for a left/right hallway).
@export var mode_3_player_track_axis: Vector3.Axis = Vector3.AXIS_X
## The player's world position where the camera path *starts* (0%).
@export var mode_3_player_track_start: float = 0.0
## The player's world position where the camera path *ends* (100%).
@export var mode_3_player_track_end: float = 20.0
## If true, the camera will always look at the player.
## If false, it will follow the path's rotation.
@export var mode_3_always_look_at_player: bool = true

# --- (Mode 4: Revert to Default has no properties) ---

# --- EDITOR-ONLY FUNCTIONALITY ---
func _enter_tree():
	if Engine.is_editor_hint():
		call_deferred("_create_shape_in_editor")
		call_deferred("_set_gizmo_color") 
		call_deferred("_update_mode_description")
		
func _create_shape_in_editor():
	if not Engine.is_editor_hint():
		return
	
	var shape_node = find_child("CSG_Shape_Gizmo", false) 
	
	if not shape_node:
		print("CameraTrigger: Creating CSG_Shape_Gizmo for visualization.")
		
		var new_shape = CSGBox3D.new()
		new_shape.name = "CSG_Shape_Gizmo" 
		
		new_shape.use_collision = false 
		new_shape.size = trigger_size 
		
		add_child(new_shape)
		new_shape.owner = get_tree().edited_scene_root

func _set_trigger_size(new_size: Vector3):
	trigger_size = new_size 

	if Engine.is_editor_hint():
		var shape = find_child("CSG_Shape_Gizmo", false)
		if is_instance_valid(shape) and shape is CSGBox3D:
			shape.size = new_size
			update_configuration_warnings()

func _get_trigger_size():
	if Engine.is_editor_hint():
		var shape = find_child("CSG_Shape_Gizmo", false)
		if is_instance_valid(shape) and shape is CSGBox3D:
			return shape.size
	
	return trigger_size

func _set_gizmo_color():
	var color_map = {
		TriggerMode.SIMPLE_FOLLOW: Color.html("#2EE07E"),  
		TriggerMode.FIXED_POSITION: Color.html("#E02E2E"),   
		TriggerMode.PATH_TRACKING: Color.html("#2E99E0"),
		TriggerMode.REVERT_TO_DEFAULT: Color.html("#E0D72E"), 
	}
	
	var shape = find_child("CSG_Shape_Gizmo", false)
	if not is_instance_valid(shape):
		return
		
	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color_map[trigger_mode] * Color(1, 1, 1, 0.3) 
	shape.material_override = material
	
	if Engine.is_editor_hint():
		update_configuration_warnings()

# --- CORE LOGIC ---
func _ready():
	body_entered.connect(_on_body_entered)
	
	var shape = find_child("CSG_Shape_Gizmo", false)
	if not Engine.is_editor_hint() and is_instance_valid(shape):
		shape.visible = false
	
	if not Engine.is_editor_hint() and set_on_start:
		await get_tree().physics_frame
		apply_trigger_logic()

func _on_body_entered(body):
	if body.is_in_group("player"):
		apply_trigger_logic()
		
## Checks this trigger's settings and applies them to the MainCamera.
func apply_trigger_logic():
	if not is_instance_valid(main_camera):
		push_warning("CameraTrigger: Main Camera not assigned!")
		return
	
	match trigger_mode:
		TriggerMode.SIMPLE_FOLLOW:
			main_camera.set_follow_target(mode_1_new_camera_offset, new_follow_speed)
		
		TriggerMode.FIXED_POSITION:
			if is_instance_valid(mode_2_fixed_target):
				main_camera.set_fixed_target(mode_2_fixed_target, new_follow_speed)
			else:
				push_warning("CameraTrigger: 'Fixed Target' is not valid!")
		
		TriggerMode.PATH_TRACKING:
			# Get the actual Path3D node from the NodePath
			var path_node = get_node_or_null(mode_3_camera_path)
			if is_instance_valid(path_node) and path_node is Path3D:
				# Bundle all the Mode 3 data into a dictionary to send
				var path_data = {
					"path_node": path_node,
					"track_axis": mode_3_player_track_axis,
					"track_start": mode_3_player_track_start,
					"track_end": mode_3_player_track_end,
					"look_at_player": mode_3_always_look_at_player
				}
				main_camera.set_path_target(path_data, new_follow_speed)
			else:
				push_warning("CameraTrigger: Path Tracking mode is missing a valid Path3D node.")
			
		TriggerMode.REVERT_TO_DEFAULT:
			main_camera.revert_to_default()

# --- EDITOR HELPER FUNCTIONS ---
func _auto_find_main_camera(value: bool):
	if Engine.is_editor_hint():
		var cam = get_tree().get_first_node_in_group("main_camera")
		if is_instance_valid(cam) and cam is Camera3D:
			main_camera = cam
			print_verbose("Cinematic Camera Plugin: Found and assigned Main Camera: " + cam.name)
			notify_property_list_changed()
		else:
			push_warning("CameraTrigger: Could not find node in 'main_camera' group.")

func _get_editor_viewport_camera():
	var viewport = get_viewport()
	if is_instance_valid(viewport):
		return viewport.get_camera_3d()
	return null

## Updates the 'mode_description' text box based on the current 'trigger_mode'.
func _update_mode_description():
	match trigger_mode:
		TriggerMode.SIMPLE_FOLLOW:
			mode_description = "SIMPLE_FOLLOW:\nSets the camera to a new, static offset (e.g., higher, further) relative to the player. Good for side-scrolling or top-down sections."
		TriggerMode.FIXED_POSITION:
			mode_description = "FIXED_POSITION:\nLocks the camera to a specific point in the world (defined by a Marker3D). The camera will not follow the player. Ideal for establishing shots or 'security camera' POVs."
		TriggerMode.PATH_TRACKING:
			mode_description = "PATH_TRACKING:\nLinks the camera's position on a Path3D to the player's movement on a single axis. The camera's progress (0-100%) is tied to the player's position on that axis. Perfect for complex, cinematic 2.5D tracking shots."
		TriggerMode.REVERT_TO_DEFAULT:
			mode_description = "REVERT_TO_DEFAULT:\nResets the camera to its original 'Simple Follow' settings (the 'camera_offset' and 'follow_speed' set on the MainCamera node). Use this to end a fixed shot or path."
	
	# This ensures the inspector updates if the script is loaded
	if Engine.is_editor_hint():
		notify_property_list_changed()

# --- EDITOR WARNINGS ---
func _get_configuration_warnings():
	var warnings = PackedStringArray() 
	
	if not is_instance_valid(main_camera):
		warnings.append("A 'Main Camera' must be assigned.")
	
	match trigger_mode:
		TriggerMode.FIXED_POSITION:
			if not is_instance_valid(mode_2_fixed_target):
				warnings.append("Trigger is in 'Fixed Position' mode, but no 'Fixed Target' is assigned.")
		TriggerMode.PATH_TRACKING:
			var path_node = get_node_or_null(mode_3_camera_path)
			if not is_instance_valid(path_node) or not path_node is Path3D:
				warnings.append("Trigger is in 'Path Tracking' mode, but no 'Camera Path' is assigned.")
			if mode_3_player_track_start == mode_3_player_track_end:
				warnings.append("Dynamic Zone: 'Player Track Start' and 'End' are the same. Camera will not move.")
	
	return warnings

# --- PROPERTY HIDING & VALIDATION ---
func _validate_property(property: Dictionary):
	if property.name == "mode_description":
		property.usage |= PROPERTY_USAGE_READ_ONLY # Makes the text box read-only
	
	if property.name == "trigger_mode":
		call_deferred("_set_gizmo_color")
	elif property.name == "trigger_size":
		_set_trigger_size(trigger_size)

	var name: String = property.name
	var show_property = true
	
	if name.begins_with("mode_1_"):
		if trigger_mode != TriggerMode.SIMPLE_FOLLOW:
			show_property = false
	elif name.begins_with("mode_2_"):
		if trigger_mode != TriggerMode.FIXED_POSITION:
			show_property = false
	elif name.begins_with("mode_3_"):
		if trigger_mode != TriggerMode.PATH_TRACKING:
			show_property = false

	if not show_property:
		property.usage = PROPERTY_USAGE_NO_EDITOR
