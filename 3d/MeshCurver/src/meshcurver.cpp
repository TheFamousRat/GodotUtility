
#include "meshcurver.hpp"

using namespace godot;

void MeshCurver::_register_methods() 
{
	godot::register_property("enableUpVector", &MeshCurver::setEnableUpVector, &MeshCurver::getEnableUpVector, true);
	godot::register_property("meshRepetitonsNumber", &MeshCurver::setMeshRepetitions, &MeshCurver::getMeshRepetitions, 1);
	godot::register_property("curvedMeshStartingOffset", &MeshCurver::setMeshOffset, &MeshCurver::getMeshOffset, 0.0f);
	godot::register_property("generateBoundingBox", &MeshCurver::setGenerateBoundingBox, &MeshCurver::getGenerateBoundingBox, false);
	godot::register_property("xyzScale", &MeshCurver::setXYZScale, &MeshCurver::getXYZSCale, Vector3(1,1,1));
	godot::register_property("magicVector", &MeshCurver::setGuidingVector, &MeshCurver::getGuidingVector, Vector3(1,0,0));

	godot::Ref<godot::ArrayMesh> defaultMesh;
	defaultMesh.instance();
	godot::register_property<MeshCurver, godot::Ref<godot::ArrayMesh>>("mainMesh", &MeshCurver::updateMesh, &MeshCurver::getMainMesh, defaultMesh);
	
	godot::register_method("_init", &MeshCurver::_init);
	godot::register_method("initMesh", &MeshCurver::initMesh);
	godot::register_method("_process", &MeshCurver::_process);
	godot::register_method("updateCurve", &MeshCurver::updateCurve);
	godot::register_method("getCurvedMesh", &MeshCurver::getCurvedMesh);
	godot::register_method("getCollisionBody", &MeshCurver::getCollisionBody);

	godot::register_signal<MeshCurver>(godot::String("commitSurfaceTool"), 
	"targetSt", GODOT_VARIANT_TYPE_OBJECT,
	"curvedMeshMdt", GODOT_VARIANT_TYPE_OBJECT,
	"beforeCurveMdt", GODOT_VARIANT_TYPE_OBJECT,
	"surfaceIndex", GODOT_VARIANT_TYPE_INT);
}

void MeshCurver::_process(float delta)
{
	deltaSum += delta;

	for (int i(0) ; i < mainMesh->get_surface_count() ; i++)
	{
		if (!mainMesh->surface_get_material(i).is_null())
		{
			curvedMesh->set_surface_material(i, mainMesh->surface_get_material(i));
			//savedMesh->set_surface_material(i, mainMesh->surface_get_material(i));
		}
	}

	if (deltaSum >= updateFrequency)
	{
		deltaSum = 0.0f;
		if (updateLowerBound != -1 && get_curve()->get_point_count() != 0)
		{
			while (curvedMesh->get_child_count() != 0)
			{curvedMesh->remove_child(curvedMesh->get_child(0));}

			curveMainMesh(get_curve(), curvedMeshStartingOffset, updateLowerBound);
			updateLowerBound = -1;
		}

	}

}

void MeshCurver::_init()
{
	mainMesh.instance();

	prevCurve.instance();
	prevCurve = get_curve()->duplicate();

	curvedMesh = godot::MeshInstance::_new();
	curvedMesh->set_name(godot::String("curvedMesh"));
	add_child(curvedMesh);

	this->connect(String("curve_changed"), this, String("updateCurve"));
}

void MeshCurver::initMesh(godot::Object* savedMeshPtr)
{
	savedMesh = cast_to<godot::MeshInstance>(savedMeshPtr);
	savedMesh->hide();
	updateMesh(savedMesh->get_mesh());
}

void MeshCurver::updateMesh(godot::Ref<godot::ArrayMesh> newMesh)
{
	if (newMesh.is_valid() && newMesh.is_null() == false)
	{
		if (newMesh->get_surface_count() > 0 && savedMesh != nullptr)
		{
			//We convert the mesh input from any mesh type to an ArrayMesh
			mainMesh.instance();
			for (int i(0) ; i < newMesh->get_surface_count() ; i++)
			{
				mainMesh->add_surface_from_arrays(godot::Mesh::PRIMITIVE_TRIANGLES, newMesh->surface_get_arrays(i));
				if (!newMesh->surface_get_material(i).is_null())
					mainMesh->surface_set_material(i, newMesh->surface_get_material(i));
			}

			savedMesh->set_mesh(mainMesh);

			//We then create a MeshDataTool, which we will use to get the vertices
			mainMeshMdt.clear();
			curvedMeshMdt.clear();
			beforeCurveMdt.clear();
			for (int i(0) ; i < newMesh->get_surface_count() ; i++)
			{
				mainMeshMdt.push_back(godot::Ref<godot::MeshDataTool>());
				mainMeshMdt[i].instance();
				curvedMeshMdt.push_back(godot::Ref<godot::MeshDataTool>());
				curvedMeshMdt[i].instance();
				beforeCurveMdt.push_back(godot::Ref<godot::MeshDataTool>());
				beforeCurveMdt[i].instance();
				mainMeshMdt[i]->create_from_surface(mainMesh, i);
			}

			//We then look for the mesh with the biggest distance
			minDist = pointDist(guidingVector, guidingVectorOrigin, mainMeshMdt[0]->get_vertex(0));
			maxDist = minDist;
			float currentDist = 0.0f;
			for (int i(0) ; i < newMesh->get_surface_count() ; i++)
			{
				for (int j(1) ; j  < mainMeshMdt[i]->get_vertex_count() ; j++)
				{
					currentDist = pointDist(guidingVector, guidingVectorOrigin, mainMeshMdt[i]->get_vertex(j));
					minDist = std::min(minDist, currentDist);
					maxDist = std::max(maxDist, currentDist);
				}
			}

			mainMeshDist = maxDist - minDist;

			repeatMeshFromMdtToMeshIns();
			curveMainMesh(get_curve(), curvedMeshStartingOffset);
		}
	}
}

void MeshCurver::updateCurve()
{
	godot::Ref<godot::Curve3D> curve = this->get_curve();

	if (prevCurve->get_point_count() != 0 && curve->get_point_count() != 0)
	{
		if (prevCurve->get_point_count() < curve->get_point_count())//A vertex was added
		{
			if (prevCurve->get_point_position(prevCurve->get_point_count()-1) != curve->get_point_position(curve->get_point_count()-1))
			{
				if (updateLowerBound == -1)
				{
					updateLowerBound = std::max(0, static_cast<int>(curve->get_point_count()-2));
				}
				else
				{
					updateLowerBound = std::min(updateLowerBound, static_cast<int>(curve->get_point_count()-2));
				}
			}
			else
			{
				for (int i(0) ; i < prevCurve->get_point_count() ; i++)
				{
					if (prevCurve->get_point_position(i) != curve->get_point_position(i))
						if (updateLowerBound == -1)
						{
							updateLowerBound = std::max(0,i-1);
						}
						else
						{
							updateLowerBound = std::min(updateLowerBound,i-1);
						}
						break;
				}
			}
		}
		else if (prevCurve->get_point_count() > curve->get_point_count())
		{
			if (prevCurve->get_point_position(prevCurve->get_point_count()-1) != curve->get_point_position(curve->get_point_count()-1))
				if (updateLowerBound == -1)
				{
					updateLowerBound = std::max(0, static_cast<int>(curve->get_point_count()-1));
				}
				else
				{
					updateLowerBound = std::min(updateLowerBound, static_cast<int>(curve->get_point_count()-1));
				}
			else
			{
				for (int i(0) ; i < prevCurve->get_point_count() ; i++)
				{
					if (prevCurve->get_point_position(i) != curve->get_point_position(i))
					{
						if (updateLowerBound == -1)
						{
							updateLowerBound = std::max(0,i-1);
						}
						else
						{
							updateLowerBound = std::min(updateLowerBound,i-1);
						}
						break;
					}
				}
			}
		}
		else//Same vertices count, but there was change
		{
			for (int i(0) ;  i < prevCurve->get_point_count() ; i++)
			{
				if (prevCurve->get_point_in(i) != curve->get_point_in(i) 
				|| prevCurve->get_point_out(i) != curve->get_point_out(i) 
				|| prevCurve->get_point_position(i) != curve->get_point_position(i) 
				|| prevCurve->get_point_tilt(i) != curve->get_point_tilt(i))
				{
					if (updateLowerBound == -1)
						updateLowerBound = std::max(0,i-1);
					else
						updateLowerBound = std::min(updateLowerBound,i);
					break;
				}
			}
		}
	}
	
	prevCurve = curve->duplicate();
}

void MeshCurver::curveMainMesh(godot::Ref<godot::Curve3D> guidingCurve, float startingOffset, int updateFromVertexOfId)
{
	if (get_curve()->get_point_count() != 0 && mainMeshMdt.size() && curvedMesh != nullptr)
	{
		godot::Ref<godot::ArrayMesh> combinedCurvedSurfaces;
		combinedCurvedSurfaces.instance();
		std::vector<godot::Ref<godot::ArrayMesh>> curvedSurfaces;

		for (int i(0) ; i < mainMeshMdt.size() ; i++)
		{
			curvedSurfaces.push_back(godot::Ref<godot::ArrayMesh>());
			curvedSurfaces[i].instance();

			float alpha = 0.0f;
			float beta = 0.0;
			godot::Vector3 originalVertex  = godot::Vector3(0,0,0);
			float vertexCurveOffset = 0.0f;
			float minOffset = curvePointIdToOffset(updateFromVertexOfId, guidingCurve);
				
			for (int vertexIndex(0) ;  vertexIndex < beforeCurveMdt[i]->get_vertex_count() ; vertexIndex++)
			{
				originalVertex = beforeCurveMdt[i]->get_vertex(vertexIndex);
				//The offset of the vertex on the curve
				vertexCurveOffset = xyzScale.x * std::min(static_cast<float>(guidingCurve->get_baked_length()/xyzScale.x), startingOffset + pointDist(guidingVector, guidingVectorOrigin, originalVertex) - minDist);
				
				if (vertexCurveOffset >= minOffset)
				{
					alpha = xyzScale.y * originalVertex.y;
					beta = xyzScale.z * originalVertex.z;
					curvedMeshMdt[i]->set_vertex(vertexIndex, guidingCurve->interpolate_baked(vertexCurveOffset) + alpha * getUpFromOffset(vertexCurveOffset) + beta * getNormalFromOffset(vertexCurveOffset));
				}
			}
			//Commit to mesh missing
			if (curvedMeshMdt[i]->get_vertex_count())
			{
				curvedMeshMdt[i]->commit_to_surface(curvedSurfaces[i]);
				combinedCurvedSurfaces->add_surface_from_arrays(godot::Mesh::PRIMITIVE_TRIANGLES, curvedSurfaces[i]->surface_get_arrays(0));
				if (!mainMesh->surface_get_material(i).is_null())
					combinedCurvedSurfaces->surface_set_material(i, mainMesh->surface_get_material(i));
			}
		}
		curvedMesh->set_mesh(combinedCurvedSurfaces);
		
		if (generateBoundingBox)
		{
			curvedMesh->get_children().clear();
			curvedMesh->create_trimesh_collision();
		}
	}
}

void MeshCurver::repeatMeshFromMdtToMeshIns()
{	
	if (!mainMeshMdt.empty())
	{
		for (int i(0) ; i < mainMeshMdt.size() ; i++)
		{
			godot::Ref<godot::SurfaceTool> targetSt;
			targetSt.instance();
			targetSt->begin(godot::Mesh::PRIMITIVE_TRIANGLES);
			
			int currentVertexId = 0;
			
			for (int meshNumber(0) ; meshNumber < meshRepetitonsNumber ; meshNumber++)
			{
				for (int faceNumber(0) ; faceNumber < mainMeshMdt[i]->get_face_count() ; faceNumber++)
				{
					for (int faceVertexNumber(0) ; faceVertexNumber < 3 ; faceVertexNumber++)
					{
						//We go through every face, and then every 3 vertices in those faces
						currentVertexId = mainMeshMdt[i]->get_face_vertex(faceNumber, faceVertexNumber);

						targetSt->add_color(mainMeshMdt[i]->get_vertex_color(currentVertexId));
						targetSt->add_normal(mainMeshMdt[i]->get_vertex_normal(currentVertexId));
						targetSt->add_uv(mainMeshMdt[i]->get_vertex_uv(currentVertexId));
						targetSt->add_vertex(guidingVector*meshNumber*mainMeshDist + mainMeshMdt[i]->get_vertex(currentVertexId));
					}
				}
			}

			targetSt->index();
			emit_signal(String("commitSurfaceTool"), targetSt, curvedMeshMdt[i], beforeCurveMdt[i], i);
		}
	}
}

float MeshCurver::curvePointIdToOffset(int idx, godot::Ref<godot::Curve3D> targetCurve)
{
	if (idx == INFINITY)
		return INFINITY;
	else if (idx == -INFINITY)
		return -INFINITY;
	else
		return(targetCurve->get_closest_offset(targetCurve->get_point_position(idx)));	
}

void MeshCurver::setMeshRepetitions(int newValue)
{
	if (newValue >= 1)
	{
		meshRepetitonsNumber = newValue;
		repeatMeshFromMdtToMeshIns();
		curveMainMesh(get_curve(), curvedMeshStartingOffset);
	}
}

void MeshCurver::setMeshOffset(float newOffset) 
{
	curvedMeshStartingOffset = newOffset;
	updateLowerBound = 0;
}

float MeshCurver::pointDist(godot::Vector3 planeNormal, godot::Vector3 normalOrigin, godot::Vector3 point)
{
	return planeNormal.x * (point.x - normalOrigin.x) + planeNormal.y * (point.y - normalOrigin.y) + planeNormal.z * (point.z - normalOrigin.z);
}

godot::Vector3 MeshCurver::getTangentFromOffset(float offset)
{
	return ((get_curve()->interpolate_baked(offset+epsilon) - get_curve()->interpolate_baked(offset-epsilon))/2).normalized();
}

	
godot::Vector3 MeshCurver::getUpFromOffset(float offset)
{
	if (enableUpVector)
		return get_curve()->interpolate_baked_up_vector(offset);
	else
		return Vector3(0,1,0);
}

		
godot::Vector3 MeshCurver::getNormalFromOffset(float offset)
{
	return getNormalFromUpAndTangent(getUpFromOffset(offset), getTangentFromOffset(offset));
}
	
godot::Vector3 MeshCurver::getNormalFromUpAndTangent(godot::Vector3 up, godot::Vector3 tangent)
{
	float x = up.x;
	float y = up.y;
	float z = up.z;
	float t = tangent.x;
	float u = tangent.y;
	float v = tangent.z;
	Vector3 ret = Vector3();

	if (y*t-u*up.x != 0)
	{
		float c = ((y*t-u*up.x) < 0 ? -1.0f : 1.0f);
		float b = c*(v*x-z*t)/(y*t-u*up.x);
		float a = c*(z*u-y*v)/(y*t-u*up.x);
		ret = Vector3(a,b,c).normalized();
	}
	else
	{
		if (t != 0)
		{
			float b = t;
			float a = -b * u / t;

			ret = Vector3(a,b,0.0).normalized();
		}
		else
		{
			if (x != 0)
			{
				float b = x;
				float a = -b * y / x;
				ret = Vector3(a,b,0.0).normalized();
			}
			else
			{
				ret = Vector3(1.0,0.0,0.0);
			}
		}
	}


	return ret;
}
	