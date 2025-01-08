@tool
extends ScrollContainer
class_name  ImagesContainer

signal drop_files(files : PackedStringArray)
signal terrain_list_entry_removed(resource_id : RID)
signal terrain_list_entry_selected(resource_id : RID)

var image_list : VBoxContainer
var hint_label : Label
var TerrainListEntry

func _enter_tree() -> void:
	TerrainListEntry = preload("res://addons/ez_tiles/terrain_list_entry.tscn")
	image_list = find_child("ImageList")
	hint_label = find_child("HintLabel")	


func _can_drop_data(at_position : Vector2, data : Variant) -> bool:
	if not typeof(data) == TYPE_DICTIONARY and "type" in data and data["type"] == "files":
		return false
	
	for file : String in data["files"]:
		if (file.ends_with(".png") or file.ends_with(".svg") or file.ends_with(".webp") or 
				file.ends_with(".jpg") or file.ends_with(".bmp") or file.ends_with(".tga")):
			return true

	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position, data):
		drop_files.emit(data["files"])


func add_file(img_resource : CompressedTexture2D):
	hint_label.hide()
	var new_entry : TerrainListEntry = TerrainListEntry.instantiate()
	new_entry.terrain_name = img_resource.resource_path
	new_entry.texture_resource = img_resource
	image_list.add_child(new_entry)
	image_list.show()
	new_entry.removed.connect(func(): terrain_list_entry_removed.emit(img_resource.get_rid()))
	new_entry.selected.connect(func(): terrain_list_entry_selected.emit(img_resource.get_rid()))
