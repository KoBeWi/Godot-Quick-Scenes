tool
extends VBoxContainer

const SCENE_LIST_SETTING := "addons/quick_scenes/scene_list"
const SELECTED_SCENE_SETTING := "addons/quick_scenes/selected_scene"
const SHORTCUT_SETTING := "addons/quick_scenes/quick_run_shortcut"

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
		var event := InputEventKey.new()
		event.scancode = KEY_F9
		event.pressed = true
		ProjectSettings.set_setting(SHORTCUT_SETTING, event)

func on_add() -> void:
	add_scene("")

func add_scene(path: String):
	var scene := preload("res://addons/QuickSceneRunner/QuickScene.tscn").instance()
	$Scenes.add_child(scene)
	
	scene.get_node("VBoxContainer/HBoxContainer/Path").text = path
	scene.get_node("VBoxContainer/HBoxContainer2/Bound").group = shortcut_group
	scene.get_node("VBoxContainer/HBoxContainer2/Bound").connect("pressed", self, "update_selected", [scene])
	scene.get_node("VBoxContainer/HBoxContainer/Del").connect("pressed", self, "remove_scene", [scene])
	scene.get_node("VBoxContainer/HBoxContainer2/Run").connect("pressed", self, "run_scene", [scene])
	scene.get_node("VBoxContainer/HBoxContainer/Path").connect("text_changed", self, "save_scenes")

func remove_scene(scene: Control):
	scene.queue_free()
	yield(get_tree(), "idle_frame")
	if ProjectSettings.get_setting(SELECTED_SCENE_SETTING) as int >= $Scenes.get_child_count():
		ProjectSettings.set_setting(SELECTED_SCENE_SETTING, $Scenes.get_child_count() - 1)
		ProjectSettings.save()
		select_button()
	save_scenes(null)

func update_selected(scene: Control):
	ProjectSettings.set_setting(SELECTED_SCENE_SETTING, scene.get_index())
	ProjectSettings.save()

func run_scene(scene: Control):
	var path := scene.get_node("VBoxContainer/HBoxContainer/Path").text as String
	var file := File.new()
	if file.file_exists(path):
		plugin.run_scene(path)
	else:
		push_error("Quick Scenes: Invalid scene to run")

func save_scenes(meh):
	var scene_list := PoolStringArray()
	
	for scene in $Scenes.get_children():
		scene_list.append(scene.get_node("VBoxContainer/HBoxContainer/Path").text)
	
	ProjectSettings.set_setting(SCENE_LIST_SETTING, scene_list)
	ProjectSettings.save()

func select_button():
	var setting := ProjectSettings.get_setting(SELECTED_SCENE_SETTING) as int
	if setting >= 0 and setting < $Scenes.get_child_count():
		$Scenes.get_child(setting).get_node("VBoxContainer/HBoxContainer2/Bound").pressed = true
	elif $Scenes.get_child_count() > 0:
		$Scenes.get_child(0).get_node("VBoxContainer/HBoxContainer2/Bound").pressed = true

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.pressed and event.shortcut_match(ProjectSettings.get_setting(SHORTCUT_SETTING)):
		if shortcut_group.get_pressed_button():
			run_scene(shortcut_group.get_pressed_button().get_parent().get_parent().get_parent())
		else:
			push_warning("Quick Scenes: No quick scene selected for shortcut")
