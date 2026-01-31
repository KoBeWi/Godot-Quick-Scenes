@tool
extends EditorDock

@onready var add_scene_button: Button = %AddSceneButton
@onready var add_current_scene_button: Button = %AddCurrentSceneButton
@onready var scenes_container: HFlowContainer = %Scenes
@onready var save_timer: Timer = %SaveTimer

var plugin: EditorPlugin
var shortcut_group: ButtonGroup

var scene_list: PackedStringArray
var selected_scene := -1

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	plugin.scene_changed.connect(_on_scene_changed)
	shortcut_group = ButtonGroup.new()
	
	selected_scene = EditorInterface.get_editor_settings().get_project_metadata("quick_scenes", "selected_scene", -1)
	
	for scene in scene_list:
		add_scene(scene)
	
	select_button()

func _notification(what: int) -> void:
	if is_part_of_edited_scene():
		return
	
	if what == NOTIFICATION_THEME_CHANGED:
		plugin.button.icon = get_theme_icon(&"TransitionSync", &"EditorIcons")
		if not is_node_ready():
			await ready
		
		add_scene_button.icon = get_theme_icon(&"Add", &"EditorIcons")
		add_current_scene_button.icon = get_theme_icon(&"Add", &"EditorIcons")

func add_scene(path: String):
	var scene: Control = preload("uid://b6qyveu25w7m5").instantiate()
	scenes_container.add_child(scene)
	scene.setup(self, path)
	scene.request_save.connect(save_scenes_delayed)

func remove_scene(scene: Control):
	scene.free()
	
	var child_count := scenes_container.get_child_count()
	if selected_scene >= child_count:
		selected_scene = child_count - 1
		save_selected_scene()
		select_button()
	save_scenes()

func update_selected(scene: Control):
	plugin.button.disabled = false
	selected_scene = scene.get_index()
	plugin.update_play_button()
	save_selected_scene()

func run_scene(scene: Control=null):
	if scene == null:
		scene = shortcut_group.get_pressed_button().get_parent().get_parent().get_parent()
	
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
		var path: String = scene.path_edit.text
		var id := ResourceLoader.get_resource_uid(path)
		if id != ResourceUID.INVALID_ID:
			path = ResourceUID.id_to_text(id)
		scene_list.append(path)

func save_scenes():
	update_scene_list()
	plugin.save_scenes(scene_list)

func save_scenes_delayed():
	save_timer.start()

func select_button():
	if selected_scene >= 0 and selected_scene < scenes_container.get_child_count():
		scenes_container.get_child(selected_scene).bound.button_pressed = true
	elif scenes_container.get_child_count() > 0:
		scenes_container.get_child(0).bound.button_pressed = true
	
	plugin.update_play_button()

func get_selected_scene() -> int:
	for quick_scene in scenes_container.get_children():
		if quick_scene.bound.button_pressed:
			return quick_scene.get_index()
	return -1

func save_selected_scene():
	EditorInterface.get_editor_settings().set_project_metadata("quick_scenes", "selected_scene", selected_scene)

func _on_add_scene_button_pressed():
	add_scene("")
	save_scenes()

func _on_add_current_scene_button_pressed():
	if not get_tree().edited_scene_root:
		return
	add_scene(get_tree().edited_scene_root.scene_file_path)
	save_scenes()

func _on_scene_changed(root: Node):
	add_current_scene_button.disabled = not root

func _update_layout(layout: int) -> void:
	if not is_node_ready():
		await ready
	
	for scene in scenes_container.get_children():
		scene.update_layout(layout)
