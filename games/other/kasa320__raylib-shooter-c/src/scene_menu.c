#include <stdio.h>
#include <stdlib.h>
#include <raylib.h>
#include <stdbool.h>
#include <math.h>
#include <rlgl.h>
#include <time.h>
#include "common.h"

Difficulty diff = NORMAL;

// メニュー画面の更新処理
void UpdateMenu() {
    ShowCursor(); // カーソルを表示
}

// メニュー画面の描画処理
void DrawMenu() {
    ClearBackground(GetColor(0x0f1923ff)); 

    int centerX = SCREEN_WIDTH / 2;
    int centerY = SCREEN_HEIGHT / 2;
    int btnWidth = 300;
    int btnHeight = 60;
    int spacing = 20; 
    int startY = centerY - 150; // ボタン配置の開始Y座標

    // タイトル描画
    const char* titleText = "2D SEARCH AND DESTROY";
    int titleFontSize = 50;
    DrawText(titleText, centerX - MeasureText(titleText, titleFontSize) / 2, 150, titleFontSize, WHITE);

    // 難易度選択のテキスト
    DrawText("- SELECT DIFFICULTY -", centerX - MeasureText("- SELECT DIFFICULTY -", 20)/2, startY + btnHeight + spacing, 20, GRAY);
    int diffStartY = startY + btnHeight + spacing + 40;

    // EASY
    Rectangle easyBtn = { centerX - btnWidth / 2, diffStartY, btnWidth, btnHeight };
    if (DrawButton(easyBtn, "1v5: EASY", GREEN)) {
        Init1v5(EASY); // 難易度を渡して初期化
        currentState = STATE_1v5;
    }

    // NORMAL
    Rectangle normalBtn = { centerX - btnWidth / 2, diffStartY + btnHeight + spacing, btnWidth, btnHeight };
    if (DrawButton(normalBtn, "1v5: NORMAL", YELLOW)) {
        Init1v5(NORMAL);
        currentState = STATE_1v5;
    }

    // HARD
    Rectangle hardBtn = { centerX - btnWidth / 2, diffStartY + (btnHeight + spacing) * 2, btnWidth, btnHeight };
    if (DrawButton(hardBtn, "1v5: HARD", RED)) {
        Init1v5(HARD);
        currentState = STATE_1v5;
    }
}