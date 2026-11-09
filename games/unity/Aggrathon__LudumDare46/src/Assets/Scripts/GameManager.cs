using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public enum State {
        Stopped,
        Setup,
        Starting,
        PreCombat,
        Combat
    }

    public static GameManager activeGM { get; protected set; }
    
    List<Unit> units;
    State state;


    public GameObject winScreen;
    public GameObject looseScreen;
    public GameObject looseScreen2;
    public GameObject spottedScreen;
    public TurnOrder turnOrder;

    private void OnEnable() {
        activeGM = this;
        units = new List<Unit>();
        state = State.Setup;
    }

    private void OnDestroy() {
        units.Clear();
    }

    public void RegisterUnit(Unit unit) {
        if (state == State.Setup && unit.team == Unit.Team.bandit) {
            state = State.Starting;
            StartCoroutine(StateMachine());
        }
        unit.priority = Random.Range(1, unit.speed);
        units.Add(unit);
    }

    public void DeregisterUnit(Unit unit) {
        if (units.Remove(unit)) {
            foreach(var u in units)
                if (u.team == unit.team)
                    return;
            NotifyLost(unit.team);
        }
    }

    public IEnumerable<Unit>EnumerateEnemies(Unit.Team team) {
        switch(team) {
            case Unit.Team.sheriff:
                foreach(var u in units)
                    if (u.team == Unit.Team.bandit || u.team == Unit.Team.leader)
                        yield return u;
                break;
            case Unit.Team.bandit:
            case Unit.Team.leader:
                foreach(var u in units)
                    if (u.team == Unit.Team.sheriff)
                        yield return u;
                break;
        }
    }

    private Unit GetNextUnit() {
        units.Sort((a, b)=> a.priority.CompareTo(b.priority));
        if (units.Count > 0) {
            int minpri = units[0].priority;
            foreach(var u in units) {
                u.priority += minpri;
            }
            units[0].priority += units[0].speed;
            turnOrder.Show(units);
            return units[0];
        }
        return null;
    }

    private IEnumerator StateMachine() {
        yield return null;
        Unit unit;
        while(true) {
            switch (state)
            {
                case State.Starting:
                    CameraController.active.FocusTop();
                    yield return new WaitForSeconds(1.9f);
                    state = State.PreCombat;
                    break;
                case State.PreCombat:
                    unit = GetNextUnit();
                    yield return unit.Act(false);
                    break;
                case State.Combat:
                    unit = GetNextUnit();
                    yield return unit.Act(true);
                    break;
                default:
                    yield break;
            }
        }
    }

    public void NotifyCombat() {
        if (state == State.PreCombat) {
            state = State.Combat;
            spottedScreen.SetActive(true);
        }
    }

    public void NotifyLost(Unit.Team team) {
        if (team == Unit.Team.sheriff) {
            state = State.Stopped;
            if (winScreen) {
                winScreen.SetActive(true);
                StopAllCoroutines();
            }
        } else if (team == Unit.Team.bandit) {
            state = State.Stopped;
            if (looseScreen) {
                looseScreen.SetActive(true);
                StopAllCoroutines();
            }
        } else if (team == Unit.Team.leader) {
            state = State.Stopped;
            if (looseScreen2) {
                looseScreen2.SetActive(true);
                StopAllCoroutines();
            }
        }
    }
}
