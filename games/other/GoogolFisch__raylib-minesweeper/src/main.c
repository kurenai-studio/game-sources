#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include"raylib.h"



struct Data{
	char *field;
	int width;
	int height;
	double time;
	int mines;   // mine count!
	int selfMin; // mines to Flag!
	int pixSize;
	int selectX;
	int selectY;
	int selecting;
	int uncoved;
	int xOff;
	int yOff;
	char dead;
	char succ;
	char isFirst;
	long long seed;
	Image *imageStack;
	Texture2D *textStack;
};

int rander(struct Data *d){
	d->seed = d->seed * 53681 + 37619;
	return d->seed;
}

void setup(struct Data *d){
	SetWindowSize(
			7 * d->width * d->pixSize + d->xOff * 2,
			7 * d->height * d->pixSize + d->yOff + d->pixSize
			);
	free(d->field);
	int sz = sizeof(char) * d->width * d->height;
	d->field = malloc(sz);
	memset(d->field,0,sz);
	int trys = 0;
	int bombCount = 0;
	int val = 0;
	for(bombCount = 0;bombCount < d->mines;bombCount++){
st_ret:
		if(trys++ > 30)
			goto st_br;
		val = rander(d) % sz;
		if(d->field[val])
			goto st_ret;
		d->field[val] = 64;
	}
st_br: // changing bombcount to reflect!
	d->mines = bombCount;

	d->selfMin = d->mines;
	printf("Mines:%d\n",d->mines);
	d->uncoved = 0;
	d->dead = 0;
	d->succ = 0;
	d->isFirst = 0;
	d->time = 0.0;
}
void reset(struct Data *d){
	d->field = malloc(0);
	d->width = 9;
	d->height = 9;
	d->mines = 10;
	d->pixSize = 6;
	d->selectX = 0;
	d->selectY = 0;
	d->selecting = 0;
	d->xOff = d->pixSize;
	d->yOff = d->pixSize * 10;
	d->imageStack = malloc(sizeof(Image) * 12);
	d->textStack = malloc(sizeof(Texture2D) * 12);
	for(int i = 0;i < 12;i++){
		d->imageStack[i] = GenImageColor(7,7,LIGHTGRAY);
	}
	ImageDrawPixel    (&d->imageStack[1],2,2,    BLUE);
	ImageDrawRectangle(&d->imageStack[1],3,1,1,4,BLUE);
	ImageDrawRectangle(&d->imageStack[1],2,5,3,1,BLUE);
	ImageDrawRectangle(&d->imageStack[2],2,1,2,1,LIME);
	ImageDrawPixel    (&d->imageStack[2],4,2,    LIME);
	ImageDrawPixel    (&d->imageStack[2],3,3,    LIME);
	ImageDrawPixel    (&d->imageStack[2],2,4,    LIME);
	ImageDrawRectangle(&d->imageStack[2],2,5,3,1,LIME);
	ImageDrawRectangle(&d->imageStack[3],2,1,2,1,RED );
	ImageDrawRectangle(&d->imageStack[3],2,3,2,1,RED );
	ImageDrawRectangle(&d->imageStack[3],2,5,2,1,RED );
	ImageDrawRectangle(&d->imageStack[3],4,1,1,5,RED );
	ImageDrawRectangle(&d->imageStack[4],2,1,1,3,DARKBLUE);
	ImageDrawPixel    (&d->imageStack[4],3,3,    DARKBLUE);
	ImageDrawRectangle(&d->imageStack[4],4,1,1,5,DARKBLUE);
	ImageDrawRectangle(&d->imageStack[5],2,1,3,1,BROWN);
	ImageDrawPixel    (&d->imageStack[5],2,2,    BROWN);
	ImageDrawRectangle(&d->imageStack[5],2,3,3,1,BROWN);
	ImageDrawPixel    (&d->imageStack[5],4,4,    BROWN);
	ImageDrawRectangle(&d->imageStack[5],2,5,2,1,BROWN);
	ImageDrawRectangle(&d->imageStack[6],3,1,2,1,SKYBLUE);
	ImageDrawRectangle(&d->imageStack[6],2,2,1,4,SKYBLUE);
	ImageDrawRectangle(&d->imageStack[6],4,3,1,3,SKYBLUE);
	ImageDrawPixel    (&d->imageStack[6],3,3,    SKYBLUE);
	ImageDrawPixel    (&d->imageStack[6],3,5,    SKYBLUE);
	ImageDrawRectangle(&d->imageStack[7],2,1,3,1,BLACK);
	ImageDrawRectangle(&d->imageStack[7],4,2,1,4,BLACK);
	ImageDrawPixel    (&d->imageStack[7],3,3,    BLACK);
	ImageDrawRectangle(&d->imageStack[8],2,1,1,5,GRAY);
	ImageDrawRectangle(&d->imageStack[8],4,1,1,5,GRAY);
	ImageDrawPixel    (&d->imageStack[8],3,1,    GRAY);
	ImageDrawPixel    (&d->imageStack[8],3,3,    GRAY);
	ImageDrawPixel    (&d->imageStack[8],3,5,    GRAY);

	ImageDrawRectangle(&d->imageStack[ 9],0,0,7,7,DARKGRAY);
	ImageDrawRectangle(&d->imageStack[ 9],1,1,5,5,GRAY);
	ImageDrawRectangle(&d->imageStack[10],0,0,7,7,DARKGRAY);
	ImageDrawRectangle(&d->imageStack[10],2,5,3,1,BLACK);
	ImageDrawRectangle(&d->imageStack[10],3,3,1,2,BLACK);
	ImageDrawRectangle(&d->imageStack[10],2,1,2,2,RED);
	ImageDrawRectangle(&d->imageStack[11],2,2,3,3,BLACK);
	ImageDrawPixel    (&d->imageStack[11],1,1,    BLACK);
	ImageDrawPixel    (&d->imageStack[11],3,1,    BLACK);
	ImageDrawPixel    (&d->imageStack[11],5,1,    BLACK);
	ImageDrawPixel    (&d->imageStack[11],5,3,    BLACK);
	ImageDrawPixel    (&d->imageStack[11],1,5,    BLACK);
	ImageDrawPixel    (&d->imageStack[11],3,5,    BLACK);
	ImageDrawPixel    (&d->imageStack[11],5,5,    BLACK);
	ImageDrawPixel    (&d->imageStack[11],1,3,    BLACK);
	for(int i = 0;i < 12;i++){
		d->textStack[i] = LoadTextureFromImage(d->imageStack[i]);
		UnloadImage(d->imageStack[i]);
	}
	setup(d);
}

int fdCount(struct Data *d,int x,int y){
	char hasHit = 0;
	// -1 for this is a mine, and 0 for no near!
	if(d->field[x + y * d->width] & 64){
		if(!d->isFirst){
			d->field[x + y * d->width] = 0;
		}else
			return -1;
	}
	char bound = 0;
	int cou = 0;
	bound |= (x <= 0) << 1;
	bound |= (y <= 0) << 2;
	bound |= (x >= d->width - 1) << 3;
	bound |= (y >= d->height - 1) << 4;
	if(!(bound &  6) && (d->field[(x - 1) + (y - 1) * d->width] & 64))cou++;
	if(!(bound &  4) && (d->field[(x    ) + (y - 1) * d->width] & 64))cou++;
	if(!(bound & 12) && (d->field[(x + 1) + (y - 1) * d->width] & 64))cou++;
	if(!(bound &  8) && (d->field[(x + 1) + (y    ) * d->width] & 64))cou++;
	if(!(bound & 24) && (d->field[(x + 1) + (y + 1) * d->width] & 64))cou++;
	if(!(bound & 16) && (d->field[(x    ) + (y + 1) * d->width] & 64))cou++;
	if(!(bound & 18) && (d->field[(x - 1) + (y + 1) * d->width] & 64))cou++;
	if(!(bound &  2) && (d->field[(x - 1) + (y    ) * d->width] & 64))cou++;
	if(hasHit){
		int trys = 0;
		int val;
		int sz = d->width * d->height;
fdC_ret:
		if(trys++ > 30)goto fdC_out;
		val = random() % sz;
		if(d->field[val])
			goto fdC_ret;
		d->field[val] = 64;
	}
fdC_out:
	d->isFirst |= 1;
	return cou;
}
void uncover(struct Data *d,int x,int y){
	if(x < 0)return;
	if(y < 0)return;
	if(y >= d->height)return;
	if(x >= d->width )return;
	if(!(d->field[x + y * d->width] & 160)) {
		int cou = fdCount(d,x,y);
		d->field[x + y * d->width] = cou + 128;
		d->uncoved++;
		if(cou == -1)d->dead |= 1;
		if(cou == 0){
			uncover(d,x - 1,y - 1);
			uncover(d,x    ,y - 1);
			uncover(d,x + 1,y - 1);
			uncover(d,x + 1,y    );
			uncover(d,x + 1,y + 1);
			uncover(d,x    ,y + 1);
			uncover(d,x - 1,y + 1);
			uncover(d,x - 1,y    );
		}
	}
}
int flagCou(struct Data *d, int x,int y){
	if(d->field[x + y * d->width] & 64){
		return -1;
	}
	char bound = 0;
	int cou = 0;
	bound |= (x <= 0) << 1;
	bound |= (y <= 0) << 2;
	bound |= (x >= d->width - 1) << 3;
	bound |= (y >= d->height - 1) << 4;
	if(!(bound &  6) && (d->field[(x - 1) + (y - 1) * d->width] & 32))cou++;
	if(!(bound &  4) && (d->field[(x    ) + (y - 1) * d->width] & 32))cou++;
	if(!(bound & 12) && (d->field[(x + 1) + (y - 1) * d->width] & 32))cou++;
	if(!(bound &  8) && (d->field[(x + 1) + (y    ) * d->width] & 32))cou++;
	if(!(bound & 24) && (d->field[(x + 1) + (y + 1) * d->width] & 32))cou++;
	if(!(bound & 16) && (d->field[(x    ) + (y + 1) * d->width] & 32))cou++;
	if(!(bound & 18) && (d->field[(x - 1) + (y + 1) * d->width] & 32))cou++;
	if(!(bound &  2) && (d->field[(x - 1) + (y    ) * d->width] & 32))cou++;
	return cou;
}

void update(double dt,struct Data *d){
	int sz = d->pixSize * 7;
	int xOff = d->xOff;
	int yOff = d->yOff;
	int mx = GetMouseY();
	int my = GetMouseX();
	if(d->isFirst && !(d->succ || d->dead))
		d->time += dt;
	if(mx < yOff)goto u_other;
	mx = (mx - yOff) / sz;
	my = (my - xOff) / sz;
	if(mx >= d->width)return;
	if(my >= d->height)return;
	d->selectX = mx;
	d->selectY = my;
	
	if(IsMouseButtonPressed(0) && !d->dead){
		d->selecting = 1;
	}else if(d->selecting){
		d->selecting = 0;
		int num = (unsigned char)d->field[mx + my * d->width];
		if(num & 128){
			int flg = flagCou(d,mx,my);
			printf("n:%d,f:%d\n",num & 127,flg);
			if(flg != (num & 127))goto u_flg;
			uncover(d,mx - 1,my - 1);
			uncover(d,mx    ,my - 1);
			uncover(d,mx + 1,my - 1);
			uncover(d,mx + 1,my    );
			uncover(d,mx + 1,my + 1);
			uncover(d,mx    ,my + 1);
			uncover(d,mx - 1,my + 1);
			uncover(d,mx - 1,my    );
		}
		uncover(d,mx,my);
		if(d->uncoved == (d->width * d->height - d->mines)){
			d->succ = 1;
		}
	}
u_flg:
	if(IsMouseButtonPressed(1) && !d->dead){
		if(d->field[mx + my * d->width] & 128)return;
		if(d->field[mx + my * d->width] & 32)
			d->field[mx + my * d->width] &= 223;
		else
			d->field[mx + my * d->width] |= 32;
	}
	return;
u_other:
	if(IsMouseButtonPressed(0)){
		setup(d);
	}
}

void drawTile(struct Data *d,char tile,int x,int y){
	int s = d->pixSize;
	int sz = s * 7;
	Vector2 pos;
	pos.x = (float)(x * sz + d->xOff);
	pos.y = (float)(y * sz + d->yOff);
	Vector2 size;
	size.y = size.x = (float)sz;
	switch((unsigned char)tile){
		case 96:
		case 32:
			DrawTextureEx(d->textStack[10],pos,0.0f,d->pixSize,WHITE);
			break;
		case 127:
		case 192:
			DrawRectangleV(pos,size,RED);
			break;
		case 64:
			if(d->dead) {
				DrawTextureEx(d->textStack[11],pos,0.0f,d->pixSize,WHITE);
				break;
			}
		case 0:
			DrawTextureEx(d->textStack[9],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 0:
			DrawTextureEx(d->textStack[0],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 1:
			DrawTextureEx(d->textStack[1],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 2:
			DrawTextureEx(d->textStack[2],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 3:
			DrawTextureEx(d->textStack[3],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 4:
			DrawTextureEx(d->textStack[4],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 5:
			DrawTextureEx(d->textStack[5],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 6:
			DrawTextureEx(d->textStack[6],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 7:
			DrawTextureEx(d->textStack[7],pos,0.0f,d->pixSize,WHITE);
			break;
		case 128 + 8:
			DrawTextureEx(d->textStack[8],pos,0.0f,d->pixSize,WHITE);
			break;
		default:
			printf("%d ",tile);
			break;
	}
}
char *conv2Str(int value){
	int valLog = 2;
	for(int vlog = value;vlog > 10;vlog /= 10){
		valLog++;
	}
	char *save = malloc(sizeof(char) * valLog);
	int catch = value;
	save[valLog] = '\0';
	while(valLog > 0){
		valLog--;
		save[valLog] = 48 | (catch % 10);
		catch /= 10;
	}
	return save;
}
void draw(struct Data *d){
	if(d->dead)
		ClearBackground(ORANGE);
	else if(d->succ)
		ClearBackground(SKYBLUE);
	else
		ClearBackground(WHITE);
	char *tak = conv2Str(d->selfMin);
	DrawText(tak,d->pixSize,d->pixSize,d->pixSize * 5,RED);
	free(tak);
	int curTime = (int)d->time;
	tak = conv2Str(curTime);
	DrawText(tak,d->xOff + (d->width >> 1) * 7 * d->pixSize,d->pixSize,d->pixSize * 5,RED);
	free(tak);
	int tile = 0;
	for(int runX = 0;runX < d->width;runX++){
		for(int runY = 0;runY < d->height;runY++){
			drawTile(d,d->field[tile++],runX,runY);
		}
	}
	
}

int main(int argl,char **argv){
	const int screenWidth = 400;
	const int screenHeight = 200;
	double dTime = 0.0;
	struct Data *g = malloc(sizeof(struct Data));
	memset(g,0,sizeof(struct Data));
	
	InitWindow(screenWidth,screenHeight,"Hello");
	SetTargetFPS(60);
	reset(g);
	while(!WindowShouldClose()){
		dTime = GetFrameTime();
		update(dTime,g);
		BeginDrawing();
		ClearBackground(RAYWHITE);
		draw(g);
		EndDrawing();
	}
	CloseWindow();
	return 0;
}
