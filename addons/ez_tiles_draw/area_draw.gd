@tool
extends Control
class_name AreaDraw

enum Shape {RECTANGLE, SLOPE_TL, SLOPE_TR, SLOPE_BR, SLOPE_BL}
var shape := Shape.RECTANGLE
var preview_container : GridContainer

func _enter_tree() -> void:
	preview_container = find_child("PreviewGridContainer")


func update_grid_preview(terrain_texture : Texture2D, tile_size : Vector2i):
	for i in range(preview_container.get_child_count()):
		var y := i / preview_container.columns
		var x := i % preview_container.columns
		var tex_rect : TextureRect = preview_container.get_child(i)
		var atlas_texture : AtlasTexture = tex_rect.texture if tex_rect.texture is AtlasTexture else  AtlasTexture.new()
		atlas_texture.atlas = terrain_texture
		if x == 0 and y == 0:
			atlas_texture.region = Rect2i(Vector2i(3, 0) * tile_size, tile_size)
		elif x == 3 and y == 0:
			atlas_texture.region = Rect2i(Vector2i(5, 0) * tile_size, tile_size)
		elif y == 0:
			atlas_texture.region = Rect2i(Vector2i(4, 0) * tile_size, tile_size)
		elif y == 3 and x == 0:
			atlas_texture.region = Rect2i(Vector2i(3, 2) * tile_size, tile_size)
		elif y == 3 and x == 3:
			atlas_texture.region = Rect2i(Vector2i(5, 2) * tile_size, tile_size)
		elif y == 3:
			atlas_texture.region = Rect2i(Vector2i(4, 2) * tile_size, tile_size)
		elif x == 0:
			atlas_texture.region = Rect2i(Vector2i(3, 1) * tile_size, tile_size)
		elif x == 3:
			atlas_texture.region = Rect2i(Vector2i(5, 1) * tile_size, tile_size)
		else:
			atlas_texture.region = Rect2i(Vector2i(4, 1) * tile_size, tile_size)
		tex_rect.texture = atlas_texture


func _on_rectangles_button_pressed() -> void:
	shape = Shape.RECTANGLE


func _on_slopes_tl_button_pressed() -> void:
	shape = Shape.SLOPE_TL


func _on_slopes_tr_button_pressed() -> void:
	shape = Shape.SLOPE_TR


func _on_slopes_br_button_pressed() -> void:
	shape = Shape.SLOPE_BR


func _on_slopes_bl_button_pressed() -> void:
	shape = Shape.SLOPE_BL
