using UnityEngine;
using System.Reflection;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class DifficultyMarker : MonoBehaviour
{
    // Method to set the difficulty for all DifficultySettings<T> fields on this GameObject's components
    public void SetDifficulty(Difficulty difficulty)
    {
        // Get all components attached to this GameObject
        var components = GetComponents<MonoBehaviour>();

        foreach (var component in components)
        {
            if (component == null)
                continue;

            // Get all fields in the component
            var fields = component
                .GetType()
                .GetFields(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);

            foreach (var field in fields)
            {
                // Check if the field is of type DifficultySettings<T>
                if (
                    field.FieldType.IsGenericType
                    && field.FieldType.GetGenericTypeDefinition() == typeof(DifficultySettings<>)
                )
                {
                    // Get the field value and call SetDifficulty on it
                    var difficultySetting = field.GetValue(component);
                    if (difficultySetting != null)
                    {
                        var setDifficultyMethod = field.FieldType.GetMethod("SetDifficulty");
                        setDifficultyMethod?.Invoke(difficultySetting, new object[] { difficulty });
                    }
                }
            }
        }
    }

    // Example method to set difficulty to Medium via the Inspector
    public void SetDifficultyToMedium()
    {
        SetDifficulty(Difficulty.Medium);
    }
}

#if UNITY_EDITOR
[CustomEditor(typeof(DifficultyMarker))]
public class DifficultyMarkerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        DifficultyMarker marker = (DifficultyMarker)target;
        if (GUILayout.Button("Set Difficulty to Easy"))
        {
            marker.SetDifficulty(Difficulty.Easy);
        }
        if (GUILayout.Button("Set Difficulty to Medium"))
        {
            marker.SetDifficulty(Difficulty.Medium);
        }
        if (GUILayout.Button("Set Difficulty to Hard"))
        {
            marker.SetDifficulty(Difficulty.Hard);
        }
    }
}
#endif
