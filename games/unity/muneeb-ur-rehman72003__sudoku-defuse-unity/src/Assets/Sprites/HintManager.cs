using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class HintManager : MonoBehaviour
{
    [Header("Hint Settings")]
    [SerializeField]
    private int maximumHints = 3;

    [SerializeField]
    private float hintTimePenalty = 15f;

    private Button hintButton;
    private TMP_Text hintButtonText;

    private int remainingHints;

    private void Awake()
    {
        hintButton = GetComponent<Button>();

        hintButtonText =
            GetComponentInChildren<TMP_Text>(true);

        if (hintButton == null)
        {
            Debug.LogError(
                "HintManager must be attached to HintButton."
            );

            return;
        }

        hintButton.onClick.AddListener(UseHint);
    }

    private void Start()
    {
        remainingHints = maximumHints;

        UpdateButtonVisual();
    }

    private void UseHint()
    {
        if (remainingHints <= 0)
        {
            return;
        }

        if (SudokuBoard.Instance == null)
        {
            return;
        }

        if (SudokuBoard.Instance.IsGameLocked)
        {
            return;
        }

        if (GameTimer.Instance != null &&
            GameTimer.Instance.HasTimeEnded)
        {
            return;
        }

        bool hintWasUsed =
            SudokuBoard.Instance.RevealRandomHint();

        if (!hintWasUsed)
        {
            return;
        }

        remainingHints--;

        if (GameTimer.Instance != null)
        {
            GameTimer.Instance.SubtractTime(
                hintTimePenalty
            );
        }

        UpdateButtonVisual();
    }

    private void UpdateButtonVisual()
    {
        if (hintButtonText != null)
        {
            hintButtonText.text =
                $"HINT ({remainingHints})";
        }

        if (hintButton != null)
        {
            hintButton.interactable =
                remainingHints > 0;
        }
    }

    private void OnDestroy()
    {
        if (hintButton != null)
        {
            hintButton.onClick.RemoveListener(
                UseHint
            );
        }
    }
}