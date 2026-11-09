using System.Collections.Generic;
using UnityEngine;

public class SudokuBoard : MonoBehaviour
{
    public static SudokuBoard Instance
    {
        get;
        private set;
    }

    private readonly SudokuCell[,] cells =
        new SudokuCell[9, 9];

    private readonly bool[] completedRows =
        new bool[9];

    private readonly bool[] completedColumns =
        new bool[9];

    private readonly bool[] completedBoxes =
        new bool[9];

    private int cellHoveredNumber;
    private int numberButtonHoveredNumber;
    private int keyboardPreviewNumber;

    private int remainingEmptyCells;
    private bool isGameLocked;

    private const float CorrectAnswerBonus = 2f;
    private const float CompletedGroupBonus = 10f;
    private const float WrongAnswerPenalty = 10f;

    public bool IsGameLocked
    {
        get
        {
            return isGameLocked;
        }
    }

    // Level 1: Easy puzzle
    private readonly int[] easyPuzzle =
    {
        5, 3, 4, 0, 7, 0, 0, 0, 0,
        6, 0, 0, 1, 9, 5, 3, 0, 8,
        1, 9, 8, 0, 0, 2, 0, 6, 7,

        8, 0, 0, 0, 6, 0, 0, 0, 3,
        4, 0, 0, 8, 0, 3, 0, 0, 1,
        7, 0, 3, 9, 2, 4, 0, 5, 6,

        0, 6, 0, 0, 0, 0, 2, 8, 4,
        0, 0, 0, 4, 1, 9, 6, 0, 5,
        0, 0, 5, 2, 8, 6, 0, 7, 9
    };

    // Level 2: Medium puzzle
    private readonly int[] mediumPuzzle =
    {
        5, 3, 0, 0, 7, 0, 0, 0, 0,
        6, 0, 0, 1, 9, 5, 0, 0, 0,
        0, 9, 8, 0, 0, 0, 0, 6, 0,

        8, 0, 0, 0, 6, 0, 0, 0, 3,
        4, 0, 0, 8, 0, 3, 0, 0, 1,
        7, 0, 0, 0, 2, 0, 0, 0, 6,

        0, 6, 0, 0, 0, 0, 2, 8, 0,
        0, 0, 0, 4, 1, 9, 0, 0, 5,
        0, 0, 0, 0, 8, 0, 0, 7, 9
    };

    // Level 3: Hard puzzle
    private readonly int[] hardPuzzle =
    {
        5, 3, 0, 0, 0, 0, 0, 1, 2,
        0, 0, 2, 0, 9, 0, 0, 0, 0,
        1, 9, 0, 0, 4, 0, 0, 0, 0,

        0, 5, 0, 7, 0, 0, 0, 0, 0,
        0, 2, 6, 0, 0, 3, 0, 0, 0,
        0, 0, 0, 0, 0, 4, 8, 0, 6,

        0, 6, 0, 0, 0, 0, 0, 8, 0,
        0, 0, 7, 4, 0, 0, 0, 3, 5,
        0, 0, 0, 2, 0, 0, 1, 0, 0
    };

    private readonly int[] puzzleSolution =
    {
        5, 3, 4, 6, 7, 8, 9, 1, 2,
        6, 7, 2, 1, 9, 5, 3, 4, 8,
        1, 9, 8, 3, 4, 2, 5, 6, 7,

        8, 5, 9, 7, 6, 1, 4, 2, 3,
        4, 2, 6, 8, 5, 3, 7, 9, 1,
        7, 1, 3, 9, 2, 4, 8, 5, 6,

        9, 6, 1, 5, 3, 7, 2, 8, 4,
        2, 8, 7, 4, 1, 9, 6, 3, 5,
        3, 4, 5, 2, 8, 6, 1, 7, 9
    };

    private void Awake()
    {
        Instance = this;
    }

    private void Start()
    {
        isGameLocked = false;
        remainingEmptyCells = 0;

        cellHoveredNumber = 0;
        numberButtonHoveredNumber = 0;
        keyboardPreviewNumber = 0;

        ResetCompletedGroups();

        int[] selectedPuzzle =
            GetSelectedPuzzle();

        if (transform.childCount != 9)
        {
            Debug.LogError(
                "BoardPanel must contain exactly 9 BoxSections."
            );

            return;
        }

        for (int boxIndex = 0;
             boxIndex < 9;
             boxIndex++)
        {
            Transform box =
                transform.GetChild(boxIndex);

            if (box.childCount != 9)
            {
                Debug.LogError(
                    box.name +
                    " must contain exactly 9 cells."
                );

                return;
            }

            for (int cellIndex = 0;
                 cellIndex < 9;
                 cellIndex++)
            {
                SudokuCell cell =
                    box.GetChild(cellIndex)
                        .GetComponent<SudokuCell>();

                if (cell == null)
                {
                    Debug.LogError(
                        box.name +
                        " contains a cell without SudokuCell script."
                    );

                    return;
                }

                int row =
                    (boxIndex / 3) * 3 +
                    (cellIndex / 3);

                int column =
                    (boxIndex % 3) * 3 +
                    (cellIndex % 3);

                int number =
                    selectedPuzzle[
                        (row * 9) + column
                    ];

                cells[row, column] = cell;

                bool isFixedCell =
                    number != 0;

                if (!isFixedCell)
                {
                    remainingEmptyCells++;
                }

                cell.InitializeCell(
                    number,
                    isFixedCell,
                    row,
                    column
                );
            }
        }

        RefreshHighlights();
    }

    private int[] GetSelectedPuzzle()
    {
        switch (LevelSelectionData.SelectedLevel)
        {
            case 2:
                return mediumPuzzle;

            case 3:
                return hardPuzzle;

            default:
                return easyPuzzle;
        }
    }

    private void ResetCompletedGroups()
    {
        for (int index = 0;
             index < 9;
             index++)
        {
            completedRows[index] = false;
            completedColumns[index] = false;
            completedBoxes[index] = false;
        }
    }

    public SudokuCell GetCell(
        int row,
        int column
    )
    {
        if (row < 0 || row > 8 ||
            column < 0 || column > 8)
        {
            return null;
        }

        return cells[row, column];
    }

    public void SetGameLocked(bool locked)
    {
        isGameLocked = locked;
    }

    public void SetHoveredNumber(int number)
    {
        cellHoveredNumber = number;
        RefreshHighlights();
    }

    public void ClearHoveredNumber()
    {
        cellHoveredNumber = 0;
        RefreshHighlights();
    }

    public void SetNumberButtonHoveredNumber(
        int number
    )
    {
        numberButtonHoveredNumber = number;
        RefreshHighlights();
    }

    public void ClearNumberButtonHoveredNumber()
    {
        numberButtonHoveredNumber = 0;
        RefreshHighlights();
    }

    public void SetKeyboardPreviewNumber(
        int number
    )
    {
        keyboardPreviewNumber = number;
        RefreshHighlights();
    }

    public void ClearKeyboardPreviewNumber()
    {
        keyboardPreviewNumber = 0;
        RefreshHighlights();
    }

    private int GetPreviewNumber(
        out bool useStrongGlow
    )
    {
        if (numberButtonHoveredNumber != 0)
        {
            useStrongGlow = false;
            return numberButtonHoveredNumber;
        }

        if (cellHoveredNumber != 0)
        {
            useStrongGlow = false;
            return cellHoveredNumber;
        }

        if (keyboardPreviewNumber != 0)
        {
            useStrongGlow = true;
            return keyboardPreviewNumber;
        }

        useStrongGlow = false;
        return 0;
    }

    public void RefreshHighlights()
    {
        SudokuCell selectedCell =
            SudokuCell.SelectedCell;

        int selectedNumber =
            selectedCell != null
                ? selectedCell.GetNumber()
                : 0;

        int previewNumber =
            GetPreviewNumber(
                out bool strongPreview
            );

        for (int row = 0; row < 9; row++)
        {
            for (int column = 0;
                 column < 9;
                 column++)
            {
                SudokuCell cell =
                    cells[row, column];

                if (cell == null)
                {
                    continue;
                }

                SudokuCellVisualState state =
                    SudokuCellVisualState.Normal;

                if (cell == selectedCell)
                {
                    state =
                        SudokuCellVisualState.Selected;
                }
                else if (
                    previewNumber != 0 &&
                    cell.GetNumber() == previewNumber
                )
                {
                    state =
                        strongPreview
                            ? SudokuCellVisualState
                                .SelectedMatch
                            : SudokuCellVisualState
                                .HoverMatch;
                }
                else if (
                    selectedNumber != 0 &&
                    cell.GetNumber() == selectedNumber
                )
                {
                    state =
                        SudokuCellVisualState
                            .SelectedMatch;
                }

                cell.SetVisualState(state);
            }
        }
    }

    public bool RevealRandomHint()
    {
        if (isGameLocked)
        {
            return false;
        }

        List<SudokuCell> emptyCells =
            new List<SudokuCell>();

        for (int row = 0; row < 9; row++)
        {
            for (int column = 0;
                 column < 9;
                 column++)
            {
                SudokuCell cell =
                    cells[row, column];

                if (cell != null &&
                    !cell.IsFixed &&
                    cell.GetNumber() == 0)
                {
                    emptyCells.Add(cell);
                }
            }
        }

        if (emptyCells.Count == 0)
        {
            return false;
        }

        int randomIndex =
            Random.Range(0, emptyCells.Count);

        SudokuCell hintCell =
            emptyCells[randomIndex];

        int solutionIndex =
            (hintCell.Row * 9) +
            hintCell.Column;

        int correctNumber =
            puzzleSolution[solutionIndex];

        hintCell.SetNumber(correctNumber);
        hintCell.SelectCell();

        remainingEmptyCells--;

        if (remainingEmptyCells < 0)
        {
            remainingEmptyCells = 0;
        }

        CheckCompletedGroups(
            hintCell.Row,
            hintCell.Column
        );

        if (remainingEmptyCells == 0)
        {
            CompletePuzzle();
        }

        return true;
    }

    public bool TryEnterNumber(
        SudokuCell cell,
        int enteredNumber
    )
    {
        if (isGameLocked)
        {
            return false;
        }

        if (GameTimer.Instance != null &&
            GameTimer.Instance.HasTimeEnded)
        {
            return false;
        }

        if (cell == null ||
            cell.IsFixed ||
            cell.GetNumber() != 0)
        {
            return false;
        }

        int solutionIndex =
            (cell.Row * 9) + cell.Column;

        int correctNumber =
            puzzleSolution[solutionIndex];

        if (enteredNumber != correctNumber)
        {
            cell.ShowWrongAnswer(enteredNumber);

            if (GameTimer.Instance != null)
            {
                GameTimer.Instance.SubtractTime(
                    WrongAnswerPenalty
                );
            }

            if (StrikeManager.Instance != null)
            {
                StrikeManager.Instance.AddStrike();
            }

            return false;
        }

        cell.SetNumber(enteredNumber);

        remainingEmptyCells--;

        if (remainingEmptyCells < 0)
        {
            remainingEmptyCells = 0;
        }

        float totalTimeBonus =
            CorrectAnswerBonus;

        totalTimeBonus +=
            CheckCompletedGroups(
                cell.Row,
                cell.Column
            );

        if (GameTimer.Instance != null)
        {
            GameTimer.Instance.AddTime(
                totalTimeBonus
            );
        }

        if (remainingEmptyCells == 0)
        {
            CompletePuzzle();
        }

        return true;
    }

    private float CheckCompletedGroups(
        int row,
        int column
    )
    {
        float earnedBonus = 0f;

        if (!completedRows[row] &&
            IsRowComplete(row))
        {
            completedRows[row] = true;

            earnedBonus +=
                CompletedGroupBonus;
        }

        if (!completedColumns[column] &&
            IsColumnComplete(column))
        {
            completedColumns[column] = true;

            earnedBonus +=
                CompletedGroupBonus;
        }

        int boxIndex =
            (row / 3) * 3 +
            (column / 3);

        if (!completedBoxes[boxIndex] &&
            IsBoxComplete(boxIndex))
        {
            completedBoxes[boxIndex] = true;

            earnedBonus +=
                CompletedGroupBonus;
        }

        return earnedBonus;
    }

    private bool IsRowComplete(int row)
    {
        for (int column = 0;
             column < 9;
             column++)
        {
            SudokuCell cell =
                cells[row, column];

            if (cell == null ||
                cell.GetNumber() == 0)
            {
                return false;
            }
        }

        return true;
    }

    private bool IsColumnComplete(int column)
    {
        for (int row = 0;
             row < 9;
             row++)
        {
            SudokuCell cell =
                cells[row, column];

            if (cell == null ||
                cell.GetNumber() == 0)
            {
                return false;
            }
        }

        return true;
    }

    private bool IsBoxComplete(int boxIndex)
    {
        int startingRow =
            (boxIndex / 3) * 3;

        int startingColumn =
            (boxIndex % 3) * 3;

        for (int rowOffset = 0;
             rowOffset < 3;
             rowOffset++)
        {
            for (int columnOffset = 0;
                 columnOffset < 3;
                 columnOffset++)
            {
                SudokuCell cell =
                    cells[
                        startingRow + rowOffset,
                        startingColumn + columnOffset
                    ];

                if (cell == null ||
                    cell.GetNumber() == 0)
                {
                    return false;
                }
            }
        }

        return true;
    }

    private void CompletePuzzle()
    {
        isGameLocked = true;

        if (GameTimer.Instance != null)
        {
            GameTimer.Instance.StopTimer();
        }

        if (GameOverManager.Instance != null)
        {
            GameOverManager.Instance.ShowVictory();
        }
    }

    private void OnDestroy()
    {
        if (Instance == this)
        {
            Instance = null;
        }
    }
}