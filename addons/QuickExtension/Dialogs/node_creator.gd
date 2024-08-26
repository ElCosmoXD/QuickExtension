@tool
extends PopupPanel

static var available_nodes_added = false
var use_custom_folder = false

func _enter_tree() -> void:
	var node_types = ClassDB.get_class_list()
	
	if available_nodes_added:
		return
	
	var nodes_container: OptionButton = $"VContainer/Node base/Nodes"
	nodes_container.clear()
	
	for node_name in node_types:
		nodes_container.add_item(node_name)

	nodes_container.selected = randi_range(0, nodes_container.item_count)
	available_nodes_added = true

func _on_create_pressed() -> void:
	var node_name = $"VContainer/Node data/LineEdit".text
	var node_type = $"VContainer/Node base/Nodes".text
	
	var class_template_cpp = FileAccess.open(QuickExtension.CLASS_TEMPLATE_SRC, FileAccess.READ)
	var class_template_cpp_src = class_template_cpp.get_as_text()
	class_template_cpp.close()
	
	var source_name = QuickExtension.camel_to_snake(node_name)
	var header_name = QuickExtension.camel_to_snake(node_name)
	
	class_template_cpp_src = class_template_cpp_src.replace("template_replace_header", header_name)
	class_template_cpp_src = class_template_cpp_src.replace("TEMPLATE_REPLACE_CLASS_NAME", node_name)

	var class_template_h = FileAccess.open(QuickExtension.CLASS_TEMPLATE_HEADER, FileAccess.READ)
	var class_template_h_src = class_template_h.get_as_text()
	class_template_h.close()

	class_template_h_src = class_template_h_src.replace("TEMPLATE_REPLACE_CLASS_NAME", node_name);
	class_template_h_src = class_template_h_src.replace("TEMPLATE_REPLACE_CLASS_BASE", node_type);
	class_template_h_src = class_template_h_src.replace("template_replace_base_class_header", QuickExtension.camel_to_snake(node_type))

	var settings = FileAccess.open(QuickExtension.DATA_PATH, FileAccess.READ)
	var settings_data = JSON.parse_string(settings.get_as_text())
	settings.close()

	var src_directory = settings_data["cpp"]["sources"]
	var header_directory = settings_data["cpp"]["headers"]

	if use_custom_folder:
		src_directory += "/{0}".format([$"VContainer/Custom folder selection/Path".text])
		header_directory += "/{0}".format([$"VContainer/Custom folder selection/Path".text])
		
		DirAccess.make_dir_recursive_absolute(src_directory)
		DirAccess.make_dir_recursive_absolute(header_directory)

	var src_path = "{0}/{1}.cpp".format([src_directory, source_name])
	var header_path = "{0}/{1}.h".format([header_directory, header_name])

	var src_target = FileAccess.open(src_path, FileAccess.WRITE);
	src_target.store_string(class_template_cpp_src)
	src_target.close()
	
	var header_target = FileAccess.open(header_path, FileAccess.WRITE);
	header_target.store_string(class_template_h_src)
	header_target.close()

	if settings_data["cpp"]["use_reg_types_template"]:
		# Check all custom nodes
		var classes_text = FileAccess.open(QuickExtension.CLASSES_PATH, FileAccess.READ_WRITE)
		var classes: Dictionary = JSON.parse_string(classes_text.get_as_text())
		classes[node_name] = header_path
		
		var classdb_template = FileAccess.open(QuickExtension.REGISTER_CLASS_TEMPLATE_SRC, FileAccess.READ)
		var classdb_template_src = classdb_template.get_as_text()
		
		# Write custom nodes to register_types.cpp
		var targets = ""
		var headers = ""
		
		for custom_class in classes.keys():
			var class_header_path = classes[custom_class]
			if not FileAccess.file_exists(class_header_path):
				# Delete the class and the header if the header doesn't exists anymore
				classes.erase(custom_class)
				continue
			
			targets += "godot::ClassDB::register_class<{0}>();\n\t".format([custom_class])
			
			var header_include_path = class_header_path.erase(0, settings_data["cpp"]["headers"].length() + 1)
			headers += "#include <{0}>\n".format([header_include_path])
		
		headers += "\n"
		classdb_template_src = headers + classdb_template_src.replace("/* REPLACE THIS WITH THE USER CLASSES */", targets)
		
		# Create register_types.cpp file
		var classdb_targets = FileAccess.open("{0}/register_types.cpp".format([settings_data["cpp"]["sources"]]), FileAccess.WRITE)
		classdb_targets.store_string(classdb_template_src)
		classdb_targets.close()
		
		# Update classes file
		classes_text.store_string(JSON.stringify(classes))
		classes_text.close()

	queue_free()

func _on_custom_folder_toggled(toggled_on: bool) -> void:
	$"VContainer/Custom folder selection".visible = toggled_on
	use_custom_folder = true
