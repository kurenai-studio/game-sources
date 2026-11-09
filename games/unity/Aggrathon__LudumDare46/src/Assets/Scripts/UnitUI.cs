using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Text;
using System;
using System.Linq;

public class UnitUI : MonoBehaviour
{
    public static UnitUI active { get; protected set; }

    public TextMeshProUGUI nameText;
    public TextMeshProUGUI descText;
    public Button actionButton;
    [SerializeField] protected Button moveButton;
    public GameObject attackText;
    public GameObject rangeFinder;

    List<Button> buttons;
    private List<Button> moveButtons;
    private Unit unit;
    
    private void Awake() {
        active = this;
        moveButtons = new List<Button>();
        moveButtons.Add(moveButton);
        buttons = new List<Button>();
        buttons.Add(actionButton);
        while(buttons.Count < 10) {
            var but = Instantiate(actionButton, actionButton.transform.parent);
            buttons.Add(but);
        }
        SetupButton(0, "Move", ShowMoveGrid);
        SetupButton(9, "Skip", SkipTurn);
        Hide();
    }

    public void Show(Unit unit) {
        this.unit = unit;
        nameText.text = unit.name;
        StringBuilder sb = new StringBuilder();
        sb.Append("   Actions: ").Append(unit.energy).Append(" / ").Append(unit.actions);
        sb.Append("\n   Health: ").Append(unit.health.health).Append(" / ").Append(unit.health.maxHealth);
        sb.Append("\n   ");
        unit.weapon.AppendStatus(sb);
        descText.text = sb.ToString();
        int index = 1;
        foreach (var act in unit.weapon.GetActions()) {
            int i = index;
            SetupButton(i, act, () => {
                HideMoveGrid();
                unit.weapon.StartAction(i, (en) => {
                    unit.energy -= en;
                    if (unit.energy > 0)
                        Show(unit);
                    else
                        Hide();
                });
            });
            index++;
        }
        for (; index < buttons.Count - 1; index++)
            buttons[index].gameObject.SetActive(false);
        gameObject.SetActive(true);
    }

    void SetupButton(int index, string text, UnityEngine.Events.UnityAction call) {
        Button button = buttons[index];
        button.gameObject.SetActive(true);
        button.GetComponentInChildren<TextMeshProUGUI>().text = text;
        button.onClick.RemoveAllListeners();
        button.onClick.AddListener(call);
    }

    public void Hide() {
        gameObject.SetActive(false);
        HideMoveGrid();
        HideAimHint();
    }

    
    void ShowMoveGrid() {
        HideAimHint();
        unit.weapon.CancelAction();
        CameraController.active.FocusOver(unit.transform);
        var graph = PathGrid.activeGrid.GetReachable(unit.blocker.i, unit.blocker.j, unit.movement);
        var grid = PathGrid.activeGrid;
        while (moveButtons.Count < graph.Count)
            moveButtons.Add(Instantiate(moveButton, moveButton.transform.parent));
        int k = 0;
        foreach (var kv in graph.AsEnumerable())
        {
            PathGrid.PathNode node = kv.Value;
            Button button = moveButtons[k];
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => {
                unit.blocker.MovePath(graph, node, () => {
                    unit.energy--;
                    if (unit.energy > 0)
                        Show(unit);
                });
                Hide();
            });
            Vector3 pos = grid.IndexToVector(node.i, node.j);
            button.transform.localPosition = new Vector3(pos.x, pos.z, 0);
            button.gameObject.SetActive(true);
            k++;
        }
        for (; k < moveButtons.Count; k++)
        {
            moveButtons[k].gameObject.SetActive(false);
        }
        moveButton.transform.parent.gameObject.SetActive(true);
    }

    void SkipTurn() {
        unit.energy = -1;
        unit.weapon.CancelAction();
        Hide();
    }

    public void HideMoveGrid() {
        moveButton.transform.parent.gameObject.SetActive(false);
    }

    public void ShowAimHint() {
        attackText.SetActive(true);
        rangeFinder.transform.localScale = new Vector3(unit.weapon.range, 1f, unit.weapon.range);
        rangeFinder.transform.position = unit.transform.position;
        rangeFinder.SetActive(true);
    }

    public void HideAimHint() {
        attackText.SetActive(false);
        rangeFinder.SetActive(false);
    }
}
