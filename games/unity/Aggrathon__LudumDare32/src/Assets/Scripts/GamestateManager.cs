using UnityEngine;
using UnityEngine.UI;

public class GamestateManager : MonoBehaviour {

    [Header("UI")]
    public GameObject deadScreen;
    public GameObject winScreen;
    public GameObject menu;
    public GameObject intro;
    [Header("Objects")]
    public GameObject inSpace;
    public GameObject inShip;
    public GameObject status;
    public GameObject crafting;

    [HideInInspector]
    public GameObject bomb;

    private states state;
    private states prevState;

    public enum states
    {
        Intro,
        Menu,
        Dead,
        Victory,
        Flying,
        Battleship,
        StatusView,
        Crafting
    }

    void OnEnable()
    {
        deadScreen.SetActive(false);
        winScreen.SetActive(false);
        menu.SetActive(false);
        inSpace.SetActive(false);
        inShip.SetActive(false);
        status.SetActive(false);
        crafting.SetActive(false);

        state = states.Battleship;
        prevState = states.Battleship;
        showIntro();
    }

    void Update()
    {
        if (Input.GetButtonDown("Menu"))
        {
            switch (state)
            {
                case states.Victory:
                case states.Dead:
                    Restart();
                    break;
                default:
                    Pause();
                    break;
            }
        }
    }

    void lockCursor()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    void unlockCursor()
    {
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }

    void changeState(states newState) {
        if (newState == states.Flying)
                lockCursor();
        else
            unlockCursor();
        switch (newState)
        {
            case states.Menu:
            case states.Intro:
            case states.Victory:
            case states.Dead:
            case states.Crafting:
                Time.timeScale = 0f;
                break;
            default:
                Time.timeScale = 1f;
                break;
        }

        if (newState != states.Menu)
        {
            switch (state)
            {
                case states.Intro:
                    intro.SetActive(false);
                    break;
                case states.Menu:
                    menu.SetActive(false);
                    break;
                case states.Flying:
                    inSpace.SetActive(false);
                    break;
                case states.Battleship:
                    inShip.SetActive(false);
                    break;
                case states.Crafting:
                    crafting.SetActive(false);
                    break;
                case states.Dead:
                    deadScreen.SetActive(false);
                    break;
                case states.Victory:
                    winScreen.SetActive(false);
                    break;
                case states.StatusView:
                    status.SetActive(false);
                    break;
            }
        }
        switch (newState)
        {
            case states.Intro:
                intro.SetActive(true);
                break;
            case states.Menu:
                menu.SetActive(true);
                break;
            case states.Flying:
                inSpace.SetActive(true);
                break;
            case states.Battleship:
                inShip.SetActive(true);
                break;
            case states.Crafting:
                crafting.SetActive(true);
                break;
            case states.Dead:
                deadScreen.SetActive(true);
                break;
            case states.Victory:
                deadScreen.SetActive(true);
                break;
            case states.StatusView:
                status.SetActive(true);
                break;
        }
        if(state != states.Menu)
            prevState = state;
        state = newState;
    }

    public void PreviousState()
    {
        changeState(prevState);
    }

    public void ChangeSensitivity(float val)
    {
        FlightController.sensitivity = val;
    }
    public void ChangeSensitivity(Slider slider)
    {
        FlightController.sensitivity = slider.value;
    }

    public void showIntro()
    {
        changeState(states.Intro);
    }

    public void craftView()
    {
        changeState(states.Crafting);
    }

    public void viewStatus()
    {
        changeState(states.StatusView);
    }

    public void Win()
    {
        changeState(states.Victory);
    }

    public void Die()
    {
        changeState(states.Dead);
    }

    public void EnterBattleShip()
    {
        changeState(states.Battleship);
    }

    public void EnterFighterShip()
    {
        changeState(states.Flying);
    }

    public void Pause()
    {
        if (state == states.Menu)
        {
            changeState(prevState);
        }
        else
        {
            changeState(states.Menu);
        }
    }

    public void Restart()
    {
        Application.LoadLevel(0);
    }

    public void Quit()
    {
        Application.Quit();
    }
}
