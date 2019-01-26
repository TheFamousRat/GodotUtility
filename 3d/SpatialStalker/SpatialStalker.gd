extends Control

#Node that follows its parent on screen, if it is a Spatial node. Otherwise it wont move and act like a regular node

var stalkedSpatial : Spatial = null

func _ready():
	pass
	
func setStalkedSpatial(newSpatial : Spatial):
	stalkedSpatial = newSpatial
	
func getStalkedSpatial():
	return stalkedSpatial
	
func _process(delta):
	if stalkedSpatial != null:
		self.set_position(-0.5 * self.get_scale() * self.get_size() + get_viewport().get_camera().unproject_position(stalkedSpatial.get_global_transform().origin))

