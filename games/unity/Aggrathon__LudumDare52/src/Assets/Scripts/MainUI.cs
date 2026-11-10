using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class MainUI : MonoBehaviour
{
    public Toggle shadows;

    public void Restart()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex, LoadSceneMode.Single);
    }

    public void Next()
    {
        var index = (SceneManager.GetActiveScene().buildIndex + 1) % SceneManager.sceneCountInBuildSettings;
        SceneManager.LoadScene(index, LoadSceneMode.Single);
    }

    public void ToggleShadows(bool shadows)
    {
        Field.shadows = shadows;
    }

    private void Start()
    {
        if (shadows != null)
        {
            shadows.isOn = Field.shadows;
            shadows.onValueChanged.AddListener(ToggleShadows);
        }
    }
}
