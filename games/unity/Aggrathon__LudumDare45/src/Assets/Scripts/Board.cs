using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.EventSystems;

public class Board : MonoBehaviour
{
    [NonSerialized] public List<BoardTarget> targets;

    bool highlighted;
    BoardTarget moving;
    Camera cam;

    private void Awake() {
        targets = new List<BoardTarget>();
        highlighted = false;
        cam = Camera.main;
    }

    public void Highlight(Func<BoardTarget, bool> filter) {
        for (int i = 0; i < targets.Count; i++)
        {
            if (filter(targets[i])) {
                targets[i].Highlight();
            }
        }
        highlighted = true;
        moving = null;
    }

    public void Unlight() {
        if (highlighted) {
            for (int i = 0; i < targets.Count; i++)
            {
                targets[i].Unlight();
            }
            highlighted = false;
            moving = null;
        }
    }

    public BoardTarget FindBest(Func<BoardTarget, (float, bool)> loss) {
        BoardTarget target = null;
        float best = float.MaxValue;
        for (int i = 0; i < targets.Count; i++)
        {
            var (l, f) = loss(targets[i]);
            if (f && l < best) {
                best = l;
                target = targets[i];
            }
        }
        return target;
    }

    private void Update() {
        if (Input.GetMouseButtonDown(0)) {
            if (!EventSystem.current.IsPointerOverGameObject()) {
                RaycastHit hit;
                if (Physics.Raycast(cam.ScreenPointToRay(Input.mousePosition), out hit, 100f))
                {
                    BoardTarget target = hit.transform.GetComponent<BoardTarget>();
                    if (target != null) {
                        if (moving != null) {
                            if (moving == target || moving.unit == null) {
                                Unlight();
                            } else {
                                moving.unit.Move(target);
                                Unlight();
                            }
                        } else if (target.unit?.team?.interactable == true) {
                            if (target.unit.moveDist < 1f && target.unit.attackDist < 1f)
                                return;
                            if (target.unit.hasMoved) {
                                target.unit.team.Alert("Unit has already moved!");
                            } else {
                                Highlight((BoardTarget b) => {
                                    var sqrDist = (b.transform.localPosition - target.transform.localPosition).sqrMagnitude;
                                    return (b.unit == null && sqrDist <= target.unit.moveDist * target.unit.moveDist)
                                        || (b.unit != null && b.unit.team != target.unit.team && sqrDist <= target.unit.attackDist * target.unit.attackDist);
                                });
                                moving = target;
                            }
                        }
                    } else if (moving != null) {
                        Unlight();
                    }
                } else if (moving != null) {
                    Unlight();
                }
            }
        }
    }
}
