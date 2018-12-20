tool

extends Node

var parentCurvedMesh : Node

func _ready():
	pass


func _on_MeshCurver_commitSurfaceTool(targetSt, curvedMeshMdt, beforeCurveMdt):
	var curvedMeshInstance : MeshInstance = get_parent().getCurvedMesh()
	
	curvedMeshInstance.set_mesh(targetSt.commit())
	
	curvedMeshMdt.create_from_surface(curvedMeshInstance.get_mesh(), 0)
	beforeCurveMdt.create_from_surface(curvedMeshInstance.get_mesh(), 0)
