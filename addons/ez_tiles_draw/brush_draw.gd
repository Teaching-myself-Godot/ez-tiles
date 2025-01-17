@tool
extends PanelContainer

var brush_size : int = 1



func _on_range_slider_with_line_edit_value_changed(value: int) -> void:
	brush_size = value
