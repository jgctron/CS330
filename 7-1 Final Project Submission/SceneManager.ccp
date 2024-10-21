///////////////////////////////////////////////////////////////////////////////
// SceneManager.cpp
// ============
// manage the loading and rendering of 3D scenes
//
//  AUTHOR: Brian Battersby - SNHU Instructor / Computer Science
//  Created for CS-330-Computational Graphics and Visualization, Nov. 1st, 2023
///////////////////////////////////////////////////////////////////////////////

#include "SceneManager.h"
#include "ShaderManager.h"

#ifndef STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#endif

#include <glm/gtx/transform.hpp>
#include <iostream>
#include <vector>
#include <GLFW/glfw3.h>


// declare the global variables
namespace
{
    const char* g_ModelName = "model";
    const char* g_ColorValueName = "objectColor";
    const char* g_TextureValueName = "objectTexture";
    const char* g_UseTextureName = "bUseTexture";
    const char* g_UseLightingName = "bUseLighting";
    const char* g_LightSource = "lightSources";
    const char* g_MaterialName = "material";
    const int KEY_M = 77;
}

// Shadow mapping parameters
const unsigned int SHADOW_WIDTH = 1024, SHADOW_HEIGHT = 1024;
GLuint depthMapFBO, depthMap;

// Projection toggle variable
bool usePerspective = true;

// Star, steam, and mouse movement parameters
std::vector<glm::vec3> starPositions;
std::vector<glm::vec3> steamPositions;

bool moveMouse = false;
float mouseMovement = 0.0f;
float mouseDirection = 0.05f;
bool rotateMonitor = false;
int currentColorIndex = 0;
std::vector<glm::vec3> monitorColors = {
    glm::vec3(1.0f, 0.0f, 0.0f),  // Red
    glm::vec3(0.0f, 1.0f, 0.0f),  // Green
    glm::vec3(0.0f, 0.0f, 1.0f),  // Blue
    glm::vec3(1.0f, 1.0f, 0.0f),  // Yellow
    glm::vec3(1.0f, 0.0f, 1.0f),  // Magenta
    glm::vec3(0.0f, 1.0f, 1.0f)   // Cyan
};

/***********************************************************
// SceneManager()
//
// The constructor for the class
***********************************************************/
SceneManager::SceneManager(ShaderManager* pShaderManager)
{
    m_pShaderManager = pShaderManager;
    m_basicMeshes = new ShapeMeshes();

    // initialize the texture collection
    for (int i = 0; i < 16; i++)
    {
        m_textureIDs[i].tag = "/0";
        m_textureIDs[i].ID = 0;
    }
    m_loadedTextures = 0;

    // Initialize the material
    m_material.ambientColor = glm::vec3(1.0f, 1.0f, 1.0f);
    m_material.ambientStrength = 0.2f;
    m_material.diffuseColor = glm::vec3(0.8f, 0.8f, 0.8f);
    m_material.specularColor = glm::vec3(1.0f, 1.0f, 1.0f);
    m_material.shininess = 64.0f;

    // Initialize the light sources
    SetupLightSource(0, glm::vec3(5.0f, 10.0f, 5.0f), glm::vec3(0.2f, 0.2f, 0.2f), glm::vec3(1.0f, 1.0f, 1.0f), glm::vec3(1.0f, 1.0f, 1.0f), 1.0f, 0.5f);
    SetupLightSource(1, glm::vec3(-5.0f, 8.0f, 10.0f), glm::vec3(0.2f, 0.2f, 0.2f), glm::vec3(0.7f, 0.7f, 0.7f), glm::vec3(1.0f, 1.0f, 1.0f), 1.0f, 0.5f);

    // Set up the framebuffer for shadow mapping
    glGenFramebuffers(1, &depthMapFBO);
    glGenTextures(1, &depthMap);
    glBindTexture(GL_TEXTURE_2D, depthMap);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, SHADOW_WIDTH, SHADOW_HEIGHT, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    float borderColor[] = { 1.0, 1.0, 1.0, 1.0 };
    glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, borderColor);

    glBindFramebuffer(GL_FRAMEBUFFER, depthMapFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthMap, 0);
    glDrawBuffer(GL_NONE);
    glReadBuffer(GL_NONE);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}
/***********************************************************
// ~SceneManager()
//
// The destructor for the class
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
// SetupLightSource()
//
// Sets up light source information and passes it to the shader.
***********************************************************/
void SceneManager::SetupLightSource(int index, glm::vec3 position, glm::vec3 ambientColor, glm::vec3 diffuseColor, glm::vec3 specularColor, float focalStrength, float specularIntensity)
{
    if (index >= 0 && index < TOTAL_LIGHTS)
    {
        m_lightSources[index].position = position;
        m_lightSources[index].ambientColor = ambientColor;
        m_lightSources[index].diffuseColor = diffuseColor;
        m_lightSources[index].specularColor = specularColor;
        m_lightSources[index].focalStrength = focalStrength;
        m_lightSources[index].specularIntensity = specularIntensity;

        // Pass light data to the shader
        m_pShaderManager->setVec3Value("lightSources[" + std::to_string(index) + "].position", m_lightSources[index].position);
        m_pShaderManager->setVec3Value("lightSources[" + std::to_string(index) + "].ambientColor", m_lightSources[index].ambientColor);
        m_pShaderManager->setVec3Value("lightSources[" + std::to_string(index) + "].diffuseColor", m_lightSources[index].diffuseColor);
        m_pShaderManager->setVec3Value("lightSources[" + std::to_string(index) + "].specularColor", m_lightSources[index].specularColor);

        // Add specular intensity to highlight metallic and reflective surfaces
        m_pShaderManager->setFloatValue("lightSources[" + std::to_string(index) + "].specularIntensity", specularIntensity);
    }
}

/***********************************************************
// SetupMaterial()
//
// Sets up material information and passes it to the shader.
***********************************************************/
void SceneManager::SetupMaterial(glm::vec3 ambientColor, float ambientStrength, glm::vec3 diffuseColor, glm::vec3 specularColor, float shininess)
{
    m_material.ambientColor = ambientColor;
    m_material.ambientStrength = ambientStrength;
    m_material.diffuseColor = diffuseColor;
    m_material.specularColor = specularColor;
    m_material.shininess = shininess;

    // Pass material data to the shader
    m_pShaderManager->setVec3Value("material.ambientColor", m_material.ambientColor);
    m_pShaderManager->setFloatValue("material.ambientStrength", m_material.ambientStrength);
    m_pShaderManager->setVec3Value("material.diffuseColor", m_material.diffuseColor);
    m_pShaderManager->setVec3Value("material.specularColor", m_material.specularColor);
    m_pShaderManager->setFloatValue("material.shininess", m_material.shininess);
}

/***********************************************************
// CreateGLTexture()
//
// This method is used for loading textures from image files,
// configuring the texture mapping parameters in OpenGL,
// generating the mipmaps, and loading the read texture into
// the next available texture slot in memory.
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
// BindGLTextures()
//
// This method is used for binding the loaded textures to
// OpenGL texture memory slots.  There are up to 16 slots.
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
// DestroyGLTextures()
//
// This method is used for freeing the memory in all the
// used texture memory slots.
***********************************************************/
void SceneManager::DestroyGLTextures()
{
    for (int i = 0; i < m_loadedTextures; i++)
    {
        glDeleteTextures(1, &m_textureIDs[i].ID);
    }
}

/***********************************************************
// FindTextureID()
//
// This method is used for getting an ID for the previously
// loaded texture bitmap associated with the passed-in tag.
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
// FindTextureSlot()
//
// This method is used for getting a slot index for the previously
// loaded texture bitmap associated with the passed-in tag.
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
// SetTransformations()
//
// This method is used for setting the transform buffer
// using the passed-in transformation values.
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
// SetShaderColor()
//
// This method is used for setting the passed-in color
// into the shader for the next draw command
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
// SetShaderTexture()
//
// This method is used for setting the texture data
// associated with the passed-in ID into the shader.
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
// SetTextureUVScale()
//
// This method is used for setting the texture UV scale
// values into the shader.
***********************************************************/
void SceneManager::SetTextureUVScale(float u, float v)
{
    if (NULL != m_pShaderManager)
    {
        m_pShaderManager->setVec2Value("UVscale", glm::vec2(u, v));
    }
}

/***********************************************************
// LoadSceneTextures()
//
// This method is used for preparing the 3D scene by loading
// the textures into memory.
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
// PrepareScene()
//
// This method is used for preparing the 3D scene by loading
// the shapes and textures in memory to support the 3D scene rendering.
***********************************************************/
void SceneManager::PrepareScene()
{
    // load the textures for the 3D scene
    LoadSceneTextures();

    // Generate star positions with higher y-coordinates
    for (int i = 0; i < 100; ++i) {
        float x = static_cast<float>(rand() % 20 - 10);
        float y = static_cast<float>(rand() % 10 + 10); // Increased height range from 10 to 20
        float z = static_cast<float>(rand() % 20 - 10);
        starPositions.push_back(glm::vec3(x, y, z));
    }

    // Generate initial steam positions for the mug
    for (int i = 0; i < 15; ++i) {
        float x = static_cast<float>(rand() % 10 - 5) * 0.05f;
        float y = static_cast<float>(rand() % 5) * 0.1f;
        float z = static_cast<float>(rand() % 10 - 5) * 0.05f;
        steamPositions.push_back(glm::vec3(x, y, z));
    }

    // Load basic meshes
    m_basicMeshes->LoadPlaneMesh();    // Desk Surface
    m_basicMeshes->LoadBoxMesh();      // Monitor Screen and Frame
    m_basicMeshes->LoadCylinderMesh(); // Mug Body,Lamp Stand, Lamp Base, Monitor Stand
    m_basicMeshes->LoadTorusMesh();    // Mug Handle, Mouse Scroll Wheel
    m_basicMeshes->LoadConeMesh();     // Lamp Shade
    m_basicMeshes->LoadSphereMesh();   // Lamp Bulb
}

/***********************************************************
// HandleInput()
//
// This method handles input for controlling the scene.
***********************************************************/
void SceneManager::HandleInput(int key, int x, int y) {
    if (key == GLFW_KEY_X) {
        // Toggle monitor rotation
        rotateMonitor = !rotateMonitor;
        std::cout << "Monitor rotation: " << (rotateMonitor ? "ON" : "OFF") << std::endl;
    }
    else if (key == GLFW_KEY_C) {
        // Cycle through colors for the monitor
        currentColorIndex = (currentColorIndex + 1) % monitorColors.size();
        std::cout << "Monitor color changed to index: " << currentColorIndex << std::endl;
    }
    else if (key == GLFW_KEY_P) {
        usePerspective = true;
        std::cout << "Switched to Perspective Projection" << std::endl;
    }
    else if (key == GLFW_KEY_O) {
        usePerspective = false;
        std::cout << "Switched to Orthographic Projection" << std::endl;
    }
}



/***********************************************************
// RenderScene()
***********************************************************/
void SceneManager::RenderScene() {


    glm::vec3 scaleXYZ;
    glm::vec3 positionXYZ;

    float aspectRatio = 800.0f / 600.0f; //
    // Projection matrices
    glm::mat4 perspectiveProjection = glm::perspective(glm::radians(45.0f), aspectRatio, 0.1f, 100.0f);
    glm::mat4 orthographicProjection = glm::ortho(-aspectRatio * 10.0f, aspectRatio * 10.0f, -10.0f, 10.0f, 0.1f, 100.0f);

    glm::mat4 viewMatrix = glm::lookAt(
        glm::vec3(0.0f, 0.0f, 10.0f), // Camera position
        glm::vec3(0.0f, 0.0f, 0.0f),  // Target position
        glm::vec3(0.0f, 1.0f, 0.0f)   // Up direction
    );

    glm::mat4 projectionMatrix = usePerspective ? perspectiveProjection : orthographicProjection;
    glm::mat4 viewProjection = projectionMatrix * viewMatrix;

    m_pShaderManager->setMat4Value("viewProjection", viewProjection);


    // First light source
    glm::vec3 lightPos1 = glm::vec3(5.0f, 10.0f, 5.0f);  // Closer light position for more
    glm::vec3 lightColor1 = glm::vec3(1.0f, 1.0f, 1.0f); // White light

    // Second light source
    glm::vec3 lightPos2 = glm::vec3(-5.0f, 8.0f, 10.0f); // Second light for better illumination
    glm::vec3 lightColor2 = glm::vec3(0.7f, 0.7f, 0.7f); // Slightly dimmer white light

    glm::vec3 viewPos = glm::vec3(0.0f, 0.0f, 10.0f); // Camera/view position

    // Ambient lighting (adjusted for slightly brighter effect)
    glm::vec3 ambientLight = glm::vec3(0.4f, 0.4f, 0.4f); // Increased ambient light for overall brightness

    // Pass first light values to the shader
    m_pShaderManager->setVec3Value("lightPos", lightPos1);
    m_pShaderManager->setVec3Value("lightColor", lightColor1);

    // Pass second light values (if supported in shader)
    m_pShaderManager->setVec3Value("lightPos2", lightPos2);
    m_pShaderManager->setVec3Value("lightColor2", lightColor2);

    // Pass ambient light to shader (if used)
    m_pShaderManager->setVec3Value("ambientLight", ambientLight);

    // **Set the background color before rendering the scene**
    glClearColor(0.0f, 0.2f, 0.4f, 1.0f); // Deep blue, simulating natural sky or ocean

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);  // Clear the screen to the background color

    // Render Stars with random colors
    for (const auto& starPos : starPositions) {
        scaleXYZ = glm::vec3(0.1f, 0.1f, 0.1f); // Small star
        SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, starPos);

        // Generate random color for each star
        float red = static_cast<float>(rand()) / static_cast<float>(RAND_MAX);
        float green = static_cast<float>(rand()) / static_cast<float>(RAND_MAX);
        float blue = static_cast<float>(rand()) / static_cast<float>(RAND_MAX);

        SetShaderColor(red, green, blue, 1.0f); // Set random color for stars
        m_basicMeshes->DrawSphereMesh();
    }

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


    // Monitor rotation logic
    static float monitorRotationAngle = 0.0f;
    if (rotateMonitor) {
        monitorRotationAngle += 0.5f;
        if (monitorRotationAngle > 360.0f) monitorRotationAngle -= 360.0f;
    }

    // Declare currentColor once outside any loops or conditionals
    glm::vec3 currentColor = monitorColors[currentColorIndex];

    // Monitor Screen
    scaleXYZ = glm::vec3(8.5f, 5.5f, 0.02f);  // Size of the monitor screen
    positionXYZ = glm::vec3(0.0f, 6.0f, -1.90f);  // Position of the monitor screen

    // Apply transformations with rotation around the Y-axis
    SetTransformations(scaleXYZ, 0.0f, monitorRotationAngle, 0.0f, positionXYZ);
   
    // Apply the selected color to the monitor screen
    SetShaderColor(currentColor.r, currentColor.g, currentColor.b, 1.0f);

    // Draw the monitor screen as a box
    m_basicMeshes->DrawBoxMesh();


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

    // Lamp Stand
    scaleXYZ = glm::vec3(0.2f, 4.0f, 0.2f);
    positionXYZ = glm::vec3(7.0f, 0.4f, -2.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderTexture("metalTexture");
    m_basicMeshes->DrawCylinderMesh();

    // Lamp Base
    scaleXYZ = glm::vec3(1.0f, 0.1f, 1.0f);
    positionXYZ = glm::vec3(7.0f, 0.05f, -2.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderTexture("metalTexture");
    m_basicMeshes->DrawCylinderMesh();

    // Lamp Shade
    scaleXYZ = glm::vec3(1.5f, 2.0f, 1.5f);
    positionXYZ = glm::vec3(7.0f, 5.0f, -2.0f);
    SetTransformations(scaleXYZ, -45.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderTexture("metalTexture");
    m_basicMeshes->DrawConeMesh();

    // Variables for light bulb brightness modulation
    static float time = 0.0f;  // Keeps track of time for the sine wave
    time += 0.02f;  // Controls the speed of brightness change (adjust for slower or faster pulses)
    float bulbBrightness = (sin(time) + 1.0f) / 2.0f;  // Outputs a value between 0 and 1

    // Amplify brightness (to make it super bright)
    float brightnessMultiplier = 4.5f;  // You can adjust this for more intensity
    bulbBrightness *= brightnessMultiplier;  // Increase the overall brightness

    // Adjust ambient light intensity based on bulbBrightness
    glm::vec3 dynamicAmbientLight = glm::vec3(0.1f, 0.1f, 0.1f) * bulbBrightness;  // Dynamically scale ambient lighting

    // Adjust the other light sources similarly for room-wide lighting effect
    glm::vec3 dynamicLightColor1 = lightColor1 * (bulbBrightness * 0.5f);  // Scale with bulbBrightness
    glm::vec3 dynamicLightColor2 = lightColor2 * (bulbBrightness * 0.5f);  // Scale with bulbBrightness

    // Pass updated ambient light to shader
    m_pShaderManager->setVec3Value("ambientLight", dynamicAmbientLight);

    // Pass updated light source colors to shader (for room dimming effect)
    m_pShaderManager->setVec3Value("lightColor", dynamicLightColor1);
    m_pShaderManager->setVec3Value("lightColor2", dynamicLightColor2);

    // Lamp Bulb Rotation
    static float bulbRotationAngle = 0.0f;  // Static to maintain the value between frames
    bulbRotationAngle += 0.5f;  // Increment the rotation angle each frame

    scaleXYZ = glm::vec3(0.5f, 0.5f, 0.5f);
    positionXYZ = glm::vec3(7.0f, 4.0f, -2.0f);
    // Apply the rotation to the Y-axis of the bulb
    SetTransformations(scaleXYZ, 0.0f, bulbRotationAngle, 0.0f, positionXYZ);

    // Set a super bright yellow color for the light bulb
    glm::vec3 bulbColor = glm::vec3(1.0f, 1.0f, 0.0f) * bulbBrightness;  // Intense yellow color
    SetShaderColor(bulbColor.r, bulbColor.g, bulbColor.b, 1.0f);

    m_basicMeshes->DrawSphereMesh();


    // Mouse Body movement controlled by 'M' key
    if (moveMouse)
    {
        mouseMovement += mouseDirection * 0.1f; // Adjust speed as needed for smoother motion

        // Bounce back and forth within a larger range for more noticeable movement
        if (mouseMovement > 2.0f || mouseMovement < -2.0f)
        {
            mouseDirection = -mouseDirection; // Reverse the direction when limit is reached
        }
    }

    // Mouse Body
    scaleXYZ = glm::vec3(0.5f, 0.2f, 0.7f);
    positionXYZ = glm::vec3(1.0f + mouseMovement, 0.1f, 6.0f); // Adjust position along X-axis with mouseMovement
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderTexture("grayTexture");
    m_basicMeshes->DrawCylinderMesh();

    // Mouse Scroll Wheel
    scaleXYZ = glm::vec3(0.15f, 0.15f, 0.15f);
    positionXYZ = glm::vec3(1.0f + mouseMovement, 0.25f, 6.0f); // Sync position with mouse body
    SetTransformations(scaleXYZ, 90.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderTexture("grayTexture");
    m_basicMeshes->DrawTorusMesh();

    // Mug Body
    scaleXYZ = glm::vec3(0.7f, 1.0f, 0.7f);
    positionXYZ = glm::vec3(-3.0f, 0.5f, 5.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderTexture("whiteTexture");
    m_basicMeshes->DrawCylinderMesh();

    // Mug Handle
    scaleXYZ = glm::vec3(0.4f, 0.4f, 0.1f);
    positionXYZ = glm::vec3(-2.5f, 0.5f, 5.0f);
    SetTransformations(scaleXYZ, 90.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderTexture("whiteTexture");
    m_basicMeshes->DrawTorusMesh();

    // Coffee (Brown liquid inside Mug)
    scaleXYZ = glm::vec3(0.65f, 0.02f, 0.65f);
    positionXYZ = glm::vec3(-3.0f, 0.95f, 5.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.44f, 0.26f, 0.08f, 1.0f);
    m_basicMeshes->DrawCylinderMesh();

    // Mug Rim
    scaleXYZ = glm::vec3(0.72f, 0.02f, 0.72f);
    positionXYZ = glm::vec3(-3.0f, 1.5f, 5.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.0f, 0.0f, 0.0f, 1.0f);
    m_basicMeshes->DrawCylinderMesh();

    // Steam Simulation
    for (int i = 0; i < steamPositions.size(); ++i) {
        scaleXYZ = glm::vec3(0.05f, 0.1f, 0.05f);
        positionXYZ = steamPositions[i] + glm::vec3(-3.0f, 1.0f, 5.0f);  // Offset steam to rise from the mug
        SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
        SetShaderColor(0.9f, 0.9f, 0.9f, 0.5f);  // Semi-transparent steam

        m_basicMeshes->DrawSphereMesh();

        // Make steam rise over time
        steamPositions[i].y += 0.02f;

        // Reset steam particle position when it goes out of view
        if (steamPositions[i].y > 3.0f) {
            steamPositions[i].y = 0.0f;
        }
    }

    // Keyboard base
    scaleXYZ = glm::vec3(5.0f, 0.2f, 1.0f);
    positionXYZ = glm::vec3(0.0f, 0.05f, -1.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderTexture("grayTexture");
    m_basicMeshes->DrawPlaneMesh();

    // Keyboard keys
    float keySpacingX = 0.5f;
    float keySpacingZ = 0.5f;
    float keyOffsetX = -2.25f;
    float keyOffsetZ = -1.4f;

    for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 10; j++) {
            scaleXYZ = glm::vec3(0.35f, 0.05f, 0.35f);
            positionXYZ = glm::vec3(keyOffsetX + (j * keySpacingX), 0.1f, keyOffsetZ + (i * keySpacingZ));
            SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
            SetShaderColor(0.5f, 0.5f, 0.5f, 1.0f);
            m_basicMeshes->DrawBoxMesh();
        }
    }
}
