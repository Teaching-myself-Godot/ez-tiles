@tool
extends ScrollContainer
class_name  ImagesContainer

signal drop_files(files : PackedStringArray)
signal terrain_list_entry_removed(resource_id : RID)
signal terrain_list_entry_selected(resource_id : RID)
signal terrain_list_collision_type_selected(resource_id : RID, type_id : EZTilesDock.CollisionType)

var image_list : VBoxContainer
var hint_label : Label
var TerrainListEntry
var terrain_name_regex := RegEx.new()


func _enter_tree() -> void:
	TerrainListEntry = preload("res://addons/ez_tiles/terrain_list_entry.tscn")
	image_list = find_child("ImageList")
	hint_label = find_child("HintLabel")
	terrain_name_regex.compile("^.*\\/([^\\.]+)\\..*$")


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


func add_file(img_resource : CompressedTexture2D, invalid_message : String = ""):
	hint_label.hide()
	var new_entry : TerrainListEntry = TerrainListEntry.instantiate()
	var regex_result := terrain_name_regex.search(img_resource.resource_path).strings
	if regex_result.size() < 2:
		new_entry.terrain_name = img_resource.resource_path
	else:
		new_entry.terrain_name = regex_result[1].replace("_", " ")
	new_entry.texture_resource = img_resource
	new_entry.warning_message = invalid_message
	image_list.add_child(new_entry)
	image_list.show()
	new_entry.removed.connect(func(): terrain_list_entry_removed.emit(img_resource.get_rid()))
	new_entry.selected.connect(func(): terrain_list_entry_selected.emit(img_resource.get_rid()))
	new_entry.collision_type_selected.connect(
			func(type_id : EZTilesDock.CollisionType): terrain_list_collision_type_selected.emit(img_resource.get_rid(), type_id)
	)

func gather_data() -> Array:
	var data := []
	for entry : TerrainListEntry in image_list.get_children():
		data.append(entry.gather_data())
	return data
