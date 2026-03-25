@tool
extends AcceptDialog

@onready var name_edit: LineEdit = %NameEdit
@onready var icon_picker: Button = %IconPicker
@onready var icon_remover: Button = %IconRemover
@onready var icon_preview: TextureRect = %IconPreview
@onready var show_border: CheckBox = %ShowBorder
@onready var color_edit: ColorPickerButton = %ColorEdit

var edited_scene

func _init() -> void:
	if not is_part_of_edited_scene():
		hide()

func _notification(what: int) -> void:
	if is_part_of_edited_scene():
		return
	
	if what == NOTIFICATION_THEME_CHANGED:
		if not is_node_ready():
			await ready
		
		icon_picker.icon = get_theme_icon(&"LoadQuick", &"EditorIcons")
		icon_remover.icon = get_theme_icon(&"ReloadSmall", &"EditorIcons")

func show_dialog(for_scene):
	edited_scene = null
	
	var style: Dictionary = for_scene.style
	name_edit.text = style.get("name", "")
	
	var icon_path: String = style.get("icon", "")
	if icon_path.is_empty():
		icon_preview.texture = null
	else:
		icon_preview.texture = load(icon_path)
	
	show_border.button_pressed = style.get("show_border", false)
	color_edit.color = Color(style.get("border_color", "ffffff"))
	
	edited_scene = for_scene
	
	reset_size()
	popup_centered()

func _on_icon_picker_pressed() -> void:
	EditorInterface.popup_quick_open(_icon_picked, [&"Texture2D"])

func _on_icon_remover_pressed() -> void:
	icon_preview.texture = null
	edited_scene.style["icon"] = ""
	edited_scene.apply_style()

func _icon_picked(path: String):
	if path.is_empty():
		return
	
	icon_preview.texture = load(path)
	
	edited_scene.style["icon"] = ResourceUID.path_to_uid(path)
	edited_scene.apply_style()

func _on_name_edit_text_changed(new_text: String) -> void:
	edited_scene.style["name"] = new_text
	edited_scene.apply_style()

func _on_show_border_pressed() -> void:
	edited_scene.style["show_border"] = show_border.button_pressed
	edited_scene.apply_style()

func _on_color_edit_color_changed(color: Color) -> void:
	edited_scene.style["border_color"] = color_edit.color.to_html(false)
	edited_scene.apply_style()
