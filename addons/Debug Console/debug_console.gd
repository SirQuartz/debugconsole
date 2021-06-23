extends LineEdit

"""
MIT License

Copyright © 2021 Nicholas Huelin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""


export var enable_console: bool = true # True if the console is enabled
export var mouse_visible_on_unpause: bool = true # Sets mouse visibility on exit

var last_command: String # Temporary var for last input command
var err = OK  # Check for errors

# GUI vars
onready var output = get_parent().get_node("Output")
onready var fps_counter = get_parent().get_node("DebugLabelVbox/FPSCounter")
onready var stats = get_parent().get_node("DebugLabelVbox/Stats")
onready var graphics_api = get_parent().get_node("Output/GraphicsAPI")
onready var viewport = get_tree().get_current_scene().get_viewport()


# User input
func _on_Input_text_entered(new_text: String):
	var input_text = new_text.to_lower().lstrip(" ").rstrip(" ") # Convert
	self.clear()
	self.placeholder_text = ""
	var command = input_text.to_lower().split(" ")
	if input_text == "help": # Display list of commands
		self.text = "Here is a list of commands"
		get_parent().get_node("CommandHelp").popup()
	if input_text == "clear": # Clear all output
		self.clear()
		output.text = ''
	if input_text == "quit":
		get_tree().quit(0)
	if err == OK && command.size() == 1:
		commands(command[0], "", "")
	elif err == OK && command.size() == 2:
		commands(command[0], command[1])
	elif err == OK && command.size() == 3:
		commands(command[0], command[1], command[2])
	else:
		last_command = input_text
		output.text += "Unknown command, " + "<" + input_text + ">" + \
		" not recognized" + '\n'


# Make the output text jump to newest line
func _on_Output_cursor_changed():
	var count = output.get_line_count()
	output.cursor_set_line(count)


func _enter_tree():
	if enable_console == false: # If console is disabled, remove it
		self.get_parent().get_parent().queue_free()


func _ready():
	var os = OS.get_name()
	var api = OS.get_current_video_driver()
	match os:
		"HTML5":
			if api == 0:
				graphics_api.text = "WebGL 2.0"
			else:
				graphics_api.text = "WebGL 1.0"
		"Android", "IOS":
			if api == 0:
				graphics_api.text = "OpenGL ES 3.0"
			else:
				graphics_api.text = "OpenGL ES 2.0"
		_:
			if api == 0:
				graphics_api.text = "OpenGL 3.3"
			else:
				graphics_api.text = "OpenGL 2.1"
				

func _process(delta): # Only FPS needs to be measured as fast as possible
	var fps = Engine.get_frames_per_second()
	fps_counter.text = "FPS: " + str(fps)


func _physics_process(delta): # Process info
	var debug_smem = OS.get_static_memory_usage()
	var debug_dmem = OS.get_dynamic_memory_usage()
	var debug_mouse = get_global_mouse_position()
	var debug_size = OS.window_size
	var debug_vsync = OS.vsync_enabled
	var debug_screen = OS.current_screen
	var debug_vid = VisualServer.get_video_adapter_name()
	var debug_time = Engine.time_scale
	var debug_draw = viewport.get_debug_draw()
	var debug_fxaa = viewport.get_use_fxaa()
	var debug_msaa = get_msaa_value()
	stats.text = "Static Memory: " + \
	str(debug_smem).humanize_size(debug_smem) + '\n'
	stats.text += "Dynamic Memory: " + \
	str(debug_dmem).humanize_size(debug_dmem) + '\n'
	stats.text += "Cursor: " + str(debug_mouse) + '\n'
	stats.text += str(debug_vid) + '\n'
	stats.text += "Resolution: " + str(debug_size) + '\n'
	stats.text += "Screen: " + str(debug_screen) + '\n'
	stats.text += "Vsync: " + str(debug_vsync) + '\n'
	stats.text += "FXAA: " + str(debug_fxaa) + '\n'
	stats.text += "MSAA: " + str(debug_msaa) + '\n'
	stats.text += "Time Scale: " + str(debug_time) + '\n'


# Handles the pausing and displaying of the console
func _input(event):
	if self.visible == false && enable_console == true:
		if event is InputEventKey && event.is_action_released("debug") && \
		!event.is_echo():
			self.grab_focus()
			self.visible = true
			output.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = !get_tree().paused # Toggle pause
	else:
		if event is InputEventKey && event.is_action_released("debug") && \
		!event.is_echo():
			self.delete_char_at_cursor()
			self.release_focus()
			self.visible = false
			output.visible = false
			if mouse_visible_on_unpause:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			get_tree().paused = !get_tree().paused
	if event is InputEventKey && event.is_pressed() && !event.is_echo() && \
	event.scancode == KEY_UP:
		self.text = last_command


# Handles all input commands, uses a prefix-command system, split by a space
func commands(prefix: String, command: String = "", Option: String = ""):
	# Write the command to the output window
	if !prefix == "clear":
		output.text += prefix + " " + command + '\n'
	match prefix: # Match the prefix, then check for the relevant command
		"cr", "change_resolution":
			var dim_array = command.split(",")
			if err == OK && str2var(dim_array[0]) is int \
			&& str2var(dim_array[1]) is int: # Make sure they're both an integer
				var dimensions = Vector2(dim_array[0], dim_array[1])
				change_dim(dimensions)
			else:
				output.text += \
				"\"cr\" expects whole integer values, ex: cr 500,500" + "\n"
		"mw", "modify_window":
			mod_window(command)
		"fxaa":
			mod_alias("fxaa", Option)
		"msaa":
			mod_alias("msaa", command)
		"vsync":
			mod_window("vsync")
		"fov", "field_of_view":
			mod_fov(command)
		"mt", "modify_time":
			mod_time(command)
		"debug":
			game_info(command)
		"help", "clear", "quit":
			pass
		_:
			output.text += "Unknown command, " + \
			str("<" + prefix + " " + command + ">") + " not recognized." + '\n'
	last_command = prefix + " " + command # Set the last command


# Changes the window dimensions
func change_dim(command: Vector2):
	OS.window_size.x = abs(command.x)
	OS.window_size.y = abs(command.y)


# Changes the window state
func mod_window(command: String):
	match command:
		"fullscreen":
			OS.window_fullscreen = true
		"windowed":
			OS.window_fullscreen = false
		"borderless":
			OS.window_borderless = true
		"bordered":
			OS.window_borderless = false
		"vsync":
			if OS.vsync_enabled == false:
				OS.set_use_vsync(true) # Enable vsync
				output.text += "Vsync enabled" + '\n'
			else:
				OS.vsync_enabled = false # Disable vsync
				output.text += "Vsync disabled" + '\n'
		_:
			output.text += \
			"Unknown command, " + "<" + command + ">" + " not recognized." +'\n'


# Displays debug game info in-game
func game_info(command: String):
	match command:
		"name": # Return the name of the project
			output.text += \
			str(ProjectSettings.get_setting("application/config/name")) + '\n'
		"desc": # Return the project's description
			output.text += \
			str(ProjectSettings.get_setting("application/config/description"))\
			 + '\n'
		"fps": # Toggle FPS counter on or off
			if fps_counter.visible == false:
				output.text += "FPS counter enabled" + '\n'
				fps_counter.visible = true
			else:
				output.text += "FPS counter disabled" + '\n'
				fps_counter.visible = false
		"stats": # Toggle useful stats on or off
			if stats.visible == false:
				output.text += "Stats enabled" + '\n'
				stats.visible = true
			else:
				output.text += "Stats disabled" + '\n'
				stats.visible = false
		"draw": # Toggle overdraw on or off
			if viewport.get_debug_draw() != Viewport.DEBUG_DRAW_OVERDRAW:
				viewport.set_debug_draw(Viewport.DEBUG_DRAW_OVERDRAW)
				output.text += "Debug draw enabled." + '\n'
			else:
				viewport.set_debug_draw(Viewport.DEBUG_DRAW_DISABLED)
				output.text += "Debug draw disabled." + '\n'
		"reload": # Reload the current scene
			get_tree().reload_current_scene()
		_:
			output.text += \
			"Unknown command, " + "<" + command + ">" + " not recognized." +'\n'


# Modifies the in-game time scale
func mod_time(command):
	if str2var(command) is float:
		Engine.set_time_scale(float(command))
	elif str2var(command) is int:
		Engine.set_time_scale(int(command))
	else:
		output.text += "<"+str(command)+">" + \
		" is not a value for modify time." + '\n'


# Modifies the in-game field of view for the current 3D camera
func mod_fov(command):
	if get_tree().get_current_scene().get_viewport().world:
		if float(command) <= 179 && float(command) >= 1:
			if get_tree().get_current_scene().get_viewport().get_camera() \
			!= null:
				get_tree().get_current_scene().get_viewport()\
				.get_camera().set_fov(float(command))
				output.text += "Field of view set to " + str(command) + '\n'
			else:
				output.text += "There is currently no 3D camera." + '\n'
		else:
			output.text += "The field of view must be between (including) " + \
			"1 and 179." + '\n'
	else:
		output.text += "Field of view is not available in a 2D scene." + '\n'


# Modifies the anti-aliasing settings for the scene viewport
func mod_alias(command, value = null):
	match command:
		"msaa":
			match value:
				"2":
					viewport.set_msaa(Viewport.MSAA_2X)
					output.text += command + " set to " + value + "x" + '\n'
				"4":
					viewport.set_msaa(Viewport.MSAA_4X)
					output.text += command + " set to " + value + "x" + '\n'
				"8":
					viewport.set_msaa(Viewport.MSAA_8X)
					output.text += command + " set to " + value + "x" + '\n'
				"off":
					viewport.set_msaa(Viewport.MSAA_DISABLED)
					output.text += command + " set to " + value + '\n'
				_:
					output.text += command + " " + value + " not recognized." \
					+ '\n'
		"fxaa":
			match value:
				"":
					if viewport.get_use_fxaa() == false:
						viewport.set_use_fxaa(true)
						output.text += command + " set to true." + '\n'
					else:
						viewport.set_use_fxaa(false)
						output.text += command + " set to false." + '\n'
				_:
					output.text += command + " " + value + " not recognized." \
					+ '\n'
		_:
			output.text += command + " " + value + " not recognized." + '\n'


# Gets the current MSAA setting
func get_msaa_value():
	match viewport.get_msaa():
		Viewport.MSAA_DISABLED:
			return "Off"
		Viewport.MSAA_2X:
			return "2X"
		Viewport.MSAA_4X:
			return "4X"
		Viewport.MSAA_8X:
			return "8X"
