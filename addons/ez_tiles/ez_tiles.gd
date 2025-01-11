@tool
extends EditorPlugin
class_name EZTiles

var dock : EZTilesDock
var selection : EditorSelection
var alert_dialog : AcceptDialog

func _enter_tree() -> void:
	dock = preload("res://addons/ez_tiles/ez_tiles_dock.tscn").instantiate()
	add_control_to_bottom_panel(dock as Control, "EZ Tiles")
	dock.request_tile_map_layer.connect(create_tile_map_layer_for_tile_set)
	alert_dialog = AcceptDialog.new()
	EditorInterface.get_base_control().add_child(alert_dialog)
	#selection = EditorInterface.get_selection()
	#selection.selection_changed.connect(handle_selected_node)

func create_tile_map_layer_for_tile_set(tile_set : TileSet) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if is_instance_valid(root) and root is Node2D:
		var tile_map_layer := TileMapLayer.new()
		tile_map_layer.tile_set = tile_set
		tile_map_layer.name = "EZTilesTileMapLayer"
		root.add_child(tile_map_layer, true)
		tile_map_layer.set_owner(root)
		EditorInterface.edit_node(tile_map_layer)
	else:
		alert_dialog.title = "Warning!"
		alert_dialog.dialog_text = """Cannot create TileMapLayer for this scene.
			Please try again when editing a Node2D scene."""
		alert_dialog.popup_centered()

#func handle_selected_node():
	#var selected_node : Node = selection.get_selected_nodes().pop_back()
	#if is_instance_valid(selected_node) and selected_node is TileMapLayer:
		#dock.activate(selected_node)
		#await get_tree().create_timer(0.1).timeout
		#make_bottom_panel_item_visible(dock)
	#else:
		#dock.deactivate()

func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.free()
