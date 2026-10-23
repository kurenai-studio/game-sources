using Controllers;
using Playfield;
using ScriptableObjects;
using UnityEngine;

[RequireComponent(typeof(IController))]
public class Paddle : MonoBehaviour
{
    [SerializeField]
    private PaddleData paddleData;

    // References to components
    private new Rigidbody2D rigidbody;
    private IController controller;
    
    private Boundary yBoundary;
    
    private void Awake()
    {
        rigidbody = GetComponent<Rigidbody2D>();
        controller = GetComponent<IController>();
        
        yBoundary = FindFirstObjectByType<Playfield.Playfield>().VerticalBoundary;
    }
    
    private void FixedUpdate()
    {
        Move();
    }
    
    private void Move()
    {
        var targetPosition = rigidbody.position;
        var targetY = rigidbody.position.y + paddleData.speed * Time.fixedDeltaTime * controller.GetVerticalInput();
        targetPosition.y = Mathf.Clamp(targetY, yBoundary.Min, yBoundary.Max);
        
        rigidbody.MovePosition(targetPosition);
    }
}
