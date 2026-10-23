#include "game.h"

using namespace pwu;

int main()
{
    // Ensure working directory is the executable's directory so that
    // relative asset paths ("resources/...", "highscore.dat") resolve
    // correctly regardless of how the game is launched.
    ChangeDirectory(GetApplicationDirectory());

    Game game;
    game.Init();

    while (!WindowShouldClose() && !game.ShouldQuit())
    {
        game.Update();
        game.Draw();
    }

    game.Close();
    return 0;
}
