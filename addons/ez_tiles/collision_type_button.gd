@tool
extends OptionButton
class_name CollisionTypeButton

signal collision_template_selected()

var template : Node = null
var template_container : Node

func _enter_tree() -> void:
	template_container = find_child("CollisionPolygonTemplates")
	if item_count == 1:
		for tpl : Node in template_container.get_children():
			add_item(tpl.name)


func _on_item_selected(index: int) -> void:
	if index == 0:
		template = null
	else:
		template = template_container.get_child(index - 1)
	collision_template_selected.emit()
