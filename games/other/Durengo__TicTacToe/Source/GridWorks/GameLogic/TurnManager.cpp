#include "TurnManager.h"

#include <algorithm>
#include <random>
#include <chrono>

#include <durlib.h>

#include <Player/Moves.h>
#include <Player/Player.h>
#include <GameLogic/GameConfiguration.h>
#include <GameLogic/GameState.h>

namespace GridWorks
{
    // Constructors & Destructors
    TurnManager::TurnManager(const std::vector<PlayerNameAndPtr> &players)
    {
        m_Players = players;
    }

    TurnManager::~TurnManager()
    {
        for (auto &playerPair : m_Players)
        {
            playerPair.ptr = nullptr;
            delete playerPair.ptr;
        }
    }

    // Getters & Setters
    PlayerNameAndPtr TurnManager::GetCurrentPlayer() const
    {
        return m_Players[m_currentTurn];
    }

    size_t TurnManager::GetCurrentTurn() const
    {
        return m_currentTurn;
    }

    std::vector<std::string> TurnManager::GetPlayerNames() const
    {
        std::vector<std::string> playerNames;
        for (const auto &playerPair : m_Players)
        {
            playerNames.push_back(playerPair.name);
        }
        return playerNames;
    }

    std::vector<Player *> TurnManager::GetPlayerPtrs() const
    {
        std::vector<Player *> playerPtrs;
        for (const auto &playerPair : m_Players)
        {
            playerPtrs.push_back(playerPair.ptr);
        }
        return playerPtrs;
    }

    PlayerNameAndPtr TurnManager::GetPlayerPair(size_t at) const
    {
        if (at < m_Players.size())
        {
            return m_Players[at];
        }
        else
        {
            throw std::out_of_range("Index out of range in GetPlayerPair");
        }
    }

    std::vector<PlayerNameAndPtr> TurnManager::GetPlayerPairs() const
    {
        return m_Players;
    }

    // Private methods
    bool TurnManager::IsWinningCondition(Grid *grid, unsigned char row, unsigned char col)
    {
        char playerChar = grid->GetCharAt(row, col);
        return grid->CheckForRecurringCharsInRow(playerChar) || grid->CheckForRecurringCharsInCol(playerChar) ||
               grid->CheckForRecurringCharsInDiagonal(playerChar) || grid->CheckForRecurringCharsInAntiDiagonal(playerChar);
    }

    bool TurnManager::IsWinningCondition(Grid *grid, char playerChar)
    {
        return grid->CheckForRecurringCharsInRow(playerChar) || grid->CheckForRecurringCharsInCol(playerChar) ||
               grid->CheckForRecurringCharsInDiagonal(playerChar) || grid->CheckForRecurringCharsInAntiDiagonal(playerChar);
    }

    bool TurnManager::IsDrawCondition(Grid *grid, unsigned char row, unsigned char col)
    {
        // Check if all spots are filled.
        bool allSpotsFilled = true;
        for (int row = 0; row < grid->GetRows(); ++row)
        {
            for (int col = 0; col < grid->GetCols(); ++col)
            {
                if (grid->GetCharAt(row, col) == grid->GetDefaultChar())
                {
                    allSpotsFilled = false; // Found an empty spot, so not all spots are filled.
                    break;
                }
            }
            if (!allSpotsFilled)
                break;
        }

        // If all spots are filled and there's no win, then it's a draw.
        return allSpotsFilled && !IsWinningCondition(grid, grid->GetLastChangedChar().first, grid->GetLastChangedChar().second);
    }

    // Public methods

    void TurnManager::Reset()
    {
        m_currentTurn = 0;
        m_totalTurns = 0;
    }

    void TurnManager::SetupPlayers(GameConfiguration *gameConfiguration, const std::vector<MoveType> &moveTypes, bool randomize)
    {
        size_t allowedPlayers = gameConfiguration->maxPlayers;

        CLI_ASSERT(m_Players.size() > 1, "Player amount exceeds max player amount.");

        if (randomize)
        {
            std::vector<MoveType> shuffledMoveTypes = moveTypes;
            std::random_device rd;
            auto rng = std::default_random_engine{rd()};
            std::shuffle(shuffledMoveTypes.begin(), shuffledMoveTypes.end(), rng);

            for (int i = 0; i < m_Players.size(); i++)
            {
                m_Players[i].ptr->SetPlayerMoveType(shuffledMoveTypes[i % shuffledMoveTypes.size()]);
            }

            // Assuming MoveType::X is the MoveType that goes first.
            std::stable_sort(m_Players.begin(), m_Players.end(),
                             [](const PlayerNameAndPtr &a, const PlayerNameAndPtr &b)
                             {
                                 return a.ptr->GetPlayerMoveType() == MoveType::X;
                             });
        }
        else
        {
            for (int i = 0; i < m_Players.size(); i++)
            {
                m_Players[i].ptr->SetPlayerMoveType(moveTypes[i % moveTypes.size()]);
            }

            std::stable_sort(m_Players.begin(), m_Players.end(),
                             [](const PlayerNameAndPtr &a, const PlayerNameAndPtr &b)
                             {
                                 return a.ptr->GetPlayerMoveType() == MoveType::X;
                             });
        }
    }

    void TurnManager::PrintPlayerMoves() const
    {
        for (const auto &playerPair : m_Players)
        {
            std::string move = GridWorks::MoveTypeEnumToString(playerPair.ptr->GetPlayerMoveType());
            CLI_TRACE("{0} | {1}", playerPair.name, move);
        }
    }

    bool TurnManager::MakeMove(Grid *grid, unsigned char row, unsigned char col)
    {
        CLI_TRACE("Player {0} is making a move at ({1}, {2}).", GetCurrentPlayer().name, row, col);
        char gridChar = grid->GetCharAt(row, col);
        if (grid->GetCharAt(row, col) != grid->GetDefaultChar())
        {
            CLI_WARN("Cannot make move at ({0}, {1}) because it is already occupied by {2}.", row, col, gridChar);
            return false;
        }

        PlayerNameAndPtr currentPlayer = GetCurrentPlayer();

        grid->SetCharAt(row, col, GridWorks::MoveTypeEnumToChar(currentPlayer.ptr->GetPlayerMoveType()));

        // this->operator++();
        return true;
    }

    GameOverType TurnManager::CheckGameOverState(Grid *grid, unsigned char row, unsigned char col)
    {
        PlayerNameAndPtr currentPlayer = GetCurrentPlayer();
        // PlayerNameAndPtr previousPlayer = GetPlayerPair((GetCurrentTurn() - 1) % m_Players.size());

        if (IsWinningCondition(grid, row, col))
        {
            CLI_INFO("Player {0} won the game!", currentPlayer.name);
            return GameOverType::Win;
        }
        if (IsDrawCondition(grid, row, col))
        {
            CLI_INFO("The game ended in a draw!");
            return GameOverType::Draw;
        }
        CLI_TRACE("Player {0} finished his move.", currentPlayer.name);
        this->operator++();
        CLI_TRACE("Player {0} is now playing.", GetCurrentPlayer().name);
        return GameOverType::None;
    }

    void TurnManager::SwapPlayerPositions()
    {
        if (m_Players.size() == 2)
        {
            std::swap(m_Players[0], m_Players[1]);
        }
        else
        {
            throw std::runtime_error("Cannot swap player positions if there are more than 2 players.");
        }
    }

}