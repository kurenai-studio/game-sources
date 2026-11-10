using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using TMPro;

[RequireComponent(typeof(AudioSource))]
public class Outro : MonoBehaviour
{

    public TextMeshProUGUI text;
    public GameObject otherUI;

    public AudioClip goodSound;
    public AudioClip badSound;

    public void ShowBad(string description)
    {
        text.text = description;
        gameObject.SetActive(true);
        otherUI.SetActive(false);
        GetComponent<AudioSource>().PlayOneShot(badSound);
    }

    public void ShowGood(string score)
    {
        text.text = string.Format(text.text, score);
        gameObject.SetActive(true);
        otherUI.SetActive(false);
        GetComponent<AudioSource>().PlayOneShot(goodSound);
    }

    public void Restart()
    {
        SceneManager.LoadScene(0);
    }
}
