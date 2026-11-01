#include <gtest/gtest.h>
#include "Grid/Grid.h"

#include <cstdlib>
#include <ctime>

#include <durlib.h>

namespace GridWorks
{

    bool CheckForWin(Grid *grid, unsigned char row, unsigned char col)
    {
        char playerChar = grid->GetCharAt(row, col);
        return grid->CheckForRecurringCharsInRow(playerChar) || grid->CheckForRecurringCharsInCol(playerChar) ||
               grid->CheckForRecurringCharsInDiagonal(playerChar) || grid->CheckForRecurringCharsInAntiDiagonal(playerChar);
    }

    bool CheckForWin(Grid *grid, char playerChar)
    {
        return grid->CheckForRecurringCharsInRow(playerChar) || grid->CheckForRecurringCharsInCol(playerChar) ||
               grid->CheckForRecurringCharsInDiagonal(playerChar) || grid->CheckForRecurringCharsInAntiDiagonal(playerChar);
    }

    bool CheckForDraw(Grid *grid)
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
        return allSpotsFilled && !CheckForWin(grid, grid->GetLastChangedChar().first, grid->GetLastChangedChar().second);
    }

    class FixedTTTLogicTest : public ::testing::Test
    {
    protected:
        Grid *grid;

        void SetUp() override
        {
            grid = new Grid(3, 3, '*');
        }

        void TearDown() override
        {
            delete grid;
        }

        // Helper function to simulate a player's move on the grid.
        void PlayerMove(char player, unsigned char row, unsigned char col)
        {
            grid->SetCharAt(row, col, player);
        }

        // Helper function to fill the grid and simulate a draw.
        void FillGridForDraw()
        {
            grid->SetCharAt(0, 0, 'X');
            grid->SetCharAt(0, 1, 'O');
            grid->SetCharAt(0, 2, 'X');
            grid->SetCharAt(1, 0, 'X');
            grid->SetCharAt(1, 1, 'O');
            grid->SetCharAt(1, 2, 'X');
            grid->SetCharAt(2, 0, 'O');
            grid->SetCharAt(2, 1, 'X');
            grid->SetCharAt(2, 2, 'O');
        }
    };

    // Tests for win conditions
    TEST_F(FixedTTTLogicTest, WinConditionInRow)
    {
        PlayerMove('X', 0, 0);
        PlayerMove('X', 0, 1);
        PlayerMove('X', 0, 2);
        EXPECT_TRUE(grid->CheckForRecurringCharsInRow('X'));
    }

    TEST_F(FixedTTTLogicTest, WinConditionInRowFail)
    {
        PlayerMove('X', 0, 0);
        PlayerMove('O', 0, 1);
        PlayerMove('X', 0, 2);
        EXPECT_FALSE(grid->CheckForRecurringCharsInRow('X'));
    }

    TEST_F(FixedTTTLogicTest, WinConditionInColumn)
    {
        PlayerMove('O', 0, 0);
        PlayerMove('O', 1, 0);
        PlayerMove('O', 2, 0);
        EXPECT_TRUE(grid->CheckForRecurringCharsInCol('O'));
    }

    TEST_F(FixedTTTLogicTest, WinConditionInColumnFail)
    {
        PlayerMove('O', 0, 0);
        PlayerMove('X', 1, 0);
        PlayerMove('O', 2, 0);
        EXPECT_FALSE(grid->CheckForRecurringCharsInCol('O'));
    }

    TEST_F(FixedTTTLogicTest, WinConditionInDiagonal)
    {
        PlayerMove('X', 0, 0);
        PlayerMove('X', 1, 1);
        PlayerMove('X', 2, 2);
        EXPECT_TRUE(grid->CheckForRecurringCharsInDiagonal('X'));
    }

    TEST_F(FixedTTTLogicTest, WinConditionInDiagonalFail)
    {
        PlayerMove('X', 0, 0);
        PlayerMove('O', 1, 1);
        PlayerMove('X', 2, 2);
        EXPECT_FALSE(grid->CheckForRecurringCharsInDiagonal('X'));
    }

    TEST_F(FixedTTTLogicTest, WinConditionInAntiDiagonal)
    {
        PlayerMove('O', 0, 2);
        PlayerMove('O', 1, 1);
        PlayerMove('O', 2, 0);
        EXPECT_TRUE(grid->CheckForRecurringCharsInAntiDiagonal('O'));
    }

    TEST_F(FixedTTTLogicTest, WinConditionInAntiDiagonalFail)
    {
        PlayerMove('O', 0, 2);
        PlayerMove('X', 1, 1);
        PlayerMove('O', 2, 0);
        EXPECT_FALSE(grid->CheckForRecurringCharsInAntiDiagonal('O'));
    }

    // Test for draw condition
    TEST_F(FixedTTTLogicTest, DrawCondition)
    {
        FillGridForDraw();
        // Assuming CheckForDraw checks if all cells are filled and there is no winner
        EXPECT_TRUE(CheckForDraw(this->grid));
    }

    TEST_F(FixedTTTLogicTest, InvalidMoveAttempt)
    {
        PlayerMove('X', 0, 0);                   // Valid move
        EXPECT_ANY_THROW(PlayerMove('O', 3, 3)); // Invalid move, outside of grid bounds
    }

    TEST_F(FixedTTTLogicTest, DetectWinAfterGridIsFull)
    {
        // Fill the grid such that the last move is a winning move
        PlayerMove('X', 0, 0);
        PlayerMove('O', 0, 1);
        PlayerMove('X', 0, 2);
        PlayerMove('O', 1, 0);
        PlayerMove('X', 1, 1);
        PlayerMove('O', 1, 2);
        PlayerMove('X', 2, 1);
        PlayerMove('O', 2, 0);
        PlayerMove('X', 2, 2); // Last move is a win for X
        EXPECT_TRUE(CheckForWin(this->grid, 2, 2));
        EXPECT_FALSE(CheckForDraw(this->grid)); // Ensure that it's not reported as a draw
    }

    TEST_F(FixedTTTLogicTest, FullGridWithoutWinner)
    {
        FillGridForDraw();
        // Assume grid->CheckForWin(char) checks for a winner
        EXPECT_FALSE(CheckForWin(this->grid, 'X')); // No win for X
        EXPECT_FALSE(CheckForWin(this->grid, 'O')); // No win for O
        EXPECT_TRUE(CheckForDraw(this->grid));
    }
}

namespace GridWorks
{
    class RandomizedGridTTTLogicTest : public ::testing::Test
    {
    protected:
        Grid *grid;
        unsigned char randomRows;
        unsigned char randomCols;
        char defaultChar = '.';

        void SetUp() override
        {
            std::srand(static_cast<unsigned int>(std::time(nullptr)));

            // Generate random sizes for the grid.
            // Here we ensure the grid is at least 3x3 and at most 255x255.
            randomRows = static_cast<unsigned char>(std::rand() % 253 + 3); // 0-252 + 3 = 3-255
            randomCols = static_cast<unsigned char>(std::rand() % 253 + 3); // 0-252 + 3 = 3-255

            grid = new Grid(randomRows, randomCols, this->defaultChar);

            DEBUG_TRACE("Grid Info: {0}", grid->GetGridInfo());
        }

        void TearDown() override
        {
            delete grid;
        }

        // Helper function to simulate a player's move on the grid.
        void PlayerMove(char player, unsigned char row, unsigned char col)
        {
            grid->SetCharAt(row, col, player);
        }

        // Helper function to fill the grid and simulate a draw.
        void FillGridForDraw()
        {
            char currentPlayerChar = 'X';

            for (unsigned char i = 0; i < grid->GetRows(); ++i)
            {
                for (unsigned char j = 0; j < grid->GetCols(); ++j)
                {
                    grid->SetCharAt(i, j, currentPlayerChar);
                    // Alternate the player character.
                    currentPlayerChar = (currentPlayerChar == 'X') ? 'O' : 'X';

                    // Avoid a diagonal win by changing the last character of the first diagonal
                    if (i == j && i == grid->GetRows() - 1)
                    {
                        currentPlayerChar = (currentPlayerChar == 'X') ? 'O' : 'X';
                        grid->SetCharAt(i, j, currentPlayerChar);
                    }
                }

                // Change starting character every row to prevent vertical wins
                currentPlayerChar = (currentPlayerChar == 'X') ? 'O' : 'X';
            }
        }

        bool CheckForDraw()
        {
            std::pair<unsigned char, unsigned char> center = grid->GetCenterMostCoords();
            unsigned char row = center.first;
            unsigned char col = center.second;
            for (int row = 0; row < grid->GetRows(); ++row)
            {
                for (int col = 0; col < grid->GetCols(); ++col)
                {
                    if (grid->GetCharAt(row, col) == grid->GetDefaultChar())
                        return false;
                }
            }
            // No spaces left, it's a draw.
            return true;
        }
    };

    // Tests for win conditions in a row for a random-sized grid.
    TEST_F(RandomizedGridTTTLogicTest, WinConditionInRow)
    {
        unsigned char winRow = std::rand() % grid->GetRows();
        for (unsigned char col = 0; col < grid->GetCols(); ++col)
        {
            PlayerMove('X', winRow, col);
        }
        EXPECT_TRUE(grid->CheckForRecurringCharsInRow('X'));
    }

    // Tests for win conditions in a column for a random-sized grid.
    TEST_F(RandomizedGridTTTLogicTest, WinConditionInColumn)
    {
        unsigned char winCol = std::rand() % grid->GetCols();
        for (unsigned char row = 0; row < grid->GetRows(); ++row)
        {
            PlayerMove('O', row, winCol);
        }
        EXPECT_TRUE(grid->CheckForRecurringCharsInCol('O'));
    }

    // Tests for win conditions in the main diagonal for a random-sized grid.
    TEST_F(RandomizedGridTTTLogicTest, WinConditionInDiagonal)
    {
        for (unsigned char i = 0; i < std::min(grid->GetRows(), grid->GetCols()); ++i)
        {
            PlayerMove('X', i, i);
        }

        EXPECT_TRUE(grid->CheckForRecurringCharsInDiagonal('X'));
    }

    // Tests for win conditions in the anti-diagonal for a random-sized grid.
    TEST_F(RandomizedGridTTTLogicTest, WinConditionInAntiDiagonal)
    {
        for (unsigned char i = 0; i < std::min(grid->GetRows(), grid->GetCols()); ++i)
        {
            PlayerMove('O', i, grid->GetCols() - 1 - i);
        }
        EXPECT_TRUE(grid->CheckForRecurringCharsInAntiDiagonal('O'));
    }

    // Test for draw condition
    TEST_F(RandomizedGridTTTLogicTest, DrawCondition)
    {
        FillGridForDraw();
        // Assuming CheckForDraw checks if all cells are filled and there is no winner
        EXPECT_TRUE(this->CheckForDraw());
    }

    // Example test to check if the grid initializes correctly with random sizes
    TEST_F(RandomizedGridTTTLogicTest, GridInitializesCorrectly)
    {
        EXPECT_EQ(grid->GetRows(), randomRows);
        EXPECT_EQ(grid->GetCols(), randomCols);
        for (int row = 0; row < randomRows; ++row)
        {
            for (int col = 0; col < randomCols; ++col)
            {
                EXPECT_EQ(grid->GetCharAt(row, col), this->defaultChar);
            }
        }
    }

    TEST_F(RandomizedGridTTTLogicTest, RandomizedInvalidMoveAttempt)
    {
        unsigned char invalidRow = static_cast<unsigned char>(grid->GetRows() + 1); // Out of bounds
        unsigned char invalidCol = static_cast<unsigned char>(grid->GetCols() + 1); // Out of bounds
        EXPECT_ANY_THROW(PlayerMove('X', invalidRow, invalidCol));                  // Invalid move attempt
    }

};

int main(int argc, char **argv)
{
    DURLIB::Log::Init();

    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}