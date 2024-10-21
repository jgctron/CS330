#include "ViewManager.h"

// GLM Math Header inclusions
#include <glm/glm.hpp>
#include <glm/gtx/transform.hpp>
#include <glm/gtc/type_ptr.hpp>    
#include <iostream>  // For debugging output

// Declaration of the global variables and defines
namespace {
    const int WINDOW_WIDTH = 1000;
    const int WINDOW_HEIGHT = 800;
    const char* g_ViewName = "view";
    const char* g_ProjectionName = "projection";

    // Camera object used for viewing and interacting with the 3D scene
    Camera* g_pCamera = nullptr;

    // These variables are used for mouse movement processing
    float gLastX = WINDOW_WIDTH / 2.0f;
    float gLastY = WINDOW_HEIGHT / 2.0f;
    bool gFirstMouse = true;

    // Time between current frame and last frame
    float gDeltaTime = 0.0f;
    float gLastFrame = 0.0f;

    // Camera movement speed, adjustable by keys
    float cameraSpeed = 2.5f;

    // Mouse sensitivity for finer control
    float mouseSensitivity = 0.1f;

    // If orthographic projection is on, this value will be true
    bool bOrthographicProjection = false;
}

/***********************************************************
 *  ViewManager()
 *
 *  The constructor for the class
 ***********************************************************/
ViewManager::ViewManager(ShaderManager* pShaderManager)
{
    m_pShaderManager = pShaderManager;
    m_pWindow = NULL;
    g_pCamera = new Camera();
    g_pCamera->Position = glm::vec3(0.5f, 5.5f, 10.0f);
    g_pCamera->Front = glm::vec3(0.0f, -0.5f, -2.0f);
    g_pCamera->Up = glm::vec3(0.0f, 1.0f, 0.0f);
    g_pCamera->Zoom = 80;
}

/***********************************************************
 *  ~ViewManager()
 *
 *  The destructor for the class
 ***********************************************************/
ViewManager::~ViewManager()
{
    m_pShaderManager = NULL;
    m_pWindow = NULL;
    if (NULL != g_pCamera)
    {
        delete g_pCamera;
        g_pCamera = NULL;
    }
}

/***********************************************************
 *  CreateDisplayWindow()
 *
 *  This method is used to create the main display window.
 ***********************************************************/
GLFWwindow* ViewManager::CreateDisplayWindow(const char* windowTitle)
{
    GLFWwindow* window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, windowTitle, NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return NULL;
    }
    glfwMakeContextCurrent(window);
    glfwSetCursorPosCallback(window, &ViewManager::Mouse_Position_Callback);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    m_pWindow = window;

    return(window);
}

/***********************************************************
 *  Mouse_Position_Callback()
 *
 *  This method is automatically called from GLFW whenever
 *  the mouse is moved within the active GLFW display window.
 ***********************************************************/
void ViewManager::Mouse_Position_Callback(GLFWwindow* window, double xMousePos, double yMousePos)
{
    if (gFirstMouse)
    {
        gLastX = xMousePos;
        gLastY = yMousePos;
        gFirstMouse = false;
    }

    float xOffset = xMousePos - gLastX;
    float yOffset = gLastY - yMousePos; // Reversed since y-coordinates go from bottom to top

    gLastX = xMousePos;
    gLastY = yMousePos;

    xOffset *= mouseSensitivity;
    yOffset *= mouseSensitivity;

    g_pCamera->ProcessMouseMovement(xOffset, yOffset);
}

/***********************************************************
 *  ProcessKeyboardEvents()
 *
 *  This method is called to process any keyboard events
 *  that may be waiting in the event queue.
 ***********************************************************/
void ViewManager::ProcessKeyboardEvents()
{
    if (glfwGetKey(m_pWindow, GLFW_KEY_ESCAPE) == GLFW_PRESS)
    {
        glfwSetWindowShouldClose(m_pWindow, true);
    }

    if (NULL == g_pCamera)
    {
        return;
    }

    // Process camera zooming in and out
    if (glfwGetKey(m_pWindow, GLFW_KEY_W) == GLFW_PRESS)
    {
        g_pCamera->ProcessKeyboard(FORWARD, gDeltaTime * cameraSpeed);
    }
    if (glfwGetKey(m_pWindow, GLFW_KEY_S) == GLFW_PRESS)
    {
        g_pCamera->ProcessKeyboard(BACKWARD, gDeltaTime * cameraSpeed);
    }

    // Process camera panning left and right
    if (glfwGetKey(m_pWindow, GLFW_KEY_A) == GLFW_PRESS)
    {
        g_pCamera->ProcessKeyboard(LEFT, gDeltaTime * cameraSpeed);
    }
    if (glfwGetKey(m_pWindow, GLFW_KEY_D) == GLFW_PRESS)
    {
        g_pCamera->ProcessKeyboard(RIGHT, gDeltaTime * cameraSpeed);
    }

    // Process camera upward and downward movement with Q and E
    if (glfwGetKey(m_pWindow, GLFW_KEY_Q) == GLFW_PRESS)
    {
        g_pCamera->ProcessKeyboard(UP, gDeltaTime * cameraSpeed);
    }
    if (glfwGetKey(m_pWindow, GLFW_KEY_E) == GLFW_PRESS)
    {
        g_pCamera->ProcessKeyboard(DOWN, gDeltaTime * cameraSpeed);
    }

    // Adjust mouse sensitivity with , and . keys
    if (glfwGetKey(m_pWindow, GLFW_KEY_COMMA) == GLFW_PRESS)
    {
        mouseSensitivity = std::max(0.01f, mouseSensitivity - 0.01f);
        std::cout << "Mouse Sensitivity: " << mouseSensitivity << std::endl;
    }
    if (glfwGetKey(m_pWindow, GLFW_KEY_PERIOD) == GLFW_PRESS)
    {
        mouseSensitivity += 0.01f;
        std::cout << "Mouse Sensitivity: " << mouseSensitivity << std::endl;
    }

    // Camera speed adjustment with + and - keys
    if (glfwGetKey(m_pWindow, GLFW_KEY_KP_ADD) == GLFW_PRESS || glfwGetKey(m_pWindow, GLFW_KEY_EQUAL) == GLFW_PRESS)
    {
        cameraSpeed += 1.0f;
        std::cout << "Camera Speed Increased: " << cameraSpeed << std::endl;
    }
    if (glfwGetKey(m_pWindow, GLFW_KEY_KP_SUBTRACT) == GLFW_PRESS || glfwGetKey(m_pWindow, GLFW_KEY_MINUS) == GLFW_PRESS)
    {
        cameraSpeed = std::max(0.5f, cameraSpeed - 1.0f);
        std::cout << "Camera Speed Decreased: " << cameraSpeed << std::endl;
    }

    // Reset camera position with R key
    if (glfwGetKey(m_pWindow, GLFW_KEY_R) == GLFW_PRESS)
    {
        g_pCamera->Position = glm::vec3(0.5f, 5.5f, 10.0f);
        g_pCamera->Front = glm::vec3(0.0f, -0.5f, -2.0f);
        g_pCamera->Up = glm::vec3(0.0f, 1.0f, 0.0f);
        std::cout << "Camera Reset to Default Position." << std::endl;
    }
}

/***********************************************************
 *  PrepareSceneView()
 *
 *  This method is used for preparing the 3D scene by loading
 *  the shapes, textures in memory to support the 3D scene
 *  rendering
 ***********************************************************/
void ViewManager::PrepareSceneView()
{
    glm::mat4 view;
    glm::mat4 projection;

    float currentFrame = glfwGetTime();
    gDeltaTime = currentFrame - gLastFrame;
    gLastFrame = currentFrame;

    ProcessKeyboardEvents();

    view = g_pCamera->GetViewMatrix();
    projection = glm::perspective(glm::radians(g_pCamera->Zoom), (GLfloat)WINDOW_WIDTH / (GLfloat)WINDOW_HEIGHT, 0.1f, 100.0f);

    if (m_pShaderManager)
    {
        m_pShaderManager->setMat4Value(g_ViewName, view);
        m_pShaderManager->setMat4Value(g_ProjectionName, projection);
        m_pShaderManager->setVec3Value("viewPosition", g_pCamera->Position);
    }
}
