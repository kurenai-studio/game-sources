using UnityEngine;

public class Deadline : MonoBehaviour
{
    public float lifetime;

    async void Start()
    {
        await Awaitable.WaitForSecondsAsync(lifetime);
        Destroy(gameObject);
    }
}
