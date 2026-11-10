using UnityEngine;

namespace LD55
{
    public class PlayerInput
    {
        public bool ActionKey()
        {
            if (Input.GetKey(KeyCode.E))
            {
                return true;
            }

            return false;
        }

        public bool ActionKeyDown()
        {
            if (Input.GetKeyDown(KeyCode.E))
            {
                return true;
            }

            return false;
        }

        public Vector2 GetMove()
        {
            var result = new Vector2();

            if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow))
            {
                result.y = 1;
            } else if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow)) {
                result.y = -1;
            }

            if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow))
            {
                result.x = 1;
            }
            else if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow))
            {
                result.x = -1;
            }

            return result.normalized;
        }
    }
}
