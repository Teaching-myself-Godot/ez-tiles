@tool
extends PanelContainer
class_name StampTab

signal snapshot_toggled(on_off : bool)

var h_flow_container : HFlowContainer
var snapshot_button : Button

func _enter_tree() -> void:
	h_flow_container = find_child("HFlowContainer")
	snapshot_button = find_child("SnapShotSelectButton")
	for stamp : Stamp in find_children("Stamp*"):
		stamp.selected.connect(func(): _on_stamp_selected(stamp))


func _on_stamp_selected(selected_stamp : Stamp):
	snapshot_button.button_pressed = false
	snapshot_button.focus_mode = Control.FOCUS_NONE
	for stamp : Stamp in find_children("Stamp*"):
		if stamp != selected_stamp:
			stamp.deselect()
	snapshot_toggled.emit(false)


func add_stamp(stamp : Stamp):
	stamp.selected.connect(func(): _on_stamp_selected(stamp))
	h_flow_container.add_child(stamp)


func start_snapshot():
	snapshot_button.button_pressed = true
	for stamp : Stamp in find_children("Stamp*"):
		stamp.deselect()



func stop_snapshotting():
	snapshot_button.button_pressed = false



func _on_snap_shot_select_button_toggled(toggled_on: bool) -> void:
	snapshot_toggled.emit(toggled_on)
