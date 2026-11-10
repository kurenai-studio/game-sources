using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(LineRenderer))]
public class WindIndicator : MonoBehaviour
{
    LineRenderer lineRenderer;
    Vector3[] positions;
    Vector3[] origPos;
    float offset;

    public float timeMult = 8f;
    public float distMult = 3f;
    public float magnitude = 0.2f;
    public float distMultX = 2.3f;
    public float timeMultX = 5.78f;
    public float magnitudeX = 0.08f;

    void Start()
    {
        lineRenderer = GetComponent<LineRenderer>();
        positions = new Vector3[lineRenderer.positionCount];
        lineRenderer.GetPositions(positions);
        origPos = (Vector3[])positions.Clone();
        offset = Random.Range(0, Mathf.PI);
        timeMult *= Random.Range(0.9f, 1.1f);
        distMult *= Random.Range(0.9f, 1.1f);
        distMultX *= Random.Range(0.9f, 1.1f);
        timeMultX *= Random.Range(0.9f, 1.1f);
    }

    void Update()
    {
        for (int i = 2; i < positions.Length; i++)
        {
            positions[i].y = magnitude * Mathf.Sin(origPos[i].x * distMult + Time.time * timeMult + offset);
            positions[i].x = magnitudeX * Mathf.Cos(origPos[i].x * distMultX + Time.time * timeMultX + offset) + origPos[i].x;
        }
        lineRenderer.SetPositions(positions);
    }
}
