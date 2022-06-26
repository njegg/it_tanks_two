module vars;

import raylib : PI, Vector3, Vector2;

const int windowWidth = 1280;
const int windowHeight = 720;

int screenWidth;
int screenHeight;

int resolutionDownscale = 6;

Vector3 cameraDistance = { x:0.0f, y:2.0f, z:5.0f };
Vector2 currMousePosition;
Vector2 prevMousePosition;

const TWO_PI = 2*PI;

float delta;
