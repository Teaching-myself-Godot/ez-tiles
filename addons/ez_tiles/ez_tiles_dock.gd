@tool
class_name EZTilesDock

extends HBoxContainer

var images_container : ImagesContainer
var x_size_line_edit : LineEdit
var y_size_line_edit : LineEdit

var resource_map : Dictionary = {}

func _enter_tree() -> void:
	images_container = find_child("ImagesContainer")
	x_size_line_edit = find_child("XSizeLineEdit")
	y_size_line_edit = find_child("YSizeLineEdit")

func _on_file_menu_load_files(files : PackedStringArray) -> void:
	load_files(files)


func _on_images_container_drop_files(files: PackedStringArray) -> void:
	load_files(files)


func load_files(files : PackedStringArray):
	var detected_size := Vector2.ZERO
	for file in files:
		var im := ResourceLoader.load(file, "Image")
		if im is CompressedTexture2D and not resource_map.has(im.get_rid()):
			images_container.add_file(im)
			resource_map[im.get_rid()] = im
			detected_size = im.get_size()

	if detected_size and x_size_line_edit.text == "":
		var tile_size := Vector2(float(detected_size.x) / 6.0, float(detected_size.y) / 4.0)
		x_size_line_edit.text = str(tile_size.x)
		y_size_line_edit.text = str(tile_size.y)


func _on_images_container_terrain_list_entry_removed(removed_resource_id: RID) -> void:
	resource_map.erase(removed_resource_id)
	if resource_map.size() == 0:
		x_size_line_edit.text = ""
		y_size_line_edit.text = ""
