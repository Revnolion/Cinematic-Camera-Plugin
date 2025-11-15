# Godot Cinematic Camera System
![Godot Version](https://img.shields.io/badge/Godot-4.x-blue?logo=godotengine)
![License](https://img.shields.io/badge/License-MIT-green)

A robust 2.5D cinematic camera solution for Godot 4.x, designed to achieve the dynamic, scale-focused perspective of games like *Little Nightmares*.

This plugin provides a `MainCamera` node and a `CameraTrigger` system that allows you to easily switch between camera behaviors (like fixed shots, path tracking, and simple following) as the player moves through your 3D environment.

![Example Screenshot](https://i.imgur.com/your-image-url.png) 
*(Optional: You can replace the URL above with a screenshot of your plugin in action after you upload one to GitHub or Imgur)*

## Key Features
* **5 Camera Modes**: Includes On Start, Simple Follow, Fixed Position, Path Tracking, and Revert to Default.
* **Intuitive Path Tracking**: Ditch complex math! Just assign a `Path3D` node to create smooth, curved, cinematic crane shots.
* **Concise UI**: The `CameraTrigger` uses conditional property validation to hide irrelevant settings and shows a dynamic description for each mode.
* **Workflow QOL**: Features an "Auto-Find Main Camera" button for one-click setup and a "Show World Axes" toggle in your plugin settings.
* **Stable & Safe**: Includes configuration warnings, runtime crash prevention, and better debug warnings.

---

## 💾 Installation

### Option 1: Install from GitHub
1.  Go to the **Releases** page of this repository.
2.  Download the latest release ZIP file.
3.  Extract the `addons/cinematic_camera` folder from the ZIP.
4.  Place this folder inside your project's `addons/` directory.

## Option 2: Install with Git
You can use Git to clone this repository directly into your `addons` folder:
```sh
git clone [https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git) res://addons/cinematic_camera'''

### Activation
After installing, you must **activate the plugin**:
1.  Go to **Project -> Project Settings -> Plugins**.
2.  Find **Cinematic Camera System** in the list.
3.  Check the **Enable** box.

---

## 🚀 How to Use

This system is split into two main parts: the `MainCamera` (the camera itself) and the `CameraTrigger` (the zones that control it).

### 1. The `MainCamera` Setup
This is your player's camera. You only need **one** in your scene.

1.  Add a `Camera3D` node to your scene and name it `MainCamera`.
2.  Attach the `main_camera.gd` script to it.
3.  In the Inspector, assign your **Player** node to the `Player Target` slot.
4.  (Optional) Add `MainCamera` to a group named `main_camera`. This lets triggers find it automatically.

### 2. The `CameraTrigger` Setup
`CameraTrigger` nodes are `Area3D` zones that change the camera's behavior when the player enters them.

1.  Add an `Area3D` node to your scene.
2.  Attach the `camera_trigger.gd` script to it.
3.  You will see a colored box in the editor. Use the **`Trigger Size`** property to resize it to fit your hallway, doorway, etc.
4.  In the Inspector, set the **`Trigger Mode`**.

### 3. Understanding the Trigger Modes

This is the core of the plugin. When you select a `Trigger Mode`, the inspector will update to show only the settings you need.

* **Mode 0: On Start**
    * If checked, this trigger's settings will be applied the moment the game loads. Use this on one trigger to set your opening camera shot.

* **Mode 1: Simple Follow**
    * This is the default follow mode. It tells the camera to follow the player using a new `Mode 1 New Camera Offset`. Good for top-down or side-scrolling sections.

* **Mode 2: Fixed Position**
    * Moves the camera to a fixed point in the world.
    * Create a `Marker3D` node in your scene and assign it to the `Mode 2 Fixed Target` slot. The camera will move to this marker and look at the player.

* **Mode 3: Path Tracking**
    * Links the camera's position on a `Path3D` to the player's movement on one axis (X, Y, or Z).
    * Create a `Path3D` node and draw your camera's path.
    * Assign the `Path3D` to the `Mode 3 Camera Path` slot.
    * Set the **`Player Track Axis`** (e.g., `AXIS_Z` if the player is moving down a Z-axis hallway).
    * Set the **`Player Track Start`** and **`Player Track End`** values. These are the player's world positions (e.g., `Z=0` and `Z=20`) that correspond to 0% and 100% of the camera's path.

* **Mode 4: Revert to Default**
    * Resets the camera to its original settings (the `camera_offset` and `follow_speed` defined on the `MainCamera` node). Use this to end a fixed shot.

---

## 📈 Version History
For a detailed list of all changes, please see the [updates.txt](addons/cinematic_camera/updates.txt) file.

## 📄 License
This plugin is released under the MIT License. See the `LICENSE` file for more information.
