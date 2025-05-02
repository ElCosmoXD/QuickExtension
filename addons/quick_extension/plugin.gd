@tool
class_name QuickExtension extends EditorPlugin

const CLASS_MENU_ITEM_NAME = "Create new Class..."

var welcome_panel: PopupPanel
var create_class_panel: PopupPanel

func create_class_dialog():
	var create_class_popup = preload("res://addons/quick_extension/popups/create_class.tscn")
	create_class_panel = create_class_popup.instantiate()
	get_editor_interface().get_base_control().add_child(create_class_panel)
	
	create_class_panel.popup_centered()
	# We load the items here instead of _enter_tree
	# because when we're developing, the items get added
	# in the file itself and that may cause problems if
	# the editor was built with less (or more) classes
	# than the number of classes available in the file 
	create_class_panel.load_items()
	
	create_class_panel.popup_hide.connect(func destroy(): create_class_panel.queue_free())
	
static func select_directory_dialog(on_selected: Callable):
	# FIXME: We're not using this function yet since calling this
	# will make the setup/welcome popup close
	
	var dialog = FileDialog.new()
	
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	
	dialog.dir_selected.connect(func call(dir): 
		on_selected.call(dir)
		)
	
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered_ratio()

static func create_class_cpp(sources_dir: String, headers_dir: String, register_types: bool, class_name_: String, class_type: String):
	
	# Write the source + header files
	
	var source_template = QuickExtensionUtils.read_text_file("res://addons/quick_extension/templates/Class-Template.cpp.txt")
	var header_template = QuickExtensionUtils.read_text_file("res://addons/quick_extension/templates/Class-Template.h.txt")

	var target_file_name = QuickExtensionUtils.camel_to_snake(class_name_)

	header_template = header_template.replace("TEMPLATE_REPLACE_CLASS_NAME", class_name_)
	header_template = header_template.replace("TEMPLATE_REPLACE_CLASS_BASE", class_type)
	header_template = header_template.replace("template_replace_base_class_header", QuickExtensionUtils.camel_to_snake(class_type))

	source_template = source_template.replace("template_replace_header", target_file_name)
	source_template = source_template.replace("TEMPLATE_REPLACE_CLASS_NAME", class_name_)
	
	var target_source_path = sources_dir + target_file_name + ".cpp"
	var target_header_path = headers_dir + target_file_name + ".h"
	
	QuickExtensionUtils.write_text_file(target_source_path, source_template)
	QuickExtensionUtils.write_text_file(target_header_path, header_template)
	
	# Write file to config file
	
	var sources_config: PackedStringArray = QuickExtensionUtils.user_files_config.get_value("cpp", "sources")
	sources_config.push_back(target_source_path)
	QuickExtensionUtils.user_files_config.set_value("cpp", "sources", sources_config)
	
	var headers_config: PackedStringArray = QuickExtensionUtils.user_files_config.get_value("cpp", "headers")
	headers_config.push_back(target_header_path)
	QuickExtensionUtils.user_files_config.set_value("cpp", "headers", headers_config)

	var classes_config: PackedStringArray = QuickExtensionUtils.user_files_config.get_value("cpp", "classes")
	classes_config.push_back(class_name_)
	QuickExtensionUtils.user_files_config.set_value("cpp", "classes", classes_config)
	
	QuickExtensionUtils.user_files_config.save(QuickExtensionUtils.USER_FILES_CONFIG_PATH)
	
	# Register type
	
	var register_types_config: bool = QuickExtensionUtils.config.get_value("cpp", "register_types")
	if register_types_config:
		var register_types_header_template = QuickExtensionUtils.read_text_file("res://addons/quick_extension/templates/register_types-Template.h.txt")
		var register_types_source_template = QuickExtensionUtils.read_text_file("res://addons/quick_extension/templates/register_types-Template.cpp.txt")

		assert(classes_config.size() == headers_config.size())

		var classes_buffer = PackedStringArray()
		var headers_buffer = PackedStringArray()
		for i in range(0, classes_config.size()):
			# TODO: Move the hardcoded C++ to a file, so the user can customize it
			
			classes_buffer.push_back("godot::ClassDB::register_class<" + classes_config[i] + ">();")
			headers_buffer.push_back("#include <" + headers_config[i].replace(headers_dir, "") + ">")
		
		register_types_source_template = register_types_source_template.replace("/* REPLACE THIS WITH THE USER CLASSES */", "\n\t".join(classes_buffer))
		register_types_source_template = register_types_source_template.replace("/* REPLACE THIS WITH THE USER HEADERS */", "\n".join(headers_buffer))

		var register_types_sources_target = sources_dir + "register_types.cpp"
		var register_types_headers_target = headers_dir + "register_types.h"
		QuickExtensionUtils.write_text_file(register_types_sources_target, register_types_source_template)
		QuickExtensionUtils.write_text_file(register_types_headers_target, register_types_header_template)

static func create_class(class_name_: String, class_type: String):
	assert(QuickExtensionUtils.exists_config_file())
	assert(QuickExtensionUtils.config.load(QuickExtensionUtils.CONFIG_PATH) == OK)
	
	if QuickExtensionUtils.config.get_value("global", "language") == "cpp":
		var sources = QuickExtensionUtils.config.get_value("cpp", "sources")
		var headers = QuickExtensionUtils.config.get_value("cpp", "headers")
		var register_types = QuickExtensionUtils.config.get_value("cpp", "register_types")
		
		create_class_cpp(sources, headers, register_types, class_name_, class_type)

func _enter_tree() -> void:
	add_tool_menu_item(CLASS_MENU_ITEM_NAME, create_class_dialog)
	
	if not QuickExtensionUtils.exists_config_file():
		var welcome_popup = preload("res://addons/quick_extension/popups/welcome.tscn")
		welcome_panel = welcome_popup.instantiate()
	
		get_editor_interface().get_base_control().add_child(welcome_panel)
	
		welcome_panel.popup_centered()
		
func _exit_tree() -> void:
	remove_tool_menu_item(CLASS_MENU_ITEM_NAME)
	
	if welcome_panel != null:
		welcome_panel.queue_free()
