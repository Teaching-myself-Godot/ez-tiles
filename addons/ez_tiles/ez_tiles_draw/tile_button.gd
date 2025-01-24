@tool
extends Button
class_name TileButton

signal clicked(coords : Vector2i)

var coords := Vector2i.ZERO

func _on_pressed() -> void:
	clicked.emit(coords)
	button_pressed = true
