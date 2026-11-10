using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Main2 : MonoBehaviour
{
    public AudioClip success_audion_clip;
    public AudioClip error_audion_clip;
    public AudioClip explosion_audio_clip;
    public List<GameObject> breakings_objects;
    public AudioSource audioSrc;
    public GameObject UI;
    public enum BreakingType
    {
        OnBoardComputer,
        Accelerometer,
        FeedFishes,
        SensorCalibration,
    }

    public static List<BreakingType> BreakingsList = new List<BreakingType>() { 
        BreakingType.OnBoardComputer,
        BreakingType.Accelerometer,
        BreakingType.FeedFishes,
        BreakingType.SensorCalibration
    };

    public static readonly List<BreakingType> BreakingsListRefer = new List<BreakingType>() {
        BreakingType.OnBoardComputer,
        BreakingType.Accelerometer,
        BreakingType.FeedFishes,
        BreakingType.SensorCalibration
    };

    void Start()
    {
        G.BreakingUpdated += OnBreakingUpdated;
        G.Successed += OnSuccessed;
        G.Errored += OnErrored;
        G.Failed += OnFailed;
    }

    void Update()
    {
        if (G.player_hp <= 0 || BreakingsList.Count == 0 || G.main_timer >= G.MAIN_TIME)
        {
            if (G.player_hp <= 0)
                G.death_msg = "You have run out of HP";
            else if (BreakingsList.Count == 0)
                G.death_msg = "All the submarine's systems failed";
            else
                G.death_msg = "You have run out of oxygen";
            G.Reset();
            SceneManager.LoadScene("Lose");
        }

        
        G.TickTimers(Time.deltaTime);

        foreach (var overtimed in G.GetOvertimedBreakings())
        {
            if (UI.transform.childCount  == 0 || (UI.transform.childCount > 0 && overtimed != UI.transform.GetChild(UI.transform.childCount-1).GetComponent<TaskChars>().breakingType))
            {
                G.breakings.Remove(overtimed);
                G.breakings_timers.Remove(overtimed);
                BreakingsList.Remove(overtimed);
                G.player_hp -= 20f;
                G.OnBreakingUpdated();
                G.OnMineExploded();
                G.OnFailed();
            }
            
        }
    }

    public void OnBreakingUpdated()
    {
        foreach (var breakings_object in breakings_objects)
            breakings_object.SetActive(false);


        foreach (var breaking in G.breakings)
        {
            breakings_objects[BreakingsListRefer.IndexOf(breaking)].SetActive(true);
        }
    }

    public void OnSuccessed()
    {
        if (audioSrc != null && audioSrc.gameObject != null)
            audioSrc.PlayOneShot(success_audion_clip, 1f);
    }

    public void OnErrored()
    {
        if (audioSrc != null && audioSrc.gameObject != null)
            audioSrc.PlayOneShot(error_audion_clip, 1f);
    }

    private void OnFailed()
    {
        if (audioSrc != null && audioSrc.gameObject != null)
            audioSrc.PlayOneShot(explosion_audio_clip, 0.2f);
    }
}
