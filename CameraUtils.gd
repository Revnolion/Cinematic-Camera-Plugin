# CameraUtils.gd
# This script will hold shared logic used by the Camera and Triggers.
extends Node

# Example: Move an editor helper function here.
func auto_find_main_camera_util(node_reference: Camera3D):
	if Engine.is_editor_hint():
		var cam = get_tree().get_first_node_in_group("main_camera")
		if is_instance_valid(cam) and cam is Camera3D:
			node_reference = cam
			return true
	return false
