@tool
extends PanelContainer

class_name Stamp

var style_box_normal : StyleBoxFlat
var style_box_hover : StyleBoxFlat
var style_box_selected : StyleBoxFlat
var grid_container : GridContainer
var is_selected := false
var stamp_size := Vector2i.ONE
var tile_textures : Array[TextureRect] = []
var tile_map_layer_under_edit : TileMapLayer

signal selected()

func _enter_tree() -> void:
	style_box_normal = preload("res://addons/ez_tiles_draw/stamp.stylebox")
	style_box_hover = preload("res://addons/ez_tiles_draw/stamp_hover.stylebox")
	style_box_selected = preload("res://addons/ez_tiles_draw/stamp_selected.stylebox")
	grid_container = find_child("GridContainer")
	grid_container.columns = stamp_size.x
	for tt in tile_textures:
		grid_container.add_child(tt)


func deselect():
	is_selected = false
	add_theme_stylebox_override("panel", style_box_normal)


func _on_mouse_entered() -> void:
	if not is_selected:
		add_theme_stylebox_override("panel", style_box_hover)


func _on_mouse_exited() -> void:
	if not is_selected:
		add_theme_stylebox_override("panel", style_box_normal)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected.emit()
			is_selected = true
			add_theme_stylebox_override("panel", style_box_selected)


func _on_remove_button_pressed() -> void:
	queue_free()
