import std.stdio;
import std.math: sin, cos;

import raylib;

const int screenWidth = 1280;
const int screenHeight = 720;

Vector3 cameraDistance = { x:0.0f, y:2.0f, z:5.0f };
Vector2 currMousePosition;
Vector2 prevMousePosition;

const TWO_PI = 2*PI;

void main()
{
	InitWindow(screenWidth, screenHeight, "It Tanks Two");
	SetTargetFPS(75);

	// creating a cube mesh and a texture made from a plain color image 
	// then making a model from a mesh and adding a texture to it
	Image image = GenImageColor(8, 8, Colors.GREEN);
	Texture texture = LoadTextureFromImage(image);
 	Mesh playerMesh = GenMeshCube(1.0f, 1.0f, 2.0f);

	UnloadImage(image);

	Model cubeModel = LoadModelFromMesh(playerMesh);
	cubeModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture;
	
	Vector3 playerSpawn = { 0.0f, 0.5f, 0.0f };
	
	// creating a player
	Player player = new Player(cubeModel, playerSpawn);
	float delta;

	Vector2 planeSize = { 10.0f, 10.0f };

	currMousePosition = GetMousePosition();

	while (!WindowShouldClose())
	{
		delta = GetFrameTime();
		player.update(delta);
		
		BeginDrawing();

			ClearBackground(Colors.WHITE);

			BeginMode3D(player.playerCamera.camera);

				DrawPlane(Vector3Zero(), planeSize, Colors.GRAY);

				player.draw();


			EndMode3D();

		EndDrawing();
	}

	UnloadTexture(texture);
}

class Player
{
	Vector3 position;
	Vector3 rotationalAxis = { y:1.0f };
	float angle = 0;
	float movementSpeed = 2.0f;
	float rotationSpeed = 2.0f;

	PlayerCamera playerCamera;
	Model model;

	this(Model model, Vector3 position)
	{
		this.model = model;

		this.position = position;
		Vector3 cameraPosition = Vector3Add(position, cameraDistance);

		Camera3D camera =
		{
			position: 	cameraPosition,
			target: 	this.position,
			up:			{ x:0.0f, y:1.0f, z:0.0f },
			fovy: 		50.0f,
			projection: CameraProjection.CAMERA_PERSPECTIVE,
		};
		SetCameraMode(camera, CameraMode.CAMERA_CUSTOM);
		
		this.playerCamera = new PlayerCamera(camera);
	}


	void update(float delta)
	{
		if (IsKeyDown(KeyboardKey.KEY_W))
		{
			this.position.x += sin(angle) * movementSpeed * delta;
			this.position.z += cos(angle) * movementSpeed * delta;
		}

		if (IsKeyDown(KeyboardKey.KEY_S))
		{
			this.position.x -= sin(angle) * movementSpeed * delta;
			this.position.z -= cos(angle) * movementSpeed * delta;
		}

		if (IsKeyDown(KeyboardKey.KEY_A))
		{
			angle += rotationSpeed * delta;
		}

		if (IsKeyDown(KeyboardKey.KEY_D))
		{
			angle -= rotationSpeed * delta;
		}

		fixAngleRad(&angle);

		playerCamera.camera.target = position;
		playerCamera.update(delta);
	}

	void draw()
	{
		float angleDeg = angle * RAD2DEG;
		DrawModelEx(model, position, rotationalAxis, angleDeg, Vector3One(), Colors.WHITE);
		DrawModelWiresEx(model, position, rotationalAxis, angleDeg, Vector3One(), Colors.BLACK);
	}
}

void fixAngleRad(float *angle)
{
	if      (*angle > TWO_PI) *angle %= TWO_PI;
	else if (*angle <   0) *angle += TWO_PI;
}

class PlayerCamera
{
	Camera3D camera;
	float sensitivity = 0.5;

	this(Camera3D camera)
	{
		this.camera = camera;
	}

	void update(float delta)
	{
		prevMousePosition = currMousePosition;
		currMousePosition = GetMousePosition();

		float rotationAmount = currMousePosition.x - prevMousePosition.x;
		Matrix rotationMatrix = MatrixRotateY(rotationAmount * delta);

		// rotate the distance to target 
		cameraDistance = Vector3Transform(cameraDistance, rotationMatrix);
		// add rotated distance to target and set it to current possiton
		this.camera.position = Vector3Add(camera.target, cameraDistance);

		UpdateCamera(&camera);
	}
}
