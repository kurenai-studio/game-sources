using UnityEngine;

public enum Direction
{
	NONE = 0,
	UP,
	RIGHT,
	DOWN,
	LEFT
};

public class PlayerController : MonoBehaviour
{
	public Direction GetDirection { get; private set; }

	public float speed = 0.8f;

	// Start is called before the first frame update
	void Start()
    {
		GetDirection = Direction.NONE;
    }

    // Update is called once per frame
    void Update()
    {
		HandleKeyInput();
		HandleMovement();
    }

	void HandleKeyInput()
	{
		if(Input.GetKeyDown(KeyCode.W))
		{
			GetDirection = Direction.UP;
		}
		else if(Input.GetKeyDown(KeyCode.D))
		{
			GetDirection = Direction.RIGHT;
		}
		else if(Input.GetKeyDown(KeyCode.S))
		{
			GetDirection = Direction.DOWN;
		}
		else if (Input.GetKeyDown(KeyCode.A))
		{
			GetDirection = Direction.LEFT;
		}
	}

	void HandleMovement()
	{
		switch(GetDirection)
		{
			case Direction.UP:
				transform.Translate(0, speed * Time.deltaTime, 0);
				break;
			case Direction.RIGHT:
				transform.Translate(speed * Time.deltaTime, 0, 0);
				break;
			case Direction.DOWN:
				transform.Translate(0, -speed * Time.deltaTime, 0);
				break;
			case Direction.LEFT:
				transform.Translate(-speed * Time.deltaTime, 0, 0);
				break;
		}
	}
}
