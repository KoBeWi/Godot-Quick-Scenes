@tool
extends EditorDock

@onready var add_scene_button: Button = %AddSceneButton
@onready var add_current_scene_button: Button = %AddCurrentSceneButton
@onready var scenes_container: HFlowContainer = %Scenes
@onready var save_timer: Timer = %SaveTimer
@onready var style_dialog: AcceptDialog = $StyleDialog
var drop_preview: Panel
var drop_style: StyleBoxFlat

var plugin: EditorPlugin
var shortcut_group: ButtonGroup
var scene_list_dirty: bool

var scene_list: Array
var selected_scene := -1

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	plugin.scene_changed.connect(_on_scene_changed)
	shortcut_group = ButtonGroup.new()
	
	selected_scene = EditorInterface.get_editor_settings().get_project_metadata("quick_scenes", "selected_scene", -1)
	
	for data in scene_list:
		add_scene(data, false)
	
	select_button()
	
	scenes_container.set_drag_forwarding(Callable(), _scene_can_drop, _scene_drop)

func _notification(what: int) -> void:
	if is_part_of_edited_scene():
		return
	
	match what:
		NOTIFICATION_ENTER_TREE:
			if drop_preview:
				return
			
			drop_preview = %DropPreview
			drop_preview.owner = null
			drop_preview.get_parent().remove_child(drop_preview)
			drop_style = drop_preview.get_theme_stylebox(&"panel")
		
		NOTIFICATION_THEME_CHANGED:
			plugin.button.icon = get_theme_icon(&"TransitionSync", &"EditorIcons")
			if not is_node_ready():
				await ready
			
			add_scene_button.icon = get_theme_icon(&"Add", &"EditorIcons")
			add_current_scene_button.icon = get_theme_icon(&"Add", &"EditorIcons")
			
			var accent_color := get_theme_color(&"accent_color", &"Editor")
			drop_style.border_color = accent_color
			drop_style.bg_color = Color(accent_color, 0.25)
		
		NOTIFICATION_DRAG_BEGIN:
			var data = get_viewport().gui_get_drag_data()
			if data.get("type", "") == "quick_scene":
				drop_preview.custom_minimum_size = scenes_container.get_child(0).size
				for scene: Control in scenes_container.get_children():
					scene.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		
		NOTIFICATION_DRAG_END:
			if drop_preview.get_parent():
				drop_preview.get_parent().remove_child(drop_preview)
			
			for scene: Control in scenes_container.get_children():
				scene.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
		
		NOTIFICATION_PREDELETE:
			if drop_preview:
				drop_preview.queue_free()

func add_scene_with_path(scene_path: String):
	add_scene({path = scene_path, style = {}})

func add_scene(data: Dictionary, ur := true):
	var scene: Control = preload("uid://b6qyveu25w7m5").instantiate()
	scenes_container.add_child(scene)
	scene.setup(self, data)
	scene.request_save.connect(save_scenes_delayed)
	scene.request_edit.connect(edit_scene_style.bind(scene))
	scene.current_changed.connect(plugin.update_play_button)
	
	if not ur:
		return
	
	save_scenes_with_dirty()
	
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action(tr("Add Quick Scene"), UndoRedo.MERGE_DISABLE, null, false, false)
	undo_redo.add_do_method(scenes_container, &"add_child", scene)
	undo_redo.add_do_method(self, &"save_scenes_with_dirty")
	undo_redo.add_do_reference(scene)
	undo_redo.add_undo_method(scenes_container, &"remove_child", scene)
	undo_redo.add_undo_method(self, &"save_scenes_with_dirty")
	undo_redo.commit_action(false)

func set_scene_path(scene: Control, path: String):
	if path == scene.path_edit.text:
		return
	
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action(tr("Assign Quick Scene"), UndoRedo.MERGE_DISABLE, null, false, false)
	undo_redo.add_do_method(scene, &"set_scene_path", path)
	undo_redo.add_do_method(self, &"save_scenes_with_dirty")
	undo_redo.add_undo_method(scene, &"set_scene_path", scene.path_edit.text)
	undo_redo.add_undo_method(self, &"save_scenes_with_dirty")
	undo_redo.commit_action()

func remove_scene(scene: Control):
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action(tr("Remove Quick Scene"), UndoRedo.MERGE_DISABLE, null, false, false)
	undo_redo.add_do_method(self, &"do_remove_scene", scene)
	undo_redo.add_do_method(self, &"save_scenes_with_dirty")
	undo_redo.add_undo_method(scenes_container, &"add_child", scene)
	undo_redo.add_undo_method(scenes_container, &"move_child", scene, scene.get_index())
	undo_redo.add_undo_method(self, &"save_scenes_with_dirty")
	undo_redo.add_undo_reference(scene)
	undo_redo.commit_action()

func do_remove_scene(scene: Control):
	if scene.bound.button_pressed:
		scene.bound.button_pressed = false
	
	scenes_container.remove_child(scene)
	selected_scene = -1
	plugin.update_play_button()
	save_selected_scene()

func update_selected(scene: Control):
	selected_scene = scene.get_index()
	plugin.update_play_button()
	save_selected_scene()

func run_scene(scene: Control = null):
	if scene == null:
		scene = shortcut_group.get_pressed_button().owner
	
	var path := scene.path_edit.text as String
	if FileAccess.file_exists(path):
		plugin.get_editor_interface().play_custom_scene(path)
	else:
		EditorInterface.get_editor_toaster().push_toast(tr("Quick Scenes: Invalid scene to run."), EditorToaster.SEVERITY_ERROR)

func edit_scene(scene: Control):
	var path := scene.path_edit.text as String
	if FileAccess.file_exists(path):
		plugin.get_editor_interface().open_scene_from_path(path)
	else:
		EditorInterface.get_editor_toaster().push_toast(tr("Quick Scenes: Invalid scene to edit."), EditorToaster.SEVERITY_ERROR)

func update_scene_list():
	scene_list.clear()
	for scene in scenes_container.get_children():
		var scene_path: String = scene.path_edit.text
		var id := ResourceLoader.get_resource_uid(scene_path)
		if id != ResourceUID.INVALID_ID:
			scene_path = ResourceUID.id_to_text(id)
		
		
		scene_list.append({
			path = scene_path,
			style = scene.style,
		})

func save_scenes():
	plugin.save_scenes(get_scene_list())

func save_scenes_with_dirty():
	scene_list_dirty = true
	save_scenes()

func save_scenes_delayed():
	scene_list_dirty = true
	save_timer.start()

func select_button():
	if selected_scene >= 0 and selected_scene < scenes_container.get_child_count():
		scenes_container.get_child(selected_scene).bound.button_pressed = true
	elif scenes_container.get_child_count() > 0:
		scenes_container.get_child(0).bound.button_pressed = true
	
	plugin.update_play_button()

func get_scene_list() -> Array:
	if scene_list_dirty:
		update_scene_list()
		scene_list_dirty = false
	
	return scene_list

func get_selected_scene() -> int:
	for quick_scene in scenes_container.get_children():
		if quick_scene.bound.button_pressed:
			return quick_scene.get_index()
	return -1

func save_selected_scene():
	EditorInterface.get_editor_settings().set_project_metadata("quick_scenes", "selected_scene", selected_scene)

func edit_scene_style(scene):
	style_dialog.show_dialog(scene)

func _on_add_scene_button_pressed():
	add_scene_with_path("")

func _on_add_current_scene_button_pressed():
	if not get_tree().edited_scene_root:
		return
	add_scene_with_path(get_tree().edited_scene_root.scene_file_path)

func _on_scene_changed(root: Node):
	add_current_scene_button.disabled = not root

func _update_layout(layout: int) -> void:
	if not is_node_ready():
		await ready
	
	for scene in scenes_container.get_children():
		scene.update_layout(layout)

func _scene_can_drop(at_position: Vector2, data: Variant) -> bool:
	var type: String = data.get("type", "")
	if type != "quick_scene":
		return false
	
	if not drop_preview.get_parent():
		scenes_container.add_child(drop_preview)
	
	for scene: Control in scenes_container.get_children():
		if not scene.visible:
			continue
		
		if Rect2(Vector2(), scene.size).has_point(scene.get_local_mouse_position()):
			if scene == drop_preview:
				return true
			else:
				scenes_container.move_child(drop_preview, scene.get_index())
				return true
	
	scenes_container.move_child(drop_preview, -1)
	
	return true

func _scene_drop(at_position: Vector2, data: Variant) -> void:
	var dragged_scene: Node = data["scene"]
	var new_index := drop_preview.get_index()
	scenes_container.remove_child(drop_preview)
	
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action(tr("Move Quick Scene"), UndoRedo.MERGE_DISABLE, null, false, false)
	undo_redo.add_do_method(scenes_container, &"move_child", dragged_scene, new_index)
	undo_redo.add_do_method(self, &"save_scenes_with_dirty")
	undo_redo.add_undo_method(scenes_container, &"move_child", dragged_scene, dragged_scene.get_index())
	undo_redo.add_undo_method(self, &"save_scenes_with_dirty")
	undo_redo.commit_action()

func _on_style_dialog_visibility_changed() -> void:
	if not style_dialog.visible:
		save_scenes_with_dirty()
