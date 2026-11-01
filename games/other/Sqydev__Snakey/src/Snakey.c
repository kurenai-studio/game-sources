#include <raylib.h>
#include <stdbool.h>

bool IsVector2Equal(Vector2 v1, Vector2 v2) {
	return v1.x == v2.x && v1.y == v2.y;
}

Vector2 SumVector2(Vector2 v1, Vector2 v2) {
	Vector2 RETURNER = {v1.x + v2.x, v1.y + v2.y};
	return RETURNER;
}

float WindowWidth = 640.0f;
float WindowHight = 640.0f;
float WindowScale = 1.0f;

int main() {
	//Colors palete
	Color EBitDarkBrown = (Color){68, 34, 0, 255};
	Color EBitBrown = (Color){136, 68, 0, 255};
	Color EBitRed = (Color){204, 0, 0, 255};
	Color EBitGreen = (Color){68, 102, 0, 255};
	Color EBitDarkGreen = (Color){0, 68, 0, 255};
	Color EBitBlue = (Color){34, 34, 238, 255};
	Color EBitDarkBlue = (Color){0, 34, 136, 255};

	InitWindow(WindowWidth * WindowScale, WindowHight * WindowScale, "Snakey");
	SetTargetFPS(165);

	//Make game screen
	RenderTexture2D GameScreen = LoadRenderTexture(16, 16);
	//Make is so It's not blured
	SetTextureFilter(GameScreen.texture, TEXTURE_FILTER_POINT);

	float Difficulty = 3.0f;

	int TailSize = 0;

	Vector2 PlayerDirThisScreen;
	Vector2 PlayerDir = {1, 0};
	Vector2 PlayerPos[256];
	PlayerPos[0].x = 4;
	PlayerPos[0].y = 7;

	Vector2 ApplePos;
	ApplePos.x = GetRandomValue(0, 15);
	ApplePos.y = GetRandomValue(0, 15);

	float elapsedTime = 0.0f;

	bool IsRunning = true;

	while(!WindowShouldClose()) {
		//Calculations
		if(IsRunning) {
			//Do things as delta time, MouseWheelDelta and elapsedTime
			float dt = GetFrameTime();
			float MouseWheelDelta = GetMouseWheelMoveV().y;
			elapsedTime += dt;

			//Calcs to make only one time a sec(or less)
			if(elapsedTime >= 1.0f / Difficulty) {
				//Movement seftey
				PlayerDirThisScreen = PlayerDir;

				//Apple Collision
				if(IsVector2Equal(PlayerPos[0], ApplePos)) {
					ApplePos.x = GetRandomValue(0, 15);
					ApplePos.y = GetRandomValue(0, 15);
				
					if(TailSize < 256) TailSize++;
					else IsRunning = false;
				}
				else {
					for(int i = 0; i < 256; i++) {
						if(IsVector2Equal(PlayerPos[i], ApplePos)) {
							ApplePos.x = GetRandomValue(0, 15);
							ApplePos.y = GetRandomValue(0, 15);
						}
					}
				}

				//New tail maker
				for(int i = TailSize; i != 0; i--) {
					PlayerPos[i].x = PlayerPos[i - 1].x;
					PlayerPos[i].y = PlayerPos[i - 1].y;
				}
				PlayerPos[0] = SumVector2(PlayerPos[0], PlayerDir);

				
				//This one checks if you touched yourself and if so you dies
				for(int i = 1; i < TailSize; i++) {
					if(IsVector2Equal(PlayerPos[0], PlayerPos[i])) IsRunning = false;
				}
			
				elapsedTime -= 1.0f / Difficulty;
			}

			//Movement everything self expenencial
			if(IsKeyDown(KEY_A) && PlayerDirThisScreen.x != 1) {
				PlayerDir.x = -1;
				PlayerDir.y = 0;
			}
			if(IsKeyDown(KEY_W) && PlayerDirThisScreen.y != 1) {
				PlayerDir.x = 0;
				PlayerDir.y = -1;
			}
			if(IsKeyDown(KEY_D) && PlayerDirThisScreen.x != -1) {
				PlayerDir.x = 1;
				PlayerDir.y = 0;
			}
			if(IsKeyDown(KEY_S) && PlayerDirThisScreen.y != -1) {
				PlayerDir.x = 0;
				PlayerDir.y = 1;
			}

			//Out of bounce collision check and reaction
			if(PlayerPos[0].x == 16) PlayerPos[0].x = 0;
			if(PlayerPos[0].x == -1) PlayerPos[0].x = 15;
			if(PlayerPos[0].y == 16) PlayerPos[0].y = 0;
			if(PlayerPos[0].y == -1) PlayerPos[0].y = 15;

			//Difficulty input thing
			if(MouseWheelDelta >= 0.0f) Difficulty += 0.5;
			if(MouseWheelDelta <= 0.0f && Difficulty > 1.0f) Difficulty -= 0.5;
		}

		//GameScreen Drawing
		BeginTextureMode(GameScreen);
		//Clear
		ClearBackground(EBitBrown);
		
		//Do chessboard thing
		for(int i = 0; i < 16; i++) {
			for(int j = 0; j < 16; j++) {
				if(i == 0 || i == 15 || j == 0 || j == 15) DrawPixel(i, j, EBitDarkBrown);
			}
		}

		DrawPixelV(ApplePos, EBitRed);
		
		for(int i = 1; i <= TailSize; i++) {
			if(i % 2) DrawPixelV(PlayerPos[i], EBitDarkGreen);
			else DrawPixelV(PlayerPos[i], EBitGreen);
		}

		DrawPixelV(PlayerPos[0], EBitBlue);

		if(!IsRunning) {
			//Do score showing thing
			for(int i = 0; i <= 7; i++) {
				if(IsMouseButtonPressed(i)) {
					TailSize = 0;
					PlayerPos[0].x = 4;
					PlayerPos[0].y = 7;
					IsRunning = true;
				}
			}
		}

		EndTextureMode();


		//GameScreen to Window Drawing
		BeginDrawing();
		ClearBackground(WHITE);

		DrawTexturePro(
    		GameScreen.texture,
    		(Rectangle){ 0, 0, 16, -16 },
			(Rectangle){ 0, 0, 640, 640 },
			(Vector2){ 0, 0 },
    		0.0f,
    		WHITE
		);
		EndDrawing();
	}

	CloseWindow();

	return 0;
}
