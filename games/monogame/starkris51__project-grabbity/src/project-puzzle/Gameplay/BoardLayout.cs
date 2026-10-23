using Microsoft.Xna.Framework;

namespace Gameplay;

public static class BoardLayout
{
    public static Rectangle[] GetViewports(int boardCount, int screenWidth, int screenHeight)
    {
        if (boardCount < 1) boardCount = 1;

        var viewports = new Rectangle[boardCount];
        int columnWidth = screenWidth / boardCount;

        for (int i = 0; i < boardCount; i++)
        {
            int width = (i == boardCount - 1) ? screenWidth - columnWidth * i : columnWidth;
            viewports[i] = new Rectangle(i * columnWidth, 0, width, screenHeight);
        }

        return viewports;
    }
}
