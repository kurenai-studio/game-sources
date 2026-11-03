
using UnityEngine;

public class Coin : MonoBehaviour
{
    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.CompareTag("Player"))
        {
            CoinManager manager = FindFirstObjectByType<CoinManager>();

            if (manager != null)
            {
                manager.AddCoin();
                Destroy(gameObject);
            }
        }
    }
}
