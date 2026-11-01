#pragma once

#include "fmt/format.h"

namespace GridWorks
{
    class Grid
    {
    private:
        // Limit grid size to 255x255.
        unsigned char rows;
        unsigned char cols;
        // Use a 2D array of chars to represent the grid.
        char **grid;

        // Store default char for resetting the grid.
        char defaultChar;

        // Store which element was last changed.
        unsigned char lastChangedChar[2] = {0, 0};

    public:
        // Constructors & Destructors
        Grid(unsigned char rows, unsigned char cols, char initialChar = '.');
        ~Grid();

        // Getters & Setters
    public:
        unsigned char GetRows() const;
        void SetRows(unsigned char rows);

        unsigned char GetCols() const;
        void SetCols(unsigned char cols);

        char **GetGrid() const;
        void SetGrid(char **grid);

        char GetDefaultChar() const;
        void SetDefaultChar(char defaultChar);

        char GetCharAt(unsigned char row, unsigned char col) const;
        void SetCharAt(unsigned char row, unsigned char col, char newChar);

        std::pair<unsigned char, unsigned char> GetLastChangedChar() const;

        // Overload the [] operator to access the grid.
    public:
        char *operator[](int index);

        // Public methods
    public:
        const std::string GetGridInfo() const;
        void ResetGrid();
        void ResetGridWithNewSize(unsigned char newRows, unsigned char newCols, char newChar = '.');
        void ResetGridWithNewChar(char newChar);

        bool CheckForRecurringCharsInRow(char playerChar);
        bool CheckForRecurringCharsInCol(char playerChar);
        bool CheckForRecurringCharsInDiagonal(char playerChar);
        bool CheckForRecurringCharsInAntiDiagonal(char playerChar);

        char GetCharCenterMostElement() const;
        std::pair<unsigned char, unsigned char> GetCenterMostCoords() const;
    };
}

// Formatting for fmt library.
template <>
struct fmt::formatter<GridWorks::Grid> : fmt::formatter<std::string>
{
    // Parses format specifications of the form '[:...]' which you can ignore.
    constexpr auto parse(format_parse_context &ctx) { return ctx.begin(); }

    // Formats the Grid using provided format specifiers.
    template <typename FormatContext>
    auto format(const GridWorks::Grid &grid, FormatContext &ctx)
    {
        // Use a memory buffer to store the temporary output.
        fmt::memory_buffer buf;

        fmt::format_to(std::back_inserter(buf), "\n");

        for (int i = 0; i < grid.GetRows(); i++)
        {
            for (int j = 0; j < grid.GetCols(); j++)
            {
                // Assuming you want a space between characters in a row.
                if (j > 0)
                    fmt::format_to(std::back_inserter(buf), " ");
                // Format each character from the grid.
                fmt::format_to(std::back_inserter(buf), "{}", grid.GetGrid()[i][j]);
            }
            // Add a newline after each row, except the last one.
            if (i < grid.GetRows() - 1)
                fmt::format_to(std::back_inserter(buf), "\n");
        }

        // Output the buffer to the formatting context and return the iterator.
        return fmt::format_to(ctx.out(), "{}", to_string(buf));
    }
};