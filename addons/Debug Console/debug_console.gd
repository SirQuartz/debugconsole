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
export var user_space: bool = false # Sets whether to use user:// or res://

var last_command: String # Temporary var for last input command
var err = OK  # Check for errors
var file: String # File name for a screenshot
var screenshot: Image # The actual screenshot
var taking_screenshot: bool # Flag for the console so it knows we're busy
var calling_func: bool # Flag for the console so it knows we're busy
var user_path: String # The user directory either res:// or user://

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
	self.placeholder_text = "" # Get rid of the placeholder text
	var command = input_text.to_lower().split(" ")
	match input_text:
		"help": # Display list of commands
			self.placeholder_text = "Here is a list of commands"
			get_parent().get_node("CommandHelp").popup()
		"clear": # Clear all output
			self.clear()
			output.text = ''
		"quit": # Closes the game
			get_tree().quit(0)
	if taking_screenshot == true:
		file = new_text
		self.placeholder_text = ""
		screenshot.save_png(user_path + "Screenshots/" + file + ".png")
		output.text += "Screenshot " + file + " saved." + '\n'
	if "." in new_text: # If were calling a method on an object
		var entity = new_text.split(".")
		var final_entity = entity[1].split(" ")
		var option = new_text.strip_edges().split(" ")
		option.remove(0)
		call_func(str(entity[0]), str(final_entity[0]), option)
	if !taking_screenshot && !calling_func: # If we're not busy, use the command
		match command.size(): # Match the command size
			1:
				commands(command[0], "", "")
			2:
				commands(command[0], command[1])
			3:
				commands(command[0], command[1], command[2])
			_:
				last_command = new_text
				output.text += "Unknown command, " + "<" + new_text + ">" + \
				" not recognized" + '\n'
	calling_func = false
	taking_screenshot = false


# Make the output text jump to newest line
func _on_Output_cursor_changed():
	var count = output.get_line_count()
	output.cursor_set_line(count)


# Waits to take a screenshot so that the debug overlay has time to be hidden
func _on_Timer_timeout():
	var img = get_tree().get_current_scene().get_viewport().get_texture()\
	.get_data() # Grab the viewport texture
	img.flip_y() # Flip the image vertically so it's upright
	var dir = Directory.new() # If screenshots folder doesn't exist, make it
	if dir.open(user_path + "Screenshots") != err:
		dir.make_dir(user_path + "Screenshots")
	self.get_parent().show() # Show the debug overlay again
	self.placeholder_text = "Enter a name for the screenshot"
	taking_screenshot = true # Let the console know we're busy
	screenshot = img # The final image to save
	self.grab_focus()


func _on_CommandHelp_popup_hide():
	self.placeholder_text = ""


func _enter_tree():
	if enable_console == false: # If console is disabled, remove it
		self.get_parent().get_parent().queue_free()
	if user_space == true: # Sets the user-path based on the user_space flag
		user_path = "user://"
	else:
		user_path = "res://"


func _ready():
	var os = OS.get_name()
	var api = OS.get_current_video_driver()
	match os: # Match the graphics API to the corresponding OS
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
	if !prefix == "clear": # Don't print the clear command to the output log
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
		"shoot", "screenshot": # Take a screenshot of the viewport
			take_screenshot()
		"fov", "field_of_view": # Modify the field of view in 3D scenes
			mod_fov(command)
		"mt", "modify_time": # Modify the in-game time scale relative to ours
			mod_time(command)
		"debug":
			game_info(command)
		"help", "clear", "quit", "shoot", "y", "n": # If just a prefix, ignore
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
			if OS.get_video_driver_name(1):
				output.text += "Debug draw mode only works with a GLES3 " + \
				"render backend." + '\n'
			elif viewport.get_debug_draw() != Viewport.DEBUG_DRAW_OVERDRAW \
			&& OS.is_debug_build() && OS.get_current_video_driver() == 0:
				viewport.set_debug_draw(Viewport.DEBUG_DRAW_OVERDRAW)
				output.text += "Debug draw enabled." + '\n'
			elif !OS.is_debug_build():
				output.text += "Debug draw doesn't work in non-debug binaries."\
				+ '\n'
			else:
				viewport.set_debug_draw(Viewport.DEBUG_DRAW_DISABLED)
				output.text += "Debug draw disabled." + '\n'
		"ray":
			if get_tree().is_debugging_collisions_hint() == false:
				get_tree().set_debug_collisions_hint(true)
				get_tree().reload_current_scene()
				output.text += "Scene reloaded!" + '\n'
				output.text += "Debug ray enabled." + '\n'
			elif get_tree().is_debugging_collisions_hint() == true:
				get_tree().set_debug_collisions_hint(false)
				get_tree().reload_current_scene()
				output.text += "Scene reloaded!" + '\n'
				output.text += "Debug ray enabled." + '\n'
		"reload": # Reload the current scene
			get_tree().reload_current_scene()
			output.text += "Scene reloaded!" + '\n'
		_:
			output.text += \
			"Unknown command, " + "<" + command + ">" + " not recognized." +'\n'


# Modifies the in-game time scale
func mod_time(command):
	if str2var(command) is float:
		Engine.set_time_scale(abs(float(command)))
		output.text += "Time scale set to " + str(abs(float(command)) * 100) + \
		" %" + '\n'
	elif str2var(command) is int:
		Engine.set_time_scale(abs(int(command)))
		output.text += "Time scale set to " + str(abs(int(command)) * 100) + \
		" %" + '\n'
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
			match value: # Matches the corresponding MSAA value and sets it
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
						output.text += command + " set to on." + '\n'
					else:
						viewport.set_use_fxaa(false)
						output.text += command + " set to off." + '\n'
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


# Hides the debug overlay, starts timer, takes a screenshot of the viewport
func take_screenshot():
	self.get_parent().hide()
	var timer = get_parent().get_node("Timer")
	timer.start()


# Calls a function manually on the first object occurence in the current scene
func call_func(object: String, method: String, option: Array):
	calling_func = true # Tell the console we're busy
	var a: Node
	if get_tree().get_current_scene().find_node(object): # Did you find it?
		a = get_tree().get_current_scene().find_node(object)
	elif get_tree().get_root().get_node(object): # Is it a singleton?
		a = get_tree().get_root().get_node(object)
	else:
		output.text += "<" + str(object) + ">" + \
			" doesn't exist in the current scene." + '\n'
	if method != "" && a != null: # Make sure they actually entered a method
		if a.has_method(method):
			match option.size():
				0: # Check if there's any optional argument set
					a.call(method) # Call the method on the object
				1: # Use optional arguments if we have any
					a.call(method, str2var(option[0]))
				2:
					a.call(method, str2var(option[0]), str2var(option[1]))
				3:
					a.call(method, str2var(option[0]), str2var(option[1]), \
					str2var(option[2]))
				_:
					output.text += "You've entered more arguments than " + \
					"the console can process." + '\n'
			output.text += str(method) + " called on " + str(object) + '\n'
		else:
			output.text += "<" + str(object) + ">" + " doesn't have method " \
			+ "<" + str(method) + ">." + '\n'
