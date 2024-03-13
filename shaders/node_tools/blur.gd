@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeBlur

func _get_name():
	return "Blur"

func _get_category():
	return "PhosphorBurn"

func _get_description():
	return "Basic Gaussian Blur"

func _init():
	set_input_port_default_value(3, Vector4(0.0, 0.0, 0.0, 0.0))

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_VECTOR_4D

func _get_input_port_count():
	return 4

func _get_input_port_name(port):
	match port:
		0:
			return "sampler2D"
		1:
			return "uv"
		2:
			return "pixel_size"
		3:
			return "mix_in"

func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_SAMPLER
		1:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		2:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		3:
			return VisualShaderNode.PORT_TYPE_VECTOR_4D

func _get_output_port_count():
	return 1

func _get_output_port_name(port):
	return "blur"

func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_VECTOR_4D

func _get_code(input_vars, output_vars, mode, type):
	#return str(output_vars[0], " = vec4(1.0, 1.0, 1.0, 1.0);")
#blur.rgb = ((1.0 - 0.25) * blur.rgb) + (0.25 * vec3(0.0, 0.0, 0.0));
	#return str("vec4 blur = vec4(1.0, 1.0, 1.0, 1.0);\n", output_vars[0], " = blur;")
	return str("vec2 uv = ", input_vars[1],";\n",
"vec2 pixel_size = ", input_vars[2], ";\n",
"vec4 mix_in = ",input_vars[3],";\n",
"vec4 nw_color = texture(", input_vars[0], ", uv - pixel_size);\n",
"vec4 n__color = texture(", input_vars[0], ", uv - vec2(0.0, pixel_size.y));\n",
"vec4 ne_color = texture(", input_vars[0], ", uv + vec2(pixel_size.x, -pixel_size.y));\n",
"vec4 _w_color = texture(", input_vars[0], ", uv - vec2(pixel_size.x, 0.0));\n",
"vec4 ___color = texture(", input_vars[0], ", uv);\n",
"vec4 _e_color = texture(", input_vars[0], ", uv + vec2(pixel_size.x, 0.0));\n",
"vec4 sw_color = texture(", input_vars[0], ", uv + vec2(-pixel_size.x, pixel_size.y));\n",
"vec4 s__color = texture(", input_vars[0], ", uv + vec2(0.0, pixel_size.y));\n",
"vec4 se_color = texture(", input_vars[0], ", uv + pixel_size);\n",
		"""
vec4 top = (nw_color + n__color + ne_color) / 3.0;
vec4 mid = (_w_color + ___color + _e_color) / 3.0;
vec4 bot = (sw_color + s__color + se_color) / 3.0;
vec4 blur = (top + mid + bot) / 3.0;
blur.rgb = ((1.0 - mix_in.a) * blur.rgb) + (mix_in.a * mix_in.rgb);
""", output_vars[0], " = blur;")
