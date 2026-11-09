using UnityEngine;


public class HomeWitchPhase : BattlePhase
{
    public float speed = 1;
    public float time = 4;
    public Transform witch;

    void Update()
    {
        witch.transform.position += Vector3.right * speed * Time.deltaTime;
        time -= Time.deltaTime;
        if (time <= 0)
            phaseOver = true;
    }
}
