module playerm;

import std.math : sin, cos;
import std.stdio : writeln;

import raylib;

import utilm;
import vars;

Player loadPlayer()
{
	// creating a cube mesh and a texture made from a plain color image 
	// then making a model from a mesh and adding a texture to it
	Image image = GenImageColor(8, 8, Colors.GREEN);
	Texture texture = LoadTextureFromImage(image);
 	Mesh playerMesh = GenMeshCube(1.0f, 1.0f, 2.0f);

	UnloadImage(image);

	Model playerModel = LoadModelFromMesh(playerMesh);
	playerModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture;
	
	Vector3 playerSpawn = { 0.0f, 0.5f, 0.0f };
	
	PlayerControls controls = new PlayerControls();
	controls.forward = KeyboardKey.KEY_W;
	controls.backwards = KeyboardKey.KEY_S;
	controls.right = KeyboardKey.KEY_D;
	controls.left = KeyboardKey.KEY_A;
	controls.shoot = KeyboardKey.KEY_SPACE;

	return new Player(playerModel, playerSpawn, controls);
}

void unloadPlayer(Player player)
{
	UnloadTexture(player.model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture);
	UnloadModel(player.model);
}

class Player
{
	Vector3 position;
	Vector3 rotationalAxis = { y:1.0f };
	float angle = 0;

	float movementSpeed = 2.0f;
	float rotationSpeed = 2.0f;

	int shouldMove = false;
	int shouldRotate = false;

	PlayerControls controls;
	PlayerCamera playerCamera;
	Model model;

	Vector3 landingPoint;

	this(Model model, Vector3 position, PlayerControls controls)
	{
		this.model = model;
		this.controls = controls;

		this.position = position;
		landingPoint = position;

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
		input();

		// Moving
		// shouldMove and should rotate can be (1 | -1 | 0)
		this.position.x += shouldMove * sin(angle) * movementSpeed * delta;
		this.position.z += shouldMove * cos(angle) * movementSpeed * delta;

		angle += shouldRotate * rotationSpeed * delta;

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

	private void input()
	{
		shouldMove = 0;
		shouldRotate = 0;
		if (IsKeyDown(controls.backwards))
		{
			shouldMove = -1;
		}

		if (IsKeyDown(controls.forward))
		{
			shouldMove = 1;
		}

		if (IsKeyDown(controls.right))
		{
			shouldRotate = -1;
		}

		if (IsKeyDown(controls.left))
		{
			shouldRotate = 1;
		}

		if (IsKeyDown(controls.shoot))
		{
			writeln(landingPoint);
			landingPoint.x = position.x + 2;
			landingPoint.z = position.z + 2;
		} else if (IsKeyReleased(controls.shoot)){
			landingPoint = position;
			writeln("shooting");
		}
	}

	/* 
		While holding shoot button, the landing point on the ground will show 
		where the bullet will fall will and the point will move on
		the ground forwards
		When button is released, the circle will disapear and the bullet will be
		spawned and will follow the rajectory to the landing point
	*/
	private void shoot()
	{

	}
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
		float rotationAmount = currMousePosition.x - prevMousePosition.x;
		Matrix rotationMatrix = MatrixRotateY(rotationAmount * delta);

		// rotate the distance to target 
		cameraDistance = Vector3Transform(cameraDistance, rotationMatrix);
		// add rotated distance to target and set it to current possiton
		this.camera.position = Vector3Add(camera.target, cameraDistance);

		UpdateCamera(&camera);
	}
}

class PlayerControls
{
	int forward;
	int backwards;
	int right;
	int left;
	int shoot;
}