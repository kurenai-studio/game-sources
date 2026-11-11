using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Splines;

public class SplineWalker : MonoBehaviour
{
    public SplineContainer spline;
    public uint count = 0;
    public GameObject walker;
    public float speed = 1;
    public float scale = 3;

    Transform[] units;

    void Start()
    {
        units = new Transform[count];
        for (int i = 0; i < count; i++) {
            units[i] = Instantiate(walker).transform;
            units[i].localScale = Vector3.one * scale;
        }
    }

    void Update()
    {
        float step = Time.time * speed;
        float3 predP = spline.EvaluatePosition(Mathf.Repeat(step + (count - 1) / (float)count, 1));
        for (int i = 0; i < count; i++) {
            float t = Mathf.Repeat(step + i / (float)count, 1);
            var p = spline.EvaluatePosition(t);
            units[i].position = p;
            units[i].rotation = Quaternion.LookRotation(predP - p, Vector3.up);
            predP = p;
        }
    }
}
