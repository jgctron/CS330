#include <GLFW/glfw3.h>
#include "linmath.h"
#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include <iostream>
#include <vector>
#include <windows.h>
#include <time.h>

using namespace std;

const float DEG2RAD = 3.14159 / 180;

void processInput(GLFWwindow* window);

// Forward declare the Circle class to avoid circular dependencies
class Circle;

// Correct declaration of ApplyPhysics function
void ApplyPhysics(Circle& circle);

enum BRICKTYPE { REFLECTIVE, DESTRUCTABLE };
enum ONOFF { ON, OFF };

// Paddle class definition
class Paddle {
public:
    float x, y, width, height;
    float speed;

    Paddle(float xx, float yy, float ww, float hh, float spd) {
        x = xx; y = yy; width = ww; height = hh; speed = spd;
    }

    void drawPaddle() {
        glColor3d(1, 1, 1); // White paddle
        glBegin(GL_POLYGON);
        glVertex2d(x - width / 2, y - height / 2);
        glVertex2d(x + width / 2, y - height / 2);
        glVertex2d(x + width / 2, y + height / 2);
        glVertex2d(x - width / 2, y + height / 2);
        glEnd();
    }

    void moveLeft() {
        if (x - width / 2 > -1) {
            x -= speed;
        }
    }

    void moveRight() {
        if (x + width / 2 < 1) {
            x += speed;
        }
    }
};

// Brick class definition with a hit counter for green bricks
class Brick {
public:
    float red, green, blue;
    float x, y, width;
    BRICKTYPE brick_type;
    ONOFF onoff;
    int hit_count;  // Hit counter for reflective (green) bricks

    Brick(BRICKTYPE bt, float xx, float yy, float ww, float rr, float gg, float bb)
    {
        brick_type = bt;
        x = xx;
        y = yy;
        width = ww;
        red = rr;
        green = gg;
        blue = bb;
        onoff = ON;
        hit_count = (bt == REFLECTIVE) ? 3 : 1;  // Green bricks need 3 hits, red bricks are destroyed in 1 hit
    }

    void drawBrick() {
        if (onoff == ON) {
            double halfside = width / 2;
            glColor3d(red, green, blue);
            glBegin(GL_POLYGON);

            glVertex2d(x + halfside, y + halfside);
            glVertex2d(x + halfside, y - halfside);
            glVertex2d(x - halfside, y - halfside);
            glVertex2d(x - halfside, y + halfside);

            glEnd();
        }
    }

    // Change the color of reflective bricks after each hit
    void changeColor() {
        red = (rand() % 100) / 100.0f;
        green = (rand() % 100) / 100.0f;
        blue = (rand() % 100) / 100.0f;
    }
};

class Circle
{
public:
    float red, green, blue;
    float radius;
    float x;
    float y;
    float speed = 0.03;
    int direction; // 1=up 2=right 3=down 4=left 5 = up right   6 = up left  7 = down right  8= down left

    Circle(double xx, double yy, double rr, int dir, float rad, float r, float g, float b)
    {
        x = xx;
        y = yy;
        radius = rr;
        red = r;
        green = g;
        blue = b;
        radius = rad;
        direction = dir;
    }

    void CheckCollision(Brick* brk)
    {
        if ((x > brk->x - brk->width && x <= brk->x + brk->width) && (y > brk->y - brk->width && y <= brk->y + brk->width)) {
            // For destructible (red) bricks, destroy on the first hit
            if (brk->brick_type == DESTRUCTABLE) {
                brk->onoff = OFF;  // Destroy the brick
            }

            // For reflective (green) bricks, require multiple hits and change color
            if (brk->brick_type == REFLECTIVE) {
                brk->hit_count--;  // Decrease hit count
                brk->changeColor();  // Change color after each hit

                // After 3 hits, destroy the green (reflective) brick
                if (brk->hit_count <= 0) {
                    brk->onoff = OFF;  // Destroy the brick
                }

                // Optionally, change ball direction
                direction = GetRandomDirection();
            }
        }
    }

    void CheckPaddleCollision(Paddle* paddle) {
        // Check if the ball is moving upwards and its top edge touches the bottom of the paddle
        if ((direction == 1 || direction == 5 || direction == 6) &&
            (x > paddle->x - paddle->width / 2 && x < paddle->x + paddle->width / 2) &&
            (y + radius >= paddle->y - paddle->height / 2 && y < paddle->y)) {
            // Bounce the ball downwards
            direction = 3; // Set direction to down
        }
    }

    void CheckCircleCollision(Circle& other)
    {
        float dx = x - other.x;
        float dy = y - other.y;
        float distance = sqrt(dx * dx + dy * dy);

        if (distance < radius + other.radius) {
            // Combine into a larger circle or change color
            if (rand() % 2 == 0) {
                radius += 0.01;  // Increase the radius
            }
            else {
                // Change color
                red = (rand() % 100) / 100.0f;
                green = (rand() % 100) / 100.0f;
                blue = (rand() % 100) / 100.0f;
            }
        }
    }

    void MoveOneStep()
    {
        if (direction == 1 || direction == 5 || direction == 6)  // up
        {
            if (y > -1 + radius)
            {
                y -= speed;
            }
            else
            {
                direction = GetRandomDirection();
            }
        }

        if (direction == 2 || direction == 5 || direction == 7)  // right
        {
            if (x < 1 - radius)
            {
                x += speed;
            }
            else
            {
                direction = GetRandomDirection();
            }
        }

        if (direction == 3 || direction == 7 || direction == 8)  // down
        {
            if (y < 1 - radius) {
                y += speed;
            }
            else
            {
                direction = GetRandomDirection();
            }
        }

        if (direction == 4 || direction == 6 || direction == 8)  // left
        {
            if (x > -1 + radius) {
                x -= speed;
            }
            else
            {
                direction = GetRandomDirection();
            }
        }
    }

    void DrawCircle()
    {
        glColor3f(red, green, blue);
        glBegin(GL_POLYGON);
        for (int i = 0; i < 360; i++) {
            float degInRad = i * DEG2RAD;
            glVertex2f((cos(degInRad) * radius) + x, (sin(degInRad) * radius) + y);
        }
        glEnd();
    }

    int GetRandomDirection()
    {
        return (rand() % 8) + 1;
    }
};

// Applying physics to alter speed and trajectory
void ApplyPhysics(Circle& circle) {
    if (circle.speed > 0.01) {
        circle.speed -= 0.0001; // Slow down gradually
    }

    // Change the trajectory angle when bouncing off walls
    if (circle.x <= -1 + circle.radius || circle.x >= 1 - circle.radius) {
        circle.direction = (circle.direction == 2 || circle.direction == 4) ? 1 : 3;
    }
}

vector<Circle> world;

int main(void) {
    srand(time(NULL));

    if (!glfwInit()) {
        exit(EXIT_FAILURE);
    }
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
    GLFWwindow* window = glfwCreateWindow(480, 480, "8-2 Assignment", NULL, NULL);
    if (!window) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    // Arrange bricks in structured rows and columns
    vector<Brick> bricks;
    float startX = -0.8, startY = 0.8;
    for (int row = 0; row < 3; ++row) {
        for (int col = 0; col < 5; ++col) {
            float x = startX + col * 0.4;
            float y = startY - row * 0.2;
            if (col % 2 == 0) {
                bricks.push_back(Brick(DESTRUCTABLE, x, y, 0.15, 1, 0, 0)); // Red destructible bricks
            }
            else {
                bricks.push_back(Brick(REFLECTIVE, x, y, 0.15, 0, 1, 0)); // Green reflective bricks
            }
        }
    }

    // Create a paddle for user control
    Paddle paddle(0, -0.8, 0.3, 0.05, 0.05);

    while (!glfwWindowShouldClose(window)) {
        // Setup View
        float ratio;
        int width, height;
        glfwGetFramebufferSize(window, &width, &height);
        ratio = width / (float)height;
        glViewport(0, 0, width, height);
        glClear(GL_COLOR_BUFFER_BIT);

        processInput(window);

        // Paddle movement based on user input
        if (glfwGetKey(window, GLFW_KEY_LEFT) == GLFW_PRESS)
            paddle.moveLeft();
        if (glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS)
            paddle.moveRight();

        // Movement and collision checks
        for (int i = 0; i < world.size(); i++) {
            for (int j = 0; j < bricks.size(); j++) {
                world[i].CheckCollision(&bricks[j]);
            }

            world[i].CheckPaddleCollision(&paddle);
            world[i].MoveOneStep();
            world[i].DrawCircle();
        }

        // Draw paddle
        paddle.drawPaddle();

        // Drawing bricks
        for (int i = 0; i < bricks.size(); i++) {
            bricks[i].drawBrick();
        }

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);
    glfwTerminate();
    exit(EXIT_SUCCESS);
}

void processInput(GLFWwindow* window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);

    if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS)
    {
        double r, g, b;
        r = rand() / 10000;
        g = rand() / 10000;
        b = rand() / 10000;
        Circle B(0, 0, 0.2, 2, 0.05, r, g, b);
        world.push_back(B);
    }
}

