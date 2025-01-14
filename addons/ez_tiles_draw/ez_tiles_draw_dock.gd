@tool
extends Control
class_name EZTilesDrawDock

enum NeighbourMode {INCLUSIVE, EXCLUSIVE, PEERING_BIT}
enum DragMode {AREA, BRUSH, STAMP}

const EZ_TILE_CUSTOM_META := "_is_ez_tiles_generated"

var TerrainPickerEntry
var under_edit : TileMapLayer = null
var hint_label : Label
var main_container : Control
var default_editor_check_button : Button
var terrain_list_container : VBoxContainer
var drag_start := Vector2i.ZERO
var drag_mode := DragMode.BRUSH

var remembered_cells := {}
var viewport_has_mouse := false
var lmb_is_down := false
var rmb_is_down := false
var current_terrain_id := 0
var neighbour_mode := NeighbourMode.INCLUSIVE

var rect_preview_container : GridContainer

#const VEC_TO_CELL_NEIGHBOUR:= {
	#Vector2i.LEFT: TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	#Vector2i.RIGHT: TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	#Vector2i.UP: TileSet.CELL_NEIGHBOR_TOP_SIDE,
	#Vector2i.DOWN: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
#}

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
	TerrainPickerEntry = preload("res://addons/ez_tiles_draw/terrain_picker_entry.tscn")
	hint_label = find_child("HintLabel")
	main_container = find_child("MainVBoxContainer")
	default_editor_check_button = find_child("DefaultEditorCheckButton")
	terrain_list_container = find_child("TerrainListVboxContainer")
	rect_preview_container = find_child("RectanglePreviewGridContainer")


func activate(node : TileMapLayer):
	current_terrain_id = 0
	remembered_cells = {}
	under_edit = node
	hint_label.hide()
	main_container.show()

	for child in terrain_list_container.get_children():
		if is_instance_valid(child):
			child.queue_free()

	if under_edit.tile_set.get_terrain_sets_count() > 0:
		for terrain_id in range(under_edit.tile_set.get_terrains_count(0)):
			var entry : TerrainPickerEntry = TerrainPickerEntry.instantiate()
			entry.terrain_name = under_edit.tile_set.get_terrain_name(0, terrain_id)
			entry.texture_resource = _get_first_texture_for_terrain(terrain_id)
			entry.terrain_id = terrain_id
			entry.selected.connect(_on_terrain_selected)
			terrain_list_container.add_child(entry)
		_update_rectangle_grid_preview()

	if under_edit.has_meta(EZ_TILE_CUSTOM_META):
		default_editor_check_button.button_pressed = true
	else:
		default_editor_check_button.button_pressed = false


func _update_rectangle_grid_preview():
	for i in range(rect_preview_container.get_child_count()):
		var y := i / rect_preview_container.columns
		var x := i % rect_preview_container.columns
		var tex_rect : TextureRect = rect_preview_container.get_child(i)
		var atlas_texture : AtlasTexture = tex_rect.texture if tex_rect.texture is AtlasTexture else  AtlasTexture.new()
		atlas_texture.atlas = _get_first_texture_for_terrain(current_terrain_id)
		if x == 0 and y == 0:
			atlas_texture.region = Rect2i(Vector2i(3, 0) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		elif x == 3 and y == 0:
			atlas_texture.region = Rect2i(Vector2i(5, 0) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		elif y == 0:
			atlas_texture.region = Rect2i(Vector2i(4, 0) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		elif y == 3 and x == 0:
			atlas_texture.region = Rect2i(Vector2i(3, 2) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		elif y == 3 and x == 3:
			atlas_texture.region = Rect2i(Vector2i(5, 2) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		elif y == 3:
			atlas_texture.region = Rect2i(Vector2i(4, 2) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		elif x == 0:
			atlas_texture.region = Rect2i(Vector2i(3, 1) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		elif x == 3:
			atlas_texture.region = Rect2i(Vector2i(5, 1) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		else:
			atlas_texture.region = Rect2i(Vector2i(4, 1) * under_edit.tile_set.tile_size, under_edit.tile_set.tile_size)
		tex_rect.texture = atlas_texture


func _get_first_source_id_for_terrain(terrain_id : int) -> int:
	for i in range(under_edit.tile_set.get_source_count()):
		var source_id := under_edit.tile_set.get_source_id(i)
		var source : TileSetAtlasSource  = under_edit.tile_set.get_source(source_id)
		if source.get_tiles_count() > 0:
			var tile_data = source.get_tile_data(source.get_tile_id(0), 0)
			if tile_data.terrain == terrain_id:
				return source_id
	printerr("Terrain %d not found in tile set sources: " % terrain_id)
	return terrain_id # assume equal in case of inconsistent data


func _get_first_texture_for_terrain(terrain_id : int) -> Texture2D:
	for i in range(under_edit.tile_set.get_source_count()):
		var source_id := under_edit.tile_set.get_source_id(i)
		var source : TileSetAtlasSource  = under_edit.tile_set.get_source(source_id)
		if source.get_tiles_count() > 0:
			var tile_data = source.get_tile_data(source.get_tile_id(0), 0)
			if tile_data.terrain == terrain_id:
				return source.texture
	return null



func deactivate():
	under_edit = null
	hint_label.show()
	main_container.hide()


func _on_terrain_selected(id : int) -> void:
	current_terrain_id = id
	_update_rectangle_grid_preview()

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


func _place_cells_preview(cells_in_current_draw_area : Array[Vector2i], terrain_id : int) -> void:
	for tile_pos in cells_in_current_draw_area:
		_remember_cell(tile_pos)
		for n_pos in _get_neighbors(tile_pos):
			_remember_cell(n_pos)
		
	for tile_pos in cells_in_current_draw_area:
		under_edit.set_cell(tile_pos, _get_first_source_id_for_terrain(terrain_id), _get_ez_atlas_coord(tile_pos, terrain_id))
		_update_atlas_coords(_get_neighbors(tile_pos))


func _commit_cell_placement(cells_in_current_draw_area : Array[Vector2i]) -> void:
	remembered_cells.clear()
	for tile_pos in cells_in_current_draw_area:
		_remember_cell(tile_pos)


func _update_atlas_coords(cells : Array[Vector2i]) -> void:
	for tile_pos in cells:
		under_edit.set_cell(tile_pos, under_edit.get_cell_source_id(tile_pos), 
				_get_ez_atlas_coord(tile_pos, under_edit.get_cell_source_id(tile_pos)))


func _erase_cells(cells : Array[Vector2i]):
	for tile_pos in cells:
		under_edit.erase_cell(tile_pos)
		_update_atlas_coords(_get_neighbors(tile_pos))


func _get_neighbors(tile_pos : Vector2i) -> Array[Vector2i]:
	return [tile_pos + Vector2i.LEFT, tile_pos + Vector2i.UP, tile_pos + Vector2i.DOWN, tile_pos + Vector2i.RIGHT]


func _get_godot_atlas_coords(cell : Vector2i, for_source_id : int) -> Vector2i:
	# TODO: implement
	return Vector2i.ZERO


func _consider_a_neighbour(cell : Vector2i, for_source_id : int) -> bool:
	var neighbour_source_id := under_edit.get_cell_source_id(cell)
	match(neighbour_mode):
		NeighbourMode.INCLUSIVE:
			return neighbour_source_id > -1
		NeighbourMode.EXCLUSIVE:
			return neighbour_source_id > -1 and neighbour_source_id == for_source_id
		NeighbourMode.PEERING_BIT:
			printerr("illegal state: you should invoke _get_godot_atlas_coords")
			return false
	return false


func _get_ez_atlas_coord(tile_pos : Vector2i, for_terrain_id : int) -> Vector2i:
	if neighbour_mode == NeighbourMode.PEERING_BIT:
		return _get_godot_atlas_coords(tile_pos, for_terrain_id)

	# EZ Tiles considers the source_id to be equal to the terrain_id
	# Therefore, in these modes the complexity of searching the correct texture is lost 
	#   (thus, making things EZ. is a lot less flexible)
	# - In inclusive mode all terrains in neighboring tiles are considered to be  the same terrain
	# - in exclusive mode the terrains from the exact same TileSetSource are considered the same terrain
	var l = "X" if _consider_a_neighbour(tile_pos + Vector2i.LEFT, for_terrain_id) else "."
	var r = "X" if _consider_a_neighbour(tile_pos + Vector2i.RIGHT, for_terrain_id) else ".";
	var t = "X" if _consider_a_neighbour(tile_pos + Vector2i.UP, for_terrain_id) else "."
	var b = "X" if _consider_a_neighbour(tile_pos + Vector2i.DOWN, for_terrain_id) else ".";

	var fmt = ".%s.%sO%s.%s." % [t, l, r, b]
	return EZ_NEIGHBOUR_MAP[fmt]  if fmt in EZ_NEIGHBOUR_MAP else Vector2i.ZERO


func _on_default_editor_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		under_edit.set_meta(EZ_TILE_CUSTOM_META, true)
	else:
		under_edit.remove_meta(EZ_TILE_CUSTOM_META)


func _on_neighbour_mode_option_button_item_selected(index: NeighbourMode) -> void:
	neighbour_mode = index


func _on_tab_container_tab_changed(tab: DragMode) -> void:
	drag_mode = tab


func _get_cell_range(p1 : Vector2i, p2 : Vector2i) -> Array[Vector2i]:
	var cells : Array[Vector2i] = []
	var from_x := p1.x if p1.x < p2.x else p2.x
	var to_x := p1.x if p1.x > p2.x else p2.x
	var from_y := p1.y if p1.y < p2.y else p2.y
	var to_y := p1.y if p1.y > p2.y else p2.y

	for x in range(from_x, to_x + 1):
		for y in range(from_y, to_y + 1):
			cells.append(Vector2i(x, y))
	return cells


func handle_mouse_move(tile_pos : Vector2i, mouse_pos : Vector2i) -> void:
	if is_instance_valid(under_edit):
		if drag_mode == DragMode.BRUSH:
			_place_back_remembered_cells()
			_place_cells_preview([tile_pos], current_terrain_id)
			if lmb_is_down:
				_commit_cell_placement([tile_pos])
			elif rmb_is_down:
				_erase_cells([tile_pos])
				_commit_cell_placement([tile_pos])
		elif drag_mode == DragMode.AREA:
			if lmb_is_down:
				_place_back_remembered_cells()
				_place_cells_preview(_get_cell_range(drag_start, tile_pos), current_terrain_id)
			elif rmb_is_down:
				_place_back_remembered_cells()
				_erase_cells(_get_cell_range(drag_start, tile_pos))
			else:
				_commit_cell_placement(_get_cell_range(drag_start, tile_pos))


func handle_mouse_up(button : MouseButton):
	match(button):
		MouseButton.MOUSE_BUTTON_LEFT:
			lmb_is_down = false
		MouseButton.MOUSE_BUTTON_RIGHT:
			rmb_is_down = false

	print("handle_mouse_up: " + str(button))


func handle_mouse_down(button : MouseButton, tile_pos: Vector2i):
	drag_start = tile_pos
	match(button):
		MouseButton.MOUSE_BUTTON_LEFT:
			lmb_is_down = true
		MouseButton.MOUSE_BUTTON_RIGHT:
			rmb_is_down = true


func handle_mouse_entered():
	viewport_has_mouse = true
	remembered_cells.clear()


func handle_mouse_out():
	lmb_is_down = false
	rmb_is_down = false
	viewport_has_mouse = false
	_place_back_remembered_cells()
