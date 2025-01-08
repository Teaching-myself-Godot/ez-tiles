@tool
extends CenterContainer

signal drop_files(files : PackedStringArray)


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
