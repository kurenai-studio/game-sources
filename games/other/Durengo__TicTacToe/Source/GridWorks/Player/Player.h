#pragma once

#include <string>
#include <map>

#include "fmt/format.h"

namespace GridWorks
{
    // Forward declarations
    enum MoveType;

    enum PlayerType
    {
        Human = 0,
        AI = 1
    };

    PlayerType PlayerTypeStringToEnum(const std::string &s);

    std::string PlayerTypeEnumToString(PlayerType playerType);

    class Player
    {
    private:
        std::string m_PlayerName;
        PlayerType m_PlayerType;
        MoveType m_MoveType;

    public:
        Player(std::string playerName = "GenericName", PlayerType playerType = PlayerType::Human);
        ~Player();

        // Getters & Setters
    public:
        std::string GetPlayerName() const;
        PlayerType GetPlayerType() const;
        MoveType GetPlayerMoveType() const;
        void SetPlayerMoveType(MoveType moveType);
    };

}

// Formatting for fmt library.
template <>
struct fmt::formatter<GridWorks::PlayerType> : formatter<std::string>
{
    template <typename FormatContext>
    auto format(GridWorks::PlayerType p, FormatContext &ctx)
    {
        std::string name = p == GridWorks::PlayerType::Human ? "Human" : "AI";
        return formatter<std::string>::format(name, ctx);
    }
};

template <>
struct fmt::formatter<GridWorks::Player> : fmt::formatter<std::string>
{
    // Parses format specifications of the form '[:...]' which you can ignore.
    constexpr auto parse(format_parse_context &ctx) { return ctx.begin(); }

    // Formats the Player using provided format specifiers.
    template <typename FormatContext>
    auto format(const GridWorks::Player &player, FormatContext &ctx)
    {
        // Use a memory buffer to store the temporary output.
        fmt::memory_buffer buf;

        fmt::format_to(std::back_inserter(buf), "{} | {}", player.GetPlayerName(), player.GetPlayerType());

        // Output the buffer to the formatting context and return the iterator.
        return fmt::format_to(ctx.out(), "{}", to_string(buf));
    }
};

namespace GridWorks
{
    static std::string PlayerVecToString(const std::vector<Player *> &players)
    {
        std::ostringstream ss;
        for (size_t i = 0; i < players.size(); ++i)
        {
            if (i > 0)
                ss << "\n";
            ss << fmt::format("{}", *players[i]);
        }
        return ss.str();
    }
}