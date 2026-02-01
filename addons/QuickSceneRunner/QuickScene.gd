@tool
extends PanelContainer

@onready var reorder: Button = %Reorder
@onready var path_edit: LineEdit = %Path
@onready var run: Button = %Run
@onready var edit: Button = %Edit
@onready var bound: CheckBox = %Bound
@onready var delete: Button = %Delete
@onready var quick_open: Button = %QuickOpen
@onready var delete_progress: TextureProgressBar = %DeleteProgress

var plugin

signal request_save
signal current_changed

func _ready() -> void:
	if is_part_of_edited_scene():
		return
	
	path_edit.set_drag_forwarding(Callable(), can_drop_data, drop_data)
	reorder.set_drag_forwarding(start_reorder, Callable(), Callable())

func setup(plugin_: Node, path: String):
	plugin = plugin_
	
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		path = ResourceUID.get_id_path(id)
	path_edit.text = path
	bound.button_group = plugin.shortcut_group
	bound.pressed.connect(plugin.update_selected.bind(self))
	run.pressed.connect(plugin.run_scene.bind(self))
	edit.pressed.connect(plugin.edit_scene.bind(self))
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
			delete_progress.texture_progress.gradient.set_color(0, Color(get_theme_color(&"accent_color", &"Editor"), 0.3))
		
		NOTIFICATION_INTERNAL_PROCESS:
			delete_progress.value += get_process_delta_time()
			if is_equal_approx(delete_progress.value, delete_progress.max_value):
				plugin.remove_scene(self)
		
		NOTIFICATION_DRAG_END:
			show()

func can_drop_data(at_position: Vector2, data) -> bool:
	if data.get("type", "") == "files" and "files" in data:
		if data.files.size() == 1:
			if data.files[0].get_extension() == "tscn":
				return true
	
	return false

func drop_data(at_position: Vector2, data) -> void:
	path_edit.text = data.files[0]
	_on_path_text_changed(data.files[0])

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
		path_edit.text = path
		_on_path_text_changed(path)

func _on_delete_button_down() -> void:
	set_process_internal(true)

func _on_delete_button_up() -> void:
	set_process_internal(false)
	delete_progress.value = 0

func update_layout(layout: EditorDock.DockLayout):
	bound.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if layout == EditorDock.DOCK_LAYOUT_VERTICAL else TextServer.OVERRUN_NO_TRIM

func start_reorder(pos: Vector2) -> Variant:
	set_drag_preview(duplicate())
	hide()
	return { "type": "quick_scene", "scene": self }
