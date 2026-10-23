using UnityEngine;
using UnityEngine.SceneManagement;

public class GameController : MonoBehaviour
{
    public GameObject floatWindow;

    void Update()
    {
        checkInputs();
    }

    void checkInputs()
    {
        if(Input.GetButton("Cancel") && floatWindow.activeSelf == true)
		{
			floatWindow.SetActive(false);
		}
		else if(Input.GetButton("Cancel") && floatWindow.activeSelf == false)
		{
			floatWindow.SetActive(true);
		}
    }

    public static void softGameReset()
    {
        GameObject ball = GameObject.Find("Ball");
        GameObject limitLeft = GameObject.Find("Paddle Left");
        GameObject limitRight = GameObject.Find("Paddle Right");

        // Reset objects
        ball.transform.position = Vector2.zero;
        ball.GetComponent<Rigidbody2D>().velocity = new Vector2(
            ball.GetComponent<BallBehavior>().moveSpeed, 0.0f
        );

        limitLeft.transform.position = new Vector2(limitLeft.transform.position.x, 0.0f);
        limitRight.transform.position = new Vector2(limitRight.transform.position.x, 0.0f);
    }

	public static void hardGameReset()
	{
		SceneManager.LoadScene("MainGame");
	}
}
