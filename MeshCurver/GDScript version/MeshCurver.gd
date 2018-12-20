tool

extends Path

export (bool) onready var showDebugRays  = false setget toggleVisibleDebugRays
export (bool) onready var enableUpVector = true setget toggleUpVector
export (Mesh) var mainMesh = PlaneMesh.new() setget updateMesh
export (int) var meshRepetitonsNumber = 1 setget updateRepetitonsNumber
export (float) var curvedMeshStartingOffset = 0.0 setget changeStartingOffset
export (bool) var createTrimeshStaticBody = false setget generateCollision
export (bool) var test = false setget testFunc#To test some things out
export (Vector3) var xyzScale = Vector3(1,1,1) setget changeXScale

var epsilon = 0.2
var debugRaysInterval = 2.0 #Don't make too small !
#Used to locate the vertices of the mesh along a line. We then consider that the curve is this very same line, but deformed
var minDist = 0.0
var maxDist = 0.0
var mainMeshDist = 0.0

var guidingVectorOrigin = Vector3(0,0,0)
var guidingVector = Vector3(1,0,0) 

var mainMeshMdt = MeshDataTool.new()
var beforeCurveMdt = MeshDataTool.new() #copy of curvedMeshMdt at creation
var curvedMeshMdt = MeshDataTool.new()

var prevCurve : Curve3D = Curve3D.new()
var updateLowerBound : int
var updateFrequency : float = 0.5#The smaller this number is, the more updates there are
var deltaSum : float = 0.0

func _ready():
	if meshRepetitonsNumber == null:
		meshRepetitonsNumber = 1
	if curvedMeshStartingOffset == null :
		curvedMeshStartingOffset = 0.0
	if mainMesh == null:
		mainMesh = ArrayMesh.new()
	enableUpVector = true
	deltaSum = 0.0
	
	updateLowerBound = -1
	prevCurve = curve.duplicate()

func _process(delta):
	deltaSum += delta
	
	if deltaSum >= updateFrequency:
		deltaSum = 0
		if updateLowerBound != -1 and curve.get_point_count() != 0:
			print(updateLowerBound)
			if showDebugRays:
				self.recalculateDebugRayCasts()
			curveMainMesh(curve, curvedMeshStartingOffset, updateLowerBound)
			updateLowerBound = -1

func updateCurve():
	if prevCurve.get_point_count() != 0 and curve.get_point_count() != 0:
		if prevCurve.get_point_count() < curve.get_point_count():#A vertex was added
			if prevCurve.get_point_position(prevCurve.get_point_count()-1) != curve.get_point_position(curve.get_point_count()-1):
				if updateLowerBound == -1:
					updateLowerBound = max(0,curve.get_point_count()-2)
				else:
					updateLowerBound = min(updateLowerBound, curve.get_point_count()-2)
			else:
				for i in prevCurve.get_point_count():
					if prevCurve.get_point_position(i) != curve.get_point_position(i):
						if updateLowerBound == -1:
							updateLowerBound = max(0,i-1)
						else:
							updateLowerBound = min(updateLowerBound,i-1)
						break
		elif prevCurve.get_point_count() > curve.get_point_count():
			if prevCurve.get_point_position(prevCurve.get_point_count()-1) != curve.get_point_position(curve.get_point_count()-1):
				if updateLowerBound == -1:
					updateLowerBound = max(0,curve.get_point_count()-1)
				else:
					updateLowerBound = min(updateLowerBound, curve.get_point_count()-1)
			else:
				for i in prevCurve.get_point_count():
					if prevCurve.get_point_position(i) != curve.get_point_position(i):
						if updateLowerBound == -1:
							updateLowerBound = max(0,i-1)
						else:
							updateLowerBound = min(updateLowerBound,i-1)
						break
		else:#Same vertices count, but there was change
			for i in prevCurve.get_point_count():
				if prevCurve.get_point_in(i) != curve.get_point_in(i) or prevCurve.get_point_out(i) != curve.get_point_out(i) or prevCurve.get_point_position(i) != curve.get_point_position(i) or prevCurve.get_point_tilt(i) != curve.get_point_tilt(i):
					if updateLowerBound == -1:
						updateLowerBound = max(0,i-1)
					else:
						updateLowerBound = min(updateLowerBound,i)
					break
	
	prevCurve = curve.duplicate()
	
func testFunc(value):
	#Used from time to time by some shady developper. Who might it be ?
	pass
	
#Adds an interval in a reunion of intervals, in such a way that all elements of the array are sorted and disjointed
func addIntervalInReunion(reunionArray : PoolVector2Array, newInterval : Vector2):
	if newInterval.x > newInterval.y:#If the interval isn't correctly sent, we swap the values
		var temp = newInterval.x
		newInterval.x = newInterval.y
		newInterval.y = temp
	
	var tempInterval
	
	if reunionArray.size() != 0:
		if newInterval.y < reunionArray[0].x:
			reunionArray.insert(0,newInterval)
		elif newInterval.x > reunionArray[reunionArray.size() - 1].y:
			reunionArray.append(newInterval)
		else:
			for i in reunionArray.size():
				tempInterval = joinTwoIntervals(reunionArray[i],newInterval)
				if tempInterval != null:
					reunionArray[i] = tempInterval
					break
				elif i < reunionArray.size()-1:
					if newInterval.x > reunionArray[i].y and newInterval.y < reunionArray[i+1].x:
						reunionArray.insert(i+1, newInterval)
						break
				
		#We ensure that all intervals are disjointed
		var allIntervalsDisjointed = false
		while allIntervalsDisjointed == false:
			allIntervalsDisjointed = true
			for i in reunionArray.size() - 1:
				tempInterval = joinTwoIntervals(reunionArray[i],reunionArray[i+1])
				if tempInterval != null:
					allIntervalsDisjointed = false
					reunionArray.remove(i+1)
					reunionArray[i] = tempInterval
					break
		
	else:
		reunionArray.append(newInterval)
	
	return reunionArray
	
#Returns a jointed interval if it exists. Otherwise, returns null
func joinTwoIntervals(interval1 : Vector2, interval2 : Vector2):
	
	if interval1.x > interval2.x:
		var temp = interval1
		interval1 = interval2
		interval2 = temp
	
	if interval1.y >= interval2.x:
		return Vector2(min(interval1.x,interval2.x),max(interval1.y,interval2.y))
		
func generateCollision(value):
	if self.has_node("CurvedMesh") and value == true:
		for i in $CurvedMesh.get_children():
			if i is StaticBody:#We delete all the previous collisionShapes
				i.queue_free()

		$CurvedMesh.create_trimesh_collision()
	
func updateMesh(mesh):
	if mesh != null and self.has_node("CurvedMesh"):
		mainMesh = ArrayMesh.new()

		#We convert the mesh input from any mesh type to an ArrayMesh
		mainMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(0))
			
		#We then create a MeshDataTool, which we will use to get the vertices
		mainMeshMdt = MeshDataTool.new()
		mainMeshMdt.create_from_surface(mainMesh, 0)
		
		minDist = pointDist(guidingVector, guidingVectorOrigin, mainMeshMdt.get_vertex(0))
		maxDist = minDist
		var currentDist = 0
		for i in range(1, mainMeshMdt.get_vertex_count()):
			currentDist = pointDist(guidingVector, guidingVectorOrigin, mainMeshMdt.get_vertex(i))
			minDist = min(minDist, currentDist)
			maxDist = max(maxDist, currentDist)
		mainMeshDist = maxDist - minDist

		repeatMeshFromMdtToMeshIns(mainMeshMdt, $CurvedMesh, meshRepetitonsNumber, mainMeshDist, curvedMeshMdt)
		curveMainMesh(curve, curvedMeshStartingOffset)
		
func updateRepetitonsNumber(value):
	if self.has_node("CurvedMesh"):
		if value >= 1:
			meshRepetitonsNumber = value
			repeatMeshFromMdtToMeshIns(mainMeshMdt, $CurvedMesh, meshRepetitonsNumber, mainMeshDist, curvedMeshMdt)
			curveMainMesh(curve, curvedMeshStartingOffset)
			
func curveMainMesh(guidingCurve : Curve3D, startingOffset : float = 0.0, updateFromVertexOfId : int = 0):
	if self.has_node("CurvedMesh") and beforeCurveMdt.get_vertex_count() != 0 and curve.get_point_count() != 0:
		
		var alpha : float = 0.0
		var beta : float = 0.0
		var originalVertex : Vector3 = Vector3(0,0,0)
		var vertexCurveOffset : float = 0.0
		var minOffset : float = curvePointIdToOffset(updateFromVertexOfId, guidingCurve)
			
		for vertexIndex in range(beforeCurveMdt.get_vertex_count()):
			originalVertex = beforeCurveMdt.get_vertex(vertexIndex)
			#The offset of the vertex on the curve
			vertexCurveOffset = xyzScale.x * min(guidingCurve.get_baked_length()/xyzScale.x, startingOffset + pointDist(guidingVector, guidingVectorOrigin, originalVertex) - minDist)
			
			if vertexCurveOffset >= minOffset:
				alpha = xyzScale.y * originalVertex.y
				beta = xyzScale.z * originalVertex.z
				curvedMeshMdt.set_vertex(vertexIndex, guidingCurve.interpolate_baked(vertexCurveOffset) + alpha * self.getUpFromOffset(vertexCurveOffset) + beta * self.getNormalFromOffset(vertexCurveOffset))

		var test = ArrayMesh.new()
		curvedMeshMdt.commit_to_surface(test)
		$CurvedMesh.set_mesh(test)
		for i in $CurvedMesh.get_children():
			if i is StaticBody:
				i.queue_free()
		
func curvePointIdToOffset(idx : int, targetCurve : Curve3D):
	if idx == INF:
		return INF
	elif idx == -INF:
		return -INF
	else:
		return(targetCurve.get_closest_offset(targetCurve.get_point_position(idx)))
		
func changeStartingOffset(newOffset):
	curvedMeshStartingOffset = newOffset

func repeatMeshFromMdtToMeshIns(sourceMdt : MeshDataTool, targetMeshInstance : MeshInstance, repetitions : int, meshSize : float, meshInstanceMdt):
	var targetSt : SurfaceTool = SurfaceTool.new()
	
	targetSt.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var currentVertexId : int = 0
	
	for meshNumber in range(repetitions):
		for faceNumber in sourceMdt.get_face_count():
			for faceVertexNumber in range(3):
				#We go through every face, and then every 3 vertices in those faces
				currentVertexId = sourceMdt.get_face_vertex(faceNumber, faceVertexNumber)
				targetSt.add_color(sourceMdt.get_vertex_color(currentVertexId))
				targetSt.add_normal(sourceMdt.get_vertex_normal(currentVertexId))
				targetSt.add_uv(sourceMdt.get_vertex_uv(currentVertexId))
				targetSt.add_vertex(guidingVector*meshNumber*meshSize + sourceMdt.get_vertex(currentVertexId))
		
	targetSt.index()
	targetMeshInstance.set_mesh(targetSt.commit())

	meshInstanceMdt.create_from_surface(targetMeshInstance.get_mesh(), 0)
	beforeCurveMdt.create_from_surface(targetMeshInstance.get_mesh(), 0)
		
func pointDist(planeNormal, normalOrigin, point):
	return planeNormal.x * (point.x - normalOrigin.x) + planeNormal.y * (point.y - normalOrigin.y) + planeNormal.z * (point.z - normalOrigin.z)

func toggleVisibleDebugRays(value):
	showDebugRays = value
	
	if !value:
		if self.has_node("AllRaycasts/NormVecs") and self.has_node("AllRaycasts/TangentVecs") and self.has_node("AllRaycasts/UpVecs"):
			for i in $AllRaycasts/NormVecs.get_children():
				i.queue_free()
			for i in $AllRaycasts/TangentVecs.get_children():
				i.queue_free()
			for i in $AllRaycasts/UpVecs.get_children():
				i.queue_free()
	
func toggleUpVector(value):
	enableUpVector = value
	if showDebugRays:
		recalculateDebugRayCasts()
	
func getTangentFromOffset(offset):
	return ((curve.interpolate_baked(offset+epsilon) - curve.interpolate_baked(offset-epsilon))/2).normalized()
	
func getUpFromOffset(offset):
	if enableUpVector:
		return curve.interpolate_baked_up_vector(offset)
	else:
		return Vector3(0,1,0)
		
func getNormalFromOffset(offset):
	return getNormalFromUpAndTangent(getUpFromOffset(offset), getTangentFromOffset(offset))
	
func getNormalFromUpAndTangent(up, tangent):
	var x = up.x
	var y = up.y
	var z = up.z
	var t = tangent.x
	var u = tangent.y
	var v = tangent.z
	var ret = Vector3()
	if (y*t-u*up.x != 0):
		var c = sign(y*t-u*up.x)
		var b = c*(v*x-z*t)/(y*t-u*up.x)
		var a = c*(z*u-y*v)/(y*t-u*up.x)
		ret = Vector3(a,b,c).normalized()
	else:
		if (t != 0):
			var b = t
			var a = -b * u / t
			ret = Vector3(a,b,0.0).normalized()
		else:
			if (x != 0):
				var b = x
				var a = -b * y / x
				ret = Vector3(a,b,0.0).normalized()
			else:
				ret = Vector3(1.0,0.0,0.0)
	return ret
	
#We recalculate the RayCasts. They are only used for visual debug and have no other purpose !
func recalculateDebugRayCasts():
	#First we create the correct number of RayCasts
	#First the up vecs
	var vecsNums = ceil(curve.get_baked_length() / debugRaysInterval)
	
	if self.has_node("AllRaycasts/NormVecs") and self.has_node("AllRaycasts/TangentVecs") and self.has_node("AllRaycasts/UpVecs"):
		if vecsNums != $AllRaycasts/UpVecs.get_child_count():
			while $AllRaycasts/UpVecs.get_child_count() < vecsNums:
				var newUpRay = RayCast.new()
				$AllRaycasts/UpVecs.add_child(newUpRay)
				newUpRay.set_owner(get_tree().get_edited_scene_root())
			while $AllRaycasts/UpVecs.get_child_count() > vecsNums:
				$AllRaycasts/UpVecs.remove_child($AllRaycasts/UpVecs.get_child(0))
		#Then the tangent rays
		if vecsNums != $AllRaycasts/TangentVecs.get_child_count():
			while $AllRaycasts/TangentVecs.get_child_count() < vecsNums:
				var newUpRay = RayCast.new()
				$AllRaycasts/TangentVecs.add_child(newUpRay)
				newUpRay.set_owner(get_tree().get_edited_scene_root())
			while $AllRaycasts/TangentVecs.get_child_count() > vecsNums:
				$AllRaycasts/TangentVecs.remove_child($AllRaycasts/TangentVecs.get_child(0))
		
		#Finally the normal rays
		if vecsNums != $AllRaycasts/NormVecs.get_child_count():
			while $AllRaycasts/NormVecs.get_child_count() < vecsNums:
				var newUpRay = RayCast.new()
				$AllRaycasts/NormVecs.add_child(newUpRay)
				newUpRay.set_owner(get_tree().get_edited_scene_root())
			while $AllRaycasts/NormVecs.get_child_count() > vecsNums:
				$AllRaycasts/NormVecs.remove_child($AllRaycasts/NormVecs.get_child(0))
				
		var offset = 0.0
		var index = 0.0
		
		while offset < curve.get_baked_length():
			index = offset / debugRaysInterval
			
			$AllRaycasts/UpVecs.get_child(index).translation = curve.interpolate_baked(offset)
			$AllRaycasts/UpVecs.get_child(index).cast_to = getUpFromOffset(offset)
				
			$AllRaycasts/TangentVecs.get_child(index).translation = curve.interpolate_baked(offset)
			$AllRaycasts/TangentVecs.get_child(index).cast_to = getTangentFromOffset(offset)
			
			$AllRaycasts/NormVecs.get_child(index).translation = curve.interpolate_baked(offset)
			$AllRaycasts/NormVecs.get_child(index).cast_to = getNormalFromUpAndTangent($AllRaycasts/UpVecs.get_child(index).cast_to, $AllRaycasts/TangentVecs.get_child(index).cast_to)
			#print("up.tang = " + str($AllRaycasts/UpVecs.get_child(index).cast_to.dot($AllRaycasts/TangentVecs.get_child(index).cast_to)))
			#print("up.norm = " + str($AllRaycasts/UpVecs.get_child(index).cast_to.dot($AllRaycasts/NormVecs.get_child(index).cast_to)))
			#print("tang.norm = " + str($AllRaycasts/TangentVecs.get_child(index).cast_to.dot($AllRaycasts/NormVecs.get_child(index).cast_to)))
			offset += debugRaysInterval
				
				
func changeXScale(newScale):
	xyzScale = newScale
	curveMainMesh(curve, curvedMeshStartingOffset)