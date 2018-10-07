# Code by Guillaume Roy, 2018.
# A basic 3rd person camera. No input interaction (except for the mouse) is implemented for now.
# The origin variable is the point around which the camera turns, while the dist is the distance between the camera and this point

extends Camera

export (bool) var movEnabled = true
export (float) var mouseSensitivity = 0.1

var lastMousePos
var yaw
var pitch
var origin = Vector3()
var dist = 4.0

func _ready():
	lastMousePos = get_viewport().get_mouse_position()
	yaw = 0
	pitch = 0
	
func _process(delta):
	var mouseVec = get_viewport().get_mouse_position() - lastMousePos
	lastMousePos = get_viewport().get_mouse_position()
	
	if movEnabled:
		yaw = fmod(yaw  - mouseVec.x * mouseSensitivity , 360)
		pitch = max(min(pitch - mouseVec.y * mouseSensitivity , 90), -90)
		
		self.set_rotation(Vector3(deg2rad(pitch), deg2rad(yaw), 0))
		self.set_translation(origin - dist * self.project_ray_normal(get_viewport().get_visible_rect().size * 0.5))
		
func get_center_ray_normal():
	#This function returns the normal vector at the center of the screen. 
	#In many games this vector is used to guide the player relative to the camera
	return self.project_ray_normal(get_viewport().get_visible_rect().size * 0.5)
