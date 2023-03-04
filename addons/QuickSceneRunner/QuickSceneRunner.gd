@tool
extends EditorPlugin

const SHORTCUT_SETTING = "addons/quick_scenes/quick_run_shortcut"

var dock: Control
var button: Button

func _enter_tree():
	var shortcut: Shortcut
	if ProjectSettings.has_setting(SHORTCUT_SETTING):
		shortcut = ProjectSettings.get_setting(SHORTCUT_SETTING)
	
	if not shortcut:
		shortcut = Shortcut.new()
		
		var event := InputEventKey.new()
		event.keycode= KEY_F9
		shortcut.events.append(event)
		
		ProjectSettings.set_setting(SHORTCUT_SETTING, shortcut)
	
	button = Button.new()
	add_control_to_container(CONTAINER_TOOLBAR, button)
	button.tooltip_text = "Run Quick Scene\nNo scene configured."
	button.disabled = true
	button.shortcut = shortcut
	button.get_parent().move_child(button, button.get_index() - 2)
	
	dock = preload("res://addons/QuickSceneRunner/QuickSceneRunner.tscn").instantiate()
	dock.plugin = self
	add_control_to_bottom_panel(dock, "Quick Scenes")
	
	button.pressed.connect(dock.run_scene)

func _exit_tree():
	remove_control_from_bottom_panel(dock)
	remove_control_from_container(CONTAINER_TOOLBAR, button)
	dock.free()
