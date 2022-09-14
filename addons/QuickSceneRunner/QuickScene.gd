@tool
extends PanelContainer

func setup(plugin: Node, path: String):
	%Path.text = path
	%Bound.button_group = plugin.shortcut_group
	%Bound.pressed.connect(plugin.update_selected.bind(self))
	%Del.pressed.connect(plugin.remove_scene.bind(self))
	%Del2.pressed.connect(plugin.remove_scene.bind(self))
	%Run.pressed.connect(plugin.run_scene.bind(self))
	%Edit.pressed.connect(plugin.edit_scene.bind(self))
	%Path.text_changed.connect(plugin.save_scenes.unbind(1))

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		%Del.icon = get_theme_icon(&"Remove", &"EditorIcons")
		%Del2.icon = get_theme_icon(&"Remove", &"EditorIcons")
