using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ToScene : MonoBehaviour
{
    public string scene_name;

    public void GoToScene()
    {
        SceneManager.LoadScene(scene_name);
    }
}
