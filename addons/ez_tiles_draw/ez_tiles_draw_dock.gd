@tool
extends Control
class_name EZTilesDrawDock

var under_edit : TileMapLayer = null
var hint_label : Label


func _enter_tree() -> void:
	hint_label = find_child("HintLabel")


func activate(node : TileMapLayer):
	under_edit = node
	hint_label.hide()
	if under_edit.has_meta("_is_ez_tiles_generated"):
		print("check da box")
	else:
		print("uncheck da box")


func deactivate():
	under_edit = null
	hint_label.show()


func handle_tile_pos_changed(tile_pos : Vector2i, lmb_pressed : bool):
	if lmb_pressed and is_instance_valid(under_edit) and visible:
		under_edit.set_cell(tile_pos, 0, Vector2.ZERO)

