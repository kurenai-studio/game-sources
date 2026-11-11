using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

[CustomEditor(typeof(MonoBehaviour), true)]
public class IDifficultyConfigurableEditor : Editor
{
    public override void OnInspectorGUI()
    {
        // Draw the default inspector
        base.OnInspectorGUI();

        // Check if the target object implements IDifficultyConfigurable
        if (target is IDifficultyConfigurable configurable)
        {
            // Draw a header for the allowed difficulties
            EditorGUILayout.LabelField("Allowed Difficulties", EditorStyles.boldLabel);

            // Get the current allowed difficulties
            List<Difficulty> allowedDifficulties = configurable.GetAllowedDifficulties();

            // Ensure the list is initialized
            if (allowedDifficulties == null)
            {
                allowedDifficulties = new List<Difficulty>();
                configurable.SetAllowedDifficulties(allowedDifficulties);
            }

            // Display checkboxes for each Difficulty enum value
            foreach (Difficulty difficulty in System.Enum.GetValues(typeof(Difficulty)))
            {
                bool isSelected = allowedDifficulties.Contains(difficulty);
                bool newIsSelected = EditorGUILayout.Toggle(difficulty.ToString(), isSelected);

                if (newIsSelected && !isSelected)
                {
                    allowedDifficulties.Add(difficulty);
                }
                else if (!newIsSelected && isSelected)
                {
                    allowedDifficulties.Remove(difficulty);
                }
            }

            // Save changes back to the object
            configurable.SetAllowedDifficulties(allowedDifficulties);

            // Mark the object as dirty to save changes
            if (GUI.changed)
            {
                EditorUtility.SetDirty(target);
            }
        }
    }
}
