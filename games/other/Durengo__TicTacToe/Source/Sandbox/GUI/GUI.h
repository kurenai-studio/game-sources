#pragma once

#include <mutex>
#include <string>

#include <gridworks.h>

struct Vector2;

namespace GWSandbox
{
    struct WindowResolution
    {
        int width;
        int height;
    };
    class GUI
    {
    private:
        static GUI *i_instance;
        static std::mutex i_mutex;
        static GridWorks::GameLogic *i_gameLogic;
        static bool i_randomizeFirstPlayer;

        std::string m_windowName;
        WindowResolution m_windowResolution;
        int m_targetFPS;
        float m_gridSize;
        float m_cellSize;
        float m_lineThickness;
        float m_margin;

        // Constructors & Destructors
    protected:
        GUI();
        ~GUI();

        // Constructors & Destructors
    public:
        // We don't want to allow copying of our singletons, so delete these operators
        GUI(GUI &other) = delete;
        void operator=(const GUI &) = delete;

        static void Initialize();
        static void DeleteInstance();

        // Getters & Setters
    public:
        static GUI *GetInstance();

        static GridWorks::GameLogic *GetGameLogic();

        static void SetGameConfiguration(GridWorks::GameConfiguration *gameConfiguration);

        static void SetRandomizeFirstPlayer(bool randomizeFirstPlayer);

        // Private methods
    private:
        static bool CheckInit();

        static void DrawGrid();

        static Vector2 GetCellFromMouse(Vector2 mousePosition);

        void DrawX(int row, int col);
        void DrawO(int row, int col);

        void ChangeGridLayout();

        void ChangeTurnOrder();

        // Public methods
    public:
        void InitializeWindow(std::string windowName, int screenWidth, int screenHeight, int targetFPS);
        void BeginMainLoop();
    };
}