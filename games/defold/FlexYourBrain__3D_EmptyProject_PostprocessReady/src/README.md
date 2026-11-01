

# **Defold Empty 3d project + postprocess ready** 

## **USE**
Sending message "posteffect" to the render socket "@render:" will enable or disable prost process effect.
```
msg.post("@render:", "posteffect")
```

tip: *In collection select "postprocess" game object then press cntrl+E to hide it from scene view.*
## **Description:**
Custom render script for 3d models and postprocess render target. Render target is automatically rebuilt on window resizing. The physics type is set to 3D. In main collection a game object with id "postprocess" has a quad model component that is sized to fit the screen , also is a child of camera game object and follows it around when moved.

The project contains a bootstrap ["main.collection"](defold://open?path=/main/main.collection) that includes a game object, camera component and script that sets a background color and sets the camera to active slot in render script. This script also acquires input, listens for the spacebar key to turn the postprocess effect on and off for demonstration purposes. This can be removed or re-purposed for your game as well as the post process shader "pp_default". Space key is set in game.input_binding.

### Check out [the documentation pages](https://defold.com/learn) for examples, tutorials, manuals and API docs.

### If you run into trouble, help is available in [our forum](https://forum.defold.com).

Happy Defolding!

