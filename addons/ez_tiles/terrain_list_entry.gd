@tool
extends HBoxContainer
class_name TerrainListEntry

signal removed()
signal selected()

var terrain_name_input : LineEdit
var terrain_name_button : Button
var edit_button : Button
var save_button : Button
var terrain_name : String
var texture_resource : CompressedTexture2D
var collision_type_button : OptionButton
var icon : TextureRect
var warning_icon : TextureRect
var warning_message : String = ""

func _enter_tree() -> void:
	save_button = find_child("SaveButton")
	edit_button = find_child("EditButton")
	collision_type_button = find_child("CollisionTypeButton")
	terrain_name_input = find_child("TerrainNameInput")
	terrain_name_button = find_child("TerrainNameButton")
	icon = find_child("IconTextureRect")
	warning_icon = find_child("WarningIcon")
	terrain_name_input.text = terrain_name
	terrain_name_button.text = terrain_name
	if is_instance_valid(texture_resource):
		icon.texture = texture_resource
		terrain_name_button.button_pressed = true
	if warning_message.length() > 0:
		warning_icon.tooltip_text = warning_message
		warning_icon.show()


func _on_edit_button_pressed() -> void:
	edit_button.hide()
	save_button.show()
	terrain_name_button.hide()
	terrain_name_input.show()
	terrain_name_input.grab_focus()


func save_new_terrain_name() -> void:
	if terrain_name_input.text.length() > 0:
		terrain_name = terrain_name_input.text

	terrain_name_button.text = terrain_name
	terrain_name_input.text = terrain_name
	terrain_name_button.show()
	terrain_name_input.hide()
	edit_button.show()
	save_button.hide()


func _on_remove_button_pressed() -> void:
	removed.emit()
	queue_free()


func _on_terrain_name_button_pressed() -> void:
	selected.emit()


func _on_terrain_name_input_text_submitted(_new_text: String) -> void:
	save_new_terrain_name()


func gather_data() -> Dictionary:
	return {
		"texture_resource": texture_resource,
		"terrain_name": terrain_name,
		"layer_type": collision_type_button.get_selected_id()
	}


func _on_icon_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected.emit()
			terrain_name_button.button_pressed = true
	if event is InputEventMouseMotion:
		terrain_name_button.grab_focus()


