@tool
extends PanelContainer
class_name BrushDraw

var brush_size : int = 1
var TileButtonScene : PackedScene

enum BrushShape {CIRCLE, SQUARE}
signal connect_mode_toggled(toggled : bool)

var tile_coords := Vector2i.ZERO
var connect_terrains_button : Button
var brush_shape := BrushShape.SQUARE
var button_container : Control
var first_tile_button : Button

func _enter_tree() -> void:
	TileButtonScene = preload("res://addons/ez_tiles/ez_tiles_draw/tile_button.tscn")
	connect_terrains_button = find_child("ConnectTerrainsButton")
	connect_terrains_button.pressed.connect(func(): connect_mode_toggled.emit(true))
	button_container = find_child("TileButtonContainer")


func _on_tile_button_pressed(coords : Vector2i):
	tile_coords = coords
	connect_mode_toggled.emit(false)


func _on_range_slider_with_line_edit_value_changed(value: int) -> void:
	brush_size = value


func update_tile_buttons(tileset_source : TileSetAtlasSource, tile_size : Vector2i):
	first_tile_button = null
	for c in button_container.get_children():
		if c is TileButton:
			c.queue_free()

	var terrain_texture := tileset_source.texture
	for idx in range(tileset_source.get_tiles_count()):
		var pos := tileset_source.get_tile_id(idx)
		var tile_button : TileButton = TileButtonScene.instantiate()
		tile_button.clicked.connect(_on_tile_button_pressed)
		tile_button.coords = pos
		var texture := AtlasTexture.new()
		tile_button.icon = texture
		tile_button.icon.atlas = terrain_texture
		tile_button.icon.region = Rect2i(pos * tile_size, tile_size)
		button_container.add_child(tile_button)
		if not is_instance_valid(first_tile_button):
			first_tile_button = tile_button
			first_tile_button.button_pressed = true


func toggle_off_connected_brush() -> void:
	if is_instance_valid(first_tile_button):
		first_tile_button.button_pressed = true

func _on_brush_shape_square_button_pressed() -> void:
	brush_shape = BrushShape.SQUARE


func _on_brush_shape_circle_button_pressed() -> void:
	brush_shape = BrushShape.CIRCLE
