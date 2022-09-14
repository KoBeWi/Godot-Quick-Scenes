# <img src="https://github.com/KoBeWi/Godot-Quick-Scenes/blob/master/Media/Icon.png" width="64" height="64"> Godot Quick Scenes
This plugin allows you to select multiple scenes for quick access. You can quickly edit the scene or run it. There is also dedicated shortcut for running selected scene.

## Usage

Enable the plugin in Project Setttings. Quick Scenes should appear in your bottom pannel. It looks like this (after you press the Add scene button):
![](https://github.com/KoBeWi/Godot-Quick-Scenes/blob/master/Media/ReadmeNumbers.png)

1. Opens the scenes panel.
2. This button is always on top and adds a new empty scene entry.
3. Path to the scene file. Best way to get it is to right-click your scene in file system dock and select Copy Path.
4. Runs the scene at the provided path.
5. Opens the scene in editor.
6. If this is checked, this scene will be ran after pressing the shortcut (default is <kbd>F9</kbd>) in the editor.
7. Press both trash bins to delete a scene from quick access. This is safety measure, as you can't undo this action.

## Settings

The addon stores a few settings in the `project.godot` file. They can be changed in "Addons/Quick Scenes" section of Project Settings.
![](https://github.com/KoBeWi/Godot-Quick-Scenes/blob/master/Media/ReadmeSettings.png)

Here you can configure the shortcut used for quick-running scene. You need to copy keycode from the docs though.

The other settings are used internally by the plugin. Don't touch them.

___
You can find all my addons on my [profile page](https://github.com/KoBeWi).

<a href='https://ko-fi.com/W7W7AD4W4' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
