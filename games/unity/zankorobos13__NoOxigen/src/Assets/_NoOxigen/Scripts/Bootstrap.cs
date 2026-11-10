using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bootstrap : MonoBehaviour
{
    public GameObject MainThemeAudio;
    void Awake()
    {
        G.ClearAllEvents();
        gameObject.GetComponent<PlayerSpawner>().SpawnPlayer();
        G.player = gameObject.GetComponent<PlayerSpawner>().GetPlayer();
        
        G.player.GetComponent<Player>().isAbleToControl = true;
        Main.isAbleToChangeMode = true; // temporary 

        if (G.IsHasSavedData)
            G.LoadData();
        else
            MainThemeAudio.GetComponent<AudioSource>().Play();


        DontDestroyOnLoad(MainThemeAudio);
    }
}
