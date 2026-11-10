using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Field : MonoBehaviour
{
    public static bool shadows = true;

    [System.Serializable]
    public struct TrackedObject
    {
        public Transform transform;
        public Vector3 offset;
        public float radius;
    }

    [Header("Field")]
    [Min(0)] public float width = 10f;
    [Min(0)] public float length = 10f;

    [Min(0)] public float widthSpace = 0.25f;
    [Min(0)] public float lengthSpace = 0.25f;


    [Header("Spawn")]
    [Min(0)] public float randomAngle = 2f;
    [Min(0)] public float randomScale = 0.05f;
    [Min(0)] public float randomHeight = 0.1f;

    [Header("Harvest")]
    public TrackedObject[] trackedObjects;
    public LayerMask groundLayerMask = 1 << 3;
    [Min(0)] public float cropHeight = 1f;
    [Min(0)] public float harvestedAngle = 50f;
    [Min(0)] public float harvestedHeight = 0.2f;
    [Min(0)] public float harvestedScale = 0.1f;

    [Header("Mesh")]
    public Mesh mesh;
    public Material[] materials;
    public Vector3 meshPosition;
    public Vector3 meshRotation;
    public Vector3 meshScale = Vector3.one;


    Matrix4x4[] matrices;
    int[,] indices;
    float widthOffset;
    float lengthOffset;
    public int columns { get; protected set; }
    public int rows { get; protected set; }

    public int TotalCrops => matrices.Length;
    public int HarvestedCrops { get; protected set; }
    public int TrampledCrops { get; protected set; }

    public void SetupGrid(System.Func<int, int, bool> filter)
    {
        columns = Mathf.FloorToInt(width / widthSpace);
        rows = Mathf.FloorToInt(length / lengthSpace);
        widthOffset = (width - columns * widthSpace) * 0.5f - width * 0.5f;
        lengthOffset = (length - rows * lengthSpace) * 0.5f - length * 0.5f;
        indices = new int[columns, rows];
        var mats = new List<Matrix4x4>(columns * rows / 2);
        Vector3 worldPos = transform.position + meshPosition;
        for (int i = 0; i < columns; i++)
        {
            for (int j = 0; j < rows; j++)
            {
                if (filter(i, j))
                {
                    var pos = IndexToLocal(i, j) + worldPos;
                    pos.x += Random.value * widthSpace - widthSpace * 0.5f;
                    pos.y -= Random.value * randomHeight;
                    pos.z += Random.value * lengthSpace - lengthSpace * 0.5f;
                    var rot = Quaternion.Euler(meshRotation.x, meshRotation.y + Random.value * 360f, meshRotation.z + Random.value * randomAngle);
                    var size = new Vector3(meshScale.x * (1f + Random.value * randomScale), meshScale.y * (1f + Random.value * randomScale), meshScale.z * (1f + Random.value * randomScale));
                    var mat = Matrix4x4.TRS(pos, rot, size);
                    indices[i, j] = mats.Count;
                    mats.Add(mat);
                }
                else
                {
                    indices[i, j] = -1;
                }
            }
        }
        matrices = mats.ToArray();
        HarvestedCrops = 0;
        TrampledCrops = 0;
        // Debug.Log(string.Format("Created {0} crops", matrices.Count), this);
    }

    [ContextMenu("Clear Gizmos")]
    public void DestroyGrid()
    {
        indices = null;
        matrices = null;
    }

    public Vector3 IndexToLocal(int i, int j)
    {
        return new Vector3(i * widthSpace + widthOffset, 0f, j * lengthSpace + lengthOffset);
    }

    public Vector3 IndexToWorld(int i, int j)
    {
        return transform.position + IndexToLocal(i, j);
    }

    protected (int, int) WorldToIndex(Vector3 pos)
    {
        var i = Mathf.RoundToInt((pos.x - transform.position.x - widthOffset) / widthSpace);
        var j = Mathf.RoundToInt((pos.z - transform.position.z - lengthOffset) / lengthSpace);
        return (i, j);
    }

    private void Update()
    {
#if UNITY_EDITOR
        if (matrices == null || matrices.Length == 0)
        {
            Debug.LogError("Add a `Field Spawner` to spawn crops (the `Field` only manages the crops)");
            enabled = false;
            return;
        }
#endif

        for (int i = 0; i < materials.Length; i++)
        {
            // for (int j = 0; j < matrices.Length; j += 1023)
            // {
            //     var k = Mathf.Min(j + 1023, matrices.Length);
            //     Graphics.DrawMeshInstanced(mesh, i, materials[i], matrices[j..k]);
            // }
            Graphics.DrawMeshInstanced(
                mesh,
                i,
                materials[i],
                matrices,
                matrices.Length,
                new MaterialPropertyBlock(),
                shadows ? UnityEngine.Rendering.ShadowCastingMode.On : UnityEngine.Rendering.ShadowCastingMode.Off,
                shadows
            );
        }
    }

    void FixedUpdate()
    {
        foreach (var obj in trackedObjects)
        {
            int rw = Mathf.CeilToInt(obj.radius / widthSpace);
            int rl = Mathf.CeilToInt(obj.radius / lengthSpace);
            var (w, l) = WorldToIndex(obj.transform.TransformPoint(obj.offset));
            var imin = Mathf.Max(0, w - rw);
            var imax = Mathf.Min(columns - 1, w + rw);
            var jmin = Mathf.Max(0, l - rl);
            var jmax = Mathf.Min(rows - 1, l + rl);
            for (int i = imin; i <= imax; ++i)
            {
                for (int j = jmin; j <= jmax; ++j)
                {
                    if (indices[i, j] >= 0)
                    {
                        var mat = matrices[indices[i, j]];
                        var pos = mat.GetPosition();
                        pos.y -= 1e-4f;
                        var dir = Vector3.up;
                        if (Physics.Raycast(pos, dir, out RaycastHit hit, cropHeight, ~groundLayerMask))
                        {
                            if (hit.collider.gameObject.GetComponent<Tresher>()?.Harvest() ?? false)
                            {
                                ++HarvestedCrops;
                            }
                            else
                            {
                                ++TrampledCrops;
                            }
                            // TODO: Destroy crop FX
                            pos.y += harvestedHeight;
                            pos -= 2 * meshPosition;
                            var rot = Quaternion.Euler(meshRotation.x - 180f, meshRotation.y + Random.value * 360f, meshRotation.z + Random.value * harvestedAngle);
                            var size = new Vector3(meshScale.x * (1f + Random.value * harvestedScale), meshScale.y * (1f + Random.value * harvestedScale), meshScale.z * (1f + Random.value * harvestedScale));
                            matrices[indices[i, j]] = Matrix4x4.TRS(pos, rot, size);
                            indices[i, j] = -1;
                        }
                    }
                }
            }
        }
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(transform.position + new Vector3(0, cropHeight * 0.5f, 0), new Vector3(width, cropHeight, length));
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        foreach (var obj in trackedObjects)
        {
            Gizmos.DrawWireSphere(obj.transform.TransformPoint(obj.offset), obj.radius);
        }
        if (matrices != null && matrices.Length > 0 && indices != null)
        {
            Gizmos.color = Color.magenta;
            foreach (var obj in trackedObjects)
            {
                int rw = Mathf.CeilToInt(obj.radius / widthSpace);
                int rl = Mathf.CeilToInt(obj.radius / lengthSpace);
                var (w, l) = WorldToIndex(obj.transform.TransformPoint(obj.offset));
                var imin = Mathf.Max(0, w - rw);
                var imax = Mathf.Min(columns - 1, w + rw);
                var jmin = Mathf.Max(0, l - rl);
                var jmax = Mathf.Min(rows - 1, l + rl);
                for (int i = imin; i <= imax; ++i)
                {
                    for (int j = jmin; j <= jmax; ++j)
                    {
                        if (indices[i, j] >= 0)
                        {
                            var mat = matrices[indices[i, j]];
                            var pos = mat.GetPosition();
                            pos.y -= 1e-4f;
                            var dir = Vector3.up;
                            Gizmos.DrawWireSphere(pos, widthSpace / 2 + lengthSpace / 2);
                        }
                    }
                }
            }

            if (!Application.isPlaying)
            {
                Gizmos.color = Color.yellow;
                foreach (var mat in matrices)
                {
                    var pos = mat.GetPosition();
                    pos.y += cropHeight * 0.5f;
                    Gizmos.DrawWireCube(pos, new Vector3(0.05f, cropHeight, 0.05f));
                }
            }
        }
    }
}
