///////////////////////////////////////////////////////////////////////////////
// SceneManager.cpp
// ============
// manage the loading and rendering of 3D scenes
//
// AUTHOR: Brian Battersby - SNHU Instructor / Computer Science
// Created for CS-330-Computational Graphics and Visualization, Nov. 1st, 2023
///////////////////////////////////////////////////////////////////////////////

#include "SceneManager.h"

#ifndef STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#endif

#include <glm/gtx/transform.hpp>

// declaration of global variables
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
    m_pShaderManager = NULL;
    delete m_basicMeshes;
    m_basicMeshes = NULL;
}

/***********************************************************
 *  SetTransformations()
 *
 *  This method is used for setting the transform buffer
 *  using the passed in transformation values.
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

    // matrix math for calculating the final model matrix
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
 *  This method is used for setting the passed in color
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
        // pass the color values into the shader
        m_pShaderManager->setIntValue(g_UseTextureName, false);
        m_pShaderManager->setVec4Value(g_ColorValueName, currentColor);
    }
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
    m_basicMeshes->LoadCylinderMesh();
    m_basicMeshes->LoadSphereMesh();
    m_basicMeshes->LoadConeMesh();
    m_basicMeshes->LoadBoxMesh();
}

/***********************************************************
 *  RenderScene()
 *
 *  This method is used for rendering the 3D scene by
 *  transforming and drawing the basic 3D shapes
 ***********************************************************/
void SceneManager::RenderScene()
{
    glm::vec3 scaleXYZ;
    float XrotationDegrees = 0.0f;
    float YrotationDegrees = 0.0f;
    float ZrotationDegrees = 0.0f;
    glm::vec3 positionXYZ;

    // Background color
    glClearColor(0.529f, 0.808f, 0.922f, 1.0f);  // Light blue background

    // First cylinder (left)
    scaleXYZ = glm::vec3(4.0f, 2.0f, 4.0f);
    positionXYZ = glm::vec3(-9.0f, 0.0f, 0.0f);  // Moved further away to the left
    SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
    SetShaderColor(0.4f, 0.7f, 1.0f, 1.0f);
    m_basicMeshes->DrawCylinderMesh();

    // Sphere (moved further away from the central blue shape)
    scaleXYZ = glm::vec3(3.0f, 3.0f, 3.0f);
    positionXYZ = glm::vec3(-9.0f, 6.0f, 0.0f);  // Moved further left and kept the height raised
    SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
    SetShaderColor(0.8f, 0.4f, 1.0f, 1.0f);  // Purple color
    m_basicMeshes->DrawSphereMesh();

    // Second cylinder (middle, raised higher)
    scaleXYZ = glm::vec3(5.0f, 3.0f, 5.0f);
    positionXYZ = glm::vec3(0.0f, 3.5f, 0.0f);  // Raised higher than before
    SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
    SetShaderColor(0.4f, 0.7f, 1.0f, 1.0f);
    m_basicMeshes->DrawCylinderMesh();

    // Cone (lowered further based on middle blue shape)
    scaleXYZ = glm::vec3(4.0f, 8.0f, 4.0f);
    positionXYZ = glm::vec3(0.0f, 6.0f, 0.0f);  // Adjusted cone based on higher middle cylinder
    SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
    SetShaderColor(1.0f, 1.0f, 0.0f, 1.0f);  // Yellow color
    m_basicMeshes->DrawConeMesh();

    // Third cylinder (right, same as the left one)
    scaleXYZ = glm::vec3(4.0f, 2.0f, 4.0f);
    positionXYZ = glm::vec3(9.0f, 0.0f, 0.0f);  // Moved further right to match the symmetry
    SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
    SetShaderColor(0.4f, 0.7f, 1.0f, 1.0f);
    m_basicMeshes->DrawCylinderMesh();

    // Box (lowered slightly more for symmetry with the sphere)
    scaleXYZ = glm::vec3(2.5f, 2.5f, 2.5f);
    positionXYZ = glm::vec3(9.0f, 4.5f, 0.0f);  // Slightly lowered
    SetTransformations(scaleXYZ, XrotationDegrees, YrotationDegrees, ZrotationDegrees, positionXYZ);
    SetShaderColor(1.0f, 0.0f, 0.0f, 1.0f);  // Red color
    m_basicMeshes->DrawBoxMesh();
}
