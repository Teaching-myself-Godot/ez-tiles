@tool
class_name EZTilesDock

extends HBoxContainer

enum LayerType {COLLIDES, NONE, NAVIGABLE}
var num_regex := RegEx.new()
var images_container : ImagesContainer
var x_size_line_edit : LineEdit
var y_size_line_edit : LineEdit
var generate_template_button : Button
var generate_tileset_button : Button
var overlay_texture_rect : TextureRect
var preview_texture_rect : TextureRect
var guide_texture_rect : TextureRect
var reset_zoom_button : Button
var resource_map : Dictionary = {}
var zoom := 1.0
var save_template_file_dialog : EditorFileDialog
var hint_color := Color(0, 0, 0, 0.702)

func _enter_tree() -> void:
	num_regex.compile("^\\d+\\.?\\d*$")
	images_container = find_child("ImagesContainer")
	x_size_line_edit = find_child("XSizeLineEdit")
	y_size_line_edit = find_child("YSizeLineEdit")
	generate_template_button = find_child("GenerateTemplateButton")
	generate_tileset_button = find_child("GenerateTileSetButton")
	overlay_texture_rect = find_child("OverlayTextureRect")
	preview_texture_rect = find_child("PreviewTextureRect")
	guide_texture_rect = find_child("GuideTextureRect")
	reset_zoom_button = find_child("ResetZoomButton")
	preview_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	save_template_file_dialog = EditorFileDialog.new()
	save_template_file_dialog.add_filter("*.png")
	save_template_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	save_template_file_dialog.file_selected.connect(_on_save_template_file_selected)
	EditorInterface.get_base_control().add_child(save_template_file_dialog)


func _on_file_menu_load_files(files : PackedStringArray) -> void:
	load_files(files)


func _on_images_container_drop_files(files: PackedStringArray) -> void:
	load_files(files)


func _on_preview_panel_container_drop_files(files: PackedStringArray) -> void:
	load_files(files)
	

func load_files(files : PackedStringArray):
	for file in files:
		var im := ResourceLoader.load(file, "Image")
		if im is CompressedTexture2D and not resource_map.has(im.get_rid()):
			images_container.add_file(im)
			var detected_size = im.get_size()
			if resource_map.is_empty():
				var tile_size := Vector2(float(detected_size.x) / 6.0, float(detected_size.y) / 4.0)
				x_size_line_edit.text = str(tile_size.x)
				y_size_line_edit.text = str(tile_size.y)
				x_size_line_edit.editable = false
				y_size_line_edit.editable = false
				generate_tileset_button.disabled = false
				handle_tilesize_update()

			resource_map[im.get_rid()] = im
			preview_texture_rect.texture = im


func _on_images_container_terrain_list_entry_removed(removed_resource_id: RID) -> void:
	resource_map.erase(removed_resource_id)
	if preview_texture_rect.texture and preview_texture_rect.texture.get_rid() == removed_resource_id:
		preview_texture_rect.texture = null

	if resource_map.size() == 0:
		x_size_line_edit.text = ""
		y_size_line_edit.text = ""
		x_size_line_edit.editable = true
		y_size_line_edit.editable = true
		generate_tileset_button.disabled = true
		handle_tilesize_update()


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

func _on_images_container_terrain_list_entry_selected(resource_id: RID) -> void:
	preview_texture_rect.texture = resource_map[resource_id]


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


func _on_generate_tile_set_button_pressed() -> void:
	var raw_intel := images_container.gather_data()
	var tile_set := TileSet.new()
	var physics_layer_added := false
	var navigation_layer_added := false
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tile_set.tile_size = Vector2i(int(x_size_line_edit.text), int(y_size_line_edit.text))
	for i in range(raw_intel.size()):
		tile_set.add_terrain(0, i)
		tile_set.set_terrain_name(0, i, raw_intel[i]["terrain_name"])
		if raw_intel[i]["layer_type"] == LayerType.COLLIDES and not physics_layer_added:
			tile_set.add_physics_layer()
			physics_layer_added = true
		elif raw_intel[i]["layer_type"] == LayerType.NAVIGABLE and not navigation_layer_added:
			tile_set.add_navigation_layer()
		var atlas_source := TileSetAtlasSource.new()
		atlas_source.texture = raw_intel[i]["texture_resource"]
		atlas_source.texture_region_size = tile_set.tile_size
		atlas_source.create_tile(Vector2i(0,0))
		var lonely_tile = atlas_source.get_tile_data(Vector2i(0,0), 0)
		lonely_tile.terrain_set = 0
		lonely_tile.terrain = i
		tile_set.add_source(atlas_source)


	ResourceSaver.save(tile_set, "res://test%d.tres" % (randi() % 10000))
	EditorInterface.get_resource_filesystem().scan()
