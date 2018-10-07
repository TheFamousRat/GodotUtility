# Code by Guillaume Roy, 2018.
# This script is a code for a basic "flying camera". The camera's orientation is guided by the mouse, and its position by the 
# directional keys

extends Camera

export (bool) var movEnabled = true
export (float) var mouseSensitivity = 0.1
export (float) var flyspeed = 1.0

var lastMousePos
var yaw
var pitch

func _ready():
	lastMousePos = get_viewport().get_mouse_position()
	yaw = 0
	pitch = 0
	
func _process(delta):
	var mouseVec = get_viewport().get_mouse_position() - lastMousePos
	lastMousePos = get_viewport().get_mouse_position()
	if movEnabled:
		var left = Input.is_action_pressed("ui_left")
		var right = Input.is_action_pressed("ui_right")
		var front = Input.is_action_pressed("ui_up")
		var back = Input.is_action_pressed("ui_down")
		
		yaw = fmod(yaw  - mouseVec.x * mouseSensitivity , 360)
		pitch = max(min(pitch - mouseVec.y * mouseSensitivity , 90), -90)
		self.set_rotation(Vector3(deg2rad(pitch), deg2rad(yaw), 0))
		
		if(front):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * flyspeed * .01)
		if(back):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * flyspeed * -.01)
		if(left):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * flyspeed * .01)
		if(right):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * flyspeed * -.01)
