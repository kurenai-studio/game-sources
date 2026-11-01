#include "Player.h"

#include "Player/Moves.h"

namespace GridWorks
{
    PlayerType PlayerTypeStringToEnum(const std::string &s)
    {
        static std::map<std::string, PlayerType> stringToEnum = {{"Human", Human}, {"AI", AI}};
        return stringToEnum[s];
    }

    std::string PlayerTypeEnumToString(PlayerType playerType)
    {
        static std::map<PlayerType, std::string> enumToString = {{Human, "Human"}, {AI, "AI"}};
        return enumToString[playerType];
    }

    // Constructors & Destructors

    Player::Player(std::string playerName, PlayerType playerType) : m_PlayerName(playerName), m_PlayerType(playerType)
    {
    }

    Player::~Player()
    {
    }

    // Getters & Setters
    std::string Player::GetPlayerName() const
    {
        return m_PlayerName;
    }

    PlayerType Player::GetPlayerType() const
    {
        return m_PlayerType;
    }

    MoveType Player::GetPlayerMoveType() const
    {
        return m_MoveType;
    }

    void Player::SetPlayerMoveType(MoveType moveType)
    {
        m_MoveType = moveType;
    }
}