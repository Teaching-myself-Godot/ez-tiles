@tool
extends PanelContainer
class_name BrushDraw

var brush_size : int = 1
const MC := Vector2i(0, 0)
const VT := Vector2i(1, 0)
const VM := Vector2i(1, 1)
const VB := Vector2i(1, 2)
const HL := Vector2i(0, 3)
const HM := Vector2i(1, 3)
const HR := Vector2i(2, 3)
const TL := Vector2i(3, 0)
const TR := Vector2i(5, 0)
const TM := Vector2i(4, 0)
const BL := Vector2i(3, 2)
const BR := Vector2i(5, 2)
const BM := Vector2i(4, 2)
const LM := Vector2i(3, 1)
const RM := Vector2i(5, 1)
const CM := Vector2i(4, 1)
const COORDS : Array[Vector2i] = [
	MC, VT, VM, VB, HL, HM, HR, TL, TM, TR, LM, CM, RM, BL, BM, BR
]
enum BrushShape {CIRCLE, SQUARE}
signal connect_mode_toggled(toggled : bool)

var tile_coords := MC
var connect_terrains_button : Button
var brush_shape := BrushShape.SQUARE


func _enter_tree() -> void:
	var buttons := find_children("TileButton*")
	for i in range(buttons.size()):
		buttons[i].pressed.connect(func(): _on_tile_button_pressed(COORDS[i]))
	connect_terrains_button = find_child("ConnectTerrainsButton")
	connect_terrains_button.pressed.connect(func(): connect_mode_toggled.emit(true))


func _on_tile_button_pressed(coords : Vector2i):
	tile_coords = coords
	connect_mode_toggled.emit(false)


func _on_range_slider_with_line_edit_value_changed(value: int) -> void:
	brush_size = value


func update_tile_buttons(terrain_texture : Texture2D, tile_size : Vector2i):
	var buttons := find_children("TileButton*")
	for i in range(buttons.size()):
		buttons[i].icon.atlas = terrain_texture
		buttons[i].icon.region = Rect2i(COORDS[i] * tile_size, tile_size)


func _on_brush_shape_square_button_pressed() -> void:
	brush_shape = BrushShape.SQUARE


func _on_brush_shape_circle_button_pressed() -> void:
	brush_shape = BrushShape.CIRCLE
