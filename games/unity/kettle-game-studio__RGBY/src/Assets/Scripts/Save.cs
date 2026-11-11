using UnityEngine;

public class Save : MonoBehaviour
{
    public Transform cube;
    float rotationSpeed;

    void Start()
    {
        rotationSpeed = 1;
    }

    void Update()
    {
        var angle = Time.deltaTime * rotationSpeed;
        cube.transform.rotation *= Quaternion.Euler(angle, angle, angle);
        rotationSpeed = 0.01f + rotationSpeed * 0.99f;
    }

    private void OnTriggerEnter(Collider other)
    {
        var player = other.GetComponent<PlayerController>();
        if (player != null)
        player.SetRestartParameters(cube.transform.position, transform.rotation.eulerAngles);
        rotationSpeed = 1000;
    }
}
