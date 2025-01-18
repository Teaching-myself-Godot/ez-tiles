@tool

extends HBoxContainer

signal value_changed(value : int)
var num_regex := RegEx.new()
var line_edit : LineEdit
var slider : HSlider
var my_value : int = 1

func _enter_tree() -> void:
	num_regex.compile("^\\d+$")
	line_edit = find_child("LineEdit")
	slider = find_child("Slider")


func _on_slider_value_changed(value: float) -> void:
	if int(value) != my_value:
		my_value = int(value)
		line_edit.text = str(my_value)
		value_changed.emit(my_value)


func _on_line_edit_text_submitted(new_text: String) -> void:
	var prev_value := my_value
	if num_regex.search(new_text):
		my_value = int(new_text)
		if my_value < 0:
			my_value = 1
		if my_value > slider.max_value:
			my_value = int(slider.max_value)

	line_edit.text = str(my_value)
	slider.value = float(my_value)
	slider.grab_focus()
	if prev_value != my_value:
		value_changed.emit(my_value)


func _on_line_edit_text_changed(new_text: String) -> void:
	var prev_value := my_value
	if num_regex.search(new_text):
		my_value = int(new_text)
		if my_value < 0:
			my_value = 1
		if my_value > slider.max_value:
			my_value = int(slider.max_value)
	line_edit.text = str(my_value)
	slider.value = float(my_value)
	if prev_value != my_value:
		value_changed.emit(my_value)
