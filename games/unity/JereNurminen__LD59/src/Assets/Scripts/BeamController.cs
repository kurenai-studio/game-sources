using UnityEngine;

public class BeamController : MonoBehaviour
{
    private LevelManager levelManager;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        levelManager = FindObjectOfType<LevelManager>();
    }

    // Update is called once per frame
    void Update() { }

    public void OnHit()
    {
        levelManager.OnBeamHit();
    }

    public void OnDone()
    {
        levelManager.OnBeamDone();
    }
}
