module vars;

import std.container : SList;

import raylib : PI, Vector3, Vector2, Color, ColorAlpha;

import projectilem;

const int windowWidth = 1280;
const int windowHeight = 720;
int screenWidth;
int screenHeight;
int resolutionDownscale = 4;

Vector3 cameraDistance = { x:0.0f, y:2.0f, z:5.0f };
Vector2 currMousePosition;
Vector2 prevMousePosition;

float delta;
const TWO_PI = 2 * PI;
float gravity = -9.806f;

auto projectiles = SList!Projectile();
auto explosions = SList!Explosion();

Color colorOne = Color(255, 161, 0, 255);
Color colorTwo = Color(0, 121, 241, 255);
Color colorOneLight = Color(255, 191, 0, 255);
Color colorTwoLight = Color(0, 151, 255, 255);
Color colorOneTransparent = Color(255, 211, 0, 200);
Color colorTwoTransparent = Color(0, 171, 255, 200);