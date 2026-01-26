@tool
extends "ExtendedEditorPlugin.gd"

const SHORTCUT_SETTING = "addons/quick_scenes/quick_run_shortcut"
const SHORTCUT_PATH = "quick_scenes/play_quick_scene"

var dock: EditorDock
var button: Button

func _init() -> void:
	add_plugin_translations_from_directory("res://addons/QuickSceneRunner/Translations")

func _enter_tree():
	register_editor_shortcut(SHORTCUT_PATH, tr_extract.tr("Run Quick Scene"), KEY_F9)
	
	button = Button.new()
	button.tooltip_text = "Run Quick Scene"
	button.disabled = true
	button.theme_type_variation = &"FlatButton"
	button.shortcut = EditorInterface.get_editor_settings().get_shortcut(SHORTCUT_PATH)
	add_control_to_container(CONTAINER_TOOLBAR, button)
	button.get_parent().move_child(button, button.get_index() - 2)
	
	dock = preload("uid://cb3s0qv3xf7f4").instantiate()
	dock.plugin = self
	add_dock(dock)
	
	button.pressed.connect(dock.run_scene)

func _exit_tree():
	remove_dock(dock)
	remove_control_from_container(CONTAINER_TOOLBAR, button)
	dock.queue_free()
	button.queue_free()
