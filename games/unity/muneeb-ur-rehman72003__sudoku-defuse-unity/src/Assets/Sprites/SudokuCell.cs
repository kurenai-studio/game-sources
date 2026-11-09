using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public enum SudokuCellVisualState
{
    Normal,
    HoverMatch,
    SelectedMatch,
    Selected
}

public class SudokuCell : MonoBehaviour,
    IPointerEnterHandler,
    IPointerExitHandler
{
    public static SudokuCell SelectedCell { get; private set; }

    public bool IsFixed { get; private set; }

    public int Row { get; private set; }
    public int Column { get; private set; }

    private Button cellButton;
    private Image cellImage;
    private TMP_Text numberText;

    private int currentNumber;

    private Coroutine wrongFlashCoroutine;
    private bool isShowingWrongFlash;

    private Color normalNumberTextColor;

    private readonly Color32 normalColor =
        new Color32(232, 238, 242, 255);

    private readonly Color32 hoverMatchColor =
        new Color32(185, 225, 245, 255);

    private readonly Color32 selectedMatchColor =
        new Color32(86, 190, 235, 255);

    private readonly Color32 selectedColor =
        new Color32(245, 197, 66, 255);

    private readonly Color32 wrongColor =
        new Color32(220, 65, 65, 255);

    private readonly Color32 wrongNumberColor =
        new Color32(255, 255, 255, 255);

    private void Awake()
    {
        cellButton = GetComponent<Button>();
        cellImage = GetComponent<Image>();

        numberText =
            GetComponentInChildren<TMP_Text>(true);

        if (numberText != null)
        {
            normalNumberTextColor = numberText.color;
        }

        if (cellButton != null)
        {
            cellButton.transition =
                Selectable.Transition.None;

            cellButton.onClick.AddListener(
                SelectCell
            );
        }

        SetVisualState(
            SudokuCellVisualState.Normal
        );
    }

    private void OnDestroy()
    {
        if (cellButton != null)
        {
            cellButton.onClick.RemoveListener(
                SelectCell
            );
        }

        if (wrongFlashCoroutine != null)
        {
            StopCoroutine(wrongFlashCoroutine);
        }

        if (SelectedCell == this)
        {
            SelectedCell = null;
        }
    }

    public void InitializeCell(
        int number,
        bool isFixedCell,
        int row,
        int column
    )
    {
        CancelWrongFlash();

        IsFixed = isFixedCell;
        currentNumber = number;

        Row = row;
        Column = column;

        RefreshNumberText();
    }

    public void SelectCell()
    {
        SelectedCell = this;

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.RefreshHighlights();
        }
        else
        {
            SetVisualState(
                SudokuCellVisualState.Selected
            );
        }
    }

    public void OnPointerEnter(
        PointerEventData eventData
    )
    {
        if (currentNumber == 0)
        {
            return;
        }

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.SetHoveredNumber(
                currentNumber
            );
        }
    }

    public void OnPointerExit(
        PointerEventData eventData
    )
    {
        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.ClearHoveredNumber();
        }
    }

    public void SetVisualState(
        SudokuCellVisualState visualState
    )
    {
        if (cellImage == null)
        {
            return;
        }

        // Wrong flash ke duran doosra color apply nahi hoga.
        if (isShowingWrongFlash)
        {
            return;
        }

        switch (visualState)
        {
            case SudokuCellVisualState.HoverMatch:
                cellImage.color = hoverMatchColor;
                break;

            case SudokuCellVisualState.SelectedMatch:
                cellImage.color = selectedMatchColor;
                break;

            case SudokuCellVisualState.Selected:
                cellImage.color = selectedColor;
                break;

            default:
                cellImage.color = normalColor;
                break;
        }
    }

    public void SetNumber(int number)
    {
        CancelWrongFlash();

        currentNumber = number;

        RefreshNumberText();

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.RefreshHighlights();
        }
    }

    public void ClearNumber()
    {
        CancelWrongFlash();

        currentNumber = 0;

        RefreshNumberText();

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.RefreshHighlights();
        }
    }

    public void ShowWrongAnswer(int wrongNumber)
    {
        CancelWrongFlash();

        wrongFlashCoroutine =
            StartCoroutine(
                WrongAnswerFlash(wrongNumber)
            );
    }

    private IEnumerator WrongAnswerFlash(
        int wrongNumber
    )
    {
        isShowingWrongFlash = true;

        if (cellImage != null)
        {
            cellImage.color = wrongColor;
        }

        if (numberText != null)
        {
            numberText.text =
                wrongNumber.ToString();

            numberText.color =
                wrongNumberColor;

            numberText.fontStyle =
                FontStyles.Bold;

            numberText.enabled = true;
        }

        // Wrong number 3 dafa blink karega.
        for (int blink = 0; blink < 3; blink++)
        {
            if (numberText != null)
            {
                numberText.enabled = true;
            }

            yield return new WaitForSeconds(0.12f);

            if (numberText != null)
            {
                numberText.enabled = false;
            }

            yield return new WaitForSeconds(0.12f);
        }

        if (numberText != null)
        {
            numberText.enabled = true;
        }

        isShowingWrongFlash = false;
        wrongFlashCoroutine = null;

        RefreshNumberText();

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.RefreshHighlights();
        }
        else
        {
            SetVisualState(
                SudokuCellVisualState.Normal
            );
        }
    }

    private void CancelWrongFlash()
    {
        if (wrongFlashCoroutine != null)
        {
            StopCoroutine(wrongFlashCoroutine);
            wrongFlashCoroutine = null;
        }

        isShowingWrongFlash = false;

        if (numberText != null)
        {
            numberText.enabled = true;
        }
    }

    private void RefreshNumberText()
    {
        if (numberText == null)
        {
            return;
        }

        numberText.enabled = true;

        numberText.text =
            currentNumber == 0
                ? ""
                : currentNumber.ToString();

        numberText.color =
            normalNumberTextColor;

        numberText.fontStyle =
            IsFixed
                ? FontStyles.Bold
                : FontStyles.Normal;
    }

    public int GetNumber()
    {
        return currentNumber;
    }
}