#pragma once

namespace GridWorks
{
    enum GameState
    {
        NotStarted = 0,
        InProgress = 1,
        Paused = 2,
        GameOver = 3
    };

    enum GameOverType
    {
        None = 0,
        Win = 1,
        Draw = 2
    };
}