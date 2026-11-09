using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class NumberButton : MonoBehaviour,
    IPointerEnterHandler,
    IPointerExitHandler
{
    public static event Action NumberWasEntered;

    public int ButtonNumber
    {
        get;
        private set;
    }

    private Button button;
    private Image buttonImage;
    private TMP_Text numberText;
    private Outline keyboardOutline;

    private readonly Color32 normalBackgroundColor =
        new Color32(38, 55, 70, 255);

    private readonly Color32 normalTextColor =
        new Color32(245, 197, 66, 255);

    private readonly Color32 selectedBackgroundColor =
        new Color32(245, 197, 66, 255);

    private readonly Color32 selectedTextColor =
        new Color32(255, 255, 255, 255);

    private void Awake()
    {
        button = GetComponent<Button>();
        buttonImage = GetComponent<Image>();

        numberText =
            GetComponentInChildren<TMP_Text>(true);

        if (numberText != null)
        {
            int.TryParse(
                numberText.text,
                out int parsedNumber
            );

            ButtonNumber = parsedNumber;
        }

        keyboardOutline = GetComponent<Outline>();

        if (keyboardOutline == null)
        {
            keyboardOutline =
                gameObject.AddComponent<Outline>();
        }

        keyboardOutline.effectColor =
            new Color32(255, 220, 80, 255);

        keyboardOutline.effectDistance =
            new Vector2(5f, -5f);

        keyboardOutline.useGraphicAlpha = false;
        keyboardOutline.enabled = false;

        if (buttonImage != null)
        {
            buttonImage.color =
                normalBackgroundColor;
        }

        if (numberText != null)
        {
            numberText.color =
                normalTextColor;
        }

        if (button != null)
        {
            button.transition =
                Selectable.Transition.None;

            button.onClick.AddListener(
                ActivateNumber
            );
        }
    }

    private void OnDestroy()
    {
        if (button != null)
        {
            button.onClick.RemoveListener(
                ActivateNumber
            );
        }
    }

    public void OnPointerEnter(
        PointerEventData eventData
    )
    {
        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance
                .SetNumberButtonHoveredNumber(
                    ButtonNumber
                );
        }
    }

    public void OnPointerExit(
        PointerEventData eventData
    )
    {
        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance
                .ClearNumberButtonHoveredNumber();
        }
    }

    public void ActivateNumber()
    {
        SudokuCell selectedCell =
            SudokuCell.SelectedCell;

        if (selectedCell == null)
        {
            return;
        }

        if (selectedCell.IsFixed)
        {
            return;
        }

        if (SudokuBoard.Instance == null)
        {
            return;
        }

        SudokuBoard.Instance.TryEnterNumber(
            selectedCell,
            ButtonNumber
        );

        NumberWasEntered?.Invoke();
    }

    public void SetKeyboardHighlight(
        bool isHighlighted
    )
    {
        if (keyboardOutline != null)
        {
            keyboardOutline.enabled =
                isHighlighted;
        }

        if (buttonImage != null)
        {
            buttonImage.color =
                isHighlighted
                    ? selectedBackgroundColor
                    : normalBackgroundColor;
        }

        if (numberText != null)
        {
            numberText.color =
                isHighlighted
                    ? selectedTextColor
                    : normalTextColor;
        }
    }
}