using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ReloadMainScene : MonoBehaviour
{
    public void ReloadScene()
    {
        UnityEngine.SceneManagement.SceneManager.LoadScene(1);
    }
}
