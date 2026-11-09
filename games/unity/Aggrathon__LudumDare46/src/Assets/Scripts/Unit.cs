using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[RequireComponent(typeof(Health))]
[RequireComponent(typeof(Blocker))]
[RequireComponent(typeof(Weapon))]
public class Unit : MonoBehaviour
{

    public enum Team {
        sheriff,
        bandit,
        neutral,
        leader
    }

    public Team team = Team.neutral;

    public int speed = 10;
    public int movement = 5;
    [Range(0.4f, 1.1f)] public float aggresiveness = 0.5f;
    public int actions = 2;
    public float sight = 10f;
    public Color color = new Color(1f, 0.8f, 0.5f);
    public float approxHeight = 1.8f;
    public float approxRadius = 0.45f;

    [SerializeField] protected Renderer[] coloredRenderers;

    [System.NonSerialized] public int energy;
    [System.NonSerialized] public int priority;

    public Health health { get; protected set; }
    public Blocker blocker { get; protected set; }
    public Weapon weapon { get; protected set; }

    private void OnEnable() {
        weapon = GetComponent<Weapon>();
        health = GetComponent<Health>();
        blocker = GetComponent<Blocker>();
        GameManager.activeGM.RegisterUnit(this);
        foreach(var r in coloredRenderers)
            r.material.color = color;
    }

    private void OnDisable() {
        GameManager.activeGM.DeregisterUnit(this);
    }

    public IEnumerator Act(bool inCombat) {
        energy = actions;
        if (team == Team.bandit) {
            CameraController.active.FocusOver(transform);
            UnitUI.active.Show(this);
            while (energy > 0)
                yield return null;
            UnitUI.active.Hide();
            weapon.CancelAction();
        } else if (team == Team.sheriff) {
            CameraController.active.FocusTop(transform);
            if (!inCombat) {
                foreach(Unit u in GameManager.activeGM.EnumerateEnemies(team)) {
                    if (u.team == Team.leader)
                        continue;
                    RaycastHit hit;
                    Vector3 dir = ( u.transform.position - transform.position).normalized;
                    if(Physics.Raycast(transform.position + dir * 0.5f + transform.up * 1.5f, dir, out hit, sight)) {
                        if (hit.rigidbody?.gameObject == u.gameObject) {
                            GameManager.activeGM.NotifyCombat();
                            inCombat = true;
                            break;
                        }
                    }
                }
            }
            yield return null;
            if (inCombat) {
                var graph = PathGrid.activeGrid.GetReachable(blocker.i, blocker.j, movement);
                float bestValue = float.MinValue;
                Vector3 bestTarget = Vector3.zero;
                PathGrid.PathNode bestNode = graph.ElementAt(0).Value;
                foreach (var kv in graph.AsEnumerable()) {
                    Vector3 secondTarget = Vector3.zero;
                    float secondValue = float.MinValue;
                    Vector3 target = PathGrid.activeGrid.IndexToVector(kv.Value.i, kv.Value.j);
                    float totalValue = 0f;
                    foreach(var en in GameManager.activeGM.EnumerateEnemies(team)) {
                        float defVal = Utils.Danger(en, this, en.transform.position, target).Item1;
                        (float offVal, Vector3 tmp) = Utils.Danger(this, en, target, en.transform.position);
                        if (offVal > 0.3f)
                            offVal = offVal * 0.75f + (1f - (float)en.health.health / (float)en.health.maxHealth) * 0.5f;
                        totalValue += offVal * aggresiveness - defVal * (1f - aggresiveness);
                        if (offVal > secondValue) {
                            secondTarget = tmp;
                            secondValue = offVal;
                        }
                    }
                    if (totalValue > bestValue) {
                        bestValue = totalValue;
                        bestTarget = secondTarget;
                        bestNode = kv.Value;
                    }
                    yield return null;
                }
                if (bestNode.i != blocker.i || bestNode.j != blocker.j)
                {
                    energy = 400;
                    blocker.MovePath(graph, bestNode, () => { this.energy = -1; });
                    while(energy > 0) {
                        yield return null;
                        energy--;
                    }
                }
                yield return weapon.AttackTarget(bestTarget, weapon.type);
            }
        } else if (team == Team.leader) {
            //TODO: maybe start hanging at some point?
            if (inCombat) {
                CameraController.active.FocusOver(transform);
                UnitUI.active.Show(this);
                while (energy > 0)
                    yield return null;
                UnitUI.active.Hide();
                weapon.CancelAction();
            } else {
                health.health--;
            }
        }
    }

    private void OnDrawGizmosSelected() {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position + Vector3.up*0.01f, sight);
        Gizmos.color = Color.cyan;
        Gizmos.DrawWireSphere(transform.position + Vector3.up * approxHeight / 2, approxRadius);
        Gizmos.DrawWireSphere(transform.position + Vector3.up * approxRadius, approxRadius);
        Gizmos.DrawWireSphere(transform.position + Vector3.up * (approxHeight - approxRadius), approxRadius);
    }
}
