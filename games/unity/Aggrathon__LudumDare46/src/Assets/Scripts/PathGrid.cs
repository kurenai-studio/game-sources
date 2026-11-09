using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System;
using System.Linq;

public class PathGrid : MonoBehaviour
{
    public static PathGrid activeGrid {get; private set;}

    [SerializeField] protected int radius = 60;
    [SerializeField] protected LayerMask worldLayer;

    private bool[,] grid;
    private Dictionary<int, PathNode> graph;
    private LinkedList<(int, int)> queue;

    private void OnEnable() {
        graph = new Dictionary<int, PathNode>();
        queue = new LinkedList<(int, int)>();
        int mw = radius * 2 + 1;
        int mh = radius * 2 + 1;
        int r2 = radius*radius;
        grid = new bool[mw, mh];
        for (int i = 0; i < mw; i++) {
            float x = transform.position.x - radius + i;
            int i2 = (i - radius)*(i - radius);
            for (int j = 0; j < mh; j++) {
                if (i2 + (j-radius)*(j-radius) < r2) {
                    float y = transform.position.z - radius + j;
                    if (Physics.Raycast(new Vector3(x, 10f, y), -Vector3.up, 9.8f, worldLayer) ||
                        Physics.Raycast(new Vector3(x + 0.3f, 10f, y), -Vector3.up, 9.8f, worldLayer) ||
                        Physics.Raycast(new Vector3(x - 0.3f, 10f, y), -Vector3.up, 9.8f, worldLayer) ||
                        Physics.Raycast(new Vector3(x, 10f, y + 0.3f), -Vector3.up, 9.8f, worldLayer) ||
                        Physics.Raycast(new Vector3(x, 10f, y - 0.3f), -Vector3.up, 9.8f, worldLayer))
                        continue;
                    grid[i, j] = true;
                }
            }
        }
        activeGrid = this;
    }

    // No bounds check is performed
    public bool CanMoveInto(int i, int j) {
        return grid[i, j];
    }

    public bool CanMoveInto(Vector3 pos) {
        (int i, int j) = VectorToIndex(pos);
        return CanMoveInto(i, j);
    }

    public (int, int) VectorToIndex(Vector3 pos) {
        int i = Mathf.Clamp(Mathf.RoundToInt(pos.x), -radius, radius) + radius;
        int j = Mathf.Clamp(Mathf.RoundToInt(pos.z), -radius, radius) + radius;
        return (i, j);
    }

    public Vector3 IndexToVector(int i, int j) {
        return new Vector3(i - radius, 0f, j - radius);
    }

    // No bounds check is performed
    public void MoveInto(int i, int j) {
        if (!grid[i, j])
            Debug.LogError("Pathgrid position already occupied! ("+ i+","+j+")");
        grid[i, j] = false;
    }

    public void MoveInto(Vector3 pos) {
        (int i, int j) = VectorToIndex(pos);
        MoveInto(i, j);
    }

    // No bounds check is performed
    public void MoveOut(int i, int j) {
        if (grid[i, j])
            Debug.LogError("Pathgrid position is not occupied! ("+ i+","+j+")");
        grid[i, j] = true;
    }

    public void MoveOut(Vector3 pos) {
        (int i, int j) = VectorToIndex(pos);
        MoveOut(i, j);
    }

    public struct PathNode {
        public PathNode(int i, int j, int pid, int d, int radius) {
            this.i = i;
            this.j = j;
            this.id =  i * radius * radius + j;
            this.pid =  pid;
            this.d = d;
            this.visited = false;
        }
        public int i;
        public int j;
        public int id;
        public int pid;
        public int d;
        public bool visited;
    }

    public Dictionary<int, PathNode> GetReachable(int i, int j, int d) {
        graph.Clear();
        queue.Clear();

        PathNode node = new PathNode(i, j, -1, 0, radius);
        queue.AddFirst((0, node.id));
        graph.Add(node.id, node);
        while(queue.Count > 0) {
            int id = queue.First.Value.Item2;
            queue.RemoveFirst();
            node = graph[id];
            if (node.visited)
                continue;
            node.visited = true;
            graph[id] = node;
            if (node.d == d)
                continue;
            PathfindingTryAdd(new PathNode(node.i + 1, node.j, node.id, node.d + 1, radius));
            PathfindingTryAdd(new PathNode(node.i - 1, node.j, node.id, node.d + 1, radius));
            PathfindingTryAdd(new PathNode(node.i, node.j + 1, node.id, node.d + 1, radius));
            PathfindingTryAdd(new PathNode(node.i, node.j - 1, node.id, node.d + 1, radius));
        }
        return graph;
    }

    private void PathfindingTryAdd(PathNode node) {
        if (!grid[node.i, node.j])
            return;
        if (graph.ContainsKey(node.id)) {
            PathNode node2 = graph[node.id];
            if (node2.visited || node.d >= node2.d)
                return;
        }
        graph[node.id] = node;
        if (queue.Count == 0)
            queue.AddFirst((node.d, node.id));
        else {
            var q = queue.First;
            while (q.Value.Item1 <= node.d && q.Next != null) q = q.Next;
            if (node.d < q.Value.Item1)
                queue.AddBefore(q, (node.d, node.id));
            else
                queue.AddAfter(q, (node.d, node.id));
        }
    }

    private void OnDrawGizmos() {
        Gizmos.color = Color.green;
        Gizmos.DrawWireSphere(transform.position + Vector3.up * 0.1f, radius);
    }

    private void OnDrawGizmosSelected() {
        if (grid == null)
            return;
        Gizmos.color = Color.blue;
        int mw = radius * 2 + 1;
        int mh = radius * 2 + 1;
        for (int i = 0; i < mw; i++) {
            float x = transform.position.x - radius + i;
            for (int j = 0; j < mh; j++) {
                float y = transform.position.z - radius + j;
                if (grid[i, j])
                    Gizmos.DrawWireCube(new Vector3(x, 0, y), Vector3.one * 0.6f);
            }
        }
    }
}
