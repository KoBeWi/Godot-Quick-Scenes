@tool
extends EditorPlugin

var dock: Control

func _enter_tree():
	dock = preload("res://addons/QuickSceneRunner/QuickSceneRunner.tscn").instantiate()
	dock.plugin = self
	add_control_to_bottom_panel(dock, "Quick Scenes")

func _exit_tree():
	remove_control_from_bottom_panel(dock)
	dock.free()
