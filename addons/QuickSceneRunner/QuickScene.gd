@tool
extends PanelContainer

@onready var reorder: Button = %Reorder
@onready var path_edit: LineEdit = %Path
@onready var run: Button = %Run
@onready var edit: Button = %Edit
@onready var bound: CheckBox = %Bound
@onready var delete: Button = %Delete
@onready var quick_open: Button = %QuickOpen
@onready var custom_name: Label = %CustomName
@onready var custom_icon: TextureRect = %CustomIcon
@onready var border: Panel = %Border
@onready var edit_style: Button = %EditStyle

var dock: EditorDock
var style: Dictionary

signal request_save
signal request_edit
signal current_changed

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	path_edit.set_drag_forwarding(Callable(), can_drop_data, drop_data)
	reorder.set_drag_forwarding(start_reorder, Callable(), Callable())

func setup(d: Node, data: Dictionary):
	dock = d
	
	var path: String = data["path"]
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		path = ResourceUID.get_id_path(id)
	
	path_edit.text = path
	bound.button_group = dock.shortcut_group
	
	style = data["style"]
	apply_style()
	
	bound.pressed.connect(dock.update_selected.bind(self))
	run.pressed.connect(dock.run_scene.bind(self))
	edit.pressed.connect(dock.edit_scene.bind(self))
	_on_path_text_changed(path, false)

func _notification(what: int) -> void:
	if is_part_of_edited_scene():
		return
	
	match what:
		NOTIFICATION_THEME_CHANGED:
			if not is_node_ready():
				await ready
			
			reorder.icon = get_theme_icon(&"TripleBar", &"EditorIcons")
			run.icon = get_theme_icon(&"Play", &"EditorIcons")
			edit.icon = get_theme_icon(&"Edit", &"EditorIcons")
			quick_open.icon = get_theme_icon(&"LoadQuick", &"EditorIcons")
			delete.icon = get_theme_icon(&"Remove", &"EditorIcons")
		
		NOTIFICATION_DRAG_END:
			show()

func can_drop_data(at_position: Vector2, data) -> bool:
	if data.get("type", "") == "files" and "files" in data:
		if data.files.size() == 1:
			if data.files[0].get_extension() == "tscn" or data.files[0].get_extension() == "scn":
				return true
	
	return false

func drop_data(at_position: Vector2, data) -> void:
	dock.set_scene_path(self, data.files[0])

func set_scene_path(path: String):
	path_edit.text = path
	_on_path_text_changed(path)

func _on_path_text_changed(new_text: String, save := true) -> void:
	var invalid: bool
	
	if not ResourceLoader.exists(new_text):
		invalid = true
	
	if not invalid:
		var res := load(new_text) as PackedScene
		invalid = not res
	
	path_edit.tooltip_text = new_text
	
	bound.disabled = invalid
	run.disabled = invalid
	edit.disabled = invalid
	
	if save:
		request_save.emit()
	
	if bound.button_pressed:
		current_changed.emit()

func _on_quick_open_pressed() -> void:
	EditorInterface.popup_quick_open(_quick_open_callback, ["PackedScene"])

func _quick_open_callback(path: String):
	if not path.is_empty():
		dock.set_scene_path(self, path)

func update_layout(layout: EditorDock.DockLayout):
	bound.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if layout == EditorDock.DOCK_LAYOUT_VERTICAL else TextServer.OVERRUN_NO_TRIM

func apply_style():
	custom_name.text = style.get("name", "")
	
	var icon_path: String = style.get("icon", "")
	if icon_path.is_empty():
		custom_icon.texture = null
	else:
		custom_icon.texture = load(icon_path)
	
	border.visible = style.get("show_border", false)
	border.modulate = Color(style.get("border_color", "ffffff"))

func start_reorder(pos: Vector2) -> Variant:
	set_drag_preview(duplicate())
	hide()
	return { "type": "quick_scene", "scene": self }

func _on_delete_pressed() -> void:
	dock.remove_scene(self)

func _on_edit_style_mouse_entered() -> void:
	if not get_viewport().gui_is_dragging():
		edit_style.icon = get_theme_icon(&"Edit", &"EditorIcons")

func _on_edit_style_mouse_exited() -> void:
	edit_style.icon = null

func _on_edit_style_pressed() -> void:
	request_edit.emit()
