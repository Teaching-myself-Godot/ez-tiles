@tool
extends EditorPlugin
class_name EZTiles

# importer
var dock : EZTilesDock
var alert_dialog : AcceptDialog

# draw
var selection : EditorSelection
var draw_dock : EZTilesDrawDock
var select_2D_viewport_button : Button
var select_mode_button : Button
var prev_tile_pos := Vector2i.ZERO
var lmb_is_down_outside_2d_viewport := false
var hint_polygon : Polygon2D
var prev_pos := Vector2i.ZERO

func _enter_tree() -> void:
	# importer
	dock = preload("res://addons/ez_tiles/ez_tiles_dock.tscn").instantiate()
	add_control_to_bottom_panel(dock as Control, "EZ Tiles")
	dock.request_tile_map_layer.connect(create_tile_map_layer_for_tile_set)
	alert_dialog = AcceptDialog.new()
	EditorInterface.get_base_control().add_child(alert_dialog)
	# draw
	draw_dock = preload("res://addons/ez_tiles/ez_tiles_draw/ez_tiles_draw_dock.tscn").instantiate()
	selection = EditorInterface.get_selection()
	selection.selection_changed.connect(handle_selected_node)
	add_control_to_bottom_panel(draw_dock as Control, "EZ Tiles Draw")
	handle_selected_node()
	select_2D_viewport_button = EditorInterface.get_base_control().find_child("2D", true, false)
	draw_dock.undo_redo = get_undo_redo()

# IMPORTER
func create_tile_map_layer_for_tile_set(tile_set : TileSet) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if is_instance_valid(root) and root is Node2D:
		var tile_map_layer := TileMapLayer.new()
		tile_map_layer.tile_set = tile_set
		tile_map_layer.name = "EZTilesTileMapLayer"
		root.add_child(tile_map_layer, true)
		tile_map_layer.set_owner(root)
		tile_map_layer.set_meta("_is_ez_tiles_generated", true)
		EditorInterface.edit_node(tile_map_layer)
	else:
		alert_dialog.title = "Warning!"
		alert_dialog.dialog_text = """Cannot create TileMapLayer for this scene.
			Please try again when editing a Node2D scene."""
		alert_dialog.popup_centered()

# DRAW
func _handles(object: Object) -> bool:
	return is_instance_valid(object) and object is TileMapLayer


func _dump_interface(n : Node, max_d : int = 2, d : int = 0) -> void:
	if n.name.contains("Dialog") or n.name.contains("Popup"):
		return
	print(n.name.lpad(d + n.name.length(), "-") + " (%d)" % [n.get_child_count()])
	for c in n.get_children():
		if d < max_d:
			_dump_interface(c, max_d, d + 1)


func _get_select_mode_button() -> Button:
	if is_instance_valid(select_mode_button):
		return select_mode_button
	else:
		select_mode_button = (
			EditorInterface.get_editor_viewport_2d().find_parent("*CanvasItemEditor*")
					.find_child("*Button*", true, false)
		)
		return select_mode_button


func _tile_pos_from_mouse_pos() -> Vector2i:
	if not is_instance_valid(draw_dock.under_edit):
		return Vector2i.ZERO
	var mouse_pos := EditorInterface.get_editor_viewport_2d().get_mouse_position()
	var cursor_pos_on_tilemaplayer := (mouse_pos - draw_dock.under_edit.global_position).rotated(-draw_dock.under_edit.global_rotation)

	var tile_pos := Vector2i(cursor_pos_on_tilemaplayer / (Vector2(draw_dock.under_edit.tile_set.tile_size) * draw_dock.under_edit.global_scale))
	if cursor_pos_on_tilemaplayer.x < 0:
		tile_pos.x -= 1
	if cursor_pos_on_tilemaplayer.y < 0:
		tile_pos.y -= 1
	return tile_pos


func _tile_pos_to_overlay_pos(tile_pos : Vector2i) -> Vector2:
	if not(draw_dock.visible and is_instance_valid(draw_dock.under_edit) and _get_select_mode_button().button_pressed):
		return Vector2i.ZERO
	return (
		(
			(
				(Vector2(tile_pos) * (Vector2(draw_dock.under_edit.tile_set.tile_size) * draw_dock.under_edit.global_scale)).rotated(draw_dock.under_edit.global_rotation) + draw_dock.under_edit.global_position
			) * EditorInterface.get_editor_viewport_2d().get_final_transform().get_scale()
		) + EditorInterface.get_editor_viewport_2d().get_final_transform().get_origin()
	)


func _forward_canvas_draw_over_viewport(overlay):
	var viewport_2d := EditorInterface.get_editor_viewport_2d()
	var g_mouse_pos = (
		EditorInterface.get_base_control().get_global_mouse_position()
				- viewport_2d.get_parent().global_position
	)
	if not viewport_2d.get_visible_rect().has_point(g_mouse_pos):
		return

	var fill :=  Color(1.0, 0.0, 0.0, 0.2) if draw_dock.rmb_is_down else Color(Color.WHITE, 0.2)
	var stroke := Color.RED if draw_dock.rmb_is_down else Color.WHITE
	var draw_rect := draw_dock.get_draw_rect(_tile_pos_from_mouse_pos())
	var tl_corner := _tile_pos_to_overlay_pos(draw_rect.position)
	var tr_corner := _tile_pos_to_overlay_pos(draw_rect.position + draw_rect.size * Vector2i.RIGHT)
	var br_corner := _tile_pos_to_overlay_pos(draw_rect.position + draw_rect.size)
	var bl_corner := _tile_pos_to_overlay_pos(draw_rect.position + draw_rect.size * Vector2i.DOWN)
	overlay.draw_polyline(PackedVector2Array([tl_corner, tr_corner, br_corner, bl_corner, tl_corner]), stroke, 0.5, true)

	if draw_dock.rmb_is_down:
		overlay.draw_polygon(PackedVector2Array([tl_corner, tr_corner, br_corner, bl_corner, tl_corner]), [fill])
	else:
		var draw_area := draw_dock.get_draw_area(_tile_pos_from_mouse_pos())
		for tile in draw_area:
			var tl := _tile_pos_to_overlay_pos(tile)
			var tr := _tile_pos_to_overlay_pos(tile + Vector2i.RIGHT)
			var br := _tile_pos_to_overlay_pos(tile + Vector2i.ONE)
			var bl := _tile_pos_to_overlay_pos(tile + Vector2i.DOWN)
			overlay.draw_polygon(PackedVector2Array([tl, tr, br, bl]), [fill])




func _input(_event) -> void:
	update_overlays()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		lmb_is_down_outside_2d_viewport = false

	if is_instance_valid(draw_dock.under_edit) and select_2D_viewport_button.button_pressed and _get_select_mode_button().button_pressed and draw_dock.visible:
		var viewport_2d := EditorInterface.get_editor_viewport_2d()
		var g_mouse_pos = (
			EditorInterface.get_base_control().get_global_mouse_position()
					- viewport_2d.get_parent().global_position
		)

		if ((viewport_2d.get_visible_rect().has_point(g_mouse_pos)
					and not (g_mouse_pos.x <= 164 and g_mouse_pos.y <= 40))
					or draw_dock.lmb_is_down or draw_dock.rmb_is_down):

			var tile_pos := _tile_pos_from_mouse_pos()
			if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) 
						and not draw_dock.lmb_is_down
						and not lmb_is_down_outside_2d_viewport):
				draw_dock.handle_mouse_down(MOUSE_BUTTON_LEFT, tile_pos)

			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not draw_dock.rmb_is_down:
				draw_dock.handle_mouse_down(MOUSE_BUTTON_RIGHT, tile_pos)

			if draw_dock.lmb_is_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				draw_dock.handle_mouse_up(MOUSE_BUTTON_LEFT, tile_pos)

			if draw_dock.rmb_is_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				draw_dock.handle_mouse_up(MOUSE_BUTTON_RIGHT, tile_pos)

			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and draw_dock.lmb_is_down:
				viewport_2d.set_input_as_handled()
			elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				viewport_2d.set_input_as_handled()

			if Input.is_key_pressed(KEY_CTRL):
				draw_dock._place_back_remembered_cells()
				draw_dock.suppress_preview = true
			else:
				draw_dock.suppress_preview = false

			if not draw_dock.viewport_has_mouse:
				draw_dock.handle_mouse_entered()
			if prev_pos != tile_pos:
				draw_dock.handle_mouse_move(tile_pos)
				prev_pos = tile_pos
		else:
			lmb_is_down_outside_2d_viewport = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			if draw_dock.viewport_has_mouse:
				draw_dock.handle_mouse_out()


func handle_selected_node():
	var selected_node : Node = selection.get_selected_nodes().pop_back()
	if is_instance_valid(selected_node) and selected_node is TileMapLayer and is_instance_valid(selected_node.tile_set):
		draw_dock.activate(selected_node)
		if selected_node.has_meta("_is_ez_tiles_generated"):
			await get_tree().create_timer(0.5).timeout
			make_bottom_panel_item_visible(draw_dock)
	else:
		draw_dock.deactivate()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.free()
	remove_control_from_bottom_panel(draw_dock)
	draw_dock.free()
