@tool
extends Window

var use_cpp_headers = false

func _on_confirm_button_up():
	var data = {"cpp": {"sources": $Container/cpp/Sources.text}}

	if use_cpp_headers:
		data["cpp"].merge({"headers": $Container/cpp/Headers.text})
	else:
		data["cpp"].merge({"headers": $Container/cpp/Sources.text})
		
	data["cpp"].merge({"use_reg_types_template": $"Container/cpp/Register Template".button_pressed})
	
	# Create directories in case the user didn't made them
	DirAccess.make_dir_recursive_absolute(data["cpp"]["sources"])
	DirAccess.make_dir_recursive_absolute(data["cpp"]["headers"])
	
	if data["cpp"]["use_reg_types_template"]:
		var register_types_header_template = FileAccess.open(QuickExtension.REGISTER_CLASS_TEMPLATE_HEADER, FileAccess.READ)
		var register_types_header = FileAccess.open("{0}/register_types.h".format([data["cpp"]["headers"]]), FileAccess.WRITE)
		print("{0}/register_types.h".format([data["cpp"]["headers"]]))
		register_types_header.store_string(register_types_header_template.get_as_text())
		
		register_types_header.close()
		register_types_header_template.close()
	
	var json = JSON.stringify(data)

	var fil = FileAccess.open(QuickExtension.DATA_PATH, FileAccess.ModeFlags.WRITE)
	fil.store_string(json)
	fil.close()
	
	queue_free()

func _on_headers_option_toggled(toggled_on: bool) -> void:
	$Container/cpp/Label2.visible = toggled_on
	$Container/cpp/Headers.visible = toggled_on
	use_cpp_headers = toggled_on
