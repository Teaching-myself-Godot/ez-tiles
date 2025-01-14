@tool
extends EditorPlugin
var selection : EditorSelection
var dock : EZTilesDrawDock
var select_2D_viewport_button : Button
var select_mode_button : Button
var prev_tile_pos := Vector2i.ZERO
var lmb_is_down_outside_2d_viewport := false
var hint_polygon : Polygon2D

func _enter_tree() -> void:
	dock = preload("res://addons/ez_tiles_draw/ez_tiles_draw_dock.tscn").instantiate()
	selection = EditorInterface.get_selection()
	selection.selection_changed.connect(handle_selected_node)
	add_control_to_bottom_panel(dock as Control, "EZ Tiles Draw")
	handle_selected_node()
	select_2D_viewport_button = EditorInterface.get_base_control().find_child("2D", true, false)


func _handles(object: Object) -> bool:
	return object is TileMapLayer


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
	var mouse_pos := EditorInterface.get_editor_viewport_2d().get_mouse_position()
	var cursor_pos_on_tilemaplayer := (mouse_pos - dock.under_edit.global_position).rotated(-dock.under_edit.global_rotation)

	var tile_pos := Vector2i(cursor_pos_on_tilemaplayer / (Vector2(dock.under_edit.tile_set.tile_size) * dock.under_edit.global_scale))
	if cursor_pos_on_tilemaplayer.x < 0:
		tile_pos.x -= 1
	if cursor_pos_on_tilemaplayer.y < 0:
		tile_pos.y -= 1
	return tile_pos


func _forward_canvas_draw_over_viewport(overlay):
	# Draw a circle at cursor position.
	if dock.lmb_is_down:
		var drag_start_cur_pos := (
			(
				(
					Vector2(dock.drag_start) * (Vector2(dock.under_edit.tile_set.tile_size) * dock.under_edit.global_scale).rotated(dock.under_edit.global_rotation)
				) * EditorInterface.get_editor_viewport_2d().get_final_transform().get_scale()
			) + EditorInterface.get_editor_viewport_2d().get_final_transform().get_origin()
		)
		
		var rect_cur_pos := (
			(
				(
					Vector2(_tile_pos_from_mouse_pos()) * (Vector2(dock.under_edit.tile_set.tile_size) * dock.under_edit.global_scale).rotated(dock.under_edit.global_rotation)
				) * EditorInterface.get_editor_viewport_2d().get_final_transform().get_scale()
			) + EditorInterface.get_editor_viewport_2d().get_final_transform().get_origin()
		)
		
		
		overlay.draw_circle(drag_start_cur_pos, 6, Color.WHITE)

		overlay.draw_circle(rect_cur_pos, 6, Color.WHITE)


func _input(_event) -> void:
	update_overlays()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		lmb_is_down_outside_2d_viewport = false

	if is_instance_valid(dock.under_edit) and select_2D_viewport_button.button_pressed and _get_select_mode_button().button_pressed and dock.visible:
		var viewport_2d := EditorInterface.get_editor_viewport_2d()
		var g_mouse_pos = (
			EditorInterface.get_base_control().get_global_mouse_position()
					- viewport_2d.get_parent().global_position
		)

		if (viewport_2d.get_visible_rect().has_point(g_mouse_pos)
					and not (g_mouse_pos.x <= 164 and g_mouse_pos.y <= 40)):

			var tile_pos := _tile_pos_from_mouse_pos()
			if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) 
						and not dock.lmb_is_down
						and not lmb_is_down_outside_2d_viewport):
				dock.handle_mouse_down(MOUSE_BUTTON_LEFT, tile_pos)

			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not dock.rmb_is_down:
				dock.handle_mouse_down(MOUSE_BUTTON_RIGHT, tile_pos)

			if dock.lmb_is_down and not  Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				dock.handle_mouse_up(MOUSE_BUTTON_LEFT, tile_pos)

			if dock.rmb_is_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				dock.handle_mouse_up(MOUSE_BUTTON_RIGHT, tile_pos)

			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and dock.lmb_is_down:
				viewport_2d.set_input_as_handled()

			elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				viewport_2d.set_input_as_handled()

			if not dock.viewport_has_mouse:
				dock.handle_mouse_entered()

			dock.handle_mouse_move(tile_pos, g_mouse_pos)
		else:
			lmb_is_down_outside_2d_viewport = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			if dock.viewport_has_mouse:
				dock.handle_mouse_out()


func handle_selected_node():
	var selected_node : Node = selection.get_selected_nodes().pop_back()
	if is_instance_valid(selected_node) and selected_node is TileMapLayer and is_instance_valid(selected_node.tile_set):
		dock.activate(selected_node)
		if selected_node.has_meta("_is_ez_tiles_generated"):
			await get_tree().create_timer(0.5).timeout
			make_bottom_panel_item_visible(dock)
	else:
		dock.deactivate()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.free()
