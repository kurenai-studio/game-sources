using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class LevelManager : MonoBehaviour
{

    public void LoadNext()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1, LoadSceneMode.Single);
    }

    public void LoadPrev()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex - 1, LoadSceneMode.Single);
    }

    public void LoadMenu()
    {
        SceneManager.LoadScene(0, LoadSceneMode.Single);
    }

    public void LoadLast()
    {
        SceneManager.LoadScene(SceneManager.sceneCountInBuildSettings - 1, LoadSceneMode.Single);
    }

    public void Reload()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex, LoadSceneMode.Single);
    }

    public static string GetSceneNameFromBuildIndex(int index)
    {
        string path = SceneUtility.GetScenePathByBuildIndex(index);
        int start = path.LastIndexOf('/') + 1;
        return path.Substring(start, path.Length - start - 6);
    }

    public static string GetSceneName()
    {
        return SceneManager.GetActiveScene().name;
        // return GetSceneNameFromBuildIndex(SceneManager.GetActiveScene().buildIndex);
    }
}
