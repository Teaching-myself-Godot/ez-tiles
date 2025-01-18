@tool
extends PanelContainer
class_name StampTab

var h_flow_container : HFlowContainer

func _enter_tree() -> void:
	h_flow_container = find_child("HFlowContainer")
	for stamp : Stamp in find_children("Stamp*"):
		stamp.selected.connect(func(): _on_stamp_selected(stamp))


func _on_stamp_selected(selected_stamp : Stamp):
	for stamp : Stamp in find_children("Stamp*"):
		if stamp != selected_stamp:
			stamp.deselect()


func add_stamp(stamp : Stamp):
	stamp.selected.connect(func(): _on_stamp_selected(stamp))
	h_flow_container.add_child(stamp)
