# GodohMyGod
You never thought your project would generate this much buzz.

GodohMyGod is a plugin that adds intimate haptic device integration directly into the Godot script editor via [buttplug.io](https://buttplug.io/). 

You'll need to have [Intiface Central](https://intiface.com/central/) installed and configured, your device(s) connected and added in Intiface, and this plugin installed and enabled in your Godot Project. Then simply connect to Intiface Central from inside Godot, choose your device and the action to perform and away you go to coding bliss! 

## GodohMyGod Control Panel
![image](https://github.com/deadpixelsociety/godohmygod/assets/6668682/f2571f12-31de-4a09-8052-a1ac38c58248)

* Server - The Intiface Central server to the connect to.
* Port - The Intiface Central server port to connect to.
* Device - The device you'd like to use. Connect this via Intiface Central.
* Action - The device action you'd like to trigger.
* Activation Interval - The number of keypresses before the device action is triggered.
* Intensity/Position - The intensity (or position for linear/moving actions) of the action from 0 (none) to 1 (max).
* Variance - A random value, plus or minus, added to the intensity to introduce some randomness.
* Duration - How long, in seconds, for the action to trigger.
