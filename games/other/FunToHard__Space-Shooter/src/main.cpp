#include "src/Game.h"
#include <iostream>

using namespace SpaceShooter;

int main()
{
    Game game;

    if(!game.Initialize()) {
#ifdef _DEBUG
        std::cerr << "Failed to initialize game!" << std::endl;
#endif
        return -1;
    }

    game.Run();
    game.Shutdown();
    return 0;
}