#include "Grid.h"

#include <stdexcept>

namespace GridWorks
{
    // Constructors & Destructors
    Grid::Grid(unsigned char rows, unsigned char cols, char initialChar) : defaultChar(initialChar)
    {
        this->rows = rows;
        this->cols = cols;

        // Allocate memory for the grid.
        grid = new char *[rows];
        for (unsigned char i = 0; i < rows; ++i)
        {
            grid[i] = new char[cols];
            // Set each character in this row to the initial char.
            std::fill_n(grid[i], cols, initialChar);
        }
    }

    Grid::~Grid()
    {
        // Deallocate memory for the grid.
        for (int i = 0; i < rows; i++)
        {
            delete[] grid[i];
        }
        delete[] grid;
    }

    // Getters & Setters

    unsigned char Grid::GetRows() const
    {
        return rows;
    }

    void Grid::SetRows(unsigned char rows)
    {
        this->rows = rows;
    }

    unsigned char Grid::GetCols() const
    {
        return cols;
    }

    void Grid::SetCols(unsigned char cols)
    {
        this->cols = cols;
    }

    char **Grid::GetGrid() const
    {
        return grid;
    }

    void Grid::SetGrid(char **grid)
    {
        this->grid = grid;
    }

    char Grid::GetDefaultChar() const
    {
        return defaultChar;
    }

    void Grid::SetDefaultChar(char defaultChar)
    {
        this->defaultChar = defaultChar;
    }

    char Grid::GetCharAt(unsigned char row, unsigned char col) const
    {
        return grid[row][col];
    }

    void Grid::SetCharAt(unsigned char row, unsigned char col, char newChar)
    {
        if (row < 0 || row >= this->GetRows() || col < 0 || col >= this->GetCols())
        {
            throw std::out_of_range("Index out of bounds");
        }
        lastChangedChar[0] = row;
        lastChangedChar[1] = col;
        grid[row][col] = newChar;
    }

    std::pair<unsigned char, unsigned char> Grid::GetLastChangedChar() const
    {
        return std::make_pair(lastChangedChar[0], lastChangedChar[1]);
    }

    // Operators

    char *Grid::operator[](int index)
    {
        if (index < 0 || index >= this->GetRows())
        {
            throw std::out_of_range("Index out of bounds");
        }
        return grid[index];
    }

    // Public methods
    const std::string Grid::GetGridInfo() const
    {
        return fmt::format("Grid: {0}x{1}", rows, cols);
    }

    void Grid::ResetGrid()
    {
        for (int i = 0; i < rows; i++)
        {
            std::fill_n(grid[i], cols, defaultChar);
        }
        lastChangedChar[0] = 0;
        lastChangedChar[1] = 0;
    }

    void Grid::ResetGridWithNewSize(unsigned char newRows, unsigned char newCols, char newChar)
    {
        defaultChar = newChar;
        ResetGrid();

        // Deallocate memory for the grid.
        for (int i = 0; i < rows; i++)
        {
            delete[] grid[i];
        }
        delete[] grid;

        // Allocate memory for the grid.
        this->rows = newRows;
        this->cols = newCols;
        grid = new char *[rows];
        for (unsigned char i = 0; i < rows; ++i)
        {
            grid[i] = new char[cols];
            // Set each character in this row to the initial char.
            std::fill_n(grid[i], cols, newChar);
        }
    }

    void Grid::ResetGridWithNewChar(char newChar)
    {
        defaultChar = newChar;
        ResetGrid();
    }

    // Previous methods checked for the occurrence of a character in a row, column, diagonal or anti-diagonal.
    // But it checked the whole row, column, diagonal or anti-diagonal.
    // This is incorrect. Because we need to check for at the very least 3 occurrences of the character in a row.
    bool Grid::CheckForRecurringCharsInRow(char playerChar)
    {
        for (int row = 0; row < rows; ++row)
        {
            int count = 0;
            for (int col = 0; col < cols; ++col)
            {
                if (GetCharAt(row, col) == playerChar)
                {
                    if (++count >= 3)
                        return true;
                }
                else
                {
                    count = 0;
                }
            }
        }
        return false;
    }

    bool Grid::CheckForRecurringCharsInCol(char playerChar)
    {
        for (int col = 0; col < cols; ++col)
        {
            int count = 0;
            for (int row = 0; row < rows; ++row)
            {
                if (GetCharAt(row, col) == playerChar)
                {
                    if (++count >= 3)
                        return true;
                }
                else
                {
                    count = 0;
                }
            }
        }
        return false;
    }

    bool Grid::CheckForRecurringCharsInDiagonal(char playerChar)
    {
        // Check from top-left to bottom-right
        for (int row = 0; row <= rows - 3; ++row)
        {
            for (int col = 0; col <= cols - 3; ++col)
            {
                int count = 0;
                for (int i = 0; i + row < rows && i + col < cols; ++i)
                {
                    if (GetCharAt(row + i, col + i) == playerChar)
                    {
                        if (++count >= 3)
                            return true;
                    }
                    else
                    {
                        break; // Exit the diagonal check if a different char is found
                    }
                }
            }
        }
        return false;
    }

    bool Grid::CheckForRecurringCharsInAntiDiagonal(char playerChar)
    {
        // Check from top-right to bottom-left
        for (int row = 0; row <= rows - 3; ++row)
        {
            for (int col = cols - 1; col >= 2; --col)
            {
                int count = 0;
                for (int i = 0; i + row < rows && col - i >= 0; ++i)
                {
                    if (GetCharAt(row + i, col - i) == playerChar)
                    {
                        if (++count >= 3)
                            return true;
                    }
                    else
                    {
                        break; // Exit the anti-diagonal check if a different char is found
                    }
                }
            }
        }
        return false;
    }

    char Grid::GetCharCenterMostElement() const
    {
        unsigned char centerRow = rows / 2;
        unsigned char centerCol = cols / 2;

        if (rows % 2 == 0)
            --centerRow;
        if (cols % 2 == 0)
            --centerCol;

        return GetCharAt(centerRow, centerCol);
    }

    std::pair<unsigned char, unsigned char> Grid::GetCenterMostCoords() const
    {
        // The center for both rows and columns in case of odd dimensions.
        unsigned char centerRow = rows / 2;
        unsigned char centerCol = cols / 2;

        // If both dimensions are even, adjust to get the top-left centermost element.
        if (rows % 2 == 0)
            --centerRow;
        if (cols % 2 == 0)
            --centerCol;

        return std::make_pair(centerRow, centerCol);
    }
}