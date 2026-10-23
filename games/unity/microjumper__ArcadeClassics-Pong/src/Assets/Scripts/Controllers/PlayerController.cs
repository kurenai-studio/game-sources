using UnityEngine;
using UnityEngine.InputSystem;

namespace Controllers
{
    public class PlayerController : MonoBehaviour, IController
    {
        private float verticalInput = 0;
    
        public void OnMove(InputAction.CallbackContext context)
        {
            verticalInput = context.phase switch
            {
                InputActionPhase.Performed => context.ReadValue<float>(),
                InputActionPhase.Canceled => 0f,
                _ => verticalInput
            };
        }

        public float GetVerticalInput() => verticalInput;
    }
}