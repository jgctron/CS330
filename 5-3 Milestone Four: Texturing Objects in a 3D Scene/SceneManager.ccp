///////////////////////////////////////////////////////////////////////////////
// shadermanager.cpp
// ============
// manage the loading and rendering of 3D scenes
//
//  AUTHOR: Brian Battersby - SNHU Instructor / Computer Science
//	Created for CS-330-Computational Graphics and Visualization, Nov. 1st, 2023
///////////////////////////////////////////////////////////////////////////////

#include "SceneManager.h"

#ifndef STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#endif

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

	// initialize the texture collection
	for (int i = 0; i < 16; i++)
	{
		m_textureIDs[i].tag = "/0";
		m_textureIDs[i].ID = -1;
	}
	m_loadedTextures = 0;
}

/***********************************************************
 *  ~SceneManager()
 *
 *  The destructor for the class
 ***********************************************************/
SceneManager::~SceneManager()
{
	// clear the allocated memory
	m_pShaderManager = NULL;
	delete m_basicMeshes;
	m_basicMeshes = NULL;
	// destroy the created OpenGL textures
	DestroyGLTextures();
}

/***********************************************************
 *  CreateGLTexture()
 *
 *  This method is used for loading textures from image files,
 *  configuring the texture mapping parameters in OpenGL,
 *  generating the mipmaps, and loading the read texture into
 *  the next available texture slot in memory.
 ***********************************************************/
bool SceneManager::CreateGLTexture(const char* filename, std::string tag)
{
	int width = 0;
	int height = 0;
	int colorChannels = 0;
	GLuint textureID = 0;

	// indicate to always flip images vertically when loaded
	stbi_set_flip_vertically_on_load(true);

	// try to parse the image data from the specified image file
	unsigned char* image = stbi_load(
		filename,
		&width,
		&height,
		&colorChannels,
		0);

	// if the image was successfully read from the image file
	if (image)
	{
		std::cout << "Successfully loaded image:" << filename << ", width:" << width << ", height:" << height << ", channels:" << colorChannels << std::endl;

		glGenTextures(1, &textureID);
		glBindTexture(GL_TEXTURE_2D, textureID);

		// set the texture wrapping parameters
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		// set texture filtering parameters
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		// if the loaded image is in RGB format
		if (colorChannels == 3)
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, image);
		// if the loaded image is in RGBA format - it supports transparency
		else if (colorChannels == 4)
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image);
		else
		{
			std::cout << "Not implemented to handle image with " << colorChannels << " channels" << std::endl;
			return false;
		}

		// generate the texture mipmaps for mapping textures to lower resolutions
		glGenerateMipmap(GL_TEXTURE_2D);

		// free the image data from local memory
		stbi_image_free(image);
		glBindTexture(GL_TEXTURE_2D, 0); // Unbind the texture

		// register the loaded texture and associate it with the special tag string
		m_textureIDs[m_loadedTextures].ID = textureID;
		m_textureIDs[m_loadedTextures].tag = tag;
		m_loadedTextures++;

		return true;
	}

	std::cout << "Could not load image:" << filename << std::endl;

	// Error loading the image
	return false;
}

/***********************************************************
 *  BindGLTextures()
 *
 *  This method is used for binding the loaded textures to
 *  OpenGL texture memory slots.  There are up to 16 slots.
 ***********************************************************/
void SceneManager::BindGLTextures()
{
	for (int i = 0; i < m_loadedTextures; i++)
	{
		// bind textures on corresponding texture units
		glActiveTexture(GL_TEXTURE0 + i);
		glBindTexture(GL_TEXTURE_2D, m_textureIDs[i].ID);
	}
}

/***********************************************************
 *  DestroyGLTextures()
 *
 *  This method is used for freeing the memory in all the
 *  used texture memory slots.
 ***********************************************************/
void SceneManager::DestroyGLTextures()
{
	for (int i = 0; i < m_loadedTextures; i++)
	{
		glGenTextures(1, &m_textureIDs[i].ID);
	}
}

/***********************************************************
 *  FindTextureID()
 *
 *  This method is used for getting an ID for the previously
 *  loaded texture bitmap associated with the passed-in tag.
 ***********************************************************/
int SceneManager::FindTextureID(std::string tag)
{
	int textureID = -1;
	int index = 0;
	bool bFound = false;

	while ((index < m_loadedTextures) && (bFound == false))
	{
		if (m_textureIDs[index].tag.compare(tag) == 0)
		{
			textureID = m_textureIDs[index].ID;
			bFound = true;
		}
		else
			index++;
	}

	return(textureID);
}

/***********************************************************
 *  FindTextureSlot()
 *
 *  This method is used for getting a slot index for the previously
 *  loaded texture bitmap associated with the passed-in tag.
 ***********************************************************/
int SceneManager::FindTextureSlot(std::string tag)
{
	int textureSlot = -1;
	int index = 0;
	bool bFound = false;

	while ((index < m_loadedTextures) && (bFound == false))
	{
		if (m_textureIDs[index].tag.compare(tag) == 0)
		{
			textureSlot = index;
			bFound = true;
		}
		else
			index++;
	}

	return(textureSlot);
}

/***********************************************************
 *  SetTransformations()
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

	modelView = translation * rotationX * rotationY * rotationZ * scale;

	if (NULL != m_pShaderManager)
	{
		m_pShaderManager->setMat4Value(g_ModelName, modelView);
	}
}

/***********************************************************
 *  SetShaderColor()
 *
 *  This method is used for setting the passed-in color
 *  into the shader for the next draw command
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
		m_pShaderManager->setIntValue(g_UseTextureName, false);
		m_pShaderManager->setVec4Value(g_ColorValueName, currentColor);
	}
}

/***********************************************************
 *  SetShaderTexture()
 *
 *  This method is used for setting the texture data
 *  associated with the passed-in ID into the shader.
 ***********************************************************/
void SceneManager::SetShaderTexture(
	std::string textureTag)
{
	if (NULL != m_pShaderManager)
	{
		m_pShaderManager->setIntValue(g_UseTextureName, true);

		int textureID = -1;
		textureID = FindTextureSlot(textureTag);
		m_pShaderManager->setSampler2DValue(g_TextureValueName, textureID);
	}
}

/***********************************************************
 *  SetTextureUVScale()
 *
 *  This method is used for setting the texture UV scale
 *  values into the shader.
 ***********************************************************/
void SceneManager::SetTextureUVScale(float u, float v)
{
	if (NULL != m_pShaderManager)
	{
		m_pShaderManager->setVec2Value("UVscale", glm::vec2(u, v));
	}
}

/***********************************************************
 *  LoadSceneTextures()
 *
 *  This method is used for preparing the 3D scene by loading
 *  the textures into memory.
 ***********************************************************/
void SceneManager::LoadSceneTextures()
{
	// Load the wood texture for the plane
	CreateGLTexture("C:/Users/ssjtr/Downloads/CS330Content (12)/CS330Content/Projects/7-1_FinalProjectMilestones/wood.png", "woodTexture");

	// Load the brick texture for the cone
	CreateGLTexture("C:/Users/ssjtr/Downloads/CS330Content (12)/CS330Content/Projects/7-1_FinalProjectMilestones/sun.png", "sunTexture");

	// Load the blue texture for the sphere
	CreateGLTexture("C:/Users/ssjtr/Downloads/CS330Content (12)/CS330Content/Projects/7-1_FinalProjectMilestones/metal.png", "metalTexture");

	// Load the yellow texture for the middle part
	CreateGLTexture("C:/Users/ssjtr/Downloads/CS330Content (12)/CS330Content/Projects/7-1_FinalProjectMilestones/gray.png", "grayTexture");

	// Load the red texture for the box
	CreateGLTexture("C:/Users/ssjtr/Downloads/CS330Content (12)/CS330Content/Projects/7-1_FinalProjectMilestones/white.png", "whiteTexture");


	// Bind the loaded textures
	BindGLTextures();
}

/***********************************************************
 *  PrepareScene()
 *
 *  This method is used for preparing the 3D scene by loading
 *  the shapes and textures in memory to support the 3D scene rendering.
 ***********************************************************/
void SceneManager::PrepareScene()
{
	// load the textures for the 3D scene
	LoadSceneTextures();

	// only one instance of a particular mesh needs to be
	// loaded in memory no matter how many times it is drawn
	// in the rendered 3D scene

		// Load basic meshes
	m_basicMeshes->LoadPlaneMesh();    // Desk Surface
	m_basicMeshes->LoadBoxMesh();      // Monitor Screen and Frame
	m_basicMeshes->LoadCylinderMesh(); // Mug Body, Lamp Stand, Lamp Base, Monitor Stand
	m_basicMeshes->LoadTorusMesh();    // Mug Handle, Mouse Scroll Wheel
	m_basicMeshes->LoadConeMesh();     // Lamp Shade
	m_basicMeshes->LoadSphereMesh();   // Lamp Bulb
}


/***********************************************************
 *  RenderScene()
 ***********************************************************/
void SceneManager::RenderScene() {
	glm::vec3 scaleXYZ;
	glm::vec3 positionXYZ;

	// Set up lighting properties
	glm::vec3 lightPos = glm::vec3(15.0f, 10.0f, 15.0f);  // Enhanced light position for better depth
	glm::vec3 lightColor = glm::vec3(1.0f, 1.0f, 1.0f);   // White light
	glm::vec3 viewPos = glm::vec3(0.0f, 0.0f, 10.0f);     // Camera/view position

	m_pShaderManager->setVec3Value("lightPos", lightPos);
	m_pShaderManager->setVec3Value("lightColor", lightColor);
	m_pShaderManager->setVec3Value("viewPos", viewPos);

	// Background (light blue)
	glClearColor(0.53f, 0.81f, 0.98f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	// Desk Surface with tiling
	scaleXYZ = glm::vec3(20.0f, 1.0f, 10.0f);
	positionXYZ = glm::vec3(0.0f, 0.0f, 0.0f);
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("woodTexture");
	SetTextureUVScale(5.0f, 5.0f);  // Tiling the texture only for the desk
	m_basicMeshes->DrawPlaneMesh();

	// Reset UV scaling for other objects
	SetTextureUVScale(1.0f, 1.0f);


	// Monitor Frame (Outer Black Box)
	scaleXYZ = glm::vec3(9.0f, 6.0f, 0.3f);  // Increased depth for the outer frame
	positionXYZ = glm::vec3(0.0f, 6.0f, -2.0f);
	SetTransformations(scaleXYZ, 0.0f, 10.0f, 0.0f, positionXYZ); // Slight Y-axis rotation
	SetShaderColor(0.1f, 0.1f, 0.1f, 1.0f);
	m_basicMeshes->DrawBoxMesh();

	// Beveled Edges (Add bevel effect)
	scaleXYZ = glm::vec3(8.8f, 5.8f, 0.05f);
	positionXYZ = glm::vec3(0.0f, 6.0f, -1.85f);
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderColor(0.2f, 0.2f, 0.2f, 1.0f);  // Dark grey bevel
	m_basicMeshes->DrawBoxMesh();

	// Monitor Screen with Multi-Texturing
	scaleXYZ = glm::vec3(8.5f, 5.5f, 0.02f);
	positionXYZ = glm::vec3(0.0f, 6.0f, -1.90f);
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);

	// Activate and bind the first texture (screen texture)
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, FindTextureID("monitorScreenTexture"));
	m_pShaderManager->setSampler2DValue("texture1", 0);  // Pass to the shader (use texture unit 0)

	// Activate and bind the second texture (reflection texture)
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, FindTextureID("reflectionTexture"));
	m_pShaderManager->setSampler2DValue("texture2", 1);  // Pass to the shader (use texture unit 1)

	// Set mixValue to blend the textures (adjust as needed)
	m_pShaderManager->setFloatValue("mixValue", 0.5f);  // Blend the two textures equally

	// Draw the monitor screen
	m_basicMeshes->DrawBoxMesh();


	// Subtle Reflection on Screen
	scaleXYZ = glm::vec3(8.5f, 5.5f, 0.01f);
	positionXYZ = glm::vec3(0.0f, 6.0f, -1.89f);
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderColor(0.9f, 0.9f, 0.9f, 0.3f);  // Reflection effect
	m_basicMeshes->DrawPlaneMesh();

	// Grey Layer at the Bottom of the Monitor Frame (Box)
	scaleXYZ = glm::vec3(9.0f, 0.3f, 0.1f);
	positionXYZ = glm::vec3(0.0f, 3.75f, -2.05f);
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("metalTexture");  
	m_basicMeshes->DrawBoxMesh();

	// Monitor Stand (Cylinder)
	scaleXYZ = glm::vec3(1.0f, 3.0f, 1.0f);
	positionXYZ = glm::vec3(0.0f, 0.0f, -2.1f);
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("metalTexture");
	m_basicMeshes->DrawCylinderMesh();

	// Lamp Stand (Slightly lower the position to connect with the base)
	scaleXYZ = glm::vec3(0.2f, 4.0f, 0.2f);  // Keep the increased height for the lamp stand
	positionXYZ = glm::vec3(7.0f, 0.4f, -2.0f);  // Slightly lowered position to ensure it connects with the base
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("metalTexture");  // Gray color for the stand
	m_basicMeshes->DrawCylinderMesh();

	// Lamp Base (Remaining the same)
	scaleXYZ = glm::vec3(1.0f, 0.1f, 1.0f);  // Flat base
	positionXYZ = glm::vec3(7.0f, 0.05f, -2.0f);  // Ensure it stays on the desk surface
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("metalTexture");
	m_basicMeshes->DrawCylinderMesh();

	// Lamp Shade
	scaleXYZ = glm::vec3(1.5f, 2.0f, 1.5f);
	positionXYZ = glm::vec3(7.0f, 5.0f, -2.0f);
	SetTransformations(scaleXYZ, -45.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("metalTexture");
	m_basicMeshes->DrawConeMesh();

	// Lamp Bulb (Yellow Sphere)
	scaleXYZ = glm::vec3(0.5f, 0.5f, 0.5f);  // Small sphere for the bulb
	positionXYZ = glm::vec3(7.0f, 4.0f, -2.0f);  // Inside the lamp shade
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("sunTexture");   // Bright yellow color for the bulb    
	m_basicMeshes->DrawSphereMesh();

	// Mug Body
	scaleXYZ = glm::vec3(0.7f, 1.0f, 0.7f);
	positionXYZ = glm::vec3(-3.0f, 0.5f, 5.0f);  // Close to the camera
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("whiteTexture");
	m_basicMeshes->DrawCylinderMesh();

	// Mug Handle
	scaleXYZ = glm::vec3(0.4f, 0.4f, 0.1f);
	positionXYZ = glm::vec3(-2.5f, 0.5f, 5.0f);  // Adjust to match mug position
	SetTransformations(scaleXYZ, 90.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("whiteTexture");
	m_basicMeshes->DrawTorusMesh();

	// Coffee (Brown liquid inside Mug)
	scaleXYZ = glm::vec3(0.65f, 0.02f, 0.65f);  // Thin cylinder for liquid surface
	positionXYZ = glm::vec3(-3.0f, 0.95f, 5.0f);  // Positioned slightly inside the mug, near the top
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderColor(0.44f, 0.26f, 0.08f, 1.0f);  // Darker brown color for the coffee
	m_basicMeshes->DrawCylinderMesh();

	// Mug Rim (Black outline at the top of the mug)
	scaleXYZ = glm::vec3(0.72f, 0.02f, 0.72f);  // Slightly larger and thicker for more contrast
	positionXYZ = glm::vec3(-3.0f, 1.5f, 5.0f);  // Correctly positioned at the top of the mug
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderColor(0.0f, 0.0f, 0.0f, 1.0f);  // Black color for the rim
	m_basicMeshes->DrawCylinderMesh();

	// Mouse Body (Move farther from the coffee mug)
	scaleXYZ = glm::vec3(0.5f, 0.2f, 0.7f);
	positionXYZ = glm::vec3(1.0f, 0.1f, 6.0f);  // Mouse position on the desk
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("grayTexture");  // Light grey for mouse body
	m_basicMeshes->DrawCylinderMesh();

	// Mouse Scroll Wheel (Add as a larger torus for visibility)
	scaleXYZ = glm::vec3(0.15f, 0.15f, 0.15f);  // Increase the size of the scroll wheel
	positionXYZ = glm::vec3(1.0f, 0.25f, 6.0f);  // Adjust position to be slightly above the mouse body
	SetTransformations(scaleXYZ, 90.0f, 0.0f, 0.0f, positionXYZ);  // Rotate to sit horizontally
	SetShaderTexture("grayTexture");  // Bright red for high contrast
	m_basicMeshes->DrawTorusMesh();

	// Adjust the scale and position of the keyboard base to fit the keys
	scaleXYZ = glm::vec3(5.0f, 0.2f, 1.0f);  // Make the keyboard wider to fit the keys
	positionXYZ = glm::vec3(0.0f, 0.05f, -1.0f);
	SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
	SetShaderTexture("grayTexture");  // Light grey for keyboard base
	m_basicMeshes->DrawPlaneMesh();

	// Spread the keys across the keyboard by increasing the spacing
	float keySpacingX = 0.5f;  // Increase spacing between keys on the X-axis
	float keySpacingZ = 0.5f;  // Increase spacing between keys on the Z-axis
	float keyOffsetX = -2.25f;   // Start position of the first key on the X-axis
	float keyOffsetZ = -1.4f;   // Start position of the first key on the Z-axis

	for (int i = 0; i < 5; i++) {  // 5 rows of keys
		for (int j = 0; j < 10; j++) {  // 10 keys per row
			scaleXYZ = glm::vec3(0.35f, 0.05f, 0.35f);  // Keep keys relatively the same size
			positionXYZ = glm::vec3(keyOffsetX + (j * keySpacingX), 0.1f, keyOffsetZ + (i * keySpacingZ));  // Adjust key position
			SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
			SetShaderColor(0.5f, 0.5f, 0.5f, 1.0f);  // Darker grey for keys
			m_basicMeshes->DrawBoxMesh();  // Draw each key as a box
		}
	}
}
