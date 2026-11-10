using UnityEngine;

public class Explosion : MonoBehaviour
{
    public void OnExploded()
    {
        Destroy(gameObject);
    }
}
