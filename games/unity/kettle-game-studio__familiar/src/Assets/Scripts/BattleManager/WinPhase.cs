using UnityEngine;


public class ToadWinPhase : BattlePhase
{
    public CameraController cameraController;
    public float waitTime = 1;

    float waitTimer = -1;

    protected override void Start()
    {
        base.Start();
    }

    public void Update()
    {
        waitTimer += Time.deltaTime;
        if (waitTimer > waitTime)
            phaseOver = true;
    }

    public override void PhaseEnter()
    {
        cameraController.BlackoutOn();
        waitTimer = 0;
        Debug.Log("Win!!!");
    }
}
