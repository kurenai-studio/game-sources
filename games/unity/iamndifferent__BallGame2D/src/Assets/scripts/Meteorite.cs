
using UnityEngine;

public class Meteorite : MonoBehaviour
{
    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.CompareTag("Player"))
        {
            GameManagerUI manager =
                FindFirstObjectByType<GameManagerUI>();

            if (manager != null)
            {
                manager.ShowDeath();
            }

            Destroy(gameObject);
        }
    }
}
