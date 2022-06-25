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
	Image image = GenImageColor(8, 8, Colors.ORANGE);
	Texture texture = LoadTextureFromImage(image);
 	Mesh playerMesh = GenMeshCube(1.0f, 0.7f, 2.0f);

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
    float barrelTiltSpeed = 0.05f;

	int shouldMove = false;
	int shouldRotate = false;

	PlayerControls controls;
	PlayerCamera playerCamera;
	Model model;

    LandingPoint landingPoint;
    float shootHoldTime = 0;
    Vector2 cameraXY, playerXY;             // Used for angle calculation

	this(Model model, Vector3 position, PlayerControls controls)
	{
		this.model = model;
		this.controls = controls;

		this.position = position;

		Vector3 cameraPosition = Vector3Add(position, cameraDistance);

		Camera3D camera =
		{
			position: 	cameraPosition,
			target: 	this.position,
			up:			{ x:0.0f, y:2.0f, z:0.0f },
			fovy: 		40.0f,
			projection: CameraProjection.CAMERA_PERSPECTIVE,
		};
		SetCameraMode(camera, CameraMode.CAMERA_CUSTOM);
		
		this.playerCamera = new PlayerCamera(camera);

        this.landingPoint = new LandingPoint(Colors.WHITE, this.position);
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

        if (landingPoint.visible)
        {
            DrawSphere(landingPoint.position, 0.2f, landingPoint.color);
        }
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

        // Shooting
        // TODO: maybe put the logic in seperate function: aim()
        if (IsKeyPressed(controls.shoot))
        {
            // spawining landing point in front of player where camera is looging
            landingPoint.position = position;
            landingPoint.position.x += cos(cameraAngleRad()) * 4;
            landingPoint.position.z += sin(cameraAngleRad()) * 4;
            landingPoint.position.y = 0;

            landingPoint.color = Colors.WHITE;

            landingPoint.visible = true;
        }
        else if (IsKeyReleased(controls.shoot)){
			landingPoint.visible = false;
            shootHoldTime = 0;
            shoot();
		}

        /*  While holding shoot button, the landing point on the ground will show 
         *  where the bullet will fall will and the point will move on
         *  the ground forwards
         *  When button is released, the circle will disapear and the bullet will be
         *  spawned and will follow the trajectory to the landing point
         */
		if (IsKeyDown(controls.shoot))
		{
            float dist = Vector3Distance(landingPoint.position, position);
            dist += barrelTiltSpeed;

            Vector3 newPos = { dist, 0, 0 };
            newPos = Vector3RotateByQuaternion(
                newPos,
                QuaternionFromEuler(0, -cameraAngleRad(), 0)
            );

            landingPoint.position = Vector3Add(newPos, position);
            landingPoint.position.y = 0;
            /*
            Vector2 newPos;     // New landing point position 

            // Vector from player to camera
            newPos = Vector2Subtract(cameraXY, playerXY); 

            // That vector inverted and normalised
            newPos = Vector2Normalize(Vector2Negate(newPos));

            // Scaling it based on hold time
            newPos = Vector2Scale(newPos, shootHoldTime * barrelTiltSpeed);

            // Adding it to player we get a point in front of player
            // from cameras perspective 
            newPos = Vector2Add(playerXY, newPos);
            
            // Starts in fron of the player
            newPos.x += cos(cameraAngleRad()) * 4;
            newPos.y += sin(cameraAngleRad()) * 4;

            // Update to new pos only if the new pos is smaller than the limmit
            if (Vector2Distance(playerXY, newPos) <= landingPoint.limit)
            {
                Vector3 newPosVec3 = { newPos.x, 0, newPos.y };
                landingPoint.position = Vector3Lerp(landingPoint.position, newPosVec3, 0.1);
            } else {
                landingPoint.color = Colors.RED;
            }
            */
		}
    }

    float cameraAngleRad()
    {
        cameraXY.x = playerCamera.camera.position.x;
        cameraXY.y = playerCamera.camera.position.z;

        playerXY.x = position.x;
        playerXY.y = position.z;

        return DEG2RAD * Vector2Angle(cameraXY, playerXY);
    }
 
	private void shoot()
	{
        writeln("shooting");
	}
}

class PlayerCamera
{
	Camera3D camera;
	float sensitivity = 0.2;

	this(Camera3D camera)
	{
		this.camera = camera;
	}

	void update(float delta)
	{
		float rotationAmount = currMousePosition.x - prevMousePosition.x;
		Matrix rotationMatrix = MatrixRotateY(rotationAmount * delta * sensitivity);

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

class LandingPoint
{
    Vector3 position;
    Color color;
    bool visible;
    
    float limit = 10.0f;
     
    this(Color color, Vector3 position)
    {
        this.position = position;
        this.color = color;
    }
}
