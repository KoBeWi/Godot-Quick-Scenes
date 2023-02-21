@tool
extends EditorPlugin

var dock: Control
var button:Control

func _enter_tree():
	dock = preload("res://addons/QuickSceneRunner/QuickSceneRunner.tscn").instantiate()
	dock.plugin = self
	add_control_to_bottom_panel(dock, "Quick Scenes")
	button = Button.new()
	button.pressed.connect(dock.run_scene)
	button.dock = dock
	button.plugin = self
	button.icon = get_editor_interface().get_base_control().get_theme_icon("TransitionSync", "EditorIcons")
	add_control_to_container(CONTAINER_TOOLBAR, button)
	button.get_parent().move_child(button, button.get_index() - 2)

func _exit_tree():
	remove_control_from_bottom_panel(dock)
	remove_control_from_container(CONTAINER_TOOLBAR, button)
	dock.free()
