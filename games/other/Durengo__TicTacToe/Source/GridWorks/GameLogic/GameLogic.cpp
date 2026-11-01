#include "GameLogic.h"

#include <durlib.h>

#include "GameLogic/GameState.h"
#include "Player/Moves.h"

namespace GridWorks
{
    // Static variables
    GameLogic *GameLogic::i_instance{nullptr};
    std::mutex GameLogic::i_mutex;
    GameState GameLogic::m_gameState{GameState::NotStarted};
    GameOverType GameLogic::m_gameOverType{GameOverType::None};
    Player *GameLogic::m_winner{nullptr};
    bool GameLogic::m_randomizeTurnOrder{true};

    // Constructors & Destructors
    GameLogic::GameLogic()
    {
    }

    GameLogic::~GameLogic()
    {
        if (i_instance->m_GameConfiguration != nullptr)
        {
            GameConfiguration *temp = i_instance->m_GameConfiguration;
            i_instance->m_GameConfiguration = nullptr;
            delete temp;
        }
    }

    void GameLogic::Initialize()
    {
        std::lock_guard<std::mutex> lock(i_mutex);
        if (i_instance == nullptr)
        {
            i_instance = new GameLogic();
        }
    }

    void GameLogic::DeleteInstance()
    {
        std::lock_guard<std::mutex> lock(i_mutex);
        if (i_instance != nullptr)
        {
            delete i_instance;
            i_instance = nullptr;
        }
    }

    // Getters & Setters

    GameLogic *GameLogic::GetInstance()
    {
        DEBUG_ASSERT(i_instance, "GameLogic instance not initialized.");

        return i_instance;
    }

    GameConfiguration *GameLogic::GetGameConfiguration() const
    {
        DEBUG_ASSERT(i_instance->m_GameConfiguration, "GameConfiguration not initialized.");

        return i_instance->m_GameConfiguration;
    }

    void GameLogic::SetGameConfiguration(GameConfiguration *gameConfiguration)
    {
        i_instance->m_GameConfiguration = gameConfiguration;
    }

    std::string GameLogic::GetGameName() const
    {
        CLI_ASSERT(i_instance->m_GameConfiguration->gameName != "", "Name not initialized.");

        return m_GameConfiguration->gameName;
    }

    Grid *GameLogic::GetGrid() const
    {
        CLI_ASSERT(i_instance->m_GameConfiguration->grid, "Grid not initialized.");

        return m_GameConfiguration->grid;
    }

    std::vector<Player *> GameLogic::GetPlayers() const
    {
        return m_GameConfiguration->players;
    }

    GameState GameLogic::GetGameState() const
    {
        return m_gameState;
    }

    void GameLogic::SetGameState(GameState gameState)
    {
        m_gameState = gameState;
    }

    GameOverType GameLogic::GetGameOverType() const
    {
        return m_gameOverType;
    }

    Player *GameLogic::GetWinner() const
    {
        return m_winner;
    }

    void GameLogic::SetRandomizeTurnOrder(bool randomize)
    {
        m_randomizeTurnOrder = randomize;
    }

    // Private methods

    bool GameLogic::CheckInit()
    {
        if (i_instance == nullptr)
        {
            CLI_ERROR("GameLogic instance not initialized.");
            return false;
        }
        return true;
    }

    void GameLogic::ResetGrid()
    {
        CLI_ASSERT(i_instance->m_GameConfiguration->grid, "Grid not initialized.");

        i_instance->m_GameConfiguration->grid->ResetGrid();
    }

    void GameLogic::ResetPlayers()
    {
        CLI_ASSERT(i_instance->m_GameConfiguration->turnManager, "TurnManager not initialized.");

        // HARDCODED
        std::vector<MoveType> moveTypes;
        moveTypes.push_back(MoveType::X);
        moveTypes.push_back(MoveType::O);
        // HARDCODED

        i_instance->m_GameConfiguration->turnManager->SetupPlayers(i_instance->m_GameConfiguration, moveTypes, m_randomizeTurnOrder);
        i_instance->m_GameConfiguration->turnManager->PrintPlayerMoves();
    }

    void GameLogic::PrintPlayersTurnOrder()
    {
        std::string players = "";
        auto playerPairs = i_instance->m_GameConfiguration->turnManager->GetPlayerPairs();
        for (size_t i = 0; i < playerPairs.size(); ++i)
        {
            players +=
                playerPairs[i].ptr->GetPlayerName() + "\t| " +
                GridWorks::PlayerTypeEnumToString(playerPairs[i].ptr->GetPlayerType()) + "\t| " +
                GridWorks::MoveTypeEnumToString(playerPairs[i].ptr->GetPlayerMoveType());
            // Add the newline character if it's not the last player
            if (i < playerPairs.size() - 1)
            {
                players += " |\n";
            }
            else
            {
                players += " |"; // Do not add newline at the end
            }
        }
        CLI_TRACE("Player Turn Order:\n{}", players);
    }

    // Public methods

    void GameLogic::SetupGame()
    {
        m_gameState = GameState::NotStarted;
        m_gameOverType = GameOverType::None;
        ResetGame();
    }

    void GameLogic::ResetGame()
    {
        if (CheckInit())
        {
            m_gameState = GameState::NotStarted;
            m_gameOverType = GameOverType::None;

            CLI_INFO("Setting up game: {}", i_instance->m_GameConfiguration->gameName);
            CLI_TRACE("Game description: {}", i_instance->m_GameConfiguration->gameDescription);

            CLI_TRACE("Resetting grid.");
            i_instance->ResetGrid();

            CLI_TRACE("Resetting turns.");
            i_instance->m_GameConfiguration->turnManager->Reset();

            CLI_TRACE("Setting up players.");
            i_instance->ResetPlayers();

            m_winner = nullptr;
        }
    }

    void GameLogic::StartGame()
    {
        if (CheckInit())
        {
            CLI_INFO("Starting game: {}", i_instance->m_GameConfiguration->gameName);
            CLI_TRACE("Game description: {}", i_instance->m_GameConfiguration->gameDescription);

            m_gameState = GameState::InProgress;

            CLI_TRACE("Grid: {}", *i_instance->m_GameConfiguration->grid);
            i_instance->PrintPlayersTurnOrder();
            // i_instance->m_GameConfiguration->turnManager->StartGame();
        }
    }

    void GameLogic::MakeMove(unsigned char row, unsigned char col)
    {
        if (CheckInit())
        {
            if (i_instance->m_GameConfiguration->turnManager->MakeMove(i_instance->m_GameConfiguration->grid, row, col) && m_gameState == GameState::InProgress)
            {
                CLI_TRACE("{}", *i_instance->m_GameConfiguration->grid);
                switch (i_instance->m_GameConfiguration->turnManager->CheckGameOverState(i_instance->m_GameConfiguration->grid, row, col))
                {
                case GameOverType::None:
                    m_gameState = GameState::InProgress;
                    // i_instance->m_GameConfiguration->turnManager++;
                    break;
                case GameOverType::Win:
                    m_gameState = GameState::GameOver;
                    m_gameOverType = GameOverType::Win;
                    m_winner = i_instance->m_GameConfiguration->turnManager->GetCurrentPlayer().ptr;
                    i_instance->PrintPlayersTurnOrder();
                    break;
                case GameOverType::Draw:
                    m_gameState = GameState::GameOver;
                    m_gameOverType = GameOverType::Draw;
                    i_instance->PrintPlayersTurnOrder();
                    break;
                default:
                    CLI_ERROR("Invalid GameOverType.");
                    break;
                }
            }
            else
            {
                throw std::runtime_error("Invalid move.");
            }
        }
    }

    void GameLogic::SwapPlayerPositions()
    {
        if (CheckInit())
        {
            std::swap(i_instance->m_GameConfiguration->players[0], i_instance->m_GameConfiguration->players[1]);
            i_instance->m_GameConfiguration->turnManager->SwapPlayerPositions();
        }
    }
}