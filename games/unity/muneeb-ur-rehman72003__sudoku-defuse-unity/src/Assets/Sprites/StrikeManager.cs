using TMPro;
using UnityEngine;

public class StrikeManager : MonoBehaviour
{
    public static StrikeManager Instance
    {
        get;
        private set;
    }

    [SerializeField]
    private int maximumStrikes = 3;

    private TMP_Text strikeText;

    public int CurrentStrikes
    {
        get;
        private set;
    }

    public bool HasReachedLimit
    {
        get
        {
            return CurrentStrikes >= maximumStrikes;
        }
    }

    private void Awake()
    {
        Instance = this;

        strikeText = GetComponent<TMP_Text>();

        if (strikeText == null)
        {
            Debug.LogError(
                "StrikeManager must be attached to StrikeText."
            );
        }
    }

    private void Start()
    {
        ResetStrikes();
    }

    public void AddStrike()
    {
        if (HasReachedLimit)
        {
            return;
        }

        CurrentStrikes++;

        UpdateStrikeText();

        if (!HasReachedLimit)
        {
            return;
        }

        if (GameTimer.Instance != null)
        {
            GameTimer.Instance.StopTimer();
        }

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.SetGameLocked(true);
        }

        if (GameOverManager.Instance != null)
        {
            GameOverManager.Instance.ShowGameOver(
                $"{maximumStrikes} STRIKES"
            );
        }
        else
        {
            Debug.Log(
                "Maximum strikes reached. Game Over!"
            );
        }
    }

    public void ResetStrikes()
    {
        // Selected level ke mutabiq strike limit set hogi.
        maximumStrikes =
            LevelSettingsData.GetMaximumStrikes();

        CurrentStrikes = 0;

        UpdateStrikeText();
    }

    private void UpdateStrikeText()
    {
        if (strikeText == null)
        {
            return;
        }

        strikeText.text =
            $"STRIKES: {CurrentStrikes} / {maximumStrikes}";
    }

    private void OnDestroy()
    {
        if (Instance == this)
        {
            Instance = null;
        }
    }
}