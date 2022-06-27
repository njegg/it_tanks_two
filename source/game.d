module game;

import std.stdio;
import std.math: sin, cos;
import std.conv;
import std.stdio;

import projectilem;
import playerm;
import vars;
import utilm;

import raylib;

Player playerOne;
Player playerTwo;

RenderTexture2D playerOneScreen;
RenderTexture2D playerTwoScreen;
Rectangle screenRectSrc;
Rectangle screenRectDst;

Model groundModel;

bool cursorEnabled = false;
char* fps;

void gameLoad()
{
	InitWindow(windowWidth, windowHeight, "It Tanks Two");
	SetTargetFPS(75);
	fps = cast(char*)MemAlloc(10);
	
	SetExitKey(KeyboardKey.KEY_Q);

	screenHeight = windowHeight;
	screenWidth = windowWidth / 2;
	
	// Making pixelated looking graphics
	// Got it from an example from raylibs website
	int screenWidthDownscaled = screenWidth / resolutionDownscale;
	int screenHeightDownscaled = screenHeight / resolutionDownscale;

    playerOneScreen = LoadRenderTexture(screenWidthDownscaled, screenHeightDownscaled);
    playerTwoScreen = LoadRenderTexture(screenWidthDownscaled, screenHeightDownscaled);

	float virtualRatio = cast(float) screenWidth / screenHeight;

	screenRectSrc = Rectangle
    (
		0.0f,
		0.0f, 
		cast(float) screenWidthDownscaled, 
		cast(float) -screenHeightDownscaled
    );

	screenRectDst = Rectangle
	(
		-virtualRatio,
		-virtualRatio,
		screenWidth  + virtualRatio * 2,
		screenHeight + virtualRatio * 2
	);


	// Creating players
	// Controls
	PlayerControls controlsOne = new PlayerControls();
	controlsOne.isGamepad = false;
	controlsOne.forward = KeyboardKey.KEY_W;
	controlsOne.backwards = KeyboardKey.KEY_S;
	controlsOne.right = KeyboardKey.KEY_D;
	controlsOne.left = KeyboardKey.KEY_A;
	controlsOne.shoot = KeyboardKey.KEY_LEFT_SHIFT;
	controlsOne.jump = KeyboardKey.KEY_SPACE;

	PlayerControls controlsTwo = new PlayerControls();
	controlsTwo.isGamepad = true;
	controlsTwo.forward = GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_UP;
	controlsTwo.backwards = GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_DOWN;
	controlsTwo.right = GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_RIGHT;
	controlsTwo.left = GamepadButton.GAMEPAD_BUTTON_LEFT_FACE_LEFT;
	controlsTwo.shoot = GamepadButton.GAMEPAD_BUTTON_LEFT_TRIGGER_1;

	Vector3 spawnPositionOne = {  5.0f, 0.31f, 0.0f};
	Vector3 spawnPositionTwo = { -5.0f, 0.31f, 0.0f};

	playerOne = loadPlayer(1, Colors.ORANGE, controlsOne, spawnPositionOne);
	playerTwo = loadPlayer(2, Colors.BLUE, controlsTwo, spawnPositionTwo);

	// Initial mouse position
	currMousePosition = GetMousePosition();

	// Ground
	Mesh planeMesh = GenMeshPlane(32.0f, 32.0f, 8, 8);
	groundModel = LoadModelFromMesh(planeMesh);

	Texture2D grassTexture = LoadTexture("assets/grass.png");
	SetMaterialTexture(&groundModel.materials[0], MATERIAL_MAP_DIFFUSE, grassTexture);
	groundModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = grassTexture;
	
	DisableCursor();
}

void gameInput()
{
	// Gonna use this as 'pause' for now
	if (IsKeyPressed(KeyboardKey.KEY_C))
	{
		cursorEnabled = !cursorEnabled;
		if (cursorEnabled) { EnableCursor(); SetTargetFPS(15); }
		else 			   { DisableCursor(); SetTargetFPS(75); }
	}

    playerOne.input();
    playerOne.input();
}

void gameUpdate()
{
    delta = GetFrameTime();

    prevMousePosition = currMousePosition;
    currMousePosition = GetMousePosition();

    playerOne.update(delta);
    playerTwo.update(delta);

    updateProjectiles(delta);
    updateExplosions(delta);
}

void gameDraw()
{
    // Drawing to playerOne's screen
    BeginTextureMode(playerOneScreen);
        ClearBackground(Colors.SKYBLUE);

        BeginMode3D(playerOne.playerCamera.camera);

            DrawModel(groundModel, Vector3Zero(), 1, Colors.WHITE);
            playerOne.draw(true);
            playerTwo.draw(false);

            drawProjectiles();
            drawExplosions();

        EndMode3D();
    EndTextureMode();

    // Drawing to playerTwo's screen
    BeginTextureMode(playerTwoScreen);
        ClearBackground(Colors.SKYBLUE);

        BeginMode3D(playerTwo.playerCamera.camera);

            DrawModel(groundModel, Vector3Zero(), 1, Colors.WHITE);
            playerOne.draw(false);
            playerTwo.draw(true);

            drawProjectiles();
            drawExplosions();

        EndMode3D();
    EndTextureMode();

    // Drawing both screens
    BeginDrawing();
        ClearBackground(Colors.BLACK);
        
        Vector2 screenOneCoords = { 0.0f, 0.0f };
        Vector2 screenTwoCoords = { -screenWidth, 0.0f };

        DrawTexturePro(playerOneScreen.texture, screenRectSrc, screenRectDst, screenOneCoords, 0, Colors.WHITE);
        DrawTexturePro(playerTwoScreen.texture, screenRectSrc, screenRectDst, screenTwoCoords, 0, Colors.WHITE);
    
        sprintf(fps, "%i", GetFPS());
        DrawText(fps, 10, 10, 30, Colors.YELLOW);

    EndDrawing();
}

void gameUnload()
{
    UnloadTexture(groundModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture);
	UnloadModel(groundModel);

	unloadPlayer(playerOne);
	unloadPlayer(playerTwo);

	MemFree(fps);

	CloseWindow();
}
