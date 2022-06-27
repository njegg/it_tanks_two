module playerm;

import std.math : sin, cos;
import std.stdio : writeln;

import raylib;

import utilm;
import vars;
import projectilem;

Player loadPlayer(int number, Color color, PlayerControls controls, Vector3 spawnPosition)
{
	// creating a cube mesh and a texture made from a plain color image 
	// then making a model from a mesh and adding a texture to it
	Image image = GenImageColor(8, 8, color);
	Texture texture = LoadTextureFromImage(image);
 	Mesh playerMesh = GenMeshCube(1.0f, 0.6, 2.0f);

	UnloadImage(image);

	Model playerModel = LoadModelFromMesh(playerMesh);
	playerModel.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture = texture;
	
	return new Player(number, playerModel, spawnPosition, controls);
}

void unloadPlayer(Player player)
{
	UnloadTexture(player.model.materials[0].maps[MATERIAL_MAP_DIFFUSE].texture);
	UnloadModel(player.model);
}

class Player
{
	Vector3 position;
	Vector3 velocity;
	Vector3 rotationalAxis = { y:1.0f };
	float angle = 0;

	float movementSpeed = 2.0f;
	float rotationSpeed = 2.0f;
    float barrelTiltSpeed = 0.04f;

	int shouldMove = false;
	int shouldRotate = false;

	float jumpForce = 0.05f ;
	bool isGrounded = false;

	PlayerControls controls;
	PlayerCamera playerCamera;
	Model model;

	int playerNumber;

	BoundingBox hitbox;

    LandingPoint landingPoint;
    float shootHoldTime = 0;
	Vector3 projectileSpawn = { 0.0f, 0.7f, 0.0f };

    Vector2 cameraXY, playerXY;             // Used for angle calculation

	this(int number, Model model, Vector3 position, PlayerControls controls)
	{
		this.model = model;
		this.controls = controls;
		this.playerNumber = number;

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
		// Moving
		// shouldMove and should rotate can be (1 | -1 | 0)
		position.x += shouldMove * sin(angle) * movementSpeed * delta;
		position.z += shouldMove * cos(angle) * movementSpeed * delta;

		velocity.y += gravity * (delta * delta);
		position.y += velocity.y;
		

		// Will do for now
		if (position.y <= 0.3) 
		{
			position.y = 0.3;
			velocity.y = 0;
			isGrounded = true;
		}

		angle += shouldRotate * rotationSpeed * delta;
		fixAngleRad(&angle);

		// Camera Update
		playerCamera.camera.target = position;

		float rotationAmount = 0;
		if (controls.isGamepad)
		{
			rotationAmount = GetGamepadAxisMovement(0, GamepadAxis.GAMEPAD_AXIS_RIGHT_X);
			rotationAmount *= playerCamera.controllerSensitivity;
		}
		else
		{
			rotationAmount = currMousePosition.x - prevMousePosition.x;
			rotationAmount *= playerCamera.mouseSensitivity;
		}

		Matrix rotationMatrix = MatrixRotateY(rotationAmount * delta);

		// rotate the distance to target 
		playerCamera.relativePosition = Vector3Transform(playerCamera.relativePosition, rotationMatrix);
		// add rotated distance to target and set it to current possiton
		playerCamera.camera.position = Vector3Add(playerCamera.camera.target, playerCamera.relativePosition);

		UpdateCamera(&playerCamera.camera);
	}

	void draw(bool isControling)
	{
		float angleDeg = angle * RAD2DEG;
		DrawModelEx(model, position, rotationalAxis, angleDeg, Vector3One(), Colors.WHITE);
		DrawModelWiresEx(model, position, rotationalAxis, angleDeg, Vector3One(), Colors.BLACK);

		DrawBoundingBox(hitbox, Colors.LIME);

        if (landingPoint.visible && isControling)
        {
            DrawSphere(landingPoint.position, 0.2f, landingPoint.color);
        }
	}

	void input()
	{
		shouldMove = 0;
		shouldRotate = 0;
		if (IsKeyDown(controls.backwards) || IsGamepadButtonDown(0, controls.backwards))
		{
			shouldMove = -1;
		}

		if (IsKeyDown(controls.forward) || IsGamepadButtonDown(0, controls.forward))
		{
			shouldMove = 1;
		}

		if (IsKeyDown(controls.right) || IsGamepadButtonDown(0, controls.right))
		{
			shouldRotate = -1;
		}

		if (IsKeyDown(controls.left) || IsGamepadButtonDown(0, controls.left))
		{
			shouldRotate = 1;
		}

        // Shooting
        // TODO: maybe put the logic in seperate function: aim()
        if (IsKeyPressed(controls.shoot) || IsGamepadButtonPressed(0, controls.shoot))
        {
            // spawining landing point in front of player where camera is looging
            landingPoint.position = position;
            landingPoint.position.x += cos(cameraAngleRad()) * 4;
            landingPoint.position.z += sin(cameraAngleRad()) * 4;
            landingPoint.position.y = 0;

            landingPoint.color = Colors.WHITE;

            landingPoint.visible = true;
            landingPoint.shootByWaiting = false;
        }
        else if (
			(IsKeyReleased(controls.shoot) || IsGamepadButtonReleased(0, controls.shoot)) 
			&& !landingPoint.shootByWaiting)
		{
			landingPoint.visible = false;
            shootHoldTime = 0;
            shoot();
		}

        /*  
         *  While holding shoot button, the landing point on the ground will show 
         *  where the bullet will fall will and the point will move on
         *  the ground forwards
         *  When button is released, the circle will disapear and the bullet will be
         *  spawned and will follow the trajectory to the landing point
         */
		if (IsKeyDown(controls.shoot) || IsGamepadButtonDown(0, controls.shoot))
		{
            if (shootHoldTime > landingPoint.maxHoldTime)
            {
                landingPoint.visible = false;
                shootHoldTime = 0;
                shoot();
                landingPoint.shootByWaiting = true;
            }

            // New point is made like this:
            //   - geting the distance to it
            //   - adding some distance
            //   - rotating a vector with that magnitude by
            //     camera angle using Quaternion that rotates
            //     it around y axis (yaw)
            float dist = Vector3Distance(landingPoint.position, position);

			// TODO: event when adding *delta, fps is afecting the amount
            if (dist < landingPoint.limit)
            {
                dist += barrelTiltSpeed;
            }
            else 
            {
                landingPoint.color = Colors.RED;
                shootHoldTime += GetFrameTime();
            }            

            Vector3 newPos = { dist, 0, 0 };
            newPos = Vector3RotateByQuaternion(
                newPos,
                QuaternionFromEuler(0, -cameraAngleRad(), 0)
            );

            landingPoint.position = Vector3Add(newPos, position);
            
            // newPos = Vector3Add(newPos, position);
            // landingPoint.position = Vector3Lerp(landingPoint.position, newPos, 0.1);

            landingPoint.position.y = 0;
		}
		
		if (isGrounded && IsKeyPressed(controls.jump))
		{
			jump();
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

	private void jump()
	{
		velocity.y += jumpForce;
		isGrounded = false;
	}

	private void shoot()
	{
		Projectile projectile = new Projectile(
			playerNumber == 1 ? colorOneLight : colorTwoLight,
			Vector3Add(position, projectileSpawn),
			landingPoint.position,
			0.5f
		);
		projectile.player = playerNumber;

		projectiles.insertFront(projectile);
	}
}

class PlayerCamera
{
	Camera3D camera;
	Vector3 relativePosition;
	float mouseSensitivity = 0.2;
	float controllerSensitivity = 4;

	this(Camera3D camera)
	{
		this.camera = camera;
		relativePosition = cameraDistance;
	}
}

class PlayerControls
{
	int forward;
	int backwards;
	int right;
	int left;
	int shoot;
	int jump;
	bool isGamepad;
}

class LandingPoint
{
    Vector3 position;
    Color color;
    bool visible;
    
    float limit = 16.0f;
    float maxHoldTime = 2.0f;
    bool shootByWaiting;
     
    this(Color color, Vector3 position)
    {
        this.position = position;
        this.color = color;
    }
}
