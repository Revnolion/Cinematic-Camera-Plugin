# 📜 Changelog / Update History

The following details the evolution and fixes applied to the Cinematic Camera plugin.

## v2.5.0 - Major Feature Consolidation

**Version Goal:** Implement and consolidate all advanced cinematic polish, dynamic control features, and the new setup diagnosis tool into a single, comprehensive release for maximum user confidence and stability.

**NOTE:** V2.4.0 was merged into this release due to additional features that were created for it. 

### New Features:
* **[Workflow] Scene Setup Checker:** Implemented a dedicated bottom panel diagnosis tool that scans the scene and instantly flags missing dependencies (e.g., Camera not in group, Triggers unassigned).
* **[Aesthetics] Event-Driven Camera Shake:** Added a system to apply procedural noise and physical feedback to the camera (for impacts, footsteps, explosions) via a simple function call.
* **[Control] Cinematic Blend Modes:** Allows designers to select non-linear easing types or custom curves for professional, smooth blending between camera modes.

---

## v2.3.1 - Stability Patch

**Version Goal:** Resolve all known runtime memory and scope issues discovered during the V2.3 implementation cycle.

### Fixes & Improvements:
* **[Code Cleanup]** Ensured the editor gizmo (`CSG_Shape_Gizmo`) is cleanly removed from memory at runtime (`queue_free()`) rather than just being hidden.
* **[Architecture]** Began the refactor foundation for a future foundational update by creating the `CameraUtils.gd` script, which will house global utility functions for better organization.

---

## v2.3 - Workflow Automation

**Version Goal:** Improve setup workflow and prevent camera lock-up errors by automating critical configuration steps.

### New Features:
* **[QOL] Auto-Set Path Bounds:** CameraTrigger now automatically detects the primary movement axis and calculates 'Player Track Start/End' values when a Path3D node is assigned. This eliminates the need for manual coordinate entry in Path Tracking mode.
* **[QOL] Auto-Find Player:** MainCamera can now automatically search the scene for a node in the 'player' group and assign it, simplifying the core setup process for new users.

### Fixes & Improvements:
* **[Stability Fix]** Implemented the `_exit_tree()` function in CameraTrigger to ensure the MainCamera always reverts to default settings if the trigger is deleted or removed mid-game, preventing a permanent camera lock-up.
* **[Code Fix]** Re-implemented missing getter and setter function definitions (`_get_trigger_size` / `_set_trigger_size`) in CameraTrigger to restore full functionality to the `Trigger Size` export property.
* **[Robustness]** Added a runtime check to guarantee the Auto-Find Main Camera logic runs correctly if enabled at startup.

---

## v2.22 - Editor Logging Polish
**Version Goal:** Ensure full logging consistency across all scripts by using `push_warning` for errors and `print_verbose` for non-critical setup information.

### Fixes & Improvements:
* **[Polish]** Consolidated logging: Replaced `print()` with `print_verbose()` for editor setup/teardown in `camera_plugin.gd` and successful `auto_find_main_camera` operations.
* **[Polish]** Ensured all error reporting is consistent by replacing `print()` with `push_warning()` for failed node lookups in `camera_trigger.gd`.

---

## v2.21 - Polish Patch
**Version Goal:** Final cleanup pass to prepare for public GitHub release.

### Fixes & Improvements:
* **[Code Cleanup]** Removed internal development comments and notes from all scripts for a clean public release.

---

## v2.2 - Polish & Stability
**Version Goal:** Add advanced quality-of-life (QOL) features, complete editor documentation, and implement critical runtime crash prevention.

### New Features:
* Added dynamic, read-only "Mode Description" in the CameraTrigger inspector to clearly explain what each mode does.
* Added "Player Look At Offset" to MainCamera to control the camera's aim point, removing a hard-coded value.

### Fixes & Improvements:
* **[CRITICAL FIX]** Added a division-by-zero check to Path Tracking mode. The game will no longer crash if "Player Track Start" and "Player Track End" are the same.
* **[Polish]** Replaced all `print()` errors with `push_warning()` for better visibility in the Godot debugger.
* **[Polish]** Added a `push_warning` if "Player Target" is not assigned on the MainCamera at runtime.
* **[Polish]** Polished tooltips across all scripts (MainCamera, CameraTrigger, camera_plugin) for better clarity.
* **[FIX]** Fixed a typo (`new_follow_spike`) that caused an error in Path Tracking mode.

---

## v2.1 - Intuitive Path Refactor
**Version Goal:** Simplify the core camera movement system by replacing the complex Dynamic Tracking mode with a user-friendly Path Tracking implementation.

### New Features:
* **Replaced Dynamic Tracking with Path Tracking (Mode 3):**
    * Removed the complex 8-property "Dynamic Tracking" mode.
    * Implemented a new, far more intuitive "Path Tracking" mode.
    * Designers now just assign a Path3D node to create smooth, curved, cinematic camera movements.
	* The camera can now follow the path's rotation or optionally continue to 'look_at' the player.
* **[Editor]** Updated Gizmo: The editor gizmo now draws a helper line to the start of the assigned Path3D.

### Fixes & Improvements:
* **[Code Cleanup]** Removed all helper functions and properties related to the old "Dynamic Tracking" mode.

---

## v2.001 (MINOR PATCH)
**Version Goal:** Address minor bugs and tooltip inconsistencies immediately following the larger v2.0 feature release.
### Fixes & Improvements:
* Minor bug fixes.
* Tooltip cleanup and adjustments.

---

## v2.0 - Architectural Completion & Final Stabilization
**Version Goal:** Integrate the first round of usability features (resizing, collision suppression) into the finalized architecture for stability.

### New Features:
* **[QOL]** Added 'Trigger Size' property to the parent node. Modifying this single property automatically scales the visual CSGBox3D size.

### Fixes & Improvements:
* **[FIX]** Added a dummy, invisible CollisionShape3D to suppress the base Area3D class warning.
* **[Code Cleanup]** Removed the problematic super._get_configuration_warnings() call.
* **[Polish]** Ensured CSGBox3D is created with use_collision = false by default.

---

## v1.9 - Visual Feedback & Workflow
**Version Goal:** Improve the visual fidelity and feedback provided to the user within the Godot editor.

### New Features:
* **[Editor]** Visual Mode Indicators: The zone box instantly changes color in the editor based on the selected 'Trigger Mode'.

### Fixes & Improvements:
* **[Structural Fix]** Switched collision/visual geometry from CollisionShape3D to CSGBox3D for better editor visualization and control.
* **[Debugging]** Stabilized the in-game debug label output.

---

## v1.8 - Core QOL Refactor
**Version Goal:** Begin the first phase of the workflow refactor by cleaning up the user interface.

### New Features:
* **[Editor]** Concise UI: Refactored properties using a single `trigger_mode` enum to hide/show irrelevant settings.
* **[Editor]** Added various editor helper buttons.

---

## v1.7 - Architectural Stability
**Version Goal:** Transition the system's boolean mode controls to a single, more stable enum system.

### Fixes & Improvements:
* **[Code Cleanup]** Converted all mode booleans to the new `trigger_mode` enum.
* **[Editor]** Implemented property validation (`_validate_property()`) to support the new concise UI.

---

## v1.6 - Feature Expansion
**Version Goal:** Add core functionality features (Set on Start, Revert) and establish a clear function for core logic handling.

**NOTE:** v1.5 was skipped and the planned changes were merged into this update.

### New Features:
* Added 'Set on Start' (Mode 0) and 'Revert to Default' (Mode 4).
* Added optional in-game debug label.

### Fixes & Improvements:
* **[Code Cleanup]** Refactored core trigger logic into a single `apply_trigger_logic()` function.

---

## v1.4 - Initial Stability Pass
**Version Goal:** Harden the setup process by ensuring critical components are automatically created and warnings are robust.

### Fixes & Improvements:
* **[Editor]** Implemented robust auto-creation of CollisionShape3D.
* **[Editor]** Hardened configuration warnings with `is_instance_valid()`.

---

## v1.3 - Plugin Stability
**Version Goal:** Add basic editor-side warnings and ensure clean plugin behavior upon being disabled.

### Fixes & Improvements:
* **[Editor]** Added in-editor configuration warnings.
* **[Editor]** Plugin now safely reverts the debug color when disabled.

---

## v1.22 - Documentation Pass
**Version Goal:** Complete initial user documentation pass for all scripts.

### Fixes & Improvements:
* **[Polish]** Enhanced all scripts with detailed comments and `##` tooltips.

---

## v1.2 - Polish
**Version Goal:** Establish basic editor integration features.

### New Features:
* **[Editor]** Implemented `class_name` to show descriptions and icons.

---

## v1.1 - Polish
**Version Goal:** Organize properties into logical user groups.

### New Features:
* **[Editor]** Organized properties into `@export_group` categories.

---

## v1.01 - Plugin Features
**Version Goal:** Add first visual feature.

### New Features:
* **[Editor]** Plugin automatically colors debug shapes.

---

## v1.0 - Initial Release
**Version Goal:** Establish the foundational code and structure.

### New Features:
* Initial release of the cinematic camera system.
