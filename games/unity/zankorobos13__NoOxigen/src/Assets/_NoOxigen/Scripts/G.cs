using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public static class G
{
    public static GameObject player { get; set; }

    public static event Action MineExploded;
    public static event Action ModeChanged;
    public static event Action BreakingUpdated;
    public static event Action PlayerDamaged;
    public static event Action BreakingInteracted;
    public static event Action BreakingClosed;
    public static event Action Successed;
    public static event Action Errored;
    public static event Action Failed;
    public static event Action AllRepStopped;

    public static List<Main2.BreakingType> breakings = new List<Main2.BreakingType>();
    public static Dictionary<Main2.BreakingType, float> breakings_timers = new Dictionary<Main2.BreakingType, float>();
    public static bool IsHasSavedData = false;
    public static readonly float BREAKING_TIME = 30f;
    public static readonly float MAIN_TIME = 300f;
    public static float main_timer = 0f;
    public static string death_msg;
    
    private static Vector3 player_pos;
    public static float player_hp;

    public static void ClearAllEvents()
    {
        MineExploded = null;
        ModeChanged = null;
        BreakingUpdated = null;
        PlayerDamaged = null;
        BreakingInteracted = null;
        BreakingClosed = null;
        Successed = null;
        Errored = null;
    }
    public static void OnMineExploded()
    {
        MineExploded?.Invoke();
    }

    public static void OnModeChanged()
    {
        ModeChanged?.Invoke();
    }

    public static void OnBreakingUpdated()
    {
        BreakingUpdated?.Invoke();
    }

    public static void OnPlayerDamaged()
    {
        PlayerDamaged?.Invoke();
    }

    public static void OnBreakingInteracted()
    {
        BreakingInteracted?.Invoke();
    }

    public static void OnBreakingClosed()
    {
        BreakingClosed?.Invoke();
    }

    public static void SaveData()
    {
        IsHasSavedData = true;
        player_pos = player.transform.position;
        player_hp = player.GetComponent<Player>().hp;
    }

    public static void LoadData()
    {
        player.transform.position = player_pos;
        player.GetComponent<Player>().hp = player_hp;
    }

    public static void OnSuccessed()
    {
        Successed?.Invoke();
    }

    public static void OnErrored()
    {
        Errored?.Invoke();
    }

    public static void OnFailed()
    {
        Failed?.Invoke();
    }

    public static void TickTimers(float deltaTime)
    {
        main_timer += deltaTime;
        if (breakings_timers.Count > 0)
        {
            Dictionary<Main2.BreakingType, float> x_breakings_timers = new Dictionary<Main2.BreakingType, float>(breakings_timers);
            foreach (var (key, value) in x_breakings_timers)
            {
                if (breakings_timers.ContainsKey(key))
                {
                    breakings_timers[key] += deltaTime;
                }
            }
        }

    }

    public static List<Main2.BreakingType> GetOvertimedBreakings()
    {
        List<Main2.BreakingType> overtimed_breakings = new List<Main2.BreakingType>();

        if (breakings_timers.Count > 0)
        {
            Dictionary<Main2.BreakingType, float> x_breakings_timers = new Dictionary<Main2.BreakingType, float>(breakings_timers);
            foreach (var (key, value) in x_breakings_timers)
            {
                if (x_breakings_timers[key] > BREAKING_TIME)
                {
                    overtimed_breakings.Add(key);
                }
            }
        }

        return overtimed_breakings;
    }

    public static void OnAllRepStopped()
    {
        AllRepStopped?.Invoke();
    }

    public static void Reset()
    {
        breakings = new List<Main2.BreakingType>();
        breakings_timers = new Dictionary<Main2.BreakingType, float>();
        player_hp = 100;
        player_pos = new Vector3(0, 0, 0);
        IsHasSavedData = false;
        player = null;
        main_timer = 0f;
        Main2.BreakingsList = new List<Main2.BreakingType>(Main2.BreakingsListRefer);
    }
}
