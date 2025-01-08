@tool
class_name EZTilesDock

extends HBoxContainer

var num_regex := RegEx.new()
var images_container : ImagesContainer
var x_size_line_edit : LineEdit
var y_size_line_edit : LineEdit
var generate_template_button : Button
var overlay_texture_rect : TextureRect
var preview_texture_rect : TextureRect
var reset_zoom_button : Button
var resource_map : Dictionary = {}
var zoom := 1.0

func _enter_tree() -> void:
	num_regex.compile("^\\d+\\.?\\d*$")
	images_container = find_child("ImagesContainer")
	x_size_line_edit = find_child("XSizeLineEdit")
	y_size_line_edit = find_child("YSizeLineEdit")
	generate_template_button = find_child("GenerateTemplateButton")
	overlay_texture_rect = find_child("OverlayTextureRect")
	preview_texture_rect = find_child("PreviewTextureRect")
	reset_zoom_button = find_child("ResetZoomButton")
	preview_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

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
		handle_tilesize_update()


func _on_xy_size_line_edit_text_changed(_new_text: String) -> void:
	handle_tilesize_update()


func handle_tilesize_update() -> void:
	if  num_regex.search(x_size_line_edit.text) and num_regex.search(y_size_line_edit.text):
		generate_template_button.disabled = false
		var tile_size := Vector2i(int(x_size_line_edit.text), int(y_size_line_edit.text))
		var new_template_overlay := Image.create_empty(tile_size.x * 6, tile_size.y * 4, false, Image.FORMAT_RGBA8)
		for y in range(new_template_overlay.get_height()):
			for x in range(new_template_overlay.get_width()):
				if (
					(x >= tile_size.x * 2 and y < tile_size.y * 3 and x < tile_size.x * 3) or 
					(x < tile_size.x and y >= tile_size.y and y < tile_size.y * 3) or
					(x >= tile_size.x * 3 and y >= tile_size.y * 3)
				):
					new_template_overlay.set_pixel(x, y, Color(1.0, 0.0, 0.0, 0.7))
		overlay_texture_rect.texture = ImageTexture.create_from_image(new_template_overlay)
		resize_texture_rects(1)
	else:
		generate_template_button.disabled = true
		preview_texture_rect.custom_minimum_size = Vector2.ZERO
		overlay_texture_rect.custom_minimum_size = Vector2.ZERO
		preview_texture_rect.texture = null


func resize_texture_rects(new_zoom : float):
	zoom = new_zoom
	var new_size := Vector2(
		float(x_size_line_edit.text) * 6 * zoom,
		float(y_size_line_edit.text) * 4 * zoom
	)
	preview_texture_rect.custom_minimum_size = new_size
	overlay_texture_rect.custom_minimum_size = new_size
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


