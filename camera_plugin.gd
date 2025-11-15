# Makes the script run in the editor
@tool
extends EditorPlugin

# Remember original color
var original_debug_color

## Toggle ON to show world axes for scene setup.
@export var show_world_axes_helper: bool = false:
	set = _set_show_world_axes_helper

# Function is called when the plugin is enabled
func _enter_tree():
	
	# Define custom color (bright pink, 40% transparent)
	var new_color = Color(1.0, 0.0, 1.0, 0.4)
	# The internal name for the setting we want to change
	var setting_path = "debug/shapes/collision/shape_color"
	
	# Get and STORE the original color
	original_debug_color = ProjectSettings.get_setting(setting_path)
	
	# Only change if it's not already the set color
	if original_debug_color != new_color:
		ProjectSettings.set_setting(setting_path, new_color)
		print("Cinematic Camera Plugin: Set debug shape color.")

# Function is called when plugin is disabled
func _exit_tree():
	
	# Set color back to original color
	var setting_path = "debug/shapes/collision/shape_color"
	
	# Only revert if a color is stored
	if original_debug_color:
		ProjectSettings.set_setting(setting_path, original_debug_color)
		print("Cinematic Camera Plugin: Reverted debug shape color.")
		
	pass

## Setter function for the axis visibility toggle.
func _set_show_world_axes_helper(value: bool):
	show_world_axes_helper = value
	
	if Engine.is_editor_hint():
		# Get the active 3D viewport, not the root viewport
		var vp_3d = get_editor_interface().get_editor_viewport_3d()
		
		# Check if the 3D viewport is valid
		if is_instance_valid(vp_3d):
			vp_3d.set_setting("3d_gizmos/display/show_editor_axis", value)
			vp_3d.update_configuration_warnings()
