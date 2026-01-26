@tool
extends EditorDock

enum ShowQuickRunLabelSetting {
	HIDDEN,
	FILENAME_ONLY,
	FULL_PATH
}

const SCENE_LIST_SETTING = "addons/quick_scenes/scene_list"
const SELECTED_SCENE_SETTING = "addons/quick_scenes/selected_scene"
const QUICK_RUN_LABEL_SETTING = "addons/quick_scenes/show_quick_run_label"
const MAX_QUICK_RUN_WIDTH_SETTING = "addons/quick_scenes/max_quick_run_label_width"
const DEFAULT_QUICK_RUN_MAX_WIDTH = 200.0
const QUICK_RUN_WIDTH_SCALE_FACTOR = 16.0

@onready var add_scene_button: Button = %AddSceneButton
@onready var add_current_scene_button: Button = %AddCurrentSceneButton
@onready var scenes_container: HFlowContainer = %Scenes
@onready var save_timer: Timer = %SaveTimer

var plugin: EditorPlugin
var shortcut_group: ButtonGroup
var last_label: String
var last_width := 0.0

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	plugin.scene_changed.connect(_on_scene_changed)
	shortcut_group = ButtonGroup.new()
	
	if not ProjectSettings.has_setting(SELECTED_SCENE_SETTING):
		ProjectSettings.set_setting(SELECTED_SCENE_SETTING, -1)
	
	if not ProjectSettings.has_setting(QUICK_RUN_LABEL_SETTING):
		ProjectSettings.set_setting(QUICK_RUN_LABEL_SETTING, ShowQuickRunLabelSetting.HIDDEN)
	ProjectSettings.set_initial_value(QUICK_RUN_LABEL_SETTING, ShowQuickRunLabelSetting.HIDDEN)
	
	if not ProjectSettings.has_setting(MAX_QUICK_RUN_WIDTH_SETTING):
		ProjectSettings.set_setting(MAX_QUICK_RUN_WIDTH_SETTING, DEFAULT_QUICK_RUN_MAX_WIDTH)
	ProjectSettings.set_initial_value(MAX_QUICK_RUN_WIDTH_SETTING, DEFAULT_QUICK_RUN_MAX_WIDTH)
	
	var property_info = {
		"name": QUICK_RUN_LABEL_SETTING,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Hidden,Filename Only,Full Path (if Possible)"
	}
	ProjectSettings.add_property_info(property_info)
	
	if ProjectSettings.has_setting(SCENE_LIST_SETTING):
		for scene in ProjectSettings.get_setting(SCENE_LIST_SETTING):
			add_scene(scene)
	
	select_button()
	
	ProjectSettings.settings_changed.connect(select_button)

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
	if !is_instance_valid(plugin):
		return
	
	plugin.button.disabled = false
	
	var setting := ProjectSettings.get_setting(SELECTED_SCENE_SETTING) as int
	var scenes := ProjectSettings.get_setting(SCENE_LIST_SETTING) as PackedStringArray
	var show_label := ProjectSettings.get_setting(QUICK_RUN_LABEL_SETTING) as ShowQuickRunLabelSetting
	var path := ""
	
	if scenes && scenes.size() > setting:
		path = scenes[setting]
		
		if path.begins_with("uid://"):
			var id := ResourceUID.text_to_id(path)
			path = ResourceUID.get_id_path(id)
	
	match show_label:
		ShowQuickRunLabelSetting.FILENAME_ONLY:
			var filename := path.get_file()
			if filename.get_extension().to_lower() == "tscn":
				filename = filename.get_basename()
			
			set_select_button_label(filename)
		ShowQuickRunLabelSetting.FULL_PATH:
			set_select_button_label(path)
		_:
			set_select_button_label("")
	
	plugin.button.tooltip_text = path
	
	if setting >= 0 and setting < scenes_container.get_child_count():
		scenes_container.get_child(setting).bound.button_pressed = true
	elif scenes_container.get_child_count() > 0:
		scenes_container.get_child(0).bound.button_pressed = true
	else:
		plugin.button.disabled = true

func set_select_button_label(path: String):
	if !is_instance_valid(plugin):
		return
	
	var max_label_width := ProjectSettings.get_setting(MAX_QUICK_RUN_WIDTH_SETTING) as float
	
	if path == last_label && max_label_width == last_width:
		return
	
	last_label = String(path)
	last_width = max_label_width
	
	plugin.button.clip_text = false
	plugin.button.custom_minimum_size.x = 0.0
	plugin.button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	
	var path_short := String(path)
	var font: Font = plugin.button.get_theme_font("font")
	var font_size: int = plugin.button.get_theme_font_size("font_size")
	
	var label_size := font.get_string_size(path_short, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var scaled_max_width := max_label_width * label_size.y / QUICK_RUN_WIDTH_SCALE_FACTOR
	
	if label_size.x > scaled_max_width:
		path_short = path.get_file()
		label_size = font.get_string_size(path_short, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		
		if label_size.x > scaled_max_width:
			plugin.button.clip_text = true
			plugin.button.custom_minimum_size.x = scaled_max_width
			plugin.button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	plugin.button.text = path_short

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
