using System.Collections.Generic;
using UnityEngine;

public class TrailLine : MonoBehaviour
{
    public Transform player;
    public Transform playerRopeMount;
    public Transform worldRopeMount;
    public LineRenderer rope;
    public float segmentDistance = 0.5f;
    public float shrinkSpeed = 1f;

    public bool moveBackFlag = false;

    List<Vector3> positions;
    int layerMask;

    void Start()
    {
        layerMask = 1 << LayerMask.NameToLayer("Default");
        rope.transform.parent = player.parent;
        rope.transform.SetPositionAndRotation(Vector3.zero, Quaternion.identity);

        positions = new List<Vector3> {
            worldRopeMount.position,
            playerRopeMount.position,
        };

        rope.SetPositions(positions.ToArray());
    }

    void Update()
    {
        RopeGarbageCollector();

        var lastPos = positions[positions.Count - 2];
        var currentPos = playerRopeMount.position;

        if (moveBackFlag && positions.Count > 2)
        {
            var preLastPos = positions[positions.Count - 2];
            if (Vector3.Distance(preLastPos, currentPos) <= segmentDistance)
            {
                // Debug.Log($"Remove point");
                positions.RemoveAt(positions.Count - 1);
                positions[^1] = currentPos;

                rope.positionCount = positions.Count;
                rope.SetPositions(positions.ToArray());
            }
        }

        positions[^1] = currentPos;
        if (!moveBackFlag && Vector3.Distance(lastPos, currentPos) > segmentDistance)
        {
            positions.Add(currentPos);
            // Debug.Log($"Add point {currentPos} ({positions.Count})");
            rope.positionCount = positions.Count;
            rope.SetPositions(positions.ToArray());
            return;
        }

        rope.SetPosition(rope.positionCount - 1, currentPos);
    }

    int countFrames = 0;
    void RopeGarbageCollector()
    {
        if (positions.Count < 3)
        {
            return;
        }

        for (var i = 2; i < positions.Count; i++)
        {
            var p0 = positions[i - 2];
            var p1 = positions[i - 1];
            var p2 = positions[i - 0];

            var v0 = p0 - p1;
            var v1 = p2 - p1;
            var vm = (v0 + v1) * 0.5f;
            var vmm = vm.magnitude;
            if (vmm < 0.01f)
                continue;

            vm = Mathf.Min(shrinkSpeed * Time.deltaTime, vmm) * (v0 + v1).normalized;

            var ray0 = Physics.Raycast(p1, v0, v0.magnitude, layerMask);
            Debug.DrawRay(p1, v0);
            if (ray0) continue;

            Debug.DrawRay(p1, v1);
            var ray1 = Physics.Raycast(p1, v1, v1.magnitude, layerMask);
            if (ray1) continue;

            positions[i - 1] += vm;
        }

        countFrames++;
        if (countFrames < 10) return;
        countFrames = 0;

        var newPositions = new List<Vector3>();
        var pPrev = positions[0];

        newPositions.Add(pPrev);
        for (var i = 1; i < positions.Count - 1; i++)
        {
            var p = positions[i];

            if (Vector3.Distance(pPrev, p) < segmentDistance * 0.5f)
            {
                var v = pPrev - p;
                Debug.DrawRay(p, v);
                var ray0 = Physics.Raycast(p, v, v.magnitude, layerMask);
                if (ray0)
                    continue;
            }

            newPositions.Add(p);
            pPrev = p;
        }
        newPositions.Add(positions[^1]);

        positions = newPositions;
        rope.positionCount = positions.Count;
        rope.SetPositions(positions.ToArray());
    }

    public Vector3 RollBackDirection()
    {
        var lastPos = positions[positions.Count - 2];
        var currentPos = playerRopeMount.position;

        return (lastPos - currentPos).normalized;
    }
}
