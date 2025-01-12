@tool
extends Control
class_name EZTilesDrawDock

var under_edit : TileMapLayer = null
var hint_label : Label

var prev_pos := Vector2i.ZERO
var remembered_cells := {}
var viewport_has_mouse := false

const EZ_NEIGHBOUR_MAP := {
	"....O...." : Vector2i.ZERO,
	"....OX..." : Vector2i(0,3),
	"....O..X." : Vector2i(1,0),
	".X..O..X." : Vector2i(1,1),
	".X..O...." : Vector2i(1,2),
	"...XOX..." : Vector2i(1,3),
	"...XO...." : Vector2i(2,3),
	"....OX.X." : Vector2i(3,0),
	".X..OX.X." : Vector2i(3,1),
	".X..OX..." : Vector2i(3,2),
	"...XOX.X." : Vector2i(4,0),
	".X.XOX.X." : Vector2i(4,1),
	".X.XOX..." : Vector2i(4,2),
	"...XO..X." : Vector2i(5,0),
	".X.XO..X." : Vector2i(5,1),
	".X.XO...." : Vector2i(5,2)
}

func _enter_tree() -> void:
	hint_label = find_child("HintLabel")


func activate(node : TileMapLayer):
	remembered_cells = {}
	under_edit = node
	hint_label.hide()
	if under_edit.has_meta("_is_ez_tiles_generated"):
		print("check da box")
	else:
		print("uncheck da box")


func deactivate():
	under_edit = null
	hint_label.show()


func _place_back_remembered_cells() -> void:
	for prev_pos in remembered_cells.keys():
		if remembered_cells[prev_pos][0] > -1:
			under_edit.set_cell(prev_pos, remembered_cells[prev_pos][0], remembered_cells[prev_pos][1])
		else:
			under_edit.erase_cell(prev_pos)
	remembered_cells.clear()


func _remember_cell(tile_pos : Vector2i) -> void:
	if under_edit.get_cell_source_id(tile_pos) > -1:
		remembered_cells[tile_pos] = [under_edit.get_cell_source_id(tile_pos), under_edit.get_cell_atlas_coords(tile_pos)]
	else:
		remembered_cells[tile_pos] = [-1, Vector2i.ZERO]


func _place_cells_preview(cells_in_current_draw_area : Array[Vector2i], source_id : int) -> void:
	for tile_pos in cells_in_current_draw_area:
		_remember_cell(tile_pos)
		under_edit.set_cell(tile_pos, source_id, _get_ez_atlas_coord(tile_pos))
		_update_atlas_coords(_get_neighbors(tile_pos))


func _commit_cell_placement(cells_in_current_draw_area : Array[Vector2i]) -> void:
	remembered_cells.clear()
	for tile_pos in cells_in_current_draw_area:
		_remember_cell(tile_pos)
		for neighbor_pos in _get_neighbors(tile_pos):
			_remember_cell(tile_pos)
	

func _update_atlas_coords(cells : Array[Vector2i]) -> void:
	for tile_pos in cells:
		_remember_cell(tile_pos)
		under_edit.set_cell(tile_pos, under_edit.get_cell_source_id(tile_pos), _get_ez_atlas_coord(tile_pos))


func _erase_cells(cells : Array[Vector2i]):
	for tile_pos in cells:
		under_edit.erase_cell(tile_pos)
		_update_atlas_coords(_get_neighbors(tile_pos))


func _get_neighbors(tile_pos : Vector2i) -> Array[Vector2i]:
	return [tile_pos + Vector2i.LEFT, tile_pos + Vector2i.UP, tile_pos + Vector2i.DOWN, tile_pos + Vector2i.RIGHT]


func _get_ez_atlas_coord(tile_pos : Vector2i) -> Vector2i:
	var l = "X" if under_edit.get_cell_source_id(tile_pos + Vector2i.LEFT) > -1 else "."
	var r = "X" if under_edit.get_cell_source_id(tile_pos + Vector2i.RIGHT) > -1 else ".";
	var t = "X" if under_edit.get_cell_source_id(tile_pos + Vector2i.UP) > -1 else "."
	var b = "X" if under_edit.get_cell_source_id(tile_pos + Vector2i.DOWN) > -1 else ".";
	var fmt = ".%s.%sO%s.%s." % [t, l, r, b]
	return EZ_NEIGHBOUR_MAP[fmt]  if fmt in EZ_NEIGHBOUR_MAP else Vector2i.ZERO


func handle_drawing_input(tile_pos : Vector2i, lmb_pressed : bool, rmb_pressed) -> void:
	if is_instance_valid(under_edit):
		_place_back_remembered_cells()
		_place_cells_preview([tile_pos], 0)
		if lmb_pressed:
			_commit_cell_placement([tile_pos])
		elif rmb_pressed:
			_erase_cells([tile_pos])
			_commit_cell_placement([tile_pos])


func handle_mouse_entered():
	viewport_has_mouse = true
	remembered_cells.clear()


func handle_mouse_out():
	viewport_has_mouse = false
	_place_back_remembered_cells()
