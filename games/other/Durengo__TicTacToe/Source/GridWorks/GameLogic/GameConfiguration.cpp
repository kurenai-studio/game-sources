#include "GameConfiguration.h"

#include <durlib.h>

namespace GridWorks
{
    ConfigurationBuilder &GameConfigurationBuilder::setGameName(const std::string &gameName)
    {
        m_GameConfiguration.gameName = gameName;
        return *this;
    }

    ConfigurationBuilder &GameConfigurationBuilder::setGameDescription(const std::string &gameDescription)
    {
        m_GameConfiguration.gameDescription = gameDescription;
        return *this;
    }

    ConfigurationBuilder &GameConfigurationBuilder::setGrid(unsigned char rows, unsigned char cols, char initialChar)
    {
        m_GameConfiguration.grid = new Grid(rows, cols, initialChar);
        return *this;
    }

    ConfigurationBuilder &GameConfigurationBuilder::setMaxPlayers(size_t maxPlayers)
    {
        m_GameConfiguration.maxPlayers = maxPlayers;
        return *this;
    }

    ConfigurationBuilder &GameConfigurationBuilder::addPlayer(Player *player)
    {
        m_GameConfiguration.players.push_back(player);
        return *this;
    }

    GameConfiguration *GameConfigurationBuilder::build()
    {
        CLI_INFO("Game Name: {0}", m_GameConfiguration.gameName);
        CLI_INFO("Game Description: {0}", m_GameConfiguration.gameDescription);
        CLI_INFO("Grid: {0}", m_GameConfiguration.grid->GetGridInfo());
        CLI_INFO("Player amount: {0}", m_GameConfiguration.players.size());
        CLI_ASSERT(m_GameConfiguration.players.size() > 1, "TurnManager cannot be initialized due to lack of players.")
        CLI_INFO("Players:\n{0}", PlayerVecToString(m_GameConfiguration.players));
        CLI_ASSERT(m_GameConfiguration.players.size() <= m_GameConfiguration.maxPlayers, "Player amount exceeds max player amount.");

        std::vector<PlayerNameAndPtr> playerPairs;
        for (auto player : m_GameConfiguration.players)
        {
            playerPairs.push_back({player->GetPlayerName(), player});
        }
        m_GameConfiguration.turnManager = new TurnManager(playerPairs);
        CLI_INFO("TurnManager initialized.");
        CLI_INFO("Player Pairs:\n{0}", PlayerNameAndPtrVecToString(m_GameConfiguration.turnManager->GetPlayerPairs()));

        return new GameConfiguration(m_GameConfiguration);
    }
}