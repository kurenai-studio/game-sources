using UnityEngine;
using Random = UnityEngine.Random;

public class Bullet : MonoBehaviour {
    public Vector2 direction = Vector2.zero;
    public float speed = 0.25f;

    private void Start() {
        transform.rotation = Quaternion.Euler(0, 0, Random.Range(0f, 255f));
    }

    private void FixedUpdate() {
        var position = transform.position;
        position = position + ((Vector3)direction * speed);
        transform.position = position;
    }
    
    private void OnCollisionEnter2D(Collision2D target) {
        var targetObject = target.gameObject;
        if (targetObject.name == "Walls" || targetObject.CompareTag("Spawner") || targetObject.CompareTag("Enemy")) {
            Destroy(gameObject);
        }
    }
}