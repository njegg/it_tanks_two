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

	Vector2 planeSize = { 20.0f, 20.0f };
	Mesh planeMesh = GenMeshPlane(32.0f, 32.0f, 8, 8);
	Model planeModel = LoadModelFromMesh(planeMesh);

	Texture2D grassTexture = LoadTexture("assets/grass.png");
	SetMaterialTexture(&planeModel.materials[0], MATERIAL_MAP_DIFFUSE, grassTexture);
	planeModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = grassTexture;
	

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

				DrawModel(planeModel, Vector3Zero(), 1, Colors.WHITE);
				
				player.draw();

		EndMode3D();
		EndDrawing();
	}

	UnloadModel(planeModel);
	UnloadTexture(grassTexture);

	unloadPlayer(player);

	CloseWindow();
}
