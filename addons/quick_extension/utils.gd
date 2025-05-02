@tool
class_name QuickExtensionUtils extends RefCounted

const CONFIG_PATH = "res://addons/quick_extension/sav/config.cfg"
static var config = ConfigFile.new()

const USER_FILES_CONFIG_PATH = "res://addons/quick_extension/sav/files.cfg"
static var user_files_config = ConfigFile.new()

static func exists_config_file() -> bool:
	var err = config.load(CONFIG_PATH)
	return err == OK

###
#
# Even though this is kind of stupid, we create a function for the
# different programming languages to avoid creating a type to store all
# the required data for all the programming languages
#
###

static func create_cpp_config_file(sources: String, headers: String, build_system: int, register_types: bool) -> bool:
	config.set_value("global", "language", "cpp")
	
	# Make sure we have the proper directory format
	if !sources.ends_with("/"):
		sources += "/"
	if !headers.ends_with("/"):
		headers += "/"
	
	config.set_value("cpp", "sources", sources)
	config.set_value("cpp", "headers", headers)
	config.set_value("cpp", "build_system", build_system)
	config.set_value("cpp", "register_types", register_types)

	user_files_config.set_value("cpp", "sources", PackedStringArray())
	user_files_config.set_value("cpp", "headers", PackedStringArray())
	user_files_config.set_value("cpp", "classes", PackedStringArray())
	
	return config.save(CONFIG_PATH) == OK && user_files_config.save(USER_FILES_CONFIG_PATH) == OK

static func read_text_file(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.ModeFlags.READ)
	
	assert(file != null)
	
	var ret = file.get_as_text()
	file.close()
	
	return ret
	
static func write_text_file(path: String, buffer: String):
	var file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	file.store_string(buffer)
	file.flush()

	file.close()
	
static func camel_to_snake(camel_case_str: String) -> String:
	var snake_case_str := ""

	for i in range(camel_case_str.length()):
		var char := camel_case_str[i]
		# I couldn't find another solution for this...
		if char == char.to_upper():
			if i != 0:
				snake_case_str += "_"
			snake_case_str += char
		else:
			snake_case_str += char

	return snake_case_str.replace("_2_D", "2D").replace("_3_D", "3D").to_lower()
