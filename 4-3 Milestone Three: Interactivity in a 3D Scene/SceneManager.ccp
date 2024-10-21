#include "SceneManager.h"
#include <glm/gtx/transform.hpp>

namespace {
    const char* g_ModelName = "model";
    const char* g_ColorValueName = "objectColor";
}

/***********************************************************
 *  SceneManager()
 ***********************************************************/
SceneManager::SceneManager(ShaderManager* pShaderManager) {
    m_pShaderManager = pShaderManager;
    m_basicMeshes = new ShapeMeshes();
}

/***********************************************************
 *  ~SceneManager()
 ***********************************************************/
SceneManager::~SceneManager() {
    delete m_basicMeshes;
}

/***********************************************************
 *  PrepareScene()
 *
 *  This method is used for preparing the 3D scene by loading
 *  the shapes in memory.
 ***********************************************************/
void SceneManager::PrepareScene() {
    // Load basic meshes
    m_basicMeshes->LoadPlaneMesh();    // Desk Surface
    m_basicMeshes->LoadBoxMesh();      // Monitor Screen and Frame
    m_basicMeshes->LoadCylinderMesh(); // Mug Body, Lamp Stand, Lamp Base, Monitor Stand
    m_basicMeshes->LoadTorusMesh();    // Mug Handle, Mouse Scroll Wheel
    m_basicMeshes->LoadConeMesh();     // Lamp Shade
    m_basicMeshes->LoadSphereMesh();   // Lamp Bulb
    m_basicMeshes->LoadPlaneMesh();    // Keyboard
}

/***********************************************************
 *  RenderScene()
 *
 *  This method is used for rendering the 3D scene.
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

    // Desk Surface
    scaleXYZ = glm::vec3(20.0f, 1.0f, 10.0f);
    positionXYZ = glm::vec3(0.0f, 0.0f, 0.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.54f, 0.27f, 0.07f, 1.0f);  // Brown for the desk surface
    m_basicMeshes->DrawPlaneMesh();

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

    // Monitor Screen (Inset Silver Box)
    scaleXYZ = glm::vec3(8.5f, 5.5f, 0.02f);
    positionXYZ = glm::vec3(0.0f, 6.0f, -1.90f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.75f, 0.75f, 0.75f, 1.0f);
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
    SetShaderColor(0.5f, 0.5f, 0.5f, 1.0f);
    m_basicMeshes->DrawBoxMesh();

    // Monitor Stand (Cylinder)
    scaleXYZ = glm::vec3(1.0f, 3.0f, 1.0f);
    positionXYZ = glm::vec3(0.0f, 0.0f, -2.1f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.5f, 0.5f, 0.5f, 1.0f);
    m_basicMeshes->DrawCylinderMesh();

    // Lamp Stand (Slightly lower the position to connect with the base)
    scaleXYZ = glm::vec3(0.2f, 4.0f, 0.2f);  // Keep the increased height for the lamp stand
    positionXYZ = glm::vec3(7.0f, 0.4f, -2.0f);  // Slightly lowered position to ensure it connects with the base
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.6f, 0.6f, 0.6f, 1.0f);  // Gray color for the stand
    m_basicMeshes->DrawCylinderMesh();

    // Lamp Base (Remaining the same)
    scaleXYZ = glm::vec3(1.0f, 0.1f, 1.0f);  // Flat base
    positionXYZ = glm::vec3(7.0f, 0.05f, -2.0f);  // Ensure it stays on the desk surface
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.5f, 0.5f, 0.5f, 1.0f);
    m_basicMeshes->DrawCylinderMesh();


    // Lamp Shade
    scaleXYZ = glm::vec3(1.5f, 2.0f, 1.5f);
    positionXYZ = glm::vec3(7.0f, 5.0f, -2.0f);
    SetTransformations(scaleXYZ, -45.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.5f, 0.5f, 0.5f, 1.0f);
    m_basicMeshes->DrawConeMesh();

    // Lamp Bulb (Yellow Sphere)
    scaleXYZ = glm::vec3(0.5f, 0.5f, 0.5f);  // Small sphere for the bulb
    positionXYZ = glm::vec3(7.0f, 4.0f, -2.0f);  // Inside the lamp shade
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(1.0f, 1.0f, 0.0f, 1.0f);  // Bright yellow color for the bulb
    m_basicMeshes->DrawSphereMesh();

    // Mug Body
    scaleXYZ = glm::vec3(0.7f, 1.0f, 0.7f);
    positionXYZ = glm::vec3(-3.0f, 0.5f, 5.0f);  // Close to the camera
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.9f, 0.9f, 0.9f, 1.0f);
    m_basicMeshes->DrawCylinderMesh();

    // Mug Handle
    scaleXYZ = glm::vec3(0.4f, 0.4f, 0.1f);
    positionXYZ = glm::vec3(-2.5f, 0.5f, 5.0f);  // Adjust to match mug position
    SetTransformations(scaleXYZ, 90.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.9f, 0.9f, 0.9f, 1.0f);
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
    SetShaderColor(0.9f, 0.9f, 0.9f, 1.0f);  // Light grey for mouse body
    m_basicMeshes->DrawCylinderMesh();

    // Mouse Scroll Wheel (Add as a larger torus for visibility)
    scaleXYZ = glm::vec3(0.15f, 0.15f, 0.15f);  // Increase the size of the scroll wheel
    positionXYZ = glm::vec3(1.0f, 0.25f, 6.0f);  // Adjust position to be slightly above the mouse body
    SetTransformations(scaleXYZ, 90.0f, 0.0f, 0.0f, positionXYZ);  // Rotate to sit horizontally
    SetShaderColor(1.0f, 0.0f, 0.0f, 1.0f);  // Bright red for high contrast
    m_basicMeshes->DrawTorusMesh();



    // Adjust the scale and position of the keyboard base to fit the keys
    scaleXYZ = glm::vec3(5.0f, 0.2f, 1.0f);  // Make the keyboard wider to fit the keys
    positionXYZ = glm::vec3(0.0f, 0.05f, -1.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.8f, 0.8f, 0.8f, 1.0f);  // Light grey for keyboard base
    m_basicMeshes->DrawPlaneMesh();

    // Adjust the scale and position of the keyboard base to fit the keys
    scaleXYZ = glm::vec3(5.0f, 0.2f, 1.0f);  // Keep the keyboard size as is
    positionXYZ = glm::vec3(0.0f, 0.05f, -1.0f);
    SetTransformations(scaleXYZ, 0.0f, 0.0f, 0.0f, positionXYZ);
    SetShaderColor(0.8f, 0.8f, 0.8f, 1.0f);  // Light grey for keyboard base
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

/***********************************************************
 *  SetTransformations()
 ***********************************************************/
void SceneManager::SetTransformations(
    glm::vec3 scaleXYZ,
    float XrotationDegrees,
    float YrotationDegrees,
    float ZrotationDegrees,
    glm::vec3 positionXYZ)
{
    glm::mat4 modelView;
    glm::mat4 scale = glm::scale(scaleXYZ);
    glm::mat4 rotationX = glm::rotate(glm::radians(XrotationDegrees), glm::vec3(1.0f, 0.0f, 0.0f));
    glm::mat4 rotationY = glm::rotate(glm::radians(YrotationDegrees), glm::vec3(0.0f, 1.0f, 0.0f));
    glm::mat4 rotationZ = glm::rotate(glm::radians(ZrotationDegrees), glm::vec3(0.0f, 0.0f, 1.0f));
    glm::mat4 translation = glm::translate(positionXYZ);

    modelView = translation * rotationX * rotationY * rotationZ * scale;

    if (m_pShaderManager)
    {
        m_pShaderManager->setMat4Value(g_ModelName, modelView);
    }
}

/***********************************************************
 *  SetShaderColor()
 ***********************************************************/
void SceneManager::SetShaderColor(float redColorValue, float greenColorValue, float blueColorValue, float alphaValue) {
    glm::vec4 currentColor(redColorValue, greenColorValue, blueColorValue, alphaValue);
    if (m_pShaderManager) {
        m_pShaderManager->setVec4Value(g_ColorValueName, currentColor);
    }
}
