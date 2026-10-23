using UnityEngine;

public class BallBehavior : MonoBehaviour
{
	public float moveSpeed = 15.0f;

	void Start()
	{
		// On start goes to the left
		GetComponent<Rigidbody2D>().velocity = Vector2.left * moveSpeed;
	}
}
