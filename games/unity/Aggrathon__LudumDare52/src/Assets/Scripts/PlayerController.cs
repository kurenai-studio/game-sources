using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(Vehicle))]
public class PlayerController : MonoBehaviour
{
    public LayerMask groundLayerMask = 1 << 3;
    public GameObject gameOverScreen;
    public GameObject gameVictoryScreen;

    Vehicle vehicle;

    void Start()
    {
        vehicle = GetComponent<Vehicle>();
    }

    public void OnForward(InputAction.CallbackContext context)
    {
        if (context.performed)
        {
            vehicle.Forward();
        }
    }

    public void OnReverse(InputAction.CallbackContext context)
    {
        if (context.performed)
        {
            vehicle.Reverse();
        }
    }

    public void OnSteer(InputAction.CallbackContext context)
    {
        vehicle.Steer(context.ReadValue<float>());
    }



    private void OnCollisionEnter(Collision other)
    {
        if ((other.gameObject.layer ^ groundLayerMask) != 0)
        {
            gameOverScreen.SetActive(true);
        }
    }

    public void Victory()
    {
        gameVictoryScreen.SetActive(true);
    }
}
