using System;
using UnityEngine;

public class Impulse : MonoBehaviour
{
    float initialScale;
    public float bpm = 130;
    public float scaleDelta = 1;
    public float shift = 0;
    void Start() {
        initialScale = transform.localScale.x;
    }
    // Update is called once per frame
    void Update()
    {
        float s = initialScale + (scaleDelta*(Mathf.Cos((shift+Time.time)*Mathf.PI*2*(bpm/60))-1));
        transform.localScale = new Vector3(s, s, s);
    }
}
