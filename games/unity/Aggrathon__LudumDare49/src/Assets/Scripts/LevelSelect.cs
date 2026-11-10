using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using TMPro;

public class LevelSelect : MonoBehaviour
{
    void Start()
    {
        var levels = SceneManager.sceneCountInBuildSettings - 2;
        Transform prefab = transform.GetChild(0);
        for (int i = transform.childCount; i < levels; i++)
        {
            Instantiate(prefab, prefab.position, prefab.rotation, transform);
        }
        for (int i = 0; i < levels; i++)
        {
            var tr = transform.GetChild(i);
            int j = i + 1;
            string name = LevelManager.GetSceneNameFromBuildIndex(j);
            tr.GetChild(0).GetComponent<TextMeshProUGUI>().text = name;
            string score = string.Format("{0,4:d}  {1,3:d}", PlayerPrefs.GetInt("time_" + name, 9999), PlayerPrefs.GetInt("num_" + name, 0));
            tr.GetChild(1).GetComponent<TextMeshProUGUI>().text = score;
            tr.GetChild(2).GetComponent<Button>().onClick.AddListener(() => SceneManager.LoadScene(j, LoadSceneMode.Single));
        }
    }
}
