@tool
extends PanelContainer

signal request_save

func _ready() -> void:
	%Path.set_drag_forwarding(Callable(), can_drop_data, drop_data)

func setup(plugin: Node, path: String):
	%Path.text = path
	%Bound.button_group = plugin.shortcut_group
	%Bound.pressed.connect(plugin.update_selected.bind(self))
	%Del.pressed.connect(plugin.remove_scene.bind(self), CONNECT_DEFERRED)
	%Del2.pressed.connect(plugin.remove_scene.bind(self), CONNECT_DEFERRED)
	%Run.pressed.connect(plugin.run_scene.bind(self))
	%Edit.pressed.connect(plugin.edit_scene.bind(self))
	request_save.connect(plugin.save_scenes)
	_on_path_text_changed(path)

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		%Del.icon = get_theme_icon(&"Remove", &"EditorIcons")
		%Del2.icon = get_theme_icon(&"Remove", &"EditorIcons")

func can_drop_data(at_position: Vector2, data) -> bool:
	if data.get("type", "") == "files" and "files" in data:
		if data.files.size() == 1:
			if data.files[0].get_extension() == "tscn":
				return true
	
	return false

func drop_data(at_position: Vector2, data) -> void:
	%Path.text = data.files[0]
	_on_path_text_changed(data.files[0])

func _on_path_text_changed(new_text: String) -> void:
	var invalid: bool
	
	if not FileAccess.file_exists(new_text) or not ResourceLoader.exists(new_text):
		invalid = true
	
	if not invalid:
		var res := load(new_text)
		if not res or not res is PackedScene:
			invalid = true
	
	%Bound.disabled = invalid
	%Run.disabled = invalid
	%Edit.disabled = invalid
	request_save.emit()
