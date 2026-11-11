using UnityEngine;

public class Blink : MonoBehaviour
{
    public MeshRenderer mesh;
    Material material;

    public float color1range1 = 1;
    public float color1range2 = 1;

    public float color2range1 = 1;
    public float color2range2 = 1;

    public float color3range1 = 1;
    public float color3range2 = 1;

    float timer1 = 0;
    float timer2 = 0;
    float timer3 = 0;

    bool state1 = false;
    bool state2 = false;
    bool state3 = false;

    void Start()
    {
        material = mesh.material;
    }

    void Update()
    {
        timer1 -= Time.deltaTime;
        if (timer1 <= 0)
        {
            state1 = !state1;
            timer1 = Random.Range(0, state1 ? color1range1 : color1range2);
            material.SetFloat("_light_1_select", state1 ? 1 : 0);
        }
        timer2 -= Time.deltaTime;
        if (timer2 <= 0)
        {
            state2 = !state2;
            timer2 = Random.Range(0, state2 ? color2range1 : color2range2);
            material.SetFloat("_light_2_select", state2 ? 1 : 0);
        }
        timer3 -= Time.deltaTime;
        if (timer3 <= 0)
        {
            state3 = !state3;
            timer3 = Random.Range(0, state3 ? color3range1 : color3range2);
            material.SetFloat("_light_3_select", state3 ? 1 : 0);
        }
    }
}
