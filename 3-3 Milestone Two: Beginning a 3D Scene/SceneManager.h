#pragma once

#include "ShaderManager.h"
#include "ShapeMeshes.h"
#include <string>
#include <vector>
#include <glm/glm.hpp>

/***********************************************************
 *  SceneManager
 *
 *  This class contains the code for preparing and rendering
 *  3D scenes, including the shader settings.
 ***********************************************************/
class SceneManager
{
public:
    // constructor
    SceneManager(ShaderManager* pShaderManager);
    // destructor
    ~SceneManager();

    struct TEXTURE_INFO
    {
        std::string tag;
        uint32_t ID;
    };

    struct OBJECT_MATERIAL
    {
        float ambientStrength;
        glm::vec3 ambientColor;
        glm::vec3 diffuseColor;
        glm::vec3 specularColor;
        float shininess;
        std::string tag;
    };

private:
    ShaderManager* m_pShaderManager;
    ShapeMeshes* m_basicMeshes;

    // total number of loaded textures
    int m_loadedTextures = 0;
    TEXTURE_INFO m_textureIDs[16] = {};
    std::vector<OBJECT_MATERIAL> m_objectMaterials;

    // Set transformation matrices
    void SetTransformations(
        glm::vec3 scaleXYZ,
        float XrotationDegrees,
        float YrotationDegrees,
        float ZrotationDegrees,
        glm::vec3 positionXYZ);

    // Set shader color
    void SetShaderColor(
        float redColorValue,
        float greenColorValue,
        float blueColorValue,
        float alphaValue);

    // Set shader texture
    void SetShaderTexture(std::string textureTag);

    // Set texture UV scale
    void SetTextureUVScale(float u, float v);

    // Set shader material
    void SetShaderMaterial(std::string materialTag);

    // Find a texture slot by tag
    int FindTextureSlot(std::string tag);

    // New function for setting lighting
    void SetLighting();

public:
    void PrepareScene();
    void RenderScene();
};
