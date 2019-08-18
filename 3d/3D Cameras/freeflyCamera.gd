# Code by Guillaume Roy, 2019
# This script is a code for a basic "flying camera". The camera's orientation is guided by the mouse, and its position by the
# directional keys

extends Camera

export (bool) var movEnabled = true
export (float) var mouseSensitivity = 0.5
export (float) var flyspeed = 100.0

var yaw : float = 0.0
var pitch : float = 0.0

func _ready():
	yaw = 0.0
	pitch = 0.0

func _input(event):
	if event is InputEventMouseMotion and movEnabled:
		var mouseVec : Vector2 = event.get_relative()

		yaw = fmod(yaw  - mouseVec.x * mouseSensitivity , 360)
		pitch = max(min(pitch - mouseVec.y * mouseSensitivity , 90), -90)
		self.set_rotation(Vector3(deg2rad(pitch), deg2rad(yaw), 0))

func _process(delta):
	if(Input.is_action_pressed("ui_up")):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * delta * flyspeed * .01)
	if(Input.is_action_pressed("ui_down")):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * delta * flyspeed * -.01)
	if(Input.is_action_pressed("ui_left")):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * delta * flyspeed * .01)
	if(Input.is_action_pressed("ui_right")):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * delta * flyspeed * -.01)