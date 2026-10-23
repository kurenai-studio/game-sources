using UnityEngine;

public class Gun : MonoBehaviour
{
    private Vector3 finalPosition;
    private Vector3 direction;
    private const float speed = 10f;

    void Start()
    {
        PrepareShootDirection();
        Destroy(gameObject, 3f);
    }

    void PrepareShootDirection()
    {
        finalPosition = Input.mousePosition;
        finalPosition = Camera.main.ScreenToWorldPoint(finalPosition);
        finalPosition.z = 0;

        direction = finalPosition - transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        transform.position += direction.normalized * speed * Time.deltaTime;
    }
}
