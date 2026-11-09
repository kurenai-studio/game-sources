using UnityEditor;
using UnityEngine;

namespace JGM.Editor
{
    public static class OpenWaveListButton
    {
        private const string WavesListPath = "Assets/Settings/Waves/Wave List.asset";

        [ToolbarButton(IconName = "VerticalLayoutGroup Icon", Tooltip = "Open Wave List", Order = -200)]
        public static void OnButtonClick()
        {
            var wavesList = AssetDatabase.LoadAssetAtPath<Object>(WavesListPath);

            if (wavesList == null)
            {
                Debug.LogError($"Wave List asset not found at path: {WavesListPath}");
                return;
            }

            EditorUtility.FocusProjectWindow();
            Selection.activeObject = wavesList;
            EditorGUIUtility.PingObject(wavesList);
        }
    }
}