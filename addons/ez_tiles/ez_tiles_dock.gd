@tool
class_name EZTilesDock

extends HBoxContainer

signal request_tile_map_layer(tile_set : TileSet)

enum CollisionType {
	RECT,
	TOP_SLOPES,
	NONE,
	ALL_SLOPES,
	BOTTOM_SLOPES,
	ROUNDED,
	INVERSE_ROUNDED,
	TREE,
	CACTUS,
	NAVIGABLE
}

var collision_previews := {}
var num_regex := RegEx.new()
var images_container : ImagesContainer
var x_size_line_edit : LineEdit
var y_size_line_edit : LineEdit
var generate_template_button : Button
var generate_tileset_button : Button
var generate_tilemaplayer_button : Button
var overlay_texture_rect : TextureRect
var preview_texture_rect : TextureRect
var guide_texture_rect : TextureRect
var reset_zoom_button : Button
var resource_map : Dictionary = {}
var collision_type_map : Dictionary = {}
var zoom := 1.0
var save_template_file_dialog : EditorFileDialog
var save_tile_set_file_dialog : EditorFileDialog
var hint_color := Color(0, 0, 0, 0.702)
var collision_layer_color := Color(1.0, 0.0, 0.0, 0.4)

func _enter_tree() -> void:
	num_regex.compile("^\\d+\\.?\\d*$")
	images_container = find_child("ImagesContainer")
	x_size_line_edit = find_child("XSizeLineEdit")
	y_size_line_edit = find_child("YSizeLineEdit")
	generate_template_button = find_child("GenerateTemplateButton")
	generate_tileset_button = find_child("GenerateTileSetButton")
	generate_tilemaplayer_button = find_child("GenerateTileMapLayerButton")
	overlay_texture_rect = find_child("OverlayTextureRect")
	preview_texture_rect = find_child("PreviewTextureRect")
	guide_texture_rect = find_child("GuideTextureRect")
	reset_zoom_button = find_child("ResetZoomButton")
	preview_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	save_template_file_dialog = EditorFileDialog.new()
	save_template_file_dialog.add_filter("*.png", "PNG image")
	save_template_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	save_template_file_dialog.file_selected.connect(_on_save_template_file_selected)
	EditorInterface.get_base_control().add_child(save_template_file_dialog)
	save_tile_set_file_dialog = EditorFileDialog.new()
	save_tile_set_file_dialog.add_filter("*.tres,*.res", "Resource file")
	save_tile_set_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	save_tile_set_file_dialog.file_selected.connect(_on_save_tile_set_file_selected)
	EditorInterface.get_base_control().add_child(save_tile_set_file_dialog)
	collision_previews[CollisionType.RECT] = preview_texture_rect.find_child("Rectangles")
	collision_previews[CollisionType.ALL_SLOPES] = preview_texture_rect.find_child("Sloped (All Corners)")
	collision_previews[CollisionType.BOTTOM_SLOPES] = preview_texture_rect.find_child("Sloped (Bottom Corners)")
	collision_previews[CollisionType.TOP_SLOPES] = preview_texture_rect.find_child("Sloped (Top Corners)")
	collision_previews[CollisionType.ROUNDED] = preview_texture_rect.find_child("Rounded Corners")
	collision_previews[CollisionType.INVERSE_ROUNDED] = preview_texture_rect.find_child("Rounded Corners (Inverse)")
	collision_previews[CollisionType.TREE] = preview_texture_rect.find_child("Tree")
	collision_previews[CollisionType.CACTUS] = preview_texture_rect.find_child("Cactus")


func _on_file_menu_load_files(files : PackedStringArray) -> void:
	load_files(files)


func _on_images_container_drop_files(files: PackedStringArray) -> void:
	load_files(files)


func _on_preview_panel_container_drop_files(files: PackedStringArray) -> void:
	load_files(files)


func validate_size(actual : Vector2) -> String:
	var tile_size = Vector2i(
		int(x_size_line_edit.text),
		int(y_size_line_edit.text)
	)
	if not tile_size:
		return ""

	var expected = Vector2i(
		int(x_size_line_edit.text) * 6, 
		int(y_size_line_edit.text) * 4
	)
	if expected.x != actual.x or expected.y != actual.y:
		return """
			Invalid size detected for %dx%d tiles!
			Expected size = %dx%d pixels
			Actual size = %dx%d pixels
		""" % [tile_size.x, tile_size.y, expected.x, expected.y, actual.x, actual.y]
	return ""


func load_files(files : PackedStringArray):
	for file in files:
		var im := ResourceLoader.load(file, "Image")
		if im is CompressedTexture2D and not resource_map.has(im.get_rid()):
			var detected_size = im.get_size()
			images_container.add_file(im, validate_size(detected_size))
			if resource_map.is_empty():
				var tile_size := Vector2(float(detected_size.x) / 6.0, float(detected_size.y) / 4.0)
				x_size_line_edit.text = str(tile_size.x)
				y_size_line_edit.text = str(tile_size.y)
				x_size_line_edit.editable = false
				y_size_line_edit.editable = false
				generate_tileset_button.disabled = false
				generate_tilemaplayer_button.disabled = false
				handle_tilesize_update()

			resource_map[im.get_rid()] = im
			collision_type_map[im.get_rid()] = CollisionType.NONE
			preview_texture_rect.texture = im
			_show_collision_preview(im.get_rid())


func _show_collision_preview(resource_id : RID) -> void:
	for c : Node in collision_previews.values():
		c.hide()
	if collision_type_map.has(resource_id) and collision_previews.has(collision_type_map[resource_id]):
		collision_previews[collision_type_map[resource_id]].show()


func _on_images_container_terrain_list_collision_type_selected(
			resource_id: RID, type_id: EZTilesDock.CollisionType) -> void:
	collision_type_map[resource_id] = type_id
	_on_images_container_terrain_list_entry_selected(resource_id)


func _on_images_container_terrain_list_entry_removed(removed_resource_id : RID) -> void:
	resource_map.erase(removed_resource_id)
	collision_type_map.erase(removed_resource_id)
	if preview_texture_rect.texture and preview_texture_rect.texture.get_rid() == removed_resource_id:
		preview_texture_rect.texture = null

	if resource_map.size() == 0:
		x_size_line_edit.text = ""
		y_size_line_edit.text = ""
		x_size_line_edit.editable = true
		y_size_line_edit.editable = true
		generate_tileset_button.disabled = true
		generate_tilemaplayer_button.disabled = true
		handle_tilesize_update()
		for c : Node2D in collision_previews.values():
			c.hide()


func _on_xy_size_line_edit_text_changed(_new_text: String) -> void:
	handle_tilesize_update()


func _redraw_overlay_texture() -> void:
	var tile_size := Vector2i(int(x_size_line_edit.text), int(y_size_line_edit.text))
	var new_template_overlay := Image.create_empty(tile_size.x * 6, tile_size.y * 4, false, Image.FORMAT_RGBA8)
	for y in range(new_template_overlay.get_height()):
		for x in range(new_template_overlay.get_width()):
			if (
				(x >= tile_size.x * 2 and y < tile_size.y * 3 and x < tile_size.x * 3) or 
				(x < tile_size.x and y >= tile_size.y and y < tile_size.y * 3) or
				(x >= tile_size.x * 3 and y >= tile_size.y * 3)
			):
				new_template_overlay.set_pixel(x, y, hint_color)
	overlay_texture_rect.texture = ImageTexture.create_from_image(new_template_overlay)
	guide_texture_rect.modulate = hint_color
	for c : Node2D in collision_previews.values():
		c.modulate = collision_layer_color

func handle_tilesize_update() -> void:
	if  num_regex.search(x_size_line_edit.text) and num_regex.search(y_size_line_edit.text):
		generate_template_button.disabled = false
		_redraw_overlay_texture()
		resize_texture_rects(1)
	else:
		generate_template_button.disabled = true
		preview_texture_rect.custom_minimum_size = Vector2.ZERO
		overlay_texture_rect.custom_minimum_size = Vector2.ZERO
		guide_texture_rect.custom_minimum_size = Vector2.ZERO
		preview_texture_rect.texture = null


func resize_texture_rects(new_zoom : float):
	zoom = new_zoom
	var new_size := Vector2(
		float(x_size_line_edit.text) * 6 * zoom,
		float(y_size_line_edit.text) * 4 * zoom
	)
	preview_texture_rect.custom_minimum_size = new_size
	overlay_texture_rect.custom_minimum_size = new_size
	guide_texture_rect.custom_minimum_size = new_size
	reset_zoom_button.text = str(zoom * 100) + "%"
	for c : Node2D in collision_previews.values():
		c.scale = Vector2(float(x_size_line_edit.text),		float(y_size_line_edit.text)) * zoom


func _on_images_container_terrain_list_entry_selected(resource_id: RID) -> void:
	preview_texture_rect.texture = resource_map[resource_id]
	_show_collision_preview(resource_id)


func _on_preview_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			resize_texture_rects(zoom + 0.25)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			resize_texture_rects(zoom - 0.25)


func _on_zoom_out_button_pressed() -> void:
	resize_texture_rects(zoom - 0.25)


func _on_reset_zoom_button_pressed() -> void:
	resize_texture_rects(1)


func _on_zoom_in_button_pressed() -> void:
	resize_texture_rects(zoom + 0.25)


func _on_generate_template_button_pressed() -> void:
	save_template_file_dialog.set_current_path(
		"res://template_%dx%d.png" % [int(x_size_line_edit.text), int(y_size_line_edit.text)])
	save_template_file_dialog.popup_file_dialog()


func _on_save_template_file_selected(path : String) -> void:
	var export_image := Image.create_empty(overlay_texture_rect.texture.get_size().x, overlay_texture_rect.texture.get_size().y, false, Image.FORMAT_RGBA8)
	var overlay_image :=  overlay_texture_rect.texture.get_image()
	var guide_image := guide_texture_rect.texture.get_image()
	var tile_size := Vector2(float(x_size_line_edit.text), float(y_size_line_edit.text))
	
	for x in range(overlay_image.get_size().x):
		for y in range(overlay_image.get_size().y):
			if overlay_image.get_pixel(x, y).a > 0.0:
				export_image.set_pixel(x, y, hint_color)
			elif guide_image.get_pixel(int((x / tile_size.x) * 256), int((y / tile_size.y) * 256)).a > 0.0:
				export_image.set_pixel(x, y, hint_color)
	export_image.save_png(path)
	EditorInterface.get_resource_filesystem().scan()


func _on_color_picker_button_color_changed(color: Color) -> void:
	hint_color = color
	_redraw_overlay_texture()


func _on_collision_layer_color_picker_button_color_changed(color: Color) -> void:
	collision_layer_color = color
	for c : Node2D in collision_previews.values():
		c.modulate = collision_layer_color


func _on_generate_tile_set_button_pressed() -> void:
	save_tile_set_file_dialog.set_current_path("res://tile_set.tres")
	save_tile_set_file_dialog.popup_file_dialog()


func _on_save_tile_set_file_selected(path : String) -> void:
	var tile_set := generate_tileset()
	ResourceSaver.save(tile_set, path)
	EditorInterface.get_resource_filesystem().scan()


func _on_generate_tile_map_layer_button_pressed() -> void:
	var tile_set := generate_tileset()
	request_tile_map_layer.emit(tile_set)


func generate_tileset() -> TileSet:
	var raw_intel := images_container.gather_data()
	var tile_set := TileSet.new()
	var physics_layer_added := false
	var nav_layer_added := false
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tile_set.tile_size = Vector2i(int(x_size_line_edit.text), int(y_size_line_edit.text))

	for terrain_id in range(raw_intel.size()):
		tile_set.add_terrain(0, terrain_id)
		tile_set.set_terrain_name(0, terrain_id, raw_intel[terrain_id]["terrain_name"])
		if raw_intel[terrain_id]["layer_type"] != CollisionType.NONE and not physics_layer_added:
			tile_set.add_physics_layer()
			physics_layer_added = true
		if raw_intel[terrain_id]["layer_type"] == CollisionType.NAVIGABLE and not nav_layer_added:
			tile_set.add_navigation_layer()
			nav_layer_added = true

	for terrain_id in range(raw_intel.size()):
		var atlas_source := TileSetAtlasSource.new()
		atlas_source.texture_region_size = tile_set.tile_size
		atlas_source.texture = raw_intel[terrain_id]["texture_resource"]
		tile_set.add_source(atlas_source)
		var created_tiles : Array[TileData] = []
		# row
		created_tiles.append(create_tile(atlas_source, terrain_id, Vector2i(0,0), _get_collision_polygon_for_tile("MC", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_single_neighbour_tile(atlas_source, terrain_id, Vector2i(1,0), raw_intel.size(), TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, _get_collision_polygon_for_tile("VT", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_dual_neighbour_tile(atlas_source, terrain_id, Vector2i(3,0), raw_intel.size(), [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE], _get_collision_polygon_for_tile("TL", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_triple_neighbour_tile(atlas_source, terrain_id, Vector2i(4,0), raw_intel.size(), [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE], _get_collision_polygon_for_tile("TM", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_dual_neighbour_tile(atlas_source, terrain_id, Vector2i(5,0), raw_intel.size(), [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE], _get_collision_polygon_for_tile("TR", atlas_source.texture.get_rid(), tile_set.tile_size)))

		# row
		created_tiles.append(create_dual_neighbour_tile(atlas_source, terrain_id, Vector2i(1,1), raw_intel.size(), [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE], _get_collision_polygon_for_tile("VM", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_triple_neighbour_tile(atlas_source, terrain_id, Vector2i(3,1), raw_intel.size(), [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE], _get_collision_polygon_for_tile("LM", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_all_sides_neighbour_tile(atlas_source, terrain_id, Vector2i(4,1), raw_intel.size(), _get_collision_polygon_for_tile("CM", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_triple_neighbour_tile(atlas_source, terrain_id, Vector2i(5,1), raw_intel.size(), [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE], _get_collision_polygon_for_tile("RM", atlas_source.texture.get_rid(), tile_set.tile_size)))

		# row
		created_tiles.append(create_single_neighbour_tile(atlas_source, terrain_id, Vector2i(1,2), raw_intel.size(), TileSet.CELL_NEIGHBOR_TOP_SIDE, _get_collision_polygon_for_tile("VB", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_dual_neighbour_tile(atlas_source, terrain_id, Vector2i(3,2), raw_intel.size(), [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE], _get_collision_polygon_for_tile("BL", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_triple_neighbour_tile(atlas_source, terrain_id, Vector2i(4,2), raw_intel.size(), [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE], _get_collision_polygon_for_tile("BC", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_dual_neighbour_tile(atlas_source, terrain_id, Vector2i(5,2), raw_intel.size(), [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_LEFT_SIDE], _get_collision_polygon_for_tile("BR", atlas_source.texture.get_rid(), tile_set.tile_size)))

		# row
		created_tiles.append(create_single_neighbour_tile(atlas_source, terrain_id, Vector2i(0,3), raw_intel.size(), TileSet.CELL_NEIGHBOR_RIGHT_SIDE, _get_collision_polygon_for_tile("HL", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_dual_neighbour_tile(atlas_source, terrain_id, Vector2i(1,3), raw_intel.size(), [TileSet.CELL_NEIGHBOR_LEFT_SIDE, TileSet.CELL_NEIGHBOR_RIGHT_SIDE], _get_collision_polygon_for_tile("HM", atlas_source.texture.get_rid(), tile_set.tile_size)))
		created_tiles.append(create_single_neighbour_tile(atlas_source, terrain_id, Vector2i(2,3), raw_intel.size(), TileSet.CELL_NEIGHBOR_LEFT_SIDE, _get_collision_polygon_for_tile("HR", atlas_source.texture.get_rid(), tile_set.tile_size)))
		if raw_intel[terrain_id]["layer_type"] == CollisionType.NAVIGABLE:
			for tile_data : TileData in created_tiles:
				tile_data.set_navigation_polygon(0, _get_new_navigation_rect(Vector2(tile_set.tile_size)))
	return tile_set


func _get_new_navigation_rect(tile_size : Vector2) -> NavigationPolygon:
	var new_navigation_mesh = NavigationPolygon.new()
	var new_vertices = PackedVector2Array([
		Vector2(-0.5, -0.5) * tile_size,
		Vector2(0.5, -0.5) * tile_size,
		Vector2(0.5, 0.5) * tile_size,
		Vector2(-0.5, 0.5) * tile_size
	])
	new_navigation_mesh.vertices = new_vertices
	var new_polygon_indices = PackedInt32Array([0, 1, 2, 3])
	new_navigation_mesh.add_polygon(new_polygon_indices)
	return new_navigation_mesh


func _get_collision_polygon_for_tile(node_name : String, resource_id : RID, tile_size : Vector2) -> PackedVector2Array:
	#print(resource_id, collision_type_map.has(resource_id))
	if not collision_type_map.has(resource_id):
		return PackedVector2Array([])

	if not collision_previews.has(collision_type_map[resource_id]):
		return PackedVector2Array([])
	var polygon_node : Polygon2D = collision_previews[collision_type_map[resource_id]].find_child(node_name)
	if is_instance_valid(polygon_node):
		var poly_points : Array[Vector2] = []
		for point : Vector2 in polygon_node.polygon:
			poly_points.append((point - Vector2(0.5, 0.5)) * tile_size)
		return PackedVector2Array(poly_points)
	return PackedVector2Array([])


func create_tile(atlas_source : TileSetAtlasSource, terrain_id : int, at_pos : Vector2i, collision_polygon_points : PackedVector2Array) -> TileData:
	atlas_source.create_tile(at_pos)
	var new_tile := atlas_source.get_tile_data(at_pos, 0)
	new_tile.terrain_set = 0
	new_tile.terrain = terrain_id
	if not collision_polygon_points.is_empty():
		new_tile.add_collision_polygon(0)
		new_tile.set_collision_polygon_points(0, 0, PackedVector2Array(collision_polygon_points))
	return new_tile


func create_single_neighbour_tile(atlas_source : TileSetAtlasSource, terrain_id : int, at_pos : Vector2i, num_terrains : int, neighbour : int, collision_polygon_points : PackedVector2Array) -> TileData:
	var new_tile := create_tile(atlas_source, terrain_id, at_pos, collision_polygon_points)
	new_tile.set_terrain_peering_bit(neighbour, terrain_id)
	return new_tile


func create_dual_neighbour_tile(atlas_source : TileSetAtlasSource, terrain_id : int, at_pos : Vector2i, num_terrains : int, neighbours : Array[int], collision_polygon_points : PackedVector2Array) -> TileData:
	var new_tile := create_tile(atlas_source, terrain_id, at_pos, collision_polygon_points)
	new_tile.set_terrain_peering_bit(neighbours[0], terrain_id)
	new_tile.set_terrain_peering_bit(neighbours[1], terrain_id)
	return new_tile


func create_triple_neighbour_tile(atlas_source : TileSetAtlasSource, terrain_id : int, at_pos : Vector2i, num_terrains : int, neighbours : Array[int], collision_polygon_points : PackedVector2Array) -> TileData:
	var new_tile := create_tile(atlas_source, terrain_id, at_pos, collision_polygon_points)
	new_tile.set_terrain_peering_bit(neighbours[0], terrain_id)
	new_tile.set_terrain_peering_bit(neighbours[1], terrain_id)
	new_tile.set_terrain_peering_bit(neighbours[2], terrain_id)
	return new_tile


func create_all_sides_neighbour_tile(atlas_source : TileSetAtlasSource, terrain_id : int, at_pos : Vector2i, num_terrains : int, collision_polygon_points : PackedVector2Array) -> TileData:
	var new_tile := create_tile(atlas_source, terrain_id, at_pos, collision_polygon_points)
	new_tile.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE, terrain_id)
	new_tile.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, terrain_id)
	new_tile.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE, terrain_id)
	new_tile.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE, terrain_id)
	return new_tile
