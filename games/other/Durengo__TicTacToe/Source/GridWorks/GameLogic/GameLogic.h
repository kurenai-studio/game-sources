#pragma once

#include <string>
#include <mutex>
#include <vector>

#include "Grid/Grid.h"
#include "Player/Player.h"
#include "GameLogic/GameConfiguration.h"

namespace GridWorks
{
    enum GameState;
    enum GameOverType;
    class GameLogic
    {
    private:
        static GameLogic *i_instance;
        static std::mutex i_mutex;
        static GameState m_gameState;
        static GameOverType m_gameOverType;
        static Player *m_winner;
        static bool m_randomizeTurnOrder;

        GameConfiguration *m_GameConfiguration;

        // Constructors & Destructors
    protected:
        GameLogic();
        ~GameLogic();

        // Constructors & Destructors
    public:
        // We don't want to allow copying of our singletons, so delete these operators
        GameLogic(GameLogic &other) = delete;
        void operator=(const GameLogic &) = delete;

        // Singleton initialization methods
        static void Initialize();
        static void DeleteInstance();

        // Getters & Setters
    public:
        static GameLogic *GetInstance();

        GameConfiguration *GetGameConfiguration() const;
        void SetGameConfiguration(GameConfiguration *gameConfiguration);

        std::string GetGameName() const;

        Grid *GetGrid() const;

        std::vector<Player *> GetPlayers() const;

        GameState GetGameState() const;
        void SetGameState(GameState gameState);

        GameOverType GetGameOverType() const;

        Player *GetWinner() const;

        void SetRandomizeTurnOrder(bool randomize);

    private:
        static bool CheckInit();

        static void ResetGrid();

        static void ResetPlayers();

        static void PrintPlayersTurnOrder();

        // Public methods
    public:
        static void SetupGame();

        static void ResetGame();

        static void StartGame();

        static void MakeMove(unsigned char row, unsigned char col);

        void SwapPlayerPositions();
    };
}
