#pragma once

#include <string>
#include <vector>

#include "fmt/format.h"

namespace GridWorks
{
    // Forward declarations
    enum MoveType;
    class Player;
    struct GameConfiguration;
    class Grid;
    enum GameOverType;

    struct PlayerNameAndPtr
    {
        std::string name;
        Player *ptr;
    };

    class TurnManager
    {
    private:
        std::vector<PlayerNameAndPtr> m_Players;
        size_t m_currentTurn = 0;
        unsigned int m_totalTurns = 0;

    public:
        // Constructors & Destructors
        TurnManager(const std::vector<PlayerNameAndPtr> &players);
        ~TurnManager();

        // Operators
        TurnManager &operator++()
        {
            m_currentTurn = (m_currentTurn + 1) % m_Players.size();
            m_totalTurns++;
            return *this;
        }

        TurnManager operator++(int)
        {
            TurnManager temp = *this;
            ++(*this);
            return temp;
        }

        // Getters & Setters
    public:
        PlayerNameAndPtr GetCurrentPlayer() const;

        size_t GetCurrentTurn() const;

        std::vector<std::string> GetPlayerNames() const;

        std::vector<Player *> GetPlayerPtrs() const;

        PlayerNameAndPtr GetPlayerPair(size_t at) const;

        std::vector<PlayerNameAndPtr> GetPlayerPairs() const;

        // Private methods:
    private:
        bool IsWinningCondition(Grid *grid, unsigned char row, unsigned char col);
        bool IsWinningCondition(Grid *grid, char playerChar);
        bool IsDrawCondition(Grid *grid, unsigned char row, unsigned char col);

        // Public methods:
    public:
        void Reset();
        void SetupPlayers(GameConfiguration *gameConfiguration, const std::vector<MoveType> &moveTypes, bool randomize = true);
        void PrintPlayerMoves() const;

        bool MakeMove(Grid *grid, unsigned char row, unsigned char col);
        GameOverType CheckGameOverState(Grid *grid, unsigned char row, unsigned char col);

        void SwapPlayerPositions();
    };
}

// Formatting for fmt library.
template <>
struct fmt::formatter<GridWorks::PlayerNameAndPtr> : fmt::formatter<std::string>
{
    constexpr auto parse(format_parse_context &ctx) { return ctx.begin(); }

    template <typename FormatContext>
    auto format(const GridWorks::PlayerNameAndPtr &player, FormatContext &ctx)
    {
        fmt::memory_buffer buf;

        fmt::format_to(std::back_inserter(buf), "{} [{}]", player.name, static_cast<const void *>(player.ptr));

        // Output the buffer to the formatting context and return the iterator.
        return fmt::format_to(ctx.out(), "{}", to_string(buf));
    }
};

namespace GridWorks
{
    static std::string PlayerNameAndPtrVecToString(const std::vector<PlayerNameAndPtr> &players)
    {
        std::ostringstream ss;
        for (size_t i = 0; i < players.size(); ++i)
        {
            if (i > 0)
                ss << "\n";
            ss << fmt::format("{}", players[i]);
        }
        return ss.str();
    }
}