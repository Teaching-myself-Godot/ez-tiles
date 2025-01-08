@tool
extends EditorPlugin
class_name EZTiles

var dock : EZTilesDock
var selection : EditorSelection


func _enter_tree() -> void:
	dock = preload("res://addons/ez_tiles/ez_tiles_dock.tscn").instantiate()
	selection = EditorInterface.get_selection()
	add_control_to_bottom_panel(dock as Control, "EZ Tiles")
	#selection.selection_changed.connect(handle_selected_node)

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
