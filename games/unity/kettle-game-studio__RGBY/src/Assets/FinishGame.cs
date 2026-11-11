using UnityEngine;

public class FinishGame : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        MusicManager.instance.PlayFinish();
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
