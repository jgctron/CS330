///////////////////////////////////////////////////////////////////////////////
// SceneManager.h
// ============
// manage the loading and rendering of 3D scenes
//
//  AUTHOR: Brian Battersby - SNHU Instructor / Computer Science
//  Created for CS-330-Computational Graphics and Visualization, Nov. 1st, 2023
///////////////////////////////////////////////////////////////////////////////

#ifndef SCENEMANAGER_H
#define SCENEMANAGER_H

#include "ShaderManager.h"
#include "ShapeMeshes.h"
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <vector>

// Define the total number of lights
const int TOTAL_LIGHTS = 2;

// Define the TextureID structure
struct TextureID {
    GLuint ID; // OpenGL texture ID
    std::string tag; // Tag for the texture
};

// Declare light and material structures
struct LightSource {
    glm::vec3 position;
    glm::vec3 ambientColor;
    glm::vec3 diffuseColor;
    glm::vec3 specularColor;
    float focalStrength;
    float specularIntensity;
};

struct Material {
    glm::vec3 ambientColor;
    float ambientStrength;
    glm::vec3 diffuseColor;
    glm::vec3 specularColor;
    float shininess;
};

class SceneManager {
public:
    SceneManager(ShaderManager* pShaderManager);
    ~SceneManager();

    void PrepareScene();
    void RenderScene();
    void RenderShadows(glm::mat4 lightSpaceMatrix); // For shadow rendering
    void RenderSceneForShadows(); // For rendering the scene from the light's perspective
    void RenderSceneWithShadows(); // For rendering the scene with shadows applied

private:
    void SetupLightSource(int index, glm::vec3 position, glm::vec3 ambientColor, glm::vec3 diffuseColor, glm::vec3 specularColor, float focalStrength, float specularIntensity);
    void SetupMaterial(glm::vec3 ambientColor, float ambientStrength, glm::vec3 diffuseColor, glm::vec3 specularColor, float shininess);
    bool CreateGLTexture(const char* filename, std::string tag);
    void BindGLTextures();
    void DestroyGLTextures();
    int FindTextureID(std::string tag);
    int FindTextureSlot(std::string tag);
    void SetTransformations(glm::vec3 scaleXYZ, float XrotationDegrees, float YrotationDegrees, float ZrotationDegrees, glm::vec3 positionXYZ);
    void SetShaderColor(float redColorValue, float greenColorValue, float blueColorValue, float alphaValue);
    void SetShaderTexture(std::string textureTag);
    void SetTextureUVScale(float u, float v);
    void LoadSceneTextures();
    void InitShadowMapFramebuffer(); // Initialize framebuffer for shadow mapping

    // Member variables
    ShaderManager* m_pShaderManager;
    ShapeMeshes* m_basicMeshes;
    LightSource m_lightSources[TOTAL_LIGHTS]; // Array of light sources
    Material m_material;
    TextureID m_textureIDs[16]; // Up to 16 textures supported
    int m_loadedTextures;

    // Shadow mapping variables
    GLuint depthMapFBO;   // Framebuffer object for shadow mapping
    GLuint depthMap;      // Depth map texture
};

#endif // SCENEMANAGER_H
