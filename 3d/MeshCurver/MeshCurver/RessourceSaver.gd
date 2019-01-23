tool

extends MeshInstance

var savedArrayMesh : ArrayMesh

func _ready():
	get_parent().connect("commitSurfaceTool", self, "_on_MeshCurver_commitSurfaceTool")
	get_parent().initMesh(self)

func _on_MeshCurver_commitSurfaceTool(targetSt : SurfaceTool, curvedMeshMdt, beforeCurveMdt, surfaceIndex):
	var curvedMeshInstance : MeshInstance = get_parent().getCurvedMesh()
	
	if surfaceIndex == 0:
		savedArrayMesh = ArrayMesh.new()
	
	savedArrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, targetSt.commit().surface_get_arrays(0))
	curvedMeshInstance.set_mesh(savedArrayMesh)
	
	curvedMeshMdt.create_from_surface(targetSt.commit(), 0)
	beforeCurveMdt.create_from_surface(targetSt.commit(), 0)
	
	curvedMeshMdt.set_material(get_parent().mainMesh.surface_get_material(surfaceIndex))
	beforeCurveMdt.set_material(get_parent().mainMesh.surface_get_material(surfaceIndex))
