using System.Collections;
using System.Linq;
using System;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class Blocker : MonoBehaviour
{
    public float moveHeight = 0.3f;
    public float moveSpeed = 2f;

    public AudioClip stepSound;

    PathGrid grid;
    public int i { get; protected set; }
    public int j { get; protected set; }
    List<Vector3> moves;
    Rigidbody rb;

    private void OnEnable() {
        moves = new List<Vector3>();
        grid = PathGrid.activeGrid;
        (this.i, this.j) = grid.VectorToIndex(transform.position);
        grid.MoveInto(this.i, this.j);
        rb = GetComponent<Rigidbody>();
    }

    private void OnDisable() {
        grid.MoveOut(this.i, this.j);
    }

    public bool Move(int i, int j) {
        if (grid.CanMoveInto(i, j)) {
            grid.MoveOut(this.i, this.j);
            grid.MoveInto(i, j);
            this.i = i;
            this.j = j;
            rb.MovePosition(grid.IndexToVector(i, j));
            return true;
        } else {
            return false;
        }
    }

    public bool Move(Vector3 target) {
        (int i, int j) = grid.VectorToIndex(target);
        return Move(i, j);
    }

    public bool MoveAnimated(List<Vector3> moves, int i, int j, Action callback = null) {
        if (grid.CanMoveInto(i, j)) {
            grid.MoveOut(this.i, this.j);
            grid.MoveInto(i, j);
            this.i = i;
            this.j = j;
            this.moves = moves;
            StartCoroutine(MoveAnimation(callback));
            return true;
        } else {
            return false;
        }
    }

    public bool MoveAnimated(List<Vector3> moves, Action callback = null) {
        (int i, int j) = grid.VectorToIndex(moves[moves.Count - 1]);
        return MoveAnimated(moves, i, j, callback);
    }

    IEnumerator MoveAnimation(Action callback = null) {
        if (moves.Count == 0) {
            callback?.Invoke();
            yield break;
        }
        Vector3 vel = Vector3.zero;
        Vector3 prev = transform.position;
        int i = 0;
        if (moves.Count > 0 && Vector3.SqrMagnitude(prev - moves[i]) < 0.01f)
            i++;
        while (i < moves.Count) {
            Vector3 move = moves[i];
            float d2 = Vector3.SqrMagnitude(transform.position - move);
            if (d2 < 0.01f) {
                if (stepSound != null)
                    FXManager.active.PlayAudio(move, stepSound);
                prev = moves[i];
                i++;
                if (i < moves.Count) {
                    move = moves[i];
                    var dir = move - transform.position;
                    dir.y = 0f;
                    transform.rotation = Quaternion.LookRotation(dir, Vector3.up);
                    d2 = dir.sqrMagnitude;
                } else
                    break;
            }
            move.y = transform.position.y;
            move = Vector3.SmoothDamp(transform.position, move, ref vel, 0.3f/moveSpeed, moveSpeed);
            float d1 = Vector3.SqrMagnitude(transform.position - prev);
            move.y = (1f - (d1 + d2 - 0.5f) * 2f) * moveHeight;
            rb.MovePosition(move);
            yield return null;
        }
        if (moves.Count > 0) {
            rb.MovePosition(moves[moves.Count - 1]);
        }
        callback?.Invoke();
    }

    public bool MovePath(Dictionary<int, PathGrid.PathNode> graph, PathGrid.PathNode target, Action callback = null) {
        moves.Clear();
        for (int i = 0; i < target.d + 1; i++)
        {
            moves.Add(Vector3.zero);
        }
        int id = target.id;
        while (id != -1) {
            var node = graph[id];
            moves[node.d] = grid.IndexToVector(node.i, node.j);
            id = node.pid;
        }
        return MoveAnimated(moves, target.i, target.j, callback);
    }

    public void RandomMove(int maxSteps = 2) {
        var graph = grid.GetReachable(this.i, this.j, maxSteps);
        var target = graph.ElementAt(UnityEngine.Random.Range(0, graph.Count)).Value;
        MovePath(graph, target, null);
    }
    
    [ContextMenu("Random Move 2")] private void RandomMove2() { RandomMove(2); }
    [ContextMenu("Random Move 5")] private void RandomMove5() { RandomMove(5); }
}
