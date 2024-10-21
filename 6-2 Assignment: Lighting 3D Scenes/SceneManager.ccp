///////////////////////////////////////////////////////////////////////////////
// shadermanager.cpp
// ============
// manage the loading and rendering of 3D scenes
//
//  AUTHOR: Brian Battersby - SNHU Instructor / Computer Science
//	Created for CS-330-Computational Graphics and Visualization, Nov. 1st, 2023
///////////////////////////////////////////////////////////////////////////////

#include "SceneManager.h"
#include <glm/gtx/transform.hpp>

// declare the global variables
namespace
{
	const char* g_ModelName = "model";
	const char* g_ColorValueName = "objectColor";
	const char* g_TextureValueName = "objectTexture";
	const char* g_UseTextureName = "bUseTexture";
	const char* g_UseLightingName = "bUseLighting";
}

/***********************************************************
 *  SceneManager()
 *
 *  The constructor for the class
 ***********************************************************/
SceneManager::SceneManager(ShaderManager* pShaderManager)
{
	m_pShaderManager = pShaderManager;
	m_basicMeshes = new ShapeMeshes();
}

/***********************************************************
 *  ~SceneManager()
 *
 *  The destructor for the class
 ***********************************************************/
SceneManager::~SceneManager()
{
	// free up the allocated memory
	m_pShaderManager = NULL;
	if (NULL != m_basicMeshes)
	{
		delete m_basicMeshes;
		m_basicMeshes = NULL;
	}
	// clear the collection of defined materials
	m_objectMaterials.clear();
}

/***********************************************************
 *  FindMaterial()
 *
 *  This method is used for getting a material from the previously
 *  defined materials list that is associated with the passed-in tag.
 ***********************************************************/
bool SceneManager::FindMaterial(std::string tag, OBJECT_MATERIAL& material)
{
	if (m_objectMaterials.size() == 0)
	{
		return(false);
	}

	int index = 0;
	bool bFound = false;
	while ((index < m_objectMaterials.size()) && (bFound == false))
	{
		if (m_objectMaterials[index].tag.compare(tag) == 0)
		{
			bFound = true;
			material.ambientColor = m_objectMaterials[index].ambientColor;
			material.ambientStrength = m_objectMaterials[index].ambientStrength;
			material.diffuseColor = m_objectMaterials[index].diffuseColor;
			material.specularColor = m_objectMaterials[index].specularColor;
			material.shininess = m_objectMaterials[index].shininess;
		}
		else
		{
			index++;
		}
	}

	return(true);
}

/***********************************************************
 *  SetTransformation()
 *
 *  This method is used for setting the transform buffer
 *  using the passed-in transformation values.
 ***********************************************************/
void SceneManager::SetTransformations(
	glm::vec3 scaleXYZ,
	float XrotationDegrees,
	float YrotationDegrees,
	float ZrotationDegrees,
	glm::vec3 positionXYZ)
{
	// variables for this method
	glm::mat4 modelView;
	glm::mat4 scale;
	glm::mat4 rotationX;
	glm::mat4 rotationY;
	glm::mat4 rotationZ;
	glm::mat4 translation;

	// set the scale value in the transform buffer
	scale = glm::scale(scaleXYZ);
	// set the rotation values in the transform buffer
	rotationX = glm::rotate(glm::radians(XrotationDegrees), glm::vec3(1.0f, 0.0f, 0.0f));
	rotationY = glm::rotate(glm::radians(YrotationDegrees), glm::vec3(0.0f, 1.0f, 0.0f));
	rotationZ = glm::rotate(glm::radians(ZrotationDegrees), glm::vec3(0.0f, 0.0f, 1.0f));
	// set the translation value in the transform buffer
	translation = glm::translate(positionXYZ);

	// matrix math is used to calculate the final model matrix
	modelView = translation * rotationX * rotationY * rotationZ * scale;
	if (NULL != m_pShaderManager)
	{
		// pass the model matrix into the shader
		m_pShaderManager->setMat4Value(g_ModelName, modelView);
	}
}

/***********************************************************
 *  SetShaderColor()
 *
 *  This method is used for setting the passed-in color
 *  into the shader for the next draw command.
 ***********************************************************/
void SceneManager::SetShaderColor(
	float redColorValue,
	float greenColorValue,
	float blueColorValue,
	float alphaValue)
{
	// variables for this method
	glm::vec4 currentColor;

	currentColor.r = redColorValue;
	currentColor.g = greenColorValue;
	currentColor.b = blueColorValue;
	currentColor.a = alphaValue;

	if (NULL != m_pShaderManager)
	{
		// pass the color values into the shader
		m_pShaderManager->setVec4Value(g_ColorValueName, currentColor);
	}
}

/***********************************************************
 *  SetShaderMaterial()
 *
 *  This method is used for passing the material values
 *  into the shader.
 ***********************************************************/
void SceneManager::SetShaderMaterial(
	std::string materialTag)
{
	if (m_objectMaterials.size() > 0)
	{
		OBJECT_MATERIAL material;
		bool bReturn = false;

		// find the defined material that matches the tag
		bReturn = FindMaterial(materialTag, material);
		if (bReturn == true)
		{
			// pass the material properties into the shader
			m_pShaderManager->setVec3Value("material.ambientColor", material.ambientColor);
			m_pShaderManager->setFloatValue("material.ambientStrength", material.ambientStrength);
			m_pShaderManager->setVec3Value("material.diffuseColor", material.diffuseColor);
			m_pShaderManager->setVec3Value("material.specularColor", material.specularColor);
			m_pShaderManager->setFloatValue("material.shininess", material.shininess);
		}
	}
}

/***********************************************************
 *  DefineObjectMaterials()
 *
 *  This method is used for configuring the various material
 *  settings for all of the objects within the 3D scene.
 ***********************************************************/
void SceneManager::DefineObjectMaterials()
{
	OBJECT_MATERIAL boxMaterial;
	boxMaterial.ambientStrength = 0.25f;
	boxMaterial.ambientColor = glm::vec3(1.0f, 1.0f, 1.0f);  // White for the box
	boxMaterial.diffuseColor = glm::vec3(1.0f, 1.0f, 1.0f);  // White
	boxMaterial.specularColor = glm::vec3(0.5f, 0.5f, 0.5f); // Slightly less reflective
	boxMaterial.shininess = 32.0f; // Lower shininess for less reflective surface
	boxMaterial.tag = "BoxMaterial";
	m_objectMaterials.push_back(boxMaterial);

	OBJECT_MATERIAL sphereMaterial;
	sphereMaterial.ambientStrength = 0.3f;
	sphereMaterial.ambientColor = glm::vec3(0.0f, 1.0f, 0.0f); // Green
	sphereMaterial.diffuseColor = glm::vec3(0.0f, 1.0f, 0.0f); // Green
	sphereMaterial.specularColor = glm::vec3(1.0f, 1.0f, 1.0f); // White
	sphereMaterial.shininess = 64.0f;
	sphereMaterial.tag = "SphereMaterial";
	m_objectMaterials.push_back(sphereMaterial);

	OBJECT_MATERIAL coneMaterial;
	coneMaterial.ambientStrength = 0.4f;
	coneMaterial.ambientColor = glm::vec3(1.0f, 0.6f, 0.2f);  // Warm orange
	coneMaterial.diffuseColor = glm::vec3(1.0f, 0.5f, 0.2f);  // Diffuse orange
	coneMaterial.specularColor = glm::vec3(1.0f, 1.0f, 1.0f); // White specular
	coneMaterial.shininess = 64.0f;
	coneMaterial.tag = "ConeMaterial";
	m_objectMaterials.push_back(coneMaterial);

	// Define material for the blue cube
	OBJECT_MATERIAL cubeMaterial;
	cubeMaterial.ambientStrength = 0.3f;
	cubeMaterial.ambientColor = glm::vec3(0.0f, 0.0f, 1.0f); // Blue
	cubeMaterial.diffuseColor = glm::vec3(0.0f, 0.0f, 1.0f); // Blue
	cubeMaterial.specularColor = glm::vec3(1.0f, 1.0f, 1.0f); // White specular highlight
	cubeMaterial.shininess = 32.0f;
	cubeMaterial.tag = "CubeMaterial";
	m_objectMaterials.push_back(cubeMaterial);
}

/***********************************************************
 *  SetupSceneLights()
 *
 *  This method is called to add and configure the light
 *  sources for the 3D scene. There are up to 4 light sources.
 ***********************************************************/
void SceneManager::SetupSceneLights()
{
	m_pShaderManager->setBoolValue(g_UseLightingName, true);

	// Set up directional light
	m_pShaderManager->setVec3Value("dirLight.direction", glm::vec3(-0.2f, -1.0f, -0.3f));
	m_pShaderManager->setVec3Value("dirLight.ambient", glm::vec3(0.2f, 0.2f, 0.2f));
	m_pShaderManager->setVec3Value("dirLight.diffuse", glm::vec3(0.5f, 0.5f, 0.5f));
	m_pShaderManager->setVec3Value("dirLight.specular", glm::vec3(1.0f, 1.0f, 1.0f));

	// Set up point light
	m_pShaderManager->setVec3Value("pointLight.position", glm::vec3(0.7f, 2.0f, 2.0f));
	m_pShaderManager->setVec3Value("pointLight.ambient", glm::vec3(0.4f, 0.4f, 0.4f));
	m_pShaderManager->setVec3Value("pointLight.diffuse", glm::vec3(1.0f, 0.8f, 0.6f));
	m_pShaderManager->setVec3Value("pointLight.specular", glm::vec3(1.0f, 1.0f, 1.0f));
	m_pShaderManager->setFloatValue("pointLight.constant", 1.0f);
	m_pShaderManager->setFloatValue("pointLight.linear", 0.09f);
	m_pShaderManager->setFloatValue("pointLight.quadratic", 0.032f);
}

/***********************************************************
 *  PrepareScene()
 *
 *  This method is used for preparing the 3D scene by loading
 *  the shapes, textures in memory to support the 3D scene
 *  rendering
 ***********************************************************/
void SceneManager::PrepareScene()
{
	// define the materials for objects in the scene
	DefineObjectMaterials();
	// add and define the light sources for the scene
	SetupSceneLights();

	// Load meshes into the pipeline buffers
	m_basicMeshes->LoadBoxMesh();
	m_basicMeshes->LoadPlaneMesh();
	m_basicMeshes->LoadCylinderMesh();
	m_basicMeshes->LoadConeMesh();
	m_basicMeshes->LoadSphereMesh();
}

/***********************************************************
 *  RenderScene()
 *
 *  This method is used for rendering the 3D scene by
 *  transforming and drawing the basic 3D shapes
 ***********************************************************/
void SceneManager::RenderScene()
{
	// declare the variables for the transformations
	glm::vec3 scaleXYZ;
	float XrotationDegrees = 0.0f;
	float YrotationDegrees = 0.0f;
	float ZrotationDegrees = 0.0f;
	glm::vec3 positionXYZ;

	// Render the base plane
	scaleXYZ = glm::vec3(20.0f, 1.0f, 10.0f);
	positionXYZ = glm::vec3(0.0f, 0.0f, 0.0f);
	SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
	SetShaderColor(1.0f, 0.8f, 0.4f, 1);
	m_basicMeshes->DrawPlaneMesh();

	// Render the cylinder
	scaleXYZ = glm::vec3(0.9f, 2.8f, 0.9f);
	XrotationDegrees = 90.0f;
	ZrotationDegrees = -15.0f;
	positionXYZ = glm::vec3(0.0f, 0.9f, 0.4f);
	SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
	SetShaderMaterial("BoxMaterial");
	m_basicMeshes->DrawCylinderMesh();

	// Render the white box
	scaleXYZ = glm::vec3(1.0f, 9.0f, 1.3f);
	ZrotationDegrees = 95.0f;
	positionXYZ = glm::vec3(0.2f, 2.27f, 2.0f);
	SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
	SetShaderMaterial("BoxMaterial");
	m_basicMeshes->DrawBoxMesh();

	// Render the sphere
	scaleXYZ = glm::vec3(1.0f, 1.0f, 1.0f);
	positionXYZ = glm::vec3(3.2f, 5.6f, 2.5f);
	SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
	SetShaderMaterial("SphereMaterial");
	m_basicMeshes->DrawSphereMesh();

	// Render the blue cube under the sphere
	scaleXYZ = glm::vec3(1.0f, 1.0f, 1.0f);
	positionXYZ = glm::vec3(3.2f, 4.0f, 2.5f); // Positioning it directly underneath the sphere
	SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
	SetShaderMaterial("CubeMaterial"); // Apply blue material for cube
	m_basicMeshes->DrawBoxMesh();

	// Render the cone
	scaleXYZ = glm::vec3(1.2f, 4.0f, 1.2f);
	XrotationDegrees = 0.0f;
	ZrotationDegrees = 5.0f;
	positionXYZ = glm::vec3(-3.3f, 2.50f, 2.0f);
	SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
	SetShaderMaterial("ConeMaterial");
	m_basicMeshes->DrawConeMesh();
}
