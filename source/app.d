import std.stdio;
import std.math: sin, cos;

import playerm;
import vars;
import utilm;

import raylib;

void main()
{
	InitWindow(screenWidth, screenHeight, "It Tanks Two");
	SetTargetFPS(75);
	
	// creating a player
	Player player = loadPlayer();

	currMousePosition = GetMousePosition();

	Vector2 planeSize = { 10.0f, 10.0f };

	DisableCursor();

	while (!WindowShouldClose())
	{
		// Update
		delta = GetFrameTime();

		prevMousePosition = currMousePosition;
		currMousePosition = GetMousePosition();

		player.update(delta);


		// Draw
		BeginDrawing();
		ClearBackground(Colors.WHITE);
		BeginMode3D(player.playerCamera.camera);

				DrawPlane(Vector3Zero(), planeSize, Colors.GRAY);
				
				player.draw();

		EndMode3D();
		EndDrawing();
	}

	EnableCursor();

	unloadPlayer(player);
}
