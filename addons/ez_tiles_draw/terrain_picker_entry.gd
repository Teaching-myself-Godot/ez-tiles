@tool
extends HBoxContainer

class_name TerrainPickerEntry

signal selected(terrain_id : int)

var terrain_id : int
var terrain_name_button : Button
var terrain_name : String
var texture_resource : Texture2D
var icon : TextureRect


func _enter_tree() -> void:
	terrain_name_button = find_child("TerrainNameButton")
	icon = find_child("IconTextureRect")
	terrain_name_button.text = terrain_name
	if is_instance_valid(texture_resource):
		icon.texture = texture_resource


func _on_icon_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected.emit(terrain_id)
			terrain_name_button.button_pressed = true
	if event is InputEventMouseMotion:
		terrain_name_button.grab_focus()


func _on_terrain_name_button_pressed() -> void:
	selected.emit(terrain_id)

