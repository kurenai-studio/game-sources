#include <gtest/gtest.h>
#include "Grid/Grid.h"

int main(int argc, char **argv)
{
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}

namespace GridWorks
{
    // Test fixture for Grid.
    class GridTest : public ::testing::Test
    {
    protected:
        Grid *grid;

        void SetUp() override
        {
            grid = new Grid(10, 10, '*');
        }

        void TearDown() override
        {
            delete grid;
        }
    };

    // Test cases.
    TEST_F(GridTest, Constructor)
    {
        EXPECT_EQ(grid->GetRows(), 10);
        EXPECT_EQ(grid->GetCols(), 10);

        // Check if all elements are initialized to '*'.
        for (int i = 0; i < grid->GetRows(); ++i)
        {
            for (int j = 0; j < grid->GetCols(); ++j)
            {
                EXPECT_EQ((*grid)[i][j], '*');
            }
        }
    }

    // Test constructor with dimensions.
    TEST_F(GridTest, ConstructorWithDimensions)
    {
        Grid tempGrid(5, 5);
        EXPECT_EQ(tempGrid.GetRows(), 5);
        EXPECT_EQ(tempGrid.GetCols(), 5);
    }

    // Test constructor with dimensions and initial char.
    TEST_F(GridTest, ConstructorWithDimensionsAndInitialChar)
    {
        char initialChar = '#';
        Grid tempGrid(5, 5, initialChar);

        // Check if all cells contain the initial char.
        for (int i = 0; i < tempGrid.GetRows(); ++i)
        {
            for (int j = 0; j < tempGrid.GetCols(); ++j)
            {
                EXPECT_EQ(tempGrid.GetGrid()[i][j], initialChar);
            }
        }
    }

    // Test index operator for valid index.
    TEST_F(GridTest, IndexOperatorValid)
    {
        grid->GetGrid()[0][0] = 'X';
        EXPECT_EQ((*grid)[0][0], 'X');
    }

    // Test index operator for invalid index.
    TEST_F(GridTest, IndexOperatorInvalid)
    {
        EXPECT_THROW((*grid)[grid->GetRows()], std::out_of_range);
        // EXPECT_ANY_THROW((*grid)[grid->GetRows()]);
    }

    // Test setters.
    TEST_F(GridTest, Setters)
    {
        grid->SetRows(5);
        grid->SetCols(5);

        EXPECT_EQ(grid->GetRows(), 5);
        EXPECT_EQ(grid->GetCols(), 5);
    }

    // Test getters.
    TEST_F(GridTest, Operator)
    {
        (*grid)[0][0] = 'X';
        (*grid)[1][1] = 'X';
        (*grid)[2][2] = 'X';

        EXPECT_EQ((*grid)[0][0], 'X');
        EXPECT_EQ((*grid)[1][1], 'X');
        EXPECT_EQ((*grid)[2][2], 'X');
    }

    // Test getters.
    TEST_F(GridTest, GetGrid)
    {
        char **gridArray = grid->GetGrid();

        EXPECT_EQ(gridArray[0][0], '*');
        EXPECT_EQ(gridArray[1][1], '*');
        EXPECT_EQ(gridArray[2][2], '*');
    }

    // Test getters.
    TEST_F(GridTest, GetRows)
    {
        EXPECT_EQ(grid->GetRows(), 10);
    }

    // Test getters.
    TEST_F(GridTest, GetCols)
    {
        EXPECT_EQ(grid->GetCols(), 10);
    }

    // Test copy constructor.
    TEST_F(GridTest, CopyConstructor)
    {
        // Create a new grid with a custom destructor.
        Grid *grid = new Grid(10, 10, '*');

        // Copy the grid.
        Grid *gridCopy = new Grid(*grid);

        // Check if the copy is correct.
        EXPECT_EQ(gridCopy->GetRows(), 10);
        EXPECT_EQ(gridCopy->GetCols(), 10);

        // Check if all elements are initialized to '*'.
        for (int i = 0; i < gridCopy->GetRows(); ++i)
        {
            for (int j = 0; j < gridCopy->GetCols(); ++j)
            {
                EXPECT_EQ((*gridCopy)[i][j], '*');
            }
        }
    }

    // Test formatting output.
    TEST_F(GridTest, FormattingOutput)
    {
        // Create a new grid with a custom destructor.
        Grid *actual = new Grid(3, 3, '*');
        std::string expectedOutput = "\n* * *\n* * *\n* * *";
        EXPECT_EQ(fmt::format("{}", *actual), expectedOutput);
    }

}