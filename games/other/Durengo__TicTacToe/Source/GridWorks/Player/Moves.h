#pragma once

#include <string>
#include <map>

namespace GridWorks
{
    enum MoveType
    {
        X = 'X',
        O = 'O',
    };

    MoveType MoveTypeStringToEnum(const std::string &s);

    std::string MoveTypeEnumToString(MoveType moveType);

    MoveType MoveTypeCharToEnum(char c);

    char MoveTypeEnumToChar(MoveType moveType);
}