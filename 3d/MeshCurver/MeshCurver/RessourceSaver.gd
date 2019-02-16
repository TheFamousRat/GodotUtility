tool

extends Node

func _ready():
	get_parent().connect("commitSurfaceTool", self, "_on_MeshCurver_commitSurfaceTool")
	get_parent().initMesh()

func _on_MeshCurver_commitSurfaceTool(targetSt : SurfaceTool, curvedMeshMdt, beforeCurveMdt, surfaceIndex):

	curvedMeshMdt.create_from_surface(targetSt.commit(), 0)
	beforeCurveMdt.create_from_surface(targetSt.commit(), 0)
	
	curvedMeshMdt.set_material(get_parent().mainMesh.surface_get_material(surfaceIndex))
	beforeCurveMdt.set_material(get_parent().mainMesh.surface_get_material(surfaceIndex))
