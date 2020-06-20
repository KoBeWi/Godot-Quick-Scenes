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
	var editor_base := get_editor_interface().get_base_control()
	var editor_node := editor_base.get_tree().root.get_child(0)
	var editor_quick_run = get_child_by_class(editor_base, "EditorQuickOpen", 2)
	var editor_main_vbox = get_child_by_class(editor_base, "VBoxContainer")
	var editor_menu_hbox = get_child_by_class(editor_main_vbox, "HBoxContainer")
	var editor_play_hbox = get_child_by_class(editor_menu_hbox, "HBoxContainer", 3)
	var play_custom_button = get_child_by_class(editor_play_hbox, "ToolButton", 5)
	play_custom_button.emit_signal("pressed")
	editor_quick_run.hide()
	var quick_run_control = get_child_by_class(editor_quick_run, "VBoxContainer")
	var quick_run_filter = get_child_by_class(quick_run_control, "MarginContainer", 1)
	var quick_run_tree = get_child_by_class(quick_run_control, "MarginContainer", 2)
	var search_box := quick_run_filter.get_child(0) as LineEdit
	var scene_list := quick_run_tree.get_child(0) as Tree
	search_box.clear()
	clear_selection(scene_list)
	search_box.text = scene.trim_prefix("res://")
	search_box.emit_signal("text_changed", search_box.text)
	var was_selected = scene_list.get_root().get_children()
	editor_node._quick_run()
	play_custom_button.emit_signal("pressed")
	editor_quick_run.hide()

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
