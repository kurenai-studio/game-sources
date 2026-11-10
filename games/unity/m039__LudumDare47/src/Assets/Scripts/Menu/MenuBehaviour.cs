using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class MenuBehaviour : MonoBehaviour
{
    public RectTransform mainGroup;

    public RectTransform authorsGroup;

    public RectTransform optionsGroup;

    RectTransform[] _groups;

    void Awake()
    {
        _groups = new RectTransform[]
        {
            mainGroup,
            authorsGroup,
            optionsGroup
        };

        SelectGroup(mainGroup);
    }

    void SelectGroup(RectTransform group)
    {
        foreach (var g in _groups)
        {
            g.gameObject.SetActive(g == group);
        }
    }

    public void StartGame()
    {
        SceneManager.LoadScene("Orbits");
    }

    public void QuitGame() {
        Application.Quit();
    }

    public void SelectOptions()
    {
        SelectGroup(optionsGroup);
    }

    public void SelectAuthors()
    {
        SelectGroup(authorsGroup);
    }

    public void BackToMainGroup()
    {
        SelectGroup(mainGroup);
    }

    public void SelectEnglish()
    {
        var language = LocalizedLanguage.English.ToString();
        StorageSystem.Settings.SetSelectedLanguage(language);
        LocalisationManager.SetLanguage(language);
        UpdateAllLocalizedText();
    }

    public void SelectRussian()
    {
        var language = LocalizedLanguage.Russian.ToString();
        StorageSystem.Settings.SetSelectedLanguage(language);
        LocalisationManager.SetLanguage(language);
        UpdateAllLocalizedText();
    }

    void UpdateAllLocalizedText()
    {
        var texts = GetComponentsInChildren<LocalizedText>();
        foreach (var t in texts)
        {
            t.UpdateText();
        }
    }
}
