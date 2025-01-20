@tool
extends OptionButton
class_name CollisionTypeButton

func _enter_tree() -> void:
	for tpl : Node in find_child("CollisionPolygonTemplates").get_children():
		add_item(tpl.name)
