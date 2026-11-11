using System.Collections;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public Music music;
    public GameState gameState;
    public PlayerController player;
    public Deadushka deadushka;
    public float[] stateHeight = {5, 7, 9, 10, 65536};
    public Door[] cellarDoors;
    public Door[] garageDoors;

    string tooltip = "game_manager";


    public enum State
    {
        Signal0 = 0,
        Signal1,
        Signal2,
        Signal3,
        TranslateState
    }
    public State state = State.Signal0;

    void Start()
    {
        StartCoroutine(StartGame());
    }

    void Update()
    {
        if (state == State.TranslateState)
            return;

        if (player.transform.position.y < stateHeight[(int)state])
            return;

        State fromState = state;
        state = State.TranslateState;
        StartCoroutine(InTranslateState(fromState));
    }

    IEnumerator InTranslateState(State fromState)
    {
        yield return new WaitForSeconds(1.0f);

        if (player.transform.position.y < stateHeight[(int)fromState])
        {
            state = fromState;
            yield break;
        }

        switch (fromState)
        {
            case State.Signal0: yield return ToState1(); break;
            case State.Signal1: yield return ToState2(); break;
            case State.Signal2: yield return ToState3(); break;
        }
    }

    IEnumerator StartGame()
    {
        yield return new WaitForSeconds(1.0f);
        player.CallPhone(Phone.State.Signal0, 5);
        player.LockInput(2.0f);
        yield return new WaitForSeconds(2.0f);
        player.Say(GetString("vnuchek_start"));
    }

    IEnumerator ToState1()
    {
        player.CallPhone(Phone.State.Signal1, 1);
        yield return new WaitForSeconds(1.0f);
        player.Say(GetString("deadushka_podval"), deadushka.tooltip);
        deadushka.TakeSound();
        foreach (var door in cellarDoors)
            door.UnlockSecondFactor();
        state = State.Signal1;
    }

    IEnumerator ToState2()
    {
        player.CallPhone(Phone.State.Signal2, 2);
        yield return new WaitForSeconds(2.0f);
        player.CallPhone(Phone.State.Message, 0);
        player.Say(GetString("brother_message"), "Brother");
        foreach (var door in garageDoors)
            door.UnlockSecondFactor();
        yield return new WaitForSeconds(4.0f);
        player.CallPhone(Phone.State.Signal2, -1);
        state = State.Signal2;
    }

    IEnumerator ToState3()
    {
        player.CallPhone(Phone.State.Signal3, 3);
        yield return new WaitForSeconds(2.0f);
        player.CallPhone(Phone.State.Message, 0);
        yield return new WaitForSeconds(1.0f);
        music.pause = true;
        player.Say(GetString("brother_message_2"), "Brother");
        player.LockInput(10.0f);
        player.CallPhone(Phone.State.Rickroll, 4, true);
        yield return new WaitForSeconds(10f);
        player.CallPhone(Phone.State.Signal3, -1, false);
        music.pause = false;
        state = State.Signal3;
    }

    string GetString(string key)
    {
        return gameState.GetString($"{tooltip}_{key}");
    }
}
