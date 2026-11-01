#include "Moves.h"

namespace GridWorks
{
    MoveType MoveTypeStringToEnum(const std::string &s)
    {
        static std::map<std::string, MoveType> stringToEnum = {{"X", X}, {"O", O}};
        return stringToEnum[s];
    }

    std::string MoveTypeEnumToString(MoveType moveType)
    {
        static std::map<MoveType, std::string> enumToString = {{X, "X"}, {O, "O"}};
        return enumToString[moveType];
    }

    MoveType MoveTypeCharToEnum(char c)
    {
        static std::map<char, MoveType> charToEnum = {{'X', X}, {'O', O}};
        return charToEnum[c];
    }

    char MoveTypeEnumToChar(MoveType moveType)
    {
        static std::map<MoveType, char> enumToChar = {{X, 'X'}, {O, 'O'}};
        return enumToChar[moveType];
    }
}