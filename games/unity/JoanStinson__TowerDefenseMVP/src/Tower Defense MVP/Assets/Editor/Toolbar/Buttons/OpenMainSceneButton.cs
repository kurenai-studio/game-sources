using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using Debug = UnityEngine.Debug;

namespace JGM.Editor
{
    public static class OpenMainSceneButton
    {
        [ToolbarButton(IconName = "SceneAsset Icon", Tooltip = "Open Main Scene", Order = 100)]
        public static void OnButtonClick()
        {
            var mainScenePath = SceneUtility.GetScenePathByBuildIndex(0);

            if (System.IO.File.Exists(mainScenePath))
            {
                EditorSceneManager.OpenScene(mainScenePath);
            }
            else
            {
                Debug.LogError($"Scene not found at path: {mainScenePath}");
            }
        }
    }
}