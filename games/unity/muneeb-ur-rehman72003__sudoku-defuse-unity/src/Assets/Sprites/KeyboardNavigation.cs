using System;
using UnityEngine;

#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

public class KeyboardNavigation : MonoBehaviour
{
    private enum NavigationMode
    {
        Board,
        Numbers
    }

    private NavigationMode currentMode =
        NavigationMode.Board;

    private NumberButton[] numberButtons;
    private int selectedNumberIndex;

    private void Start()
    {
        numberButtons =
            FindObjectsByType<NumberButton>();

        Array.Sort(
            numberButtons,
            (first, second) =>
                first.ButtonNumber.CompareTo(
                    second.ButtonNumber
                )
        );
    }

    private void OnEnable()
    {
        NumberButton.NumberWasEntered +=
            ReturnToBoardMode;
    }

    private void OnDisable()
    {
        NumberButton.NumberWasEntered -=
            ReturnToBoardMode;

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance
                .ClearKeyboardPreviewNumber();
        }
    }

    private void Update()
    {
        bool upPressed = false;
        bool downPressed = false;
        bool leftPressed = false;
        bool rightPressed = false;
        bool spacePressed = false;

        int directNumber = 0;

#if ENABLE_INPUT_SYSTEM

        Keyboard keyboard = Keyboard.current;

        if (keyboard == null)
        {
            return;
        }

        upPressed =
            keyboard.upArrowKey.wasPressedThisFrame;

        downPressed =
            keyboard.downArrowKey.wasPressedThisFrame;

        leftPressed =
            keyboard.leftArrowKey.wasPressedThisFrame;

        rightPressed =
            keyboard.rightArrowKey.wasPressedThisFrame;

        spacePressed =
            keyboard.spaceKey.wasPressedThisFrame;

        directNumber =
            GetNewInputNumber(keyboard);

#elif ENABLE_LEGACY_INPUT_MANAGER

        upPressed =
            Input.GetKeyDown(KeyCode.UpArrow);

        downPressed =
            Input.GetKeyDown(KeyCode.DownArrow);

        leftPressed =
            Input.GetKeyDown(KeyCode.LeftArrow);

        rightPressed =
            Input.GetKeyDown(KeyCode.RightArrow);

        spacePressed =
            Input.GetKeyDown(KeyCode.Space);

        directNumber =
            GetLegacyInputNumber();

#endif

        if (directNumber >= 1 &&
            directNumber <= 9)
        {
            EnterDirectNumber(directNumber);
            return;
        }

        if (currentMode ==
            NavigationMode.Board)
        {
            HandleBoardNavigation(
                upPressed,
                downPressed,
                leftPressed,
                rightPressed,
                spacePressed
            );
        }
        else
        {
            HandleNumberNavigation(
                upPressed,
                downPressed,
                leftPressed,
                rightPressed,
                spacePressed
            );
        }
    }

#if ENABLE_INPUT_SYSTEM

    private int GetNewInputNumber(
        Keyboard keyboard
    )
    {
        if (keyboard.digit1Key.wasPressedThisFrame ||
            keyboard.numpad1Key.wasPressedThisFrame)
        {
            return 1;
        }

        if (keyboard.digit2Key.wasPressedThisFrame ||
            keyboard.numpad2Key.wasPressedThisFrame)
        {
            return 2;
        }

        if (keyboard.digit3Key.wasPressedThisFrame ||
            keyboard.numpad3Key.wasPressedThisFrame)
        {
            return 3;
        }

        if (keyboard.digit4Key.wasPressedThisFrame ||
            keyboard.numpad4Key.wasPressedThisFrame)
        {
            return 4;
        }

        if (keyboard.digit5Key.wasPressedThisFrame ||
            keyboard.numpad5Key.wasPressedThisFrame)
        {
            return 5;
        }

        if (keyboard.digit6Key.wasPressedThisFrame ||
            keyboard.numpad6Key.wasPressedThisFrame)
        {
            return 6;
        }

        if (keyboard.digit7Key.wasPressedThisFrame ||
            keyboard.numpad7Key.wasPressedThisFrame)
        {
            return 7;
        }

        if (keyboard.digit8Key.wasPressedThisFrame ||
            keyboard.numpad8Key.wasPressedThisFrame)
        {
            return 8;
        }

        if (keyboard.digit9Key.wasPressedThisFrame ||
            keyboard.numpad9Key.wasPressedThisFrame)
        {
            return 9;
        }

        return 0;
    }

#endif

#if ENABLE_LEGACY_INPUT_MANAGER

    private int GetLegacyInputNumber()
    {
        if (Input.GetKeyDown(KeyCode.Alpha1) ||
            Input.GetKeyDown(KeyCode.Keypad1))
        {
            return 1;
        }

        if (Input.GetKeyDown(KeyCode.Alpha2) ||
            Input.GetKeyDown(KeyCode.Keypad2))
        {
            return 2;
        }

        if (Input.GetKeyDown(KeyCode.Alpha3) ||
            Input.GetKeyDown(KeyCode.Keypad3))
        {
            return 3;
        }

        if (Input.GetKeyDown(KeyCode.Alpha4) ||
            Input.GetKeyDown(KeyCode.Keypad4))
        {
            return 4;
        }

        if (Input.GetKeyDown(KeyCode.Alpha5) ||
            Input.GetKeyDown(KeyCode.Keypad5))
        {
            return 5;
        }

        if (Input.GetKeyDown(KeyCode.Alpha6) ||
            Input.GetKeyDown(KeyCode.Keypad6))
        {
            return 6;
        }

        if (Input.GetKeyDown(KeyCode.Alpha7) ||
            Input.GetKeyDown(KeyCode.Keypad7))
        {
            return 7;
        }

        if (Input.GetKeyDown(KeyCode.Alpha8) ||
            Input.GetKeyDown(KeyCode.Keypad8))
        {
            return 8;
        }

        if (Input.GetKeyDown(KeyCode.Alpha9) ||
            Input.GetKeyDown(KeyCode.Keypad9))
        {
            return 9;
        }

        return 0;
    }

#endif

    private void EnterDirectNumber(int number)
    {
        SudokuCell selectedCell =
            SudokuCell.SelectedCell;

        if (selectedCell == null ||
            selectedCell.IsFixed)
        {
            return;
        }

        if (numberButtons == null)
        {
            return;
        }

        foreach (NumberButton numberButton
                 in numberButtons)
        {
            if (numberButton.ButtonNumber == number)
            {
                numberButton.ActivateNumber();
                return;
            }
        }
    }

    private void HandleBoardNavigation(
        bool upPressed,
        bool downPressed,
        bool leftPressed,
        bool rightPressed,
        bool spacePressed
    )
    {
        if (spacePressed)
        {
            EnterNumberMode();
            return;
        }

        int rowChange = 0;
        int columnChange = 0;

        if (upPressed)
        {
            rowChange = -1;
        }
        else if (downPressed)
        {
            rowChange = 1;
        }
        else if (leftPressed)
        {
            columnChange = -1;
        }
        else if (rightPressed)
        {
            columnChange = 1;
        }

        if (rowChange != 0 ||
            columnChange != 0)
        {
            MoveCellSelection(
                rowChange,
                columnChange
            );
        }
    }

    private void HandleNumberNavigation(
        bool upPressed,
        bool downPressed,
        bool leftPressed,
        bool rightPressed,
        bool spacePressed
    )
    {
        if (spacePressed)
        {
            ConfirmSelectedNumber();
            return;
        }

        if (leftPressed || upPressed)
        {
            MoveNumberSelection(-1);
        }
        else if (rightPressed || downPressed)
        {
            MoveNumberSelection(1);
        }
    }

    private void MoveCellSelection(
        int rowChange,
        int columnChange
    )
    {
        if (SudokuBoard.Instance == null)
        {
            return;
        }

        SudokuCell currentCell =
            SudokuCell.SelectedCell;

        if (currentCell == null)
        {
            SudokuCell firstCell =
                SudokuBoard.Instance.GetCell(0, 0);

            if (firstCell != null)
            {
                firstCell.SelectCell();
            }

            return;
        }

        int newRow = Mathf.Clamp(
            currentCell.Row + rowChange,
            0,
            8
        );

        int newColumn = Mathf.Clamp(
            currentCell.Column + columnChange,
            0,
            8
        );

        SudokuCell targetCell =
            SudokuBoard.Instance.GetCell(
                newRow,
                newColumn
            );

        if (targetCell != null)
        {
            targetCell.SelectCell();
        }
    }

    private void EnterNumberMode()
    {
        SudokuCell selectedCell =
            SudokuCell.SelectedCell;

        if (selectedCell == null ||
            selectedCell.IsFixed)
        {
            return;
        }

        if (numberButtons == null ||
            numberButtons.Length == 0)
        {
            return;
        }

        int currentNumber =
            selectedCell.GetNumber();

        selectedNumberIndex =
            currentNumber >= 1 &&
            currentNumber <= 9
                ? currentNumber - 1
                : 0;

        currentMode =
            NavigationMode.Numbers;

        RefreshNumberHighlight();
    }

    private void MoveNumberSelection(
        int direction
    )
    {
        if (numberButtons == null ||
            numberButtons.Length == 0)
        {
            return;
        }

        selectedNumberIndex += direction;

        if (selectedNumberIndex < 0)
        {
            selectedNumberIndex =
                numberButtons.Length - 1;
        }

        if (selectedNumberIndex >=
            numberButtons.Length)
        {
            selectedNumberIndex = 0;
        }

        RefreshNumberHighlight();
    }

    private void RefreshNumberHighlight()
    {
        for (int index = 0;
             index < numberButtons.Length;
             index++)
        {
            numberButtons[index]
                .SetKeyboardHighlight(
                    index == selectedNumberIndex
                );
        }

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance
                .SetKeyboardPreviewNumber(
                    numberButtons[
                        selectedNumberIndex
                    ].ButtonNumber
                );
        }
    }

    private void ConfirmSelectedNumber()
    {
        if (numberButtons == null ||
            numberButtons.Length == 0)
        {
            return;
        }

        numberButtons[
            selectedNumberIndex
        ].ActivateNumber();
    }

    private void ReturnToBoardMode()
    {
        if (numberButtons != null)
        {
            foreach (NumberButton numberButton
                     in numberButtons)
            {
                numberButton.SetKeyboardHighlight(
                    false
                );
            }
        }

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance
                .ClearKeyboardPreviewNumber();
        }

        currentMode =
            NavigationMode.Board;
    }
}