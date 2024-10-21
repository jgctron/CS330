Jorge Cintron
SNHU
CS330

About Me: Computational Graphics and Visualization Journey
During my last assignment for CS 330, I created a 3D Scene that simulated a given 2D image in C++ programming with OpenGL graphics libraries. Students used low-polygon 3D objects with textures, lighting, and a walk-around, animated camera. Each component was carefully thought out – even the title was created in a 3D Object editing program. I also made deliberate decisions about structuring my code so that the principles and practices learned could be reused for future programming projects, as illustrated below:

Development Choices for the 3D Scene
3D Objects

I’ve created multiple copies of myself (aka 3D objects) that are rotating around this 2D image, rendering some typical objects I usually use at my desk: a monitor, desk, mug, lamp, and keyboard. To make the objects look realistic, I’ve recreated them using primitive and basic geometric shapes such as box object, cylinder, cone and plane – as few polygons as possible, to perform the best! For example, monitor is a combination of three boxes (a box for screen, a box for the desktop frame and another for monitor base) and one cylinder for the monitor stand. Furthermore, I’ve applied an animated colour changing effect on the monitor desktop screen – changing colours from red to green and to blue, and also orange, yellow, magenta, and blue-green (Cyan) by using numbers in RGB values.

Code Structure and Key Functions
Its foundation is built on the SceneManager, ShaderManager, and ViewManager classes, each handling assembly of the Scene related to construction, shading, or user input:

SceneManager: Uses objects, lights, textures, and transformations to create a 3D scene. Manages the Scene’s rendering, and applies three transformations (scaling, rotation, and position) to the Scene by implementing a method known as SetTransformations.

ShaderManager: A class that loads and manages shader data – vertex and fragment shaders, to be specific – so that you can change lighting and texture parameters at runtime.

viewManager: that computers through the camera can obtain perspective or orthographic information about the current frame rate. Managers manage these frame rates and also assist players in navigating around the 3D space.

The main purpose of the SetTransformations function was to manipulate the object of the Scene. This function scales, rotates, and shifts every object in the Scene using parameters that are passed to it. The scaling factors, the rotation angles, and the position coordinates of each object are set to guarantee that the object is placed in the right 3D point of the Scene.
An overview of the function that is in charge of manipulating the object from the Scene:

void SceneManager::SetTransformations(
    glm::vec3 scaleXYZ,
    float XrotationDegrees,
    float YrotationDegrees,
    float ZrotationDegrees,
    glm::vec3 positionXYZ)
{
    // Apply scale, rotation, and translation matrices
    glm::mat4 modelView = glm::translate(positionXYZ) * 
                          glm::rotate(glm::radians(XrotationDegrees), glm::vec3(1.0f, 0.0f, 0.0f)) * 
                          glm::rotate(glm::radians(YrotationDegrees), glm::vec3(0.0f, 1.0f, 0.0f)) * 
                          glm::rotate(glm::radians(ZrotationDegrees), glm::vec3(0.0f, 0.0f, 1.0f)) * 
                          glm::scale(scaleXYZ);
    m_pShaderManager->setMat4Value("model", modelView);
}
Textures
Textures were also applied to the table, monitor, and lamp to increase realism. For the desk, for example, a wood texture was applied. It was tiled to create a larger image that would emulate the surface of a wooden desk: To load the texture and perform the texture filtering and wrapping, the CreateGLTexture function was used:


CreateGLTexture("C:/Users/ssjtr/Downloads/CS330Content/wood.png", "wood texture");
SetShaderTexture("woodTexture");
m_basicMeshes->DrawPlaneMesh();
Lighting

In the Scene, I have two different light sources modeled: a directional and a point light source, which together achieve the Phong shading model with ambient, diffuse, and specular light. To make the lamp bulb more realistic, I am modifying the brightness of the bulb back and forth using a sinusoidal function:

float bulbBrightness = (sin(time) + 1.0f) / 2.0f;
SetShaderColor(bulbColor.r * bulbBrightness, bulbColor.g * bulbBrightness, bulbColor.b * bulbBrightness, 1.0f);
User Navigation in the 3D Scene
Secondly, implementing user-controlled navigation of the camera in the Scene. The camera is moved left/right (X-axis) forward/back (Z-axis) and panned up/down using the WASD keys, respectively. The Y movement is handled by the QE keys. The pitch/yaw navigation is handled by the mouse movement, allowing for looking around the Scene. The scroll wheel controls the speed of the camera. Finally, the K/U keys toggle between perspective and orthographic view.

Custom Features
Rotating screen: By pressing the X key, we could rotate the monitoring monochromatic portrait around the Y-axis. Changing color: By pressing the C key, the screen can cycle through six different colors.

Randomized sparkling colors of the stars – Sparkling Stars: The stars in the Scene have randomized colors, changing in each step of the render loop.

Persistent Steam in Coffee Mug: I simulated boiling steam by having small spheres continually rise from the mug and zoom back into the cup when they leave the view, creating a looping effect.

Users can change the color of the screen on the monitor using the X and C keys to give a lay adding activity to the Scene.

Conclusion
This project successfully recreates the 2D image in 3D using low-polygon objects, realistic textures, lighting, and interactive control of the viewer's position. Through this project, I accomplished the technical requirements while creating a realm where rich user interactions are possible. By leveraging computational modules that I developed and then adding dynamic elements such as rotating computer monitor screens and color-change effects, I created in 3D a scene that would not have been possible were it not for my skill in computational graphics. It has been my pleasure to participate in this project, and it has enhanced my ability to implement exciting challenges in computational graphics, which I aspire to do in my future work.
