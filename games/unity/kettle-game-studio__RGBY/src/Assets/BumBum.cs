using System;
using UnityEngine;

public class BumBum : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    public float bpm = 130;
    public Color[] colors;
    public Light light;
    void Start()
    {
        light = GetComponent<Light>();
    }

    // Update is called once per frame
    void Update()
    {
        var t1 = Time.time*(bpm/60);
        var t = (Mathf.Cos(t1*Mathf.PI*2)+1)/2;
        var current = (int)t1%colors.Length;
        var next = (current+1)%colors.Length;
        var c1 = colors[current];
        var c2 = colors[next];
        // Interpolation between c1 and c2
        var c = c1*t+c2*(t-1);
        light.color = c;
    }
}
