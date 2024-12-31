@tool
extends VBoxContainer

const SCENE_LIST_SETTING = "addons/quick_scenes/scene_list"
const SELECTED_SCENE_SETTING = "addons/quick_scenes/selected_scene"

@onready var add_scene_button: Button = %AddSceneButton
@onready var add_current_scene_button: Button = %AddCurrentSceneButton
@onready var scenes_container: HFlowContainer = $Scenes
@onready var save_timer: Timer = $SaveTimer

var plugin: EditorPlugin
var shortcut_group: ButtonGroup

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	plugin.scene_changed.connect(_on_scene_changed)
	shortcut_group = ButtonGroup.new()
	
	if not ProjectSettings.has_setting(SELECTED_SCENE_SETTING):
		ProjectSettings.set_setting(SELECTED_SCENE_SETTING, -1)
	
	if ProjectSettings.has_setting(SCENE_LIST_SETTING):
		for scene in ProjectSettings.get_setting(SCENE_LIST_SETTING):
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
	var scene: Control = preload("res://addons/QuickSceneRunner/QuickScene.tscn").instantiate()
	scenes_container.add_child(scene)
	
	scene.setup(self, path)

func remove_scene(scene: Control):
	scene.free()
	
	var child_count := scenes_container.get_child_count()
	if ProjectSettings.get_setting(SELECTED_SCENE_SETTING) as int >= child_count:
		ProjectSettings.set_setting(SELECTED_SCENE_SETTING, child_count - 1)
		ProjectSettings.save()
		select_button()
	save_scenes()

func update_selected(scene: Control):
	plugin.button.disabled = false
	ProjectSettings.set_setting(SELECTED_SCENE_SETTING, scene.get_index())
	ProjectSettings.save()

func run_scene(scene: Control=null):
	if scene == null:
		scene = shortcut_group.get_pressed_button().get_parent().get_parent().get_parent()
	
	var path := scene.path_edit.text as String
	if FileAccess.file_exists(path):
		plugin.get_editor_interface().play_custom_scene(path)
	else:
		push_error("Quick Scenes: Invalid scene to run")

func edit_scene(scene: Control):
	var path := scene.path_edit.text as String
	if FileAccess.file_exists(path):
		plugin.get_editor_interface().open_scene_from_path(path)
	else:
		push_error("Quick Scenes: Invalid scene to edit")

func save_scenes():
	var scene_list := PackedStringArray()
	for scene in scenes_container.get_children():
		var path: String = scene.path_edit.text
		var id := ResourceLoader.get_resource_uid(path)
		if id != ResourceUID.INVALID_ID:
			path = ResourceUID.id_to_text(id)
		scene_list.append(path)
	
	ProjectSettings.set_setting(SCENE_LIST_SETTING, scene_list)
	ProjectSettings.save()

func save_scenes_delayed():
	save_timer.start()

func select_button():
	plugin.button.disabled = false
	
	var setting := ProjectSettings.get_setting(SELECTED_SCENE_SETTING) as int
	if setting >= 0 and setting < scenes_container.get_child_count():
		scenes_container.get_child(setting).bound.button_pressed = true
	elif scenes_container.get_child_count() > 0:
		scenes_container.get_child(0).bound.button_pressed = true
	else:
		plugin.button.disabled = true

func _on_add_scene_button_pressed():
	add_scene("")

func _on_add_current_scene_button_pressed():
	if get_tree().edited_scene_root:
		add_scene(get_tree().edited_scene_root.scene_file_path)

func _on_scene_changed(root: Node):
	add_current_scene_button.disabled = not root
