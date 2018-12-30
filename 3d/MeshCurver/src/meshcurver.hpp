#ifndef MESHCURVER_HPP
#define MESHCURVER_HPP

#include <iostream>
#include <algorithm>
#include <locale>
#include <string>
#include <vector>

#include <core/Godot.hpp>
#include <gen/Spatial.hpp>
#include <gen/Sprite.hpp>
#include <gen/Path.hpp>
#include <gen/Curve3D.hpp>
#include <gen/Mesh.hpp>
#include <gen/ArrayMesh.hpp>
#include <gen/MeshDataTool.hpp>
#include <gen/MeshInstance.hpp>
#include <gen/SurfaceTool.hpp>
#include <gen/Script.hpp>
#include <gen/File.hpp>
#include <gen/Material.hpp>
#include <gen/SpatialMaterial.hpp>


namespace godot{

class MeshCurver : public godot::Path {
	GODOT_CLASS(MeshCurver, Path);

	private:

		bool enableUpVector = true;
		godot::Ref<godot::ArrayMesh> mainMesh = godot::Ref<godot::ArrayMesh>();
		int meshRepetitonsNumber = 1;
		float curvedMeshStartingOffset = 0.0f;
		bool generateBoundingBox = false;
		godot::Vector3 xyzScale = godot::Vector3(1.0f, 1.0f, 1.0f);

		float epsilon = 0.2f;
		float minDist = 0.0f;
		float maxDist = 0.0f;
		float mainMeshDist = 0.0f;

		godot::Vector3 guidingVectorOrigin = Vector3(0,0,0);
		godot::Vector3 guidingVector = Vector3(1,0,0);
		godot::Vector3 guidingVectorVisual = Vector3(1,0,0);//The above one is just this one, but normalized

		std::vector<godot::Ref<godot::MeshDataTool>> mainMeshMdt;
		std::vector<godot::Ref<godot::MeshDataTool>> beforeCurveMdt;
		std::vector<godot::Ref<godot::MeshDataTool>> curvedMeshMdt;

		godot::Ref<godot::Curve3D> prevCurve = godot::Ref<godot::Curve3D>();
		int updateLowerBound = -1;
		float updateFrequency = 0.1f;
		float deltaSum = 0.0f;

		godot::MeshInstance* curvedMesh;
		godot::MeshInstance* savedMesh;

	public:
		static void _register_methods();

		void _init();
		void _process(float delta);

		//Setters and getters
		void setEnableUpVector(bool newValue) {enableUpVector = newValue;};
		bool getEnableUpVector() const {return enableUpVector;};
		
		void updateMesh(godot::Ref<godot::ArrayMesh> newMesh);
		godot::Ref<godot::ArrayMesh> getMainMesh() const {return mainMesh;};
		
		void setMeshRepetitions(int newValue);
		int getMeshRepetitions() const {return meshRepetitonsNumber;};
		
		void setMeshOffset(float newOffset);
		float getMeshOffset() const {return curvedMeshStartingOffset;};
		
		void setGenerateBoundingBox(bool newValue) {generateBoundingBox = newValue;};
		bool getGenerateBoundingBox() const {return generateBoundingBox;};
		
		void setXYZScale(godot::Vector3 newScale) {xyzScale = newScale; updateLowerBound = 0;};
		godot::Vector3 getXYZSCale() const {return xyzScale;};
		
		void setGuidingVector(godot::Vector3 newGuidingVec) 
		{guidingVectorVisual = newGuidingVec;
		guidingVector = newGuidingVec.normalized(); 
		updateMesh(mainMesh);};
		godot::Vector3 getGuidingVector() const {return guidingVectorVisual;};
		
		godot::MeshInstance* getCurvedMesh() {return curvedMesh;};

		void initMesh(godot::Object* savedMesh);
		void updateCurve();
		void curveMainMesh(godot::Ref<godot::Curve3D> guidingCurve, float startingOffset = 0.0f, int updateFromVertexOfId = 0);
		void repeatMeshFromMdtToMeshIns();

		void recalculateDebugRayCasts() {};

		float curvePointIdToOffset(int idx, godot::Ref<godot::Curve3D> targetCurve);

		float pointDist(godot::Vector3 planeNormal, godot::Vector3 normalOrigin, godot::Vector3 point);
		godot::Vector3 getTangentFromOffset(float offset);
		godot::Vector3 getUpFromOffset(float offset);
		godot::Vector3 getNormalFromOffset(float offset);
		godot::Vector3 getNormalFromUpAndTangent(godot::Vector3 up, godot::Vector3 tangent);
}; 

}

#endif