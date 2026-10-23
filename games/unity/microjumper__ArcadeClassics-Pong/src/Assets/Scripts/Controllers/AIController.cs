using UnityEngine;

namespace Controllers
{
    public class AIController : MonoBehaviour, IController
    {
        [SerializeField]
        private GameObject ball;
        
        [SerializeField]
        private float deadZone = 0.15f;

        private float verticalInput = 0;
        
        public float GetVerticalInput()
        {
            var difference = ball.transform.position.y - transform.position.y;
        
            var direction = 0f;
        
            if (Mathf.Abs(difference) > deadZone)
            {
                direction = Mathf.Sign(difference);
            }

            verticalInput = Mathf.Lerp(verticalInput, direction, Time.deltaTime * 10f); // TODO use paddle speed

            return verticalInput;
        }
    }
}
