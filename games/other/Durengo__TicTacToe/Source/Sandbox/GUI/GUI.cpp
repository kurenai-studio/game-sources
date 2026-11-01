#include "GUI.h"

#include <durlib.h>
#include <raylib.h>

#include "GUI/BasicButton.h"
#include "GUI/BasicText.h"

namespace GWSandbox
{
    GUI *GUI::i_instance{nullptr};
    std::mutex GUI::i_mutex;
    GridWorks::GameLogic *GUI::i_gameLogic;
    bool GUI::i_randomizeFirstPlayer{true};

    // Constructors & Destructors
    GUI::GUI()
    {
        GridWorks::GameLogic::Initialize();
        i_instance->i_gameLogic = GridWorks::GameLogic::GetInstance();
    }

    GUI::~GUI()
    {
        if (i_instance->i_gameLogic != nullptr)
        {
            i_instance->i_gameLogic = nullptr;
            GridWorks::GameLogic::DeleteInstance();
        }
    }

    void GUI::Initialize()
    {
        std::lock_guard<std::mutex> lock(i_mutex);
        if (i_instance == nullptr)
        {
            i_instance = new GUI();
        }
    }

    void GUI::DeleteInstance()
    {
        std::lock_guard<std::mutex> lock(i_mutex);
        if (i_instance != nullptr)
        {
            delete i_instance;
            i_instance = nullptr;
        }
    }

    // Getters & Setters

    GUI *GUI::GetInstance()
    {
        DEBUG_ASSERT(i_instance, "GUI instance not initialized.");

        return i_instance;
    }

    GridWorks::GameLogic *GUI::GetGameLogic()
    {
        DEBUG_ASSERT(i_instance, "GUI instance not initialized.");

        return i_instance->i_gameLogic;
    }

    void GUI::SetGameConfiguration(GridWorks::GameConfiguration *gameConfiguration)
    {
        DEBUG_ASSERT(i_instance, "GUI instance not initialized.");
        DEBUG_ASSERT(i_instance->i_gameLogic, "GameLogic instance not initialized.");

        i_instance->i_gameLogic->SetGameConfiguration(gameConfiguration);

        i_instance->m_gridSize = i_instance->i_gameLogic->GetGrid()->GetRows();
    }

    void GUI::SetRandomizeFirstPlayer(bool randomizeFirstPlayer)
    {
        DEBUG_ASSERT(i_instance, "GUI instance not initialized.");

        i_instance->i_randomizeFirstPlayer = randomizeFirstPlayer;
    }

    // Private methods

    bool GUI::CheckInit()
    {
        if (i_instance == nullptr)
        {
            CLI_ERROR("GUI instance not initialized.");
            return false;
        }
        return true;
    }

    void GUI::DrawGrid()
    {
        // Set the desired padding around the grid
        float padding = i_instance->m_margin;

        // Calculate the size of the cells to fit the grid in the window, accounting for padding
        i_instance->m_cellSize = (std::min(i_instance->m_windowResolution.width, i_instance->m_windowResolution.height) - (2 * padding)) / static_cast<float>(i_instance->m_gridSize);

        // Calculate any necessary offsets if the window is not square
        float xOffset = (i_instance->m_windowResolution.width - (i_instance->m_cellSize * i_instance->m_gridSize)) / 2.0f;
        float yOffset = (i_instance->m_windowResolution.height - (i_instance->m_cellSize * i_instance->m_gridSize)) / 2.0f;

        // Adjust offsets for padding
        xOffset = std::max(xOffset, padding);
        yOffset = std::max(yOffset, padding);

        // Draw vertical lines
        for (int i = 0; i <= i_instance->m_gridSize; i++)
        {
            float lineX = xOffset + i * i_instance->m_cellSize;
            DrawLine(lineX, yOffset, lineX, yOffset + i_instance->m_cellSize * i_instance->m_gridSize, GRAY);
        }

        // Draw horizontal lines
        for (int i = 0; i <= i_instance->m_gridSize; i++)
        {
            float lineY = yOffset + i * i_instance->m_cellSize;
            DrawLine(xOffset, lineY, xOffset + i_instance->m_cellSize * i_instance->m_gridSize, lineY, GRAY);
        }

        // Iterate over the grid state and draw 'X' or 'O' as needed
        for (int i = 0; i < i_instance->m_gridSize; i++)
        {
            for (int j = 0; j < i_instance->m_gridSize; j++)
            {
                if (i_instance->i_gameLogic->GetGrid()->GetCharAt(i, j) == GridWorks::MoveTypeEnumToChar(GridWorks::MoveType::X))
                {
                    i_instance->DrawX(i, j);
                }
                else if (i_instance->i_gameLogic->GetGrid()->GetCharAt(i, j) == GridWorks::MoveTypeEnumToChar(GridWorks::MoveType::O))
                {
                    i_instance->DrawO(i, j);
                }
                else if (i_instance->i_gameLogic->GetGrid()->GetCharAt(i, j) == i_instance->i_gameLogic->GetGrid()->GetDefaultChar())
                {
                    // Do nothing
                }
                else
                {
                    throw std::runtime_error("Invalid cell type.");
                }
            }
        }
    }

    Vector2 GUI::GetCellFromMouse(Vector2 mousePosition)
    {
        // Calculate the starting point of the grid on the screen
        float gridStartX = (i_instance->m_windowResolution.width - (i_instance->m_cellSize * i_instance->m_gridSize)) / 2.0f;
        float gridStartY = (i_instance->m_windowResolution.height - (i_instance->m_cellSize * i_instance->m_gridSize)) / 2.0f;

        // Adjust the mouse position by subtracting the starting point of the grid
        float adjustedMouseX = mousePosition.x - gridStartX;
        float adjustedMouseY = mousePosition.y - gridStartY;

        // Check if the adjusted mouse position is outside the bounds of the grid
        if (adjustedMouseX < 0 || adjustedMouseY < 0 || adjustedMouseX >= (i_instance->m_cellSize * i_instance->m_gridSize) || adjustedMouseY >= (i_instance->m_cellSize * i_instance->m_gridSize))
        {
            // Outside of grid bounds, return an invalid cell position
            return Vector2(-1, -1);
        }

        // Convert the adjusted mouse position to cell indices
        int cellIndexX = static_cast<int>(adjustedMouseX / i_instance->m_cellSize);
        int cellIndexY = static_cast<int>(adjustedMouseY / i_instance->m_cellSize);

        // The Y coordinate needs to be inverted because the 2D array (0,0) starts at the top-left
        // but in screen coordinates, Y increases as you go down.
        // Since we are not using an upside-down grid, we don't invert Y.

        return Vector2(static_cast<float>(cellIndexX), static_cast<float>(cellIndexY));
    }

    void GUI::DrawX(int row, int col)
    {
        float padding = i_instance->m_margin; // Use the same margin for consistency

        // Calculate offsets for non-square windows (same as in DrawGrid)
        float xOffset = (i_instance->m_windowResolution.width - (i_instance->m_cellSize * i_instance->m_gridSize)) / 2.0f;
        float yOffset = (i_instance->m_windowResolution.height - (i_instance->m_cellSize * i_instance->m_gridSize)) / 2.0f;
        xOffset = std::max(xOffset, padding);
        yOffset = std::max(yOffset, padding);

        // Calculate the starting and ending points for the two lines of the X
        float startX = xOffset + col * i_instance->m_cellSize + padding;
        float startY = yOffset + row * i_instance->m_cellSize + padding;
        float endX = xOffset + (col + 1) * i_instance->m_cellSize - padding;
        float endY = yOffset + (row + 1) * i_instance->m_cellSize - padding;

        // Draw the first diagonal line of the X
        DrawLine(startX, startY, endX, endY, BLACK);

        // Draw the second diagonal line of the X
        DrawLine(startX, endY, endX, startY, BLACK);
    }

    void GUI::DrawO(int row, int col)
    {
        // Use the same margin for consistency and to make sure 'O' is within the cell bounds
        float padding = i_instance->m_margin;

        // Calculate offsets for non-square windows (same as in DrawGrid)
        float xOffset = (i_instance->m_windowResolution.width - (i_instance->m_cellSize * i_instance->m_gridSize)) / 2.0f;
        float yOffset = (i_instance->m_windowResolution.height - (i_instance->m_cellSize * i_instance->m_gridSize)) / 2.0f;
        xOffset = std::max(xOffset, padding);
        yOffset = std::max(yOffset, padding);

        // Radius of 'O' should probably be a bit less than half the cell size to fit within the cell,
        // minus some padding to avoid touching the cell borders.
        float radius = (i_instance->m_cellSize / 2) - padding;

        // Center point calculations now include the offset and padding
        float centerX = xOffset + col * i_instance->m_cellSize + (i_instance->m_cellSize / 2);
        float centerY = yOffset + row * i_instance->m_cellSize + (i_instance->m_cellSize / 2);

        DrawCircleLines(centerX, centerY, radius, BLACK);
    }

    void GUI::ChangeGridLayout()
    {
        CLI_TRACE("Input the dimensions of the grid (3-10): ");
        unsigned char dimensions = static_cast<unsigned char>(DURLIB::GIBI(3, 10));
        m_gridSize = dimensions;

        i_instance->i_gameLogic->GetGameConfiguration()->grid->ResetGridWithNewSize(dimensions, dimensions, '.');
    }

    void GUI::ChangeTurnOrder()
    {
        int choice = 0;
        while (choice == 0)
        {
            CLI_TRACE("\n1. Start as X\n2. Start as O\n3. Random");
            choice = DURLIB::GIBI(1, 3);
        }

        if (choice == 1)
        {
            if (i_instance->i_gameLogic->GetPlayers()[0]->GetPlayerName() == "Player1")
            {
                i_instance->i_gameLogic->GetPlayers()[0]->SetPlayerMoveType(GridWorks::MoveType::X);
                i_instance->i_gameLogic->GetPlayers()[1]->SetPlayerMoveType(GridWorks::MoveType::O);
            }
            else
            {
                i_instance->i_gameLogic->GetPlayers()[0]->SetPlayerMoveType(GridWorks::MoveType::O);
                i_instance->i_gameLogic->GetPlayers()[1]->SetPlayerMoveType(GridWorks::MoveType::X);
                i_instance->i_gameLogic->SwapPlayerPositions();
            }

            i_instance->SetRandomizeFirstPlayer(false);
        }
        else if (choice == 2)
        {
            if (i_instance->i_gameLogic->GetPlayers()[0]->GetPlayerName() == "Player1")
            {
                i_instance->i_gameLogic->GetPlayers()[0]->SetPlayerMoveType(GridWorks::MoveType::O);
                i_instance->i_gameLogic->GetPlayers()[1]->SetPlayerMoveType(GridWorks::MoveType::X);
            }
            else
            {
                i_instance->i_gameLogic->GetPlayers()[0]->SetPlayerMoveType(GridWorks::MoveType::X);
                i_instance->i_gameLogic->GetPlayers()[1]->SetPlayerMoveType(GridWorks::MoveType::O);
                i_instance->i_gameLogic->SwapPlayerPositions();
            }

            // i_instance->i_gameLogic->GetPlayers()[0]->SetPlayerMoveType(GridWorks::MoveType::O);
            // i_instance->i_gameLogic->GetPlayers()[1]->SetPlayerMoveType(GridWorks::MoveType::X);

            // GridWorks::Player *temp = i_instance->i_gameLogic->GetPlayers()[1];
            // i_instance->i_gameLogic->GetPlayers()[1] = i_instance->i_gameLogic->GetPlayers()[0];
            // i_instance->i_gameLogic->GetPlayers()[0] = temp;

            i_instance->SetRandomizeFirstPlayer(false);
        }
        else if (choice == 3)
        {
            i_instance->SetRandomizeFirstPlayer(true);
        }

        switch (i_instance->i_randomizeFirstPlayer)
        {
        case true:
            i_instance->i_gameLogic->SetRandomizeTurnOrder(true);
            break;
        case false:
            i_instance->i_gameLogic->SetRandomizeTurnOrder(false);
            break;
        }

        unsigned int dimension = i_instance->i_gameLogic->GetGrid()->GetRows();
        char defaultChar = i_instance->i_gameLogic->GetGrid()->GetDefaultChar();

        i_instance->i_gameLogic->GetGameConfiguration()->grid->ResetGridWithNewSize(dimension, dimension, defaultChar);
    }

    // Public methods

    void GUI::InitializeWindow(std::string windowName, int screenWidth, int screenHeight, int targetFPS)
    {
        DEBUG_ASSERT(i_instance, "GUI instance not initialized.");

        i_instance->m_windowName = windowName;
        i_instance->m_windowResolution.width = screenWidth;
        i_instance->m_windowResolution.height = screenHeight;
        i_instance->m_targetFPS = targetFPS;

        i_instance->m_lineThickness = 2.5f;
        i_instance->m_margin = 20.0f;
        // i_instance->m_gridSize = gridSize;
        // i_instance->m_cellSize = static_cast<float>(i_instance->m_windowResolution.width) / i_instance->m_gridSize;
        // i_instance->m_cellSize = std::min(i_instance->m_windowResolution.width, i_instance->m_windowResolution.height) / static_cast<float>(i_instance->m_gridSize);

        SetConfigFlags(FLAG_WINDOW_RESIZABLE);

        InitWindow(m_windowResolution.width, m_windowResolution.height, m_windowName.c_str());

        SetTargetFPS(m_targetFPS);
    }

    void GUI::BeginMainLoop()
    {
        DEBUG_ASSERT(i_instance, "GUI instance not initialized.");
        DEBUG_ASSERT(i_instance->i_gameLogic, "GameLogic instance not initialized.");

        switch (i_instance->i_randomizeFirstPlayer)
        {
        case true:
            i_instance->i_gameLogic->SetRandomizeTurnOrder(true);
            break;
        case false:
            i_instance->i_gameLogic->SetRandomizeTurnOrder(false);
            break;
        }

        i_instance->i_gameLogic->SetupGame();
        i_instance->i_gameLogic->StartGame();

        Button restartButton(
            {static_cast<float>(i_instance->m_windowResolution.width) / 2 - 100, static_cast<float>(i_instance->m_windowResolution.height) / 2 + 30, 200, 40},
            GRAY, DARKGRAY, LIGHTGRAY, []()
            {
                CLI_TRACE("Restarting game...");
                i_instance->i_gameLogic->ResetGame();
                i_instance->i_gameLogic->SetGameState(GridWorks::GameState::InProgress); },
            "Restart", false);

        Button changeGridButton(
            {static_cast<float>(i_instance->m_windowResolution.width) / 2 - 100, static_cast<float>(i_instance->m_windowResolution.height) / 2 + 90, 200, 40},
            GRAY, DARKGRAY, LIGHTGRAY, []()
            {
                CLI_TRACE("Changing Grid Layout");
                i_instance->ChangeGridLayout();

                i_instance->i_gameLogic->ResetGame();
                i_instance->i_gameLogic->SetGameState(GridWorks::GameState::InProgress); },
            "Change Grid", false);

        // Button changeTurnOrderButton(
        //     {static_cast<float>(i_instance->m_windowResolution.width) / 2 - 100, static_cast<float>(i_instance->m_windowResolution.height) / 2 + 150, 200, 40},
        //     GRAY, DARKGRAY, LIGHTGRAY, []()
        //     {
        //         CLI_TRACE("Changing Turn Order");
        //         i_instance->ChangeTurnOrder();

        //         i_instance->i_gameLogic->ResetGame();
        //         i_instance->i_gameLogic->SetGameState(GridWorks::GameState::InProgress); },
        //     "Change Turns", false);

        GWSandbox::BasicText gameOverText("Game Over!", 20, 0, 100, BLACK, GWSandbox::Justify::CENTER_X, i_instance->m_windowResolution.width, i_instance->m_windowResolution.height);

        GWSandbox::BasicText winnerText("Winner: ", 20, 0, 150, BLACK, GWSandbox::Justify::CENTER_X, i_instance->m_windowResolution.width, i_instance->m_windowResolution.height);

        GWSandbox::BasicText currentPlayerText("Current Player: ", 8, 5, 5, BLACK, GWSandbox::Justify::NONE, i_instance->m_windowResolution.width, i_instance->m_windowResolution.height);
        GWSandbox::BasicText turnText("Turn: ", 8, 5, 20, BLACK, GWSandbox::Justify::NONE, i_instance->m_windowResolution.width, i_instance->m_windowResolution.height);

        GWSandbox::BasicText drawText("Draw!", 20, 0, 100, BLACK, GWSandbox::Justify::CENTER_X, i_instance->m_windowResolution.width, i_instance->m_windowResolution.height);

        while (!WindowShouldClose()) // Detect window close button or ESC key
        {
            i_instance->m_windowResolution.width = GetScreenWidth();
            i_instance->m_windowResolution.height = GetScreenHeight();
            // Update
            if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON) && i_instance->i_gameLogic->GetGameState() != GridWorks::GameState::GameOver)
            {
                Vector2 cell = GetCellFromMouse(GetMousePosition());

                try
                {
                    if (cell.x == -1 || cell.y == -1)
                        throw std::runtime_error("Invalid cell position.");
                    else
                        i_instance->i_gameLogic->MakeMove((unsigned char)cell.y, (unsigned char)cell.x);
                }
                catch (const std::runtime_error &e)
                {
                    CLI_WARN(e.what());
                }
                catch (const std::exception &e)
                {
                    CLI_FATAL(e.what());
                }
            }

            restartButton.Update();
            changeGridButton.Update();
            // changeTurnOrderButton.Update();

            // Draw
            BeginDrawing();
            ClearBackground(RAYWHITE);
            if (i_instance->i_gameLogic->GetGameState() == GridWorks::GameState::InProgress)
            {
                restartButton.isEnabled = false;
                changeGridButton.isEnabled = false;
                // changeTurnOrderButton.isEnabled = false;

                DrawGrid();
                currentPlayerText.SetText("Current Player: " + i_instance->i_gameLogic->GetGameConfiguration()->turnManager->GetCurrentPlayer().ptr->GetPlayerName());
                turnText.SetText("Turn: " + GridWorks::MoveTypeEnumToString(i_instance->i_gameLogic->GetGameConfiguration()->turnManager->GetCurrentPlayer().ptr->GetPlayerMoveType()));
                currentPlayerText.Draw();
                turnText.Draw();
            }
            else if (i_instance->i_gameLogic->GetGameState() == GridWorks::GameState::GameOver)
            {
                if (i_instance->i_gameLogic->GetGameOverType() == GridWorks::GameOverType::Win)
                {
                    restartButton.isEnabled = true;
                    changeGridButton.isEnabled = true;
                    // changeTurnOrderButton.isEnabled = true;

                    winnerText.SetText("Winner: " + i_instance->i_gameLogic->GetWinner()->GetPlayerName() + " (" + GridWorks::MoveTypeEnumToString(i_instance->i_gameLogic->GetWinner()->GetPlayerMoveType()) + ")");
                    gameOverText.Draw();
                    winnerText.Draw();
                    restartButton.Draw();
                    changeGridButton.Draw();
                    // changeTurnOrderButton.Draw();
                }
                else if (i_instance->i_gameLogic->GetGameOverType() == GridWorks::GameOverType::Draw)
                {
                    restartButton.isEnabled = true;
                    changeGridButton.isEnabled = true;
                    // changeTurnOrderButton.isEnabled = true;

                    drawText.Draw();
                    restartButton.Draw();
                    changeGridButton.Draw();
                    // changeTurnOrderButton.Draw();
                }
            }

            EndDrawing();
        }

        CloseWindow();
    }
}