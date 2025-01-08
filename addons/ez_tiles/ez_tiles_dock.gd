@tool
class_name EZTilesDock

extends HBoxContainer

var num_regex := RegEx.new()
var images_container : ImagesContainer
var x_size_line_edit : LineEdit
var y_size_line_edit : LineEdit
var generate_template_button : Button
var resource_map : Dictionary = {}



func _enter_tree() -> void:
	num_regex.compile("^\\d+\\.?\\d*$")
	images_container = find_child("ImagesContainer")
	x_size_line_edit = find_child("XSizeLineEdit")
	y_size_line_edit = find_child("YSizeLineEdit")
	generate_template_button = find_child("GenerateTemplateButton")

func _on_file_menu_load_files(files : PackedStringArray) -> void:
	load_files(files)


func _on_images_container_drop_files(files: PackedStringArray) -> void:
	load_files(files)


func load_files(files : PackedStringArray):
	for file in files:
		var im := ResourceLoader.load(file, "Image")
		if im is CompressedTexture2D and not resource_map.has(im.get_rid()):
			images_container.add_file(im)
			var detected_size = im.get_size()
			if resource_map.is_empty():
				var tile_size := Vector2(float(detected_size.x) / 6.0, float(detected_size.y) / 4.0)
				x_size_line_edit.text = str(tile_size.x)
				y_size_line_edit.text = str(tile_size.y)
				x_size_line_edit.editable = false
				y_size_line_edit.editable = false
			resource_map[im.get_rid()] = im


func _on_images_container_terrain_list_entry_removed(removed_resource_id: RID) -> void:
	resource_map.erase(removed_resource_id)
	if resource_map.size() == 0:
		x_size_line_edit.text = ""
		y_size_line_edit.text = ""
		x_size_line_edit.editable = true
		y_size_line_edit.editable = true


func _on_xy_size_line_edit_text_changed(_new_text: String) -> void:
	print(_new_text)
	if  num_regex.search(x_size_line_edit.text) and num_regex.search(y_size_line_edit.text):
		generate_template_button.disabled = false
	else:
		generate_template_button.disabled = true
