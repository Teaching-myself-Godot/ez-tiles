@tool
class_name EZTilesDock

extends HBoxContainer

var images_container : ImagesContainer

func _enter_tree() -> void:
	images_container = find_child("ImagesContainer")


func _on_file_menu_load_files(files : PackedStringArray) -> void:
	load_files(files)


func _on_images_container_drop_files(files: PackedStringArray) -> void:
	load_files(files)


func load_files(files : PackedStringArray):
	for file in files:
		var im := ResourceLoader.load(file, "Image")
		if im is CompressedTexture2D:
			images_container.add_file(file)

