using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public enum LocalizedLanguage
{
    Russian, English
}

public enum LocalizedString
{
    game_name,
    start_game,
    authors,
    options,
    back,
    authors_top,
    authors_name,
    authors_info,
    quit
}

[ExecuteInEditMode]
public class LocalizedText : MonoBehaviour
{
    public LocalizedString stringKey;

    private void OnEnable()
    {
        UpdateText();
    }

    private void OnValidate()
    {
        UpdateText();
    }

    public void UpdateText()
    {
        var textMeshPro = GetComponentInChildren<TextMeshProUGUI>();
        if (textMeshPro != null)
        {
            textMeshPro.text = LocalisationManager.GetString(stringKey.ToString());
        }
    }
}
