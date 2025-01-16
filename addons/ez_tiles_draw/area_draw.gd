@tool
extends Control
class_name AreaDraw

enum Shape {RECTANGLE, SLOPE_TL, SLOPE_TR, SLOPE_BR, SLOPE_BL}
var shape := Shape.RECTANGLE
var preview_container : GridContainer

const TL := Vector2i(3, 0)
const TR := Vector2i(5, 0)
const TM := Vector2i(4, 0)
const BL := Vector2i(3, 2)
const BR := Vector2i(5, 2)
const BM := Vector2i(4, 2)
const LM := Vector2i(3, 1)
const RM := Vector2i(5, 1)
const CM := Vector2i(4, 1)
const XX := null

const SHAPE_MAP := {
	Shape.RECTANGLE: [
		[TL, TM, TM, TM, TR],
		[LM, CM, CM, CM, RM],
		[LM, CM, CM, CM, RM],
		[BL, BM, BM, BM, BR],
	],
	Shape.SLOPE_TL: [
		[XX, XX, XX, TL, TM],
		[XX, XX, TL, CM, CM],
		[XX, TL, CM, CM, CM],
		[TL, CM, CM, CM, CM],
	],
	Shape.SLOPE_TR: [
		[TM, TR, XX, XX, XX],
		[CM, CM, TR, XX, XX],
		[CM, CM, CM, TR, XX],
		[CM, CM, CM, CM, TR],
	],
	Shape.SLOPE_BR: [
		[CM, CM, CM, CM, BR],
		[CM, CM, CM, BR, XX],
		[CM, CM, BR, XX, XX],
		[BM, BR, XX, XX, XX],
	],
	Shape.SLOPE_BL: [
		[BL, CM, CM, CM, CM],
		[XX, BL, CM, CM, CM],
		[XX, XX, BL, CM, CM],
		[XX, XX, XX, BL, BM],
	],
}

var cur_terrain_texture : Texture2D
var cur_tile_size : Vector2i

func _enter_tree() -> void:
	preview_container = find_child("PreviewGridContainer")


func _get_empty_tex(tile_size : Vector2i) -> Texture2D:
	var plc_tex := GradientTexture2D.new()
	plc_tex.width = tile_size.x
	plc_tex.height = tile_size.y
	plc_tex.gradient = Gradient.new()
	plc_tex.gradient.colors = [Color.TRANSPARENT]
	return plc_tex

func update_grid_preview(terrain_texture : Texture2D = cur_terrain_texture, tile_size : Vector2i = cur_tile_size):
	cur_terrain_texture = terrain_texture
	cur_tile_size = tile_size 
	var i := 0
	for y in range(SHAPE_MAP[shape].size()):
		for x in range(SHAPE_MAP[shape][y].size()):
			var tex_rect : TextureRect = preview_container.get_child(i)
			i += 1
			if not is_instance_valid(tex_rect):
				continue
			if SHAPE_MAP[shape][y][x] == null:
				tex_rect.texture = _get_empty_tex(tile_size)
				continue
			var atlas_texture : AtlasTexture = tex_rect.texture if tex_rect.texture is AtlasTexture else  AtlasTexture.new()
			atlas_texture.atlas = terrain_texture
			atlas_texture.region = Rect2i(SHAPE_MAP[shape][y][x] * tile_size, tile_size)
			tex_rect.texture = atlas_texture


func _on_rectangles_button_pressed() -> void:
	shape = Shape.RECTANGLE
	update_grid_preview()


func _on_slopes_tl_button_pressed() -> void:
	shape = Shape.SLOPE_TL
	update_grid_preview()


func _on_slopes_tr_button_pressed() -> void:
	shape = Shape.SLOPE_TR
	update_grid_preview()


func _on_slopes_br_button_pressed() -> void:
	shape = Shape.SLOPE_BR
	update_grid_preview()


func _on_slopes_bl_button_pressed() -> void:
	shape = Shape.SLOPE_BL
	update_grid_preview()


static func get_cells_rectangle(p1 : Vector2i, p2 : Vector2i) -> Array[Vector2i]:
	var cells : Array[Vector2i] = []
	for x in range(p1.x, p2.x + 1):
		for y in range(p1.y, p2.y + 1):
			cells.append(Vector2i(x, y))
	return cells


static func get_cells_slope_tl(p1 : Vector2i, p2 : Vector2i) -> Array[Vector2i]:
	var cells : Array[Vector2i] = []
	var width := p2.x - p1.x + 1
	var height := p2.y - p1.y + 1
	var sq_siz := min(width, height)
	for y in range(sq_siz):
		for x in range(sq_siz - y - 1 if sq_siz - y - 1 > 0 else 0, sq_siz):
			cells.append(Vector2i(p1.x + x, p1.y + y))
	if width > sq_siz:
		for x in range(sq_siz, width):
			for y in range(height):
				cells.append(Vector2i(p1.x + x, p1.y + y))
	else:
		for y in range(sq_siz, height):
			for x in range(width):
				cells.append(Vector2i(p1.x + x, p1.y + y))
	return cells


static func get_cells_slope_bl(p1 : Vector2i, p2 : Vector2i) -> Array[Vector2i]:
	var cells : Array[Vector2i] = []
	var width := p2.x - p1.x + 1
	var height := p2.y - p1.y + 1
	var sq_siz := min(width, height)

	if width > sq_siz:
		for x in range(sq_siz, width):
			for y in range(height):
				cells.append(Vector2i(p1.x + x, p1.y + y))
		for y in range(sq_siz):
			for x in range(sq_siz - (height-y) if sq_siz - (height-y) > 0 else 0, sq_siz):
				cells.append(Vector2i(p1.x + x, p1.y + y))
	else:
		for y in range(height):
			for x in range(sq_siz - (height-y) if sq_siz - (height-y) > 0 else 0, sq_siz):
				cells.append(Vector2i(p1.x + x, p1.y + y))
	return cells
