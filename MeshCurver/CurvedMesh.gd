tool

extends MeshInstance

func _ready():
	print("yeah")
	get_parent().setMeshInstancePointer(self)

