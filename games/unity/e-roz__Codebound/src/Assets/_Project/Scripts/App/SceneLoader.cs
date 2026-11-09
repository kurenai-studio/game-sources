using UnityEngine.SceneManagement;

namespace Codebound.App
{
    public static class SceneLoader
    {
        public const string MainMenuScene = "MainMenu";
        public const string RoomScene = "Room";

        public static void LoadRoom(string roomId)
        {
            GameSession.SelectRoom(roomId);
            SceneManager.LoadScene(RoomScene);
        }

        public static void LoadKeepMap()
        {
            GameSession.RequestReturnToKeep();
            SceneManager.LoadScene(MainMenuScene);
        }
    }
}
