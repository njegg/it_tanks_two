import std.stdio;
import std.math: sin, cos;
import std.conv;
import std.stdio;


import playerm;
import vars;
import utilm;

import raylib;

void main()
{
	InitWindow(windowWidth, windowHeight, "It Tanks Two");
	SetTargetFPS(75);
	char* fps = cast(char*)MemAlloc(10);

	screenHeight = windowHeight;
	screenWidth = windowWidth / 2;
	
	// creating players
	PlayerControls controlsOne = new PlayerControls();
	controlsOne.isGamepad = false;
	controlsOne.forward = KeyboardKey.KEY_W;
	controlsOne.backwards = KeyboardKey.KEY_S;
	controlsOne.right = KeyboardKey.KEY_D;
	controlsOne.left = KeyboardKey.KEY_A;
	controlsOne.shoot = KeyboardKey.KEY_SPACE;

	PlayerControls controlsTwo = new PlayerControls();
	controlsTwo.isGamepad = true;
	controlsTwo.forward = GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP;
	controlsTwo.backwards = GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN;
	controlsTwo.right = GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT;
	controlsTwo.left = GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT;
	controlsTwo.shoot = GamepadButton.GAMEPAD_BUTTON_LEFT_TRIGGER_1;

	Vector3 spawnPositionOne = {  5.0f, 0.31f, 0.0f};
	Vector3 spawnPositionTwo = { -5.0f, 0.31f, 0.0f};

	Player playerOne = loadPlayer(Colors.ORANGE, controlsOne, spawnPositionOne);
	Player playerTwo = loadPlayer(Colors.BLUE, controlsTwo, spawnPositionTwo);

	// Making pixelated looking graphics
	// Got it from an example from raylibs website

	int screenWidthDownscaled = screenWidth / resolutionDownscale;
	int screenHeightDownscaled = screenHeight / resolutionDownscale;

    RenderTexture2D playerOneScreen = LoadRenderTexture(screenWidthDownscaled, screenHeightDownscaled);
    RenderTexture2D playerTwoScreen = LoadRenderTexture(screenWidthDownscaled, screenHeightDownscaled);

	float virtualRatio = cast(float) screenWidth / screenHeight;

	Rectangle screenRect = 
	{
		x:0.0f,
		y:0.0f, 
		w:cast(float) screenWidthDownscaled, 
		h:cast(float) -screenHeightDownscaled
	};

	Rectangle screenRect2 = 
	{
		x:-virtualRatio,
		y:-virtualRatio,
		w:screenWidth  + virtualRatio * 2,
		h:screenHeight + virtualRatio * 2
	};

	// Initial mouse position
	currMousePosition = GetMousePosition();

	// Ground
	Mesh planeMesh = GenMeshPlane(32.0f, 32.0f, 8, 8);
	Model planeModel = LoadModelFromMesh(planeMesh);

	Texture2D grassTexture = LoadTexture("assets/grass.png");
	SetMaterialTexture(&planeModel.materials[0], MATERIAL_MAP_DIFFUSE, grassTexture);
	planeModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = grassTexture;
	

	bool cursorEnabled = false;
	DisableCursor();

	while (!WindowShouldClose())
	{
		// Update
		delta = GetFrameTime();

		prevMousePosition = currMousePosition;
		currMousePosition = GetMousePosition();

		playerOne.update(delta);
		playerTwo.update(delta);

		// Gonna use this as 'pause' for now
		if (IsKeyPressed(KeyboardKey.KEY_C))
		{
			cursorEnabled = !cursorEnabled;
			if (cursorEnabled) EnableCursor();
			else 			   DisableCursor();
		}


		// Draw
		BeginTextureMode(playerOneScreen);
			ClearBackground(Colors.SKYBLUE);

			BeginMode3D(playerOne.playerCamera.camera);

				DrawModel(planeModel, Vector3Zero(), 1, Colors.WHITE);
				playerOne.draw(true);
				playerTwo.draw(false);

			EndMode3D();
		EndTextureMode();

		BeginTextureMode(playerTwoScreen);
			ClearBackground(Colors.SKYBLUE);

			BeginMode3D(playerTwo.playerCamera.camera);

				DrawModel(planeModel, Vector3Zero(), 1, Colors.WHITE);
				playerOne.draw(false);
				playerTwo.draw(true);

			EndMode3D();
		EndTextureMode();

		BeginDrawing();
			ClearBackground(Colors.BLACK);
			
			Vector2 screenOneCoords = { 0.0f, 0.0f };
			Vector2 screenTwoCoords = { -screenWidth, 0.0f };

			DrawTexturePro(playerOneScreen.texture, screenRect, screenRect2, screenOneCoords, 0, Colors.WHITE);
			DrawTexturePro(playerTwoScreen.texture, screenRect, screenRect2, screenTwoCoords, 0, Colors.WHITE);

			// DrawTextureRec(playerOneScreen.texture, screenRect, screenOneCoords, Colors.WHITE);
			// DrawTextureRec(playerTwoScreen.texture, screenRect, screenTwoCoords, Colors.WHITE);

			sprintf(fps, "%i", GetFPS());
			DrawText(fps, 10, 10, 30, Colors.YELLOW);

		EndDrawing();
	}

	UnloadModel(planeModel);
	UnloadTexture(grassTexture);

	unloadPlayer(playerOne);
	unloadPlayer(playerTwo);

	MemFree(fps);

	CloseWindow();
}
