@tool
extends EditorPlugin
var selection : EditorSelection
var dock : EZTilesDrawDock
var select_2D_viewport_button : Button
var select_mode_button : Button
var prev_tile_pos := Vector2i.ZERO

func _enter_tree() -> void:
	dock = preload("res://addons/ez_tiles_draw/ez_tiles_draw_dock.tscn").instantiate()
	selection = EditorInterface.get_selection()
	selection.selection_changed.connect(handle_selected_node)
	add_control_to_bottom_panel(dock as Control, "EZ Tiles Draw")
	handle_selected_node()
	select_2D_viewport_button = EditorInterface.get_base_control().find_child("2D", true, false)
	#_dump_interface(EditorInterface.get_base_control(), 4)


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
	var cursor_pos_on_tilemaplayer := mouse_pos - dock.under_edit.global_position
	var tile_pos := Vector2i(cursor_pos_on_tilemaplayer / Vector2(dock.under_edit.tile_set.tile_size))
	if cursor_pos_on_tilemaplayer.x < 0:
		tile_pos.x -= 1
	if cursor_pos_on_tilemaplayer.y < 0:
		tile_pos.y -= 1
	return tile_pos


func _input(_event) -> void:
	if is_instance_valid(dock.under_edit) and select_2D_viewport_button.button_pressed and _get_select_mode_button().button_pressed and dock.visible:
		var viewport_2d := EditorInterface.get_editor_viewport_2d()
		var g_mouse_pos = (
			EditorInterface.get_base_control().get_global_mouse_position()
					- viewport_2d.get_parent().global_position
		)

		if viewport_2d.get_visible_rect().has_point(g_mouse_pos):
			var tile_pos := _tile_pos_from_mouse_pos()
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				viewport_2d.set_input_as_handled()
			elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				viewport_2d.set_input_as_handled()

			if not dock.viewport_has_mouse:
				dock.handle_mouse_entered()
			if prev_tile_pos != tile_pos:
				dock.handle_tile_pos_changed(tile_pos,
						Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
						Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
				)
				prev_tile_pos = tile_pos
		else:
			if dock.viewport_has_mouse:
				dock.handle_mouse_out()


func handle_selected_node():
	var selected_node : Node = selection.get_selected_nodes().pop_back()
	if is_instance_valid(selected_node) and selected_node is TileMapLayer and selected_node.has_meta("_is_ez_tiles_generated"):
		dock.activate(selected_node)
		await get_tree().create_timer(0.5).timeout
		make_bottom_panel_item_visible(dock)
	else:
		dock.deactivate()

func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.free()
