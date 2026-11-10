using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Toggle))]
public class MusicToggle : MonoBehaviour
{

    void Start()
    {
        GetComponent<Toggle>().isOn = !AudioManager.IsMusicMuted;
    }

    public void ToggleMusic(bool on)
    {
        AudioManager.ToggleMusic(on);
    }
}
