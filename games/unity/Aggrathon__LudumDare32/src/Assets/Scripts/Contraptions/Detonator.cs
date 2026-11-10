using UnityEngine;
using System.Collections;

public class Detonator : MonoBehaviour {

    float timer;

    public enum DetonType
    {
        Timer, Impact, Remote
    }
    public DetonType type;
    public float timerLength = 3f;

	// Use this for initialization
	void OnEnable () {
        timer = timerLength;
	}
	
	// Update is called once per frame
	void Update () {
        if (type == DetonType.Remote && Input.GetButtonUp("Detonate") && Time.deltaTime > 0f)
            Detonate();
        if (type == DetonType.Timer)
        {
            timer -= Time.deltaTime;
            if (timer < 0)
                Detonate();
        }
	}

    void OnCollision()
    {
        if (type == DetonType.Impact)
        {
            Detonate();
        }
    }

    public void Detonate()
    {
        foreach (Explosive e in transform.GetComponentsInChildren<Explosive>())
            e.Explode();
        foreach (EMP e in transform.GetComponentsInChildren<EMP>())
            e.Blast();
    }
}
