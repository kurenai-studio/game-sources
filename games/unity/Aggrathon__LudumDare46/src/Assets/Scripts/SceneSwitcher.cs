using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneSwitcher : MonoBehaviour
{
    public void RestartScene() {
        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }

    public void LoadScene(string name) {
        SceneManager.LoadScene(name);
    }
}
