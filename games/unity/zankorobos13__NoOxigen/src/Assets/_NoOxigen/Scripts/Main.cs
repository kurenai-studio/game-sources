using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Main : MonoBehaviour
{
    public AudioClip alert_audio_clip;
    public AudioClip explosion_audio_clip;
    public static bool isAbleToChangeMode = true;
    public GameObject explosion_prefab;

    private AudioSource audioSrc => GetComponent<AudioSource>();
    private void Start()
    {
        G.MineExploded += OnMineExploded;
       StartCoroutine(TestBreakigAlerts());
    }

    private IEnumerator TestBreakigAlerts()
    {
        yield return new WaitForSeconds(20f);
        AddRandomBreaking();
    }

    void Update()
    {
        if (G.player.transform.position.y >= 100)
        {
            G.Reset();
            SceneManager.LoadScene("Win");
        }

        if (G.player.GetComponent<Player>().hp <= 0 || Main2.BreakingsList.Count == 0 || G.main_timer >= G.MAIN_TIME)
        {
            if (G.player.GetComponent<Player>().hp <= 0)
                G.death_msg = "You have run out of HP";
            else if (Main2.BreakingsList.Count == 0)
                G.death_msg = "All the submarine's systems failed";
            else
                G.death_msg = "You have run out of oxygen";

            G.Reset();
            SceneManager.LoadScene("Lose");
        }

        if ((int)G.main_timer == 55 && G.breakings.Count < 2)
        {
            AddRandomBreaking();
        }

        if ((int)G.main_timer == 120 && G.breakings.Count < 1)
        {
            AddRandomBreaking();
        }

        if ((int)G.main_timer == 150 && G.breakings.Count < 1)
        {
            AddRandomBreaking();
        }


        if (G.main_timer > 45 && G.main_timer < 100f && G.breakings.Count == 1)
        {
            AddRandomBreaking();
        }


        if (G.main_timer > 10 && G.main_timer < 40 && G.breakings.Count == 0)
        {
            AddRandomBreaking();
        }

        foreach (var overtimed in G.GetOvertimedBreakings())
        {
            G.breakings.Remove(overtimed);
            G.breakings_timers.Remove(overtimed);
            Main2.BreakingsList.Remove(overtimed);
            G.OnBreakingUpdated();
            G.OnMineExploded();
            G.player.GetComponent<Player>().Damage(20f);
            Instantiate(explosion_prefab, G.player.transform.position, G.player.transform.rotation);
        }

        G.TickTimers(Time.deltaTime);

        if (Input.GetKeyDown(KeyCode.Space) && isAbleToChangeMode)
            OnModeChanged();
    }

    private IEnumerator LoadSceneAfterSeconds(float seconds)
    {
        yield return new WaitForSeconds(seconds);
        G.SaveData();
        SceneManager.LoadScene("Submarine");
    }

    private void OnModeChanged()
    {
        isAbleToChangeMode = false;

        G.OnModeChanged();
        StartCoroutine(LoadSceneAfterSeconds(1.9f));
    }

    private void AddRandomBreaking()
    {
        List<int> index_list = new List<int>();

        for (int i = 0; i < Main2.BreakingsList.Count; i++)
            index_list.Add(i);

        foreach (var b in G.breakings)
        {
            int chk_index = Main2.BreakingsList.IndexOf(b);
            if (chk_index != -1)
                index_list.Remove(chk_index);
        }
        
        if (index_list.Count > 0)
        {
            int rand_index = index_list[Random.Range(0, index_list.Count)];
            Main2.BreakingType breaking = Main2.BreakingsList[rand_index];
            AddBreaking(breaking);
        }
        else
        {
            Debug.Log("NO FREE BREAKINGS");
        }
    }

    private void AddBreaking(Main2.BreakingType breaking)
    {
        G.breakings.Add(breaking);
        G.breakings_timers.Add(breaking, 0f);
        StartCoroutine(PlayAlert(3));
        G.OnBreakingUpdated();
    }

    private IEnumerator PlayAlert(int times)
    {
        for (int i = 0; i < times; i++)
        {
            audioSrc.PlayOneShot(alert_audio_clip, 0.2f);
            yield return new WaitForSeconds(alert_audio_clip.length);
        }
    }

    private void RemoveBreaking(Main2.BreakingType breaking)
    {
        // Some action
        G.OnBreakingUpdated();
    }

    private void OnMineExploded()
    {
        audioSrc.PlayOneShot(explosion_audio_clip, 0.25f);
        AddRandomBreaking();
    }
}
