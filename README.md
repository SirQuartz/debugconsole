# Debug Console
A general-purpose debug console for the Godot Engine.

![Debug Console](screenshots/Debug-Console-Demo.gif)
## Features
- Debugging suite full of useful in-game commands
- Usable in any project
- Lightweight and easy to use
- Persistent across all scenes

## Overview
I made this debug console to be a tool used in any type of project by incorporating many useful commands. It has commands to change the resolution, window mode, enable/disable vsync, display useful debug information such as frames per second, memory, cursor position, current resolution, current screen, and more. There's a command to change the time scale, as well as reload the current scene. There's a "help" command that displays a popup with all the commands and more information about them.

This scene is autoloaded and persistent across all scenes, therefore, you don't need to instance it into every scene, it already exists within every scene by default. When the debug console is brought up it automatically pauses the game, then when it's exited it automatically unpauses the game for you.

## Usage
Copy the `addons/Debug Console` folder into your projects directory, Then autoload the `console.tscn` scene within the Debug Console folder. This will make it present in every scene within your game. Press the tilde "~" on American keyboards just below the escape button to make the debug console appear in-game.

## Commands
Below is a list of all available commands that the debug console will accept. It works by typing the prefix followed by a space then enter the value.
- help
- clear
- quit
- cr `int,int`
- mw `fullscreen, windowed, borderless, bordered, vsync`
- mt `float`
- ma `string`, optional: `string`
- fov `float`
- debug `name, desc, fps, stats, draw, reload`

## License
MIT license.
