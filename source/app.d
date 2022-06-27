import raylib :WindowShouldClose;

import game;

void main()
{
	gameLoad();

	while (!WindowShouldClose())
	{
		gameInput();
		gameUpdate();
		gameDraw();
	}

	gameUnload();
}
