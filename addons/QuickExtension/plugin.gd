@tool
extends EditorPlugin

const welcome_screen_packed = preload("res://addons/QuickExtension/Dialogs/Welcome.tscn")
var welcome_screen_instance: Window

const create_node_packed = preload("res://addons/QuickExtension/Dialogs/Node Creator.tscn")
var create_node_instance: PopupPanel

func create_welcome_dialog():
	welcome_screen_instance = welcome_screen_packed.instantiate()

	EditorInterface.get_editor_main_screen().add_child(welcome_screen_instance)

	welcome_screen_instance.visible = true
	welcome_screen_instance.show()

func create_class_dialog():
	if create_node_instance != null:
		create_node_instance.queue_free()
		
	create_node_instance = create_node_packed.instantiate()

	add_child(create_node_instance)

	create_node_instance.show()

func _enter_tree():
	if not FileAccess.file_exists(QuickExtension.DATA_PATH):
		create_welcome_dialog()

	if not FileAccess.file_exists(QuickExtension.CLASSES_PATH):
		var classes = FileAccess.open(QuickExtension.CLASSES_PATH, FileAccess.WRITE)
		classes.store_string(JSON.stringify({}))
		classes.close()

	add_tool_menu_item("Create new Class...", create_class_dialog)

func _has_main_screen():
	return true

func _exit_tree():
	if welcome_screen_instance:
		welcome_screen_instance.queue_free()
		
	if create_node_instance:
		create_node_instance.queue_free()

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
