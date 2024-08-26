@tool
class_name QuickExtension extends RefCounted

const DATA_PATH = "res://addons/QuickExtension/data.json"
const CLASSES_PATH = "res://addons/QuickExtension/classes.json"

const CLASS_TEMPLATE_SRC = "res://addons/QuickExtension/Templates/Class-Template.cpp.txt"
const CLASS_TEMPLATE_HEADER = "res://addons/QuickExtension/Templates/Class-Template.h.txt"
const REGISTER_CLASS_TEMPLATE_SRC = "res://addons/QuickExtension/Templates/ClassDB-Template.cpp.txt"
const REGISTER_CLASS_TEMPLATE_HEADER = "res://addons/QuickExtension/Templates/ClassDB-Template.h.txt"

# Fuck Regex
# static func camel_to_snake(camel_case_str: String) -> String:
#	var reg := RegEx.new()
#
#	reg.compile("(.)([A-Z][a-z]+)")
#	var res = reg.sub(camel_case_str, r"$\1_\2", true)
#
#	reg.compile("([a-z0-9])([A-Z])")
#	res = reg.sub(res, r"$\1_\2", true)
#
#	res = res.replace("2_D", "2D").replace("3_D", "3D").to_lower()
#	print(res)
#
#	assert(res != "")
#	return res

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
