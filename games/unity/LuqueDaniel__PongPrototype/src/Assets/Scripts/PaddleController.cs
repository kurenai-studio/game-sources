using UnityEngine;

public class PaddleController : MonoBehaviour
{
    public float moveSpeed = 15;
    public string axisName = "Vertical";
    private Vector2 moveVector;
    
    void FixedUpdate() 
    {
        checkInputs();
    }

    void OnCollisionEnter2D(Collision2D collision)
    {
        // Only with ball
        if (collision.gameObject.name == "Ball")
        {
            // Ball's angle variables
            float ballPosition = collision.transform.position.y;  // Ball position Y
            float paddlePosition = transform.position.y;  // Paddle position Y
            float paddleHeight = GetComponent<Collider2D>().bounds.size.y;  // Paddle collider size Y

            // New x and y for direction
            float x;
            float y = (ballPosition - paddlePosition) / paddleHeight;  // (ball.y - paddle.y) / paddle.height
            float speed = collision.gameObject.GetComponent<BallBehavior>().moveSpeed;

            // Set new x direction
            if (transform.position.x < 0.0f)
            {
                x = 1.0f;
            }
            else
            {
                x = -1.0f;
            }

            // Set new x and y direction and * speed
            collision.gameObject.GetComponent<Rigidbody2D>().velocity = new Vector2(x, y) * speed;
        }
    }

    private void checkInputs()
    {
        // Get input axis
        moveVector.y = Input.GetAxisRaw(axisName);
        GetComponent<Rigidbody2D>().velocity = moveVector * moveSpeed;  // Move paddle
    }
}
