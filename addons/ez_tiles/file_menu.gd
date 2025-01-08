@tool
extends MenuButton

signal load_files(files : PackedStringArray)

enum MenuItems { LOAD_FILE }
var menu : PopupMenu
var file_dialog : EditorFileDialog

func _enter_tree() -> void:
	file_dialog = EditorFileDialog.new()
	file_dialog.add_filter("*.png,*.svg,*.webp,*.jpg,*.jpeg,*.bmp,*.tga", "Image files")
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	file_dialog.files_selected.connect(_on_files_selected)
	EditorInterface.get_base_control().add_child(file_dialog)
	menu = get_popup()
	menu.id_pressed.connect(_on_menu_item_selected)

func _on_files_selected(files : PackedStringArray) -> void:
	load_files.emit(files)

func _on_menu_item_selected(id : int) -> void:
	match (id):
		MenuItems.LOAD_FILE: 
			file_dialog.popup_file_dialog()

func _exit_tree():
	# Cleanup
	file_dialog.queue_free()
