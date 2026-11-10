using UnityEngine;
using System.Collections;

public class MouseSteering : MonoBehaviour
{

	new private Camera camera;
	public Ship player;
	private Rigidbody2D playerRig;
	private Vector2 target;
	public float zoomMultiplier = 10f;
	public float turnAngle = 30f;

	void Awake()
	{
		camera = GetComponent<Camera>();
		if (player == null)
			player = GameObject.FindGameObjectWithTag("Player").GetComponent<Ship>();
		playerRig = player.GetComponent<Rigidbody2D>();
		turnAngle *= Mathf.Deg2Rad;
	}

	void Update()
	{
		camera.orthographicSize *= 1 - (Input.GetAxis("Scroll") * Time.deltaTime * zoomMultiplier);
		if (Input.GetMouseButtonUp(0))
		{
			player.FireMissile();
		}
		if (Input.GetMouseButtonUp(1))
		{
			player.ActivateShield();
		}
		target = camera.ScreenToWorldPoint(Input.mousePosition);
		PhysicsFunctions.RigidBodyFollow(playerRig, target, player.acceleration, player.turnRate, turnAngle);

	}

	public void OnDrawGizmos()
	{
		Gizmos.color = Color.green;
		Gizmos.DrawLine(transform.position, target);
	}
}
