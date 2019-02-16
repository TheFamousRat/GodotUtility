Guillaume Roy - 2018

MeshCurver v1.0

A small MeshCurver plugin, imagined as a combination between Blender's Array and Curve modifier. 
What this plugin does is allow you to create a 3D Bezier curve, and deform a mesh relative to that 3D curve.
The plugin supports multi-surfaces meshes, all Godot-supported shaders, scaling of the mesh on the curve, as well as the creation of 
Trimesh bounding boxes that allow the deformed meshes to be obstacles in the game.

Being written in C++, the plugin is very fast, and most game-sized meshes shouldn't cause any problem.

To use this plugin : 
1/Download
2/Place everything in your project folder
3/Instance MeshCurver.tscn (you have to click on the small chain just above your Scene's main node)
4/Now you're ready to curve meshes like there's no tomorrow !
