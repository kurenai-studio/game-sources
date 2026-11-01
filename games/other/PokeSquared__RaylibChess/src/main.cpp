#include <iostream>
#include <cstdlib>
#include <algorithm>
#include <string>
#include <fstream>
#include <thread>
#include <chrono>
#include "chess.hpp"
#include "raylib.h"

using namespace std;

vector<int> gameover = {0,0}; // [0] = state (0 = not lost, 1 = lost, 2 = check) , [1] = color (0 = white, 1 = black)

const int screenWidth = 800;
const int screenHeight = 900;

Vector2 tomove[100];
int moveindex = 0;


void checkcheck(ChessManager game) {
    if (game.sidechecked(PWHITE)) {

            if (game.sidecheckmate(PWHITE)) {
                gameover = {1,1};
            }
            else {
                gameover = { 2,1 };
            }
        }

        if (game.sidechecked(PBLACK)) {

            if (game.sidecheckmate(PBLACK)) {
                gameover = {1,0};
            }
            else {
                gameover = { 2,0 };
            }
        }
}

void checkerboard() {
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {

            if ((i + j) % 2 == 0) {
                DrawRectangle(i * 100, j * 100, 100, 100, BEIGE);
            }
            else {
                DrawRectangle(i * 100, j * 100, 100, 100, DARKBROWN);
            }
        }
    }
}

void highlight(Vector2 pos) {

    int x = (int)pos.x;
    int y = (int)pos.y;
    if (!(y == 8 and x > 4)) {
        if ((x + y) % 2 == 0) {
            DrawRectangle(x * 100, y * 100, 100, 100, Color{ 252, 223, 3 , 255 });
        }
        else {
            DrawRectangle(x * 100, y * 100, 100, 100, Color{ 237, 182, 0 , 255 });
        }
    }
}

void drawpieces(ChessManager game , Texture2D ptx[12]) {


    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {

            if (game.plist[game.find({ i,j })].color != NOCOL) {

                if (game.plist[game.find({ i,j })].color == PWHITE) {
                    switch (game.plist[game.find({ i,j })].type) {
                        case PAWN:
                            DrawTextureEx(ptx[9], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                            break;
                        case ROOK:
                            DrawTextureEx(ptx[11], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                            break;
                        case BISHOP:
                            DrawTextureEx(ptx[6], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                            break;
                        case KNIGHT:
                            DrawTextureEx(ptx[8], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                            break;
                        case QUEEN:
                            DrawTextureEx(ptx[10], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                            break;
                        case KING:
                            DrawTextureEx(ptx[7], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                            break;
                    }
                }
                else {
                    switch (game.plist[game.find({ i,j })].type) {
                    case PAWN:
                        DrawTextureEx(ptx[3], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                        break;
                    case ROOK:
                        DrawTextureEx(ptx[5], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                        break;
                    case BISHOP:
                        DrawTextureEx(ptx[0], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                        break;
                    case KNIGHT:
                        DrawTextureEx(ptx[2], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                        break;
                    case QUEEN:
                        DrawTextureEx(ptx[4], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                        break;
                    case KING:
                        DrawTextureEx(ptx[1], Vector2{ (float)(i * 100), (float)(j * 100) }, 0, (100.0 / 128.0), WHITE);
                        break;
                    }

                }
            }

        }
    }
}

void movehighlights(ChessManager game, vector<int> pos, int turn) {

    Piece piece = game.plist[game.find(pos)];
    moveindex = 0;


    if (piece.color != NOCOL) {

        if (piece.type != PAWN) {
            for (int i = 0; i < piece.offsets.size(); i++) {

                if (game.checkmove(piece, { pos[0] + piece.offsets[i][0] , pos[1] + piece.offsets[i][1] }, turn)) {

                    if (!game.preventcheck(turn, { pos[0] + piece.offsets[i][0] , pos[1] + piece.offsets[i][1] }, pos)) {
                        continue;
                    }


                    tomove[moveindex] = Vector2{ (float)(pos[0] + piece.offsets[i][0]) , (float)(pos[1] + piece.offsets[i][1]) };
                    moveindex += 1;

                    if (((pos[0] + piece.offsets[i][0]) + (pos[1] + piece.offsets[i][1])) % 2 == 0) {
                        DrawRectangle((pos[0] + piece.offsets[i][0]) * 100, (pos[1] + piece.offsets[i][1]) * 100, 100, 100, BLUE);
                    }
                    else {
                        DrawRectangle((pos[0] + piece.offsets[i][0]) * 100, (pos[1] + piece.offsets[i][1]) * 100, 100, 100, DARKBLUE);
                    }
                }

            }
        }
        else {

            if (game.checkmove(piece, { pos[0] + piece.offsets[0][0] , pos[1] + piece.offsets[0][1] }, turn)) {

                if (game.preventcheck(turn, { pos[0] + piece.offsets[0][0] , pos[1] + piece.offsets[0][1] }, pos)) {

                    tomove[moveindex] = Vector2{ (float)(pos[0] + piece.offsets[0][0]) , (float)(pos[1] + piece.offsets[0][1]) };
                    moveindex += 1;

                    if (((pos[0] + piece.offsets[0][0]) + (pos[1] + piece.offsets[0][1])) % 2 == 0) {
                        DrawRectangle((pos[0] + piece.offsets[0][0]) * 100, (pos[1] + piece.offsets[0][1]) * 100, 100, 100, BLUE);
                    }
                    else {
                        DrawRectangle((pos[0] + piece.offsets[0][0]) * 100, (pos[1] + piece.offsets[0][1]) * 100, 100, 100, DARKBLUE);
                    }

                }
            }

            for (int i = 0; i < piece.specoffsets.size(); i++) {

                if (game.checkmove(piece, { pos[0] + piece.specoffsets[i][0] , pos[1] + piece.specoffsets[i][1] }, turn)) {

                    if (!game.preventcheck(turn, { pos[0] + piece.specoffsets[i][0] , pos[1] + piece.specoffsets[i][1] }, pos)) {
                        continue;
                    }



                    tomove[moveindex] = Vector2{ (float)(pos[0] + piece.specoffsets[i][0]) , (float)(pos[1] + piece.specoffsets[i][1]) };
                    moveindex += 1;

                    if (((pos[0] + piece.specoffsets[i][0]) + (pos[1] + piece.specoffsets[i][1])) % 2 == 0) {
                        DrawRectangle((pos[0] + piece.specoffsets[i][0]) * 100, (pos[1] + piece.specoffsets[i][1]) * 100, 100, 100, BLUE);
                    }
                    else {
                        DrawRectangle((pos[0] + piece.specoffsets[i][0]) * 100, (pos[1] + piece.specoffsets[i][1]) * 100, 100, 100, DARKBLUE);
                    }
                }
            }
        }

    }

}

void promotion(bool turn, Texture2D ptx[12]) {
    if (turn == PWHITE) {
        DrawTextureEx(ptx[11], Vector2{ 0, 800 }, 0 , (100.0 / 128.0), WHITE);
        DrawTextureEx(ptx[6], Vector2{ 100, 800 }, 0, (100.0 / 128.0), WHITE);
        DrawTextureEx(ptx[8], Vector2{ 200, 800 }, 0, (100.0 / 128.0), WHITE);
        DrawTextureEx(ptx[10], Vector2{ 300, 800 }, 0, (100.0 / 128.0), WHITE);
    }
    else {
        DrawTextureEx(ptx[5], Vector2{ 0, 800 }, 0, (100.0 / 128.0), WHITE);
        DrawTextureEx(ptx[0], Vector2{ 100, 800 }, 0, (100.0 / 128.0), WHITE);
        DrawTextureEx(ptx[2], Vector2{ 200, 800 }, 0, (100.0 / 128.0), WHITE);
        DrawTextureEx(ptx[4], Vector2{ 300, 800 }, 0, (100.0 / 128.0), WHITE);
    }
}

int main()
{



    for (int i = 0; i < 100; i++) {
        tomove[i] = Vector2{ 9,9 };
    }

    // chess variables  
    ChessManager game;
    
    int turn = PWHITE;
    
    string pos1;
    string pos2;
    
    vector<int> numpos1 = {0,0};
    vector<int> numpos2 = {0,0};
    
    ifstream demo;
    ofstream newdemo;
    string chessdemo;
    
    bool usingdemo = false;
    bool makingdemo = false;
    
    string chardemo = "";
    
    int demowait = 500;

    //raylib variables

    Vector2 mousepos = { 0,0 };

    Vector2 selectedpos = { 8,8 };

    Vector2 movepos = { 9,9 };

    Vector2 prevpos;

    bool domove = false;
    
    /*cout << "TO LOAD DEMO, ENTER D; TO CREATE DEMO, ENTER C; TO PLAY A GAME, ENTER ANYTHING ELSE." << endl;
    
    cin >> chessdemo;
    
    if (chessdemo == "D") {
        newdemo.close();
        
        
        cout << "ENTER CHESS DEMO FILE PATH" << endl;
        
        
        cin >> chessdemo;
        
        
        demo.open(chessdemo);
        
        
        if (!demo.is_open()) {
            cout << "ERROR LOADING DEMO FILE" << endl;
            return -1;
        }
        
        usingdemo = true;
    }
    else if (chessdemo == "C") {
        demo.close();
        
        
        newdemo.open("demo.txt");
        
        
        if (!newdemo.is_open()) {
            cout << "ERROR CREATING DEMO FILE" << endl;
            return -1;
        }
        
        makingdemo = true;
        
    }

    */


    
    SetTargetFPS(60);
    InitWindow(screenWidth, screenHeight, "RaylibChess");

    // raylib image setup

    Texture2D piecetextures[12];

    ChangeDirectory("Assets");

    for (int i = 0; i < 12; i++) {

        Image image = LoadImage(LoadDirectoryFiles(GetWorkingDirectory()).paths[i]);
        piecetextures[i] = LoadTextureFromImage(image);
        UnloadImage(image);
    }
    
    while (!WindowShouldClose())
    {
        game.castlecheck();


        gameover = { 0,0 };

        checkcheck(game);

        vector<int> procheck = game.promotioncheck();



        mousepos = GetMousePosition();

        BeginDrawing();

        ClearBackground(Color { 36, 27, 22 , 255});

        DrawRectangle(500, 800, 350, 100, BLACK);

        checkerboard();


        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {

            if (procheck[0] == 0) {

                prevpos = selectedpos;

                selectedpos = { (mousepos.x / 100),(mousepos.y / 100) };

                for (int i = 0; i < 100; i++) {
                    if (tomove[i].x == (int)selectedpos.x and tomove[i].y == (int)selectedpos.y) {
                        movepos = Vector2{ tomove[i].x , tomove[i].y };
                        domove = true;
                        break;
                    }
                }

                for (int i = 0; i < 100; i++) {
                    tomove[i] = Vector2{ 9,9 };
                }


            }
            else {

                if ((int)(mousepos.y / 100) == 8) {
                    if (game.plist[procheck[1]].color == PWHITE) {
                        switch ((int)(mousepos.x / 100)) {
                            case 0:
                                game.plist[procheck[1]] = pmake(2, game.plist[procheck[1]].pos);
                                break;
                            case 1:
                                game.plist[procheck[1]] = pmake(4, game.plist[procheck[1]].pos);
                                break;
                            case 2:
                                game.plist[procheck[1]] = pmake(6, game.plist[procheck[1]].pos);
                                break;
                            case 3:
                                game.plist[procheck[1]] = pmake(8, game.plist[procheck[1]].pos);
                                break;
                        }
                    }
                    else {
                        switch ((int)(mousepos.x / 100)) {
                            case 0:
                                game.plist[procheck[1]] = pmake(3, game.plist[procheck[1]].pos);
                                break;
                            case 1:
                                game.plist[procheck[1]] = pmake(5, game.plist[procheck[1]].pos);
                                break;
                            case 2:
                                game.plist[procheck[1]] = pmake(7, game.plist[procheck[1]].pos);
                                break;
                            case 3:
                                game.plist[procheck[1]] = pmake(9, game.plist[procheck[1]].pos);
                                break;
                        }
                    }

                }


            }
        }

        movehighlights(game, game.plist[game.find( { (int)selectedpos.x , (int)selectedpos.y })].pos, turn);

        highlight(Vector2 { mousepos.x / 100, mousepos.y / 100});
        highlight(selectedpos);

        if (procheck[0] == 1) {
            promotion(game.plist[procheck[1]].color, piecetextures);
        }

        drawpieces(game, piecetextures);


        if (gameover[0] == 1) {
            if (gameover[1] == 0) {
                DrawText("BLACK HAS BEEN \nCHECKMATED", 500, 800, 30, WHITE);
            }
            else {
                DrawText("WHITE HAS BEEN \nCHECKMATED", 500, 800, 30, WHITE);
            }
        }

        if (gameover[0] == 2) {
            if (gameover[1] == 0) {
                DrawText("BLACK HAS BEEN \nCHECKED", 500, 800, 30, WHITE);
            }
            else {
                DrawText("WHITE HAS BEEN \nCHECKED", 500, 800, 30, WHITE);
            }
        }


        if (domove) {
            domove = false;

            game.movepiece(game.plist[game.find({(int)prevpos.x,(int)prevpos.y})], {(int)movepos.x , (int)movepos.y}, true);

            if (turn == PWHITE) {
                turn = PBLACK;
            }
            else {
                turn = PWHITE;
            }

        }




        EndDrawing();
    }
    CloseWindow();
    
    
    

    return 0;
}
