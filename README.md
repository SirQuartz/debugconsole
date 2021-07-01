# Debug Console
A general-purpose debug console for the Godot Engine.

![Debug Console](screenshots/Debug-Console-Demov1.gif)
## Features
- Debugging suite full of useful in-game commands
- Usable in any project
- Lightweight and easy to use
- Persistent across all scenes

## Overview
I made this debug console to be a tool used in any type of project by incorporating many useful commands. It has commands to change the resolution, window mode, enable/disable vsync, display useful debug information such as frames per second, memory, cursor position, current resolution, current screen, and more. There's a command to change the time scale, as well as reload the current scene. There's a "help" command that displays a popup with all the commands and more information about them.

This scene is autoloaded and persistent across all scenes, therefore, you don't need to instance it into every scene, it already exists within every scene by default. When the debug console is brought up it automatically pauses the game, then when it's exited it automatically unpauses the game for you.

![Debug Stats](https://raw.githubusercontent.com/SirQuartz/debugconsole/main/screenshots/Debug%20stats.PNG)

## Usage
Copy the `addons/Debug Console` folder into your projects directory, Then autoload the `console.tscn` scene within the Debug Console folder. This will make it present in every scene within your game. Next you need to create a new `InputEventAction` by going to Project>Project Settings>Input Map and create an action called "debug" and assign it a key. Press the "debug" action to bring up the console in-game. Be sure to consult the [wiki](https://github.com/SirQuartz/debugconsole/wiki) for more detailed information.

## Commands
Below is a list of all available commands that the debug console will accept. It works by typing the prefix followed by a space then enter the value.
- help
- clear
- quit
- shoot
- cr `int,int`
- mw `fullscreen, windowed, borderless, bordered`
- mt `float`
- vsync
- fxaa
- msaa `2, 4, 8, off`
- fov `float`
- debug `name, desc, fps, stats, draw, reload`

## License
MIT license.
