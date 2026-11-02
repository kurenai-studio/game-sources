using UnityEngine;
using UnityEngine.InputSystem;

public class GameInput : MonoBehaviour
{
   // Public properties
   public Vector2 MoveInput { get; private set; } 
   
   
   // External Functions
   public void OnMove(InputAction.CallbackContext context)
   {
      MoveInput = context.ReadValue<Vector2>();
   }
}
