@tool
extends HBoxContainer
class_name TerrainListEntry

var terrain_name_input : LineEdit
var terrain_name_button : Button
var edit_button : Button
var save_button : Button
var value : String


func _enter_tree() -> void:
	save_button = find_child("SaveButton")
	edit_button = find_child("EditButton")
	terrain_name_input = find_child("TerrainNameInput")
	terrain_name_button = find_child("TerrainNameButton")
	terrain_name_input.text = value
	terrain_name_button.text = value


func _on_edit_button_pressed() -> void:
	edit_button.hide()
	save_button.show()
	terrain_name_button.hide()
	terrain_name_input.show()
	terrain_name_input.grab_focus()


func save_new_terrain_name() -> void:
	if terrain_name_input.text.length() > 0:
		value = terrain_name_input.text

	terrain_name_button.text = value
	terrain_name_input.text = value
	terrain_name_button.show()
	terrain_name_input.hide()
	edit_button.show()
	save_button.hide()


func _on_remove_button_pressed() -> void:
	queue_free()


func _on_terrain_name_input_text_submitted(_new_text: String) -> void:
	save_new_terrain_name()
