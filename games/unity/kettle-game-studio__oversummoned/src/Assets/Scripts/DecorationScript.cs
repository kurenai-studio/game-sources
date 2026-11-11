using UnityEngine;

public class DecorationScript : MonoBehaviour
{
    void Start()
    {
        var hit = Physics.Raycast(transform.position + Vector3.up * 10, Vector3.down, out var collision);
        if (!hit || collision.transform.gameObject.GetComponent<TileScript>() == null)
        {
            Destroy(gameObject);
        }
    }
}
