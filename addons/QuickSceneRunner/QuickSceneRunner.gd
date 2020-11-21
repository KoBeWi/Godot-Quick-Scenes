tool
extends EditorPlugin

var dock: Control

func _enter_tree():
	dock = preload("res://addons/QuickSceneRunner/QuickSceneRunner.tscn").instance()
	dock.plugin = self
	add_control_to_bottom_panel(dock, "Quick Scenes")

func _exit_tree():
	remove_control_from_bottom_panel(dock)
	dock.free()

func run_scene(scene: String):
	get_editor_interface().play_custom_scene(scene)

func get_child_by_class(node : Node, child_class : String, counter : int = 1) -> Node:
	var match_counter = 0
	var node_children = node.get_children()
	
	for child in node_children:
		if (child.get_class() == child_class):
			match_counter += 1
		if (match_counter == counter):
			return child
		
	return null

func clear_selection(tree : Tree) -> void:
	var selected_item = tree.get_next_selected(null)
	while (selected_item):
		for i in tree.columns:
			if (selected_item.is_selected(i)):
				selected_item.deselect(i)
		
		selected_item = tree.get_next_selected(selected_item)
