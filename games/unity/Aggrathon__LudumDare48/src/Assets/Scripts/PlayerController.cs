using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class PlayerController : MonoBehaviour
{
    private CharacterController controller;
    private Transform mainCamera;
    private Vector2 input;
    private float gravity;
    public float speed = 2.0f;
    public float sensitivity = 1.0f;

    float verticalAngle = 0.0f;

    void Start()
    {
        controller = GetComponent<CharacterController>();
        mainCamera = Camera.main.transform;
    }

    void Update()
    {
        if (controller.isGrounded && gravity < 0)
        {
            gravity = 0f;
        }
        else
        {
            gravity -= 9.81f * Time.deltaTime;
        }

        Vector3 move = new Vector3(input.x, gravity, input.y);
        if (move.sqrMagnitude > 1e-6)
        {
            float y = mainCamera.rotation.eulerAngles.y;
            move = Quaternion.Euler(0, y, 0) * move;
            controller.Move(move * Time.deltaTime * speed);
        }
    }

    public void OnMove(InputAction.CallbackContext input)
    {
        this.input = input.ReadValue<Vector2>();
    }


    public void OnLook(InputAction.CallbackContext input)
    {
        Vector2 look = input.ReadValue<Vector2>();
        verticalAngle = Mathf.Clamp(verticalAngle - look.y * sensitivity, -75f, 75f);
        mainCamera.localRotation = Quaternion.Euler(verticalAngle, 0, 0);
        transform.Rotate(new Vector3(0, look.x * sensitivity, 0), Space.World);
    }
}
