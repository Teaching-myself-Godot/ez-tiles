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
var layer_button : OptionButton

func _enter_tree() -> void:
	save_button = find_child("SaveButton")
	edit_button = find_child("EditButton")
	layer_button = find_child("LayerButton")
	terrain_name_input = find_child("TerrainNameInput")
	terrain_name_button = find_child("TerrainNameButton")
	terrain_name_input.text = terrain_name
	terrain_name_button.text = terrain_name
	var img = texture_resource.get_image()
	img.resize(90, int((float(img.get_height()) / float(img.get_width())) * 90.0))
	terrain_name_button.icon = ImageTexture.create_from_image(img)
	terrain_name_button.button_pressed = true


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
		"layer_type": layer_button.selected
	}
