@tool
extends VBoxContainer

const SCENE_LIST_SETTING = "addons/quick_scenes/scene_list"
const SELECTED_SCENE_SETTING = "addons/quick_scenes/selected_scene"
const SHORTCUT_SETTING = "addons/quick_scenes/quick_run_shortcut"

var plugin: EditorPlugin
var shortcut_group: ButtonGroup

func _ready() -> void:
	shortcut_group = ButtonGroup.new()
	
	if not ProjectSettings.has_setting(SELECTED_SCENE_SETTING):
		ProjectSettings.set_setting(SELECTED_SCENE_SETTING, -1)
	
	if ProjectSettings.has_setting(SCENE_LIST_SETTING):
		for scene in ProjectSettings.get_setting(SCENE_LIST_SETTING):
			add_scene(scene)
	select_button()
	
	if not ProjectSettings.has_setting(SHORTCUT_SETTING):
		var shortcut := Shortcut.new()
		
		var event := InputEventKey.new()
		event.keycode= KEY_F9
		shortcut.events.append(event)
		
		ProjectSettings.set_setting(SHORTCUT_SETTING, shortcut)

func on_add() -> void:
	add_scene("")

func add_scene(path: String):
	var scene: Control = preload("res://addons/QuickSceneRunner/QuickScene.tscn").instantiate()
	$Scenes.add_child(scene)
	
	scene.setup(self, path)

func remove_scene(scene: Control):
	if not scene.get_node(^"%Del").button_pressed or not scene.get_node(^"%Del2").button_pressed:
		return
	
	scene.queue_free()
	await get_tree().process_frame
	if ProjectSettings.get_setting(SELECTED_SCENE_SETTING) as int >= $Scenes.get_child_count():
		ProjectSettings.set_setting(SELECTED_SCENE_SETTING, $Scenes.get_child_count() - 1)
		ProjectSettings.save()
		select_button()
	save_scenes()

func update_selected(scene: Control):
	ProjectSettings.set_setting(SELECTED_SCENE_SETTING, scene.get_index())
	ProjectSettings.save()

func run_scene(scene: Control):
	var path := scene.get_node(^"%Path").text as String
	if FileAccess.file_exists(path):
		plugin.get_editor_interface().play_custom_scene(path)
	else:
		push_error("Quick Scenes: Invalid scene to run")

func edit_scene(scene: Control):
	var path := scene.get_node(^"%Path").text as String
	if FileAccess.file_exists(path):
		plugin.get_editor_interface().open_scene_from_path(path)
	else:
		push_error("Quick Scenes: Invalid scene to edit")

func save_scenes():
	var scene_list := PackedStringArray()
	
	for scene in $Scenes.get_children():
		scene_list.append(scene.get_node(^"%Path").text)
	
	ProjectSettings.set_setting(SCENE_LIST_SETTING, scene_list)
	ProjectSettings.save()

func select_button():
	var setting := ProjectSettings.get_setting(SELECTED_SCENE_SETTING) as int
	if setting >= 0 and setting < $Scenes.get_child_count():
		$Scenes.get_child(setting).get_node(^"%Bound").button_pressed = true
	elif $Scenes.get_child_count() > 0:
		$Scenes.get_child(0).get_node(^"%Bound").button_pressed = true

func _unhandled_key_input(event: InputEvent) -> void:
	var shortcut: Shortcut = ProjectSettings.get_setting(SHORTCUT_SETTING)
	if not shortcut:
		return
	
	if event.is_pressed() and shortcut.matches_event(event):
		if shortcut_group.get_pressed_button():
			run_scene(shortcut_group.get_pressed_button().get_parent().get_parent().get_parent())
		else:
			push_warning("Quick Scenes: No quick scene selected for shortcut")
		get_viewport().set_input_as_handled()
