@tool
extends "ExtendedEditorPlugin.gd"

enum ShowQuickRunLabelSetting {
	HIDDEN,
	FILENAME_ONLY,
	FULL_PATH
}

const SHORTCUT_PATH = "quick_scenes/play_quick_scene"

const SCENE_LIST_SETTING = "addons/quick_scenes/scene_list_file"
const QUICK_RUN_LABEL_SETTING = "addons/quick_scenes/show_quick_run_label"
const MAX_QUICK_RUN_WIDTH_SETTING = "addons/quick_scenes/max_quick_run_label_width"

const LEGACY_SCENE_LIST = "addons/quick_scenes/scene_list"

var scenes_path: String
var label_state: ShowQuickRunLabelSetting
var label_width: float
var last_width: float
var last_label_text: String

var dock: EditorDock
var button: Button

func _init() -> void:
	add_plugin_translations_from_directory("res://addons/QuickSceneRunner/Translations")

func _enter_tree():
	var scene_list: PackedStringArray
	
	scenes_path = define_project_setting(SCENE_LIST_SETTING, "res://quick_scenes.txt", PROPERTY_HINT_SAVE_FILE)
	track_project_setting(SCENE_LIST_SETTING)
	
	# Compat
	if ProjectSettings.has_setting(LEGACY_SCENE_LIST):
		scene_list = ProjectSettings.get_setting(LEGACY_SCENE_LIST)
		ProjectSettings.set(LEGACY_SCENE_LIST, null)
		save_scenes(scene_list)
	else:
		var scene_file := FileAccess.open(scenes_path, FileAccess.READ)
		if scene_file:
			scene_list = scene_file.get_as_text().split("\n")
	
	label_state = define_editor_setting(QUICK_RUN_LABEL_SETTING, ShowQuickRunLabelSetting.HIDDEN, PROPERTY_HINT_ENUM, "Hidden,Filename Only,Full Path (if Possible)")
	track_editor_setting(QUICK_RUN_LABEL_SETTING)
	label_width = define_editor_setting(MAX_QUICK_RUN_WIDTH_SETTING, 200.0)
	track_editor_setting(MAX_QUICK_RUN_WIDTH_SETTING)
	
	var shortcut := register_editor_shortcut(SHORTCUT_PATH, tr_extract.tr("Run Quick Scene"), KEY_F9)
	
	button = Button.new()
	button.disabled = true
	button.theme_type_variation = &"FlatButton"
	button.shortcut = shortcut
	add_control_to_container(CONTAINER_TOOLBAR, button)
	button.get_parent().move_child(button, button.get_index() - 2)
	
	dock = preload("uid://cb3s0qv3xf7f4").instantiate()
	dock.plugin = self
	dock.scene_list = scene_list
	add_dock(dock)
	
	button.pressed.connect(dock.run_scene)

func _exit_tree():
	remove_dock(dock)
	remove_control_from_container(CONTAINER_TOOLBAR, button)
	dock.queue_free()
	button.queue_free()

func update_play_button():
	button.disabled = false
	
	var selected_scene: int = dock.get_selected_scene()
	
	var path := ""
	var scene_list: PackedStringArray = dock.get_scene_list()
	if scene_list.size() > selected_scene:
		path = ResourceUID.ensure_path(scene_list[selected_scene])
	
	match label_state:
		ShowQuickRunLabelSetting.HIDDEN:
			set_select_button_label("")
		ShowQuickRunLabelSetting.FILENAME_ONLY:
			var filename := path.get_file()
			if filename.get_extension().to_lower() == "tscn":
				filename = filename.get_basename()
			
			set_select_button_label(filename)
		ShowQuickRunLabelSetting.FULL_PATH:
			set_select_button_label(path)
	
	button.tooltip_text = path
	button.disabled = dock.selected_scene == -1

func set_select_button_label(path: String):
	if path == last_label_text and label_width == last_width:
		return
	
	last_label_text = path
	last_width = label_width
	
	button.clip_text = false
	button.custom_minimum_size.x = 0.0
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	
	var path_short := path
	var font := button.get_theme_font(&"font")
	var font_size := button.get_theme_font_size(&"font_size")
	
	var label_size := font.get_string_size(path_short, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var scaled_max_width := label_width * label_size.y / 16.0
	
	if label_size.x > scaled_max_width:
		path_short = path.get_file()
		label_size = font.get_string_size(path_short, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		
		if label_size.x > scaled_max_width:
			button.clip_text = true
			button.custom_minimum_size.x = scaled_max_width
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	button.text = path_short

func save_scenes(scenes: PackedStringArray):
	var file := FileAccess.open(scenes_path, FileAccess.WRITE)
	file.store_string("\n".join(scenes))

func _on_setting_changed(setting: String):
	if setting == QUICK_RUN_LABEL_SETTING or setting == MAX_QUICK_RUN_WIDTH_SETTING:
		var es := EditorInterface.get_editor_settings()
		label_state = es.get_setting(QUICK_RUN_LABEL_SETTING)
		label_width = es.get_setting(MAX_QUICK_RUN_WIDTH_SETTING)
		update_play_button()
	elif setting == SCENE_LIST_SETTING:
		var new_path := ProjectSettings.get_setting(SCENE_LIST_SETTING)
		if FileAccess.file_exists(scenes_path) and not FileAccess.file_exists(new_path):
			DirAccess.rename_absolute(scenes_path, new_path)
			EditorInterface.get_resource_filesystem().update_file(scenes_path)
			EditorInterface.get_resource_filesystem().update_file(new_path)
		
		scenes_path = new_path
