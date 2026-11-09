using TMPro;
using UnityEngine;

public class LevelNameDisplay : MonoBehaviour
{
    private TMP_Text levelNameText;

    private void Awake()
    {
        levelNameText =
            GetComponent<TMP_Text>();

        if (levelNameText == null)
        {
            Debug.LogError(
                "LevelNameDisplay must be attached to LevelNameText."
            );
        }
    }

    private void Start()
    {
        UpdateLevelName();
    }

    private void UpdateLevelName()
    {
        if (levelNameText == null)
        {
            return;
        }

        int selectedLevel =
            LevelSelectionData.SelectedLevel;

        string levelName =
            LevelSettingsData.GetLevelName();

        levelNameText.text =
            $"LEVEL {selectedLevel} • {levelName}";
    }
}