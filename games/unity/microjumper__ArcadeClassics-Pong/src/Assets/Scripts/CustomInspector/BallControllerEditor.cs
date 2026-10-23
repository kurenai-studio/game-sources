using UnityEditor;
using UnityEngine;

namespace CustomInspector
{
    [CustomEditor(typeof(Ball))]
    public class BallControllerEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            // Draw the default inspector (shows ballDataTemplate normally)
            DrawDefaultInspector();

            var controller = (Ball)target;

            // Only show the runtime copy while the game is playing
            if (Application.isPlaying && controller.RuntimeBallData)
            {
                EditorGUILayout.Space();
            
                EditorGUILayout.LabelField("Runtime Ball Data", EditorStyles.boldLabel);

                // Create a nested inspector for the runtime ScriptableObject
                using (new EditorGUI.DisabledScope(false))
                {
                    var runtimeEditor = CreateEditor(controller.RuntimeBallData);
                
                    if (runtimeEditor)
                    {
                        runtimeEditor.OnInspectorGUI();
                    }
                }
            }
            else
            {
                EditorGUILayout.HelpBox("Runtime data will appear here in Play Mode.", MessageType.Info);
            }
        }
    }
}
