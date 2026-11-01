#include <GUI/GUI.h>

#include <durlib.h>

int main(void)
{
    DURLIB::Log::Init();

    GWSandbox::GUI::Initialize();
    GWSandbox::GUI *gui = GWSandbox::GUI::GetInstance();

    GridWorks::Player *p1 = new GridWorks::Player("Player1", GridWorks::PlayerType::Human);
    GridWorks::Player *p2 = new GridWorks::Player("Player2", GridWorks::PlayerType::Human);

    unsigned char dimensions = 3;

    CLI_TRACE("Input the dimensions of the grid (3-10): ");
    dimensions = static_cast<unsigned char>(DURLIB::GIBI(3, 10));

    int choice = 0;
    while (choice == 0)
    {
        CLI_TRACE("\n1. Start as X\n2. Start as O\n3. Random");
        choice = DURLIB::GIBI(1, 3);
    }

    if (choice == 1)
    {
        p1->SetPlayerMoveType(GridWorks::MoveType::X);
        p2->SetPlayerMoveType(GridWorks::MoveType::O);
        gui->SetRandomizeFirstPlayer(false);
        gui->SetGameConfiguration(GridWorks::GameConfigurationBuilder()
                                      .setGameName("TicTacToe")
                                      .setGameDescription("TicTacToe Game")
                                      .setGrid(dimensions, dimensions, '.')
                                      .setMaxPlayers(2)
                                      .addPlayer(p1)
                                      .addPlayer(p2)
                                      .build());
    }
    else if (choice == 2)
    {
        p1->SetPlayerMoveType(GridWorks::MoveType::O);
        p2->SetPlayerMoveType(GridWorks::MoveType::X);
        gui->SetRandomizeFirstPlayer(false);
        gui->SetGameConfiguration(GridWorks::GameConfigurationBuilder()
                                      .setGameName("TicTacToe")
                                      .setGameDescription("TicTacToe Game")
                                      .setGrid(dimensions, dimensions, '.')
                                      .setMaxPlayers(2)
                                      .addPlayer(p2)
                                      .addPlayer(p1)
                                      .build());
    }
    else if (choice == 3)
    {
        gui->SetRandomizeFirstPlayer(true);
        gui->SetGameConfiguration(GridWorks::GameConfigurationBuilder()
                                      .setGameName("TicTacToe")
                                      .setGameDescription("TicTacToe Game")
                                      .setGrid(dimensions, dimensions, '.')
                                      .setMaxPlayers(2)
                                      .addPlayer(p1)
                                      .addPlayer(p2)
                                      .build());
    }

    gui->InitializeWindow("GridWorks", 800, 600, 60);
    gui->BeginMainLoop();

    return 0;
}