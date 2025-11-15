# Makes the script run in the editor
@tool
extends EditorPlugin

# Remember original color
var original_debug_color

# --- V2.4 PLUGIN PANEL VARIABLES ---
var main_panel: Control
var results_label: RichTextLabel
var diagnosis_button: Button

## If true, shows the 3D world axis gizmo in all 3D viewports.
## Useful for aligning scenes with the world origin.
@export var show_world_axes_helper: bool = false:
	set = _set_show_world_axes_helper

# --- V2.4 PLUGIN SETUP ---
# Function is called when the plugin is enabled
func _enter_tree():
	# Define custom color (bright pink, 40% transparent)
	var new_color = Color(1.0, 0.0, 1.0, 0.4)
	var setting_path = "debug/shapes/collision/shape_color"
	
	# Get and STORE the original color
	original_debug_color = ProjectSettings.get_setting(setting_path)
	
	# Only change if it's not already the set color
	if original_debug_color != new_color:
		ProjectSettings.set_setting(setting_path, new_color)
		print_verbose("Cinematic Camera Plugin: Set debug shape color.")
	
	# V2.4: Create and add the custom bottom panel
	_create_plugin_panel()
	add_control_to_bottom_panel(main_panel, "Camera Setup")

# Function is called when plugin is disabled
func _exit_tree():
	# 1. Revert debug color
	var setting_path = "debug/shapes/collision/shape_color"
	if original_debug_color:
		ProjectSettings.set_setting(setting_path, original_debug_color)
		print_verbose("Cinematic Camera Plugin: Reverted debug shape color.")
	
	# 2. Remove V2.4 custom panel
	remove_control_from_bottom_panel(main_panel)
	main_panel.free()
	
	pass

# --- V2.4 UI CREATION LOGIC ---
func _create_plugin_panel():
	main_panel = VBoxContainer.new()
	main_panel.name = "CameraSetupPanel"
	
	# 1. Button Container
	var button_container = HBoxContainer.new()
	main_panel.add_child(button_container)
	
	# Diagnostic Button
	diagnosis_button = Button.new()
	diagnosis_button.text = "Run Scene Diagnosis (F5)"
	diagnosis_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagnosis_button.pressed.connect(_run_scene_diagnosis)
	button_container.add_child(diagnosis_button)

	# 2. Results Label
	results_label = RichTextLabel.new()
	results_label.text = "Press 'Run Scene Diagnosis' to check for missing dependencies."
	results_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_label.selection_enabled = true
	
	results_label.bbcode_enabled = true 
	
	main_panel.add_child(results_label)
	
	# Initial diagnosis on load
	call_deferred("_run_scene_diagnosis")

# --- V2.4 DIAGNOSTIC LOGIC ---
func _run_scene_diagnosis():
	if not Engine.is_editor_hint():
		return
	
	var text = ""
	var issues_found = 0
	
	# --- Title and Header ---
	text += "[center][color=white][font_size=24][b]SCENE DEPENDENCY DIAGNOSIS[/b][/font_size][/color][/center]\n\n"
	
	# --- Check 1: Main Camera Presence ---
	var main_camera = get_tree().get_first_node_in_group("main_camera")
	if is_instance_valid(main_camera):
		text += "[color=green]  ✅ [b]CORE[/b] SUCCESS:[/color] MainCamera node found in 'main_camera' group.\n"
	else:
		text += "[color=red]  ❌ [b]CORE[/b] ERROR:[/color] MainCamera not found. Add your camera to the 'main_camera' group.\n"
		issues_found += 1
	
	# --- Check 2: Player Presence & Group ---
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		text += "[color=green]  ✅ [b]CORE[/b] SUCCESS:[/color] Player node found in 'player' group.\n"
	else:
		text += "[color=red]  ❌ [b]CORE[/b] ERROR:[/color] Player node not found. Ensure your player is in the 'player' group.\n"
		issues_found += 1

	# --- Check 3: CameraTrigger Assignments ---
	var triggers = get_tree().get_nodes_in_group("camera_trigger")
	var unassigned_triggers = 0
	
	if triggers.is_empty():
		text += "\n[color=yellow]⚠️ [b]WARNING:[/b][/color] No CameraTrigger nodes found in scene.\n"
	else:
		for trigger in triggers:
			# NOTE: This check relies on the trigger having the 'camera_trigger.gd' script attached.
			# We check if the expected property (main_camera) is valid.
			if trigger.has_method("get_main_camera") and not is_instance_valid(trigger.main_camera):
				unassigned_triggers += 1
	
	if unassigned_triggers > 0:
		text += "\n[color=red]  ❌ [b]TRIGGER[/b] ERROR:[/color] [b]%d CameraTrigger nodes[/b] are missing a 'Main Camera' assignment.\n" % unassigned_triggers
		issues_found += 1
	elif not triggers.is_empty():
		text += "\n[color=green]  ✅ [b]TRIGGER[/b] SUCCESS:[/color] %d CameraTrigger nodes are assigned correctly.\n" % triggers.size()

	# --- Final Summary ---
	text += "\n\n[center][color=white]--[/color] [b]DIAGNOSIS COMPLETE[/b] [color=white]--[/color][/center]\n"
	if issues_found == 0:
		text += "[center][color=green][font_size=28]✅ SCENE READY[/font_size][/color][/center]"
	else:
		text += "[center][color=red][font_size=28]⚠️ %d ISSUES FOUND[/font_size][/color][/center]" % issues_found
	
	results_label.text = text

# --- CORE PLUGIN LOGIC ---

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
