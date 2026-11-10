using UnityEngine;

[RequireComponent(typeof(TrailRenderer))]
public class Warper : MonoBehaviour
{
	private Ship ship;
	private float camZoom;
	private float halfway;

	new public Camera camera;
	public float zoomOut = 1200f;
	public WarpGate target;
	public float speed = 300f;
	public bool antiClockWiseOrbit = false;

	void Start()
	{
		if (camera == null)
			camera = Camera.main;
	}
	
	public void Warp(Ship ship, WarpGate target, Vector3 start)
	{
		transform.position = start + Vector3.back * 100f;
		ship.transform.position = start;
		ship.transform.parent = transform;
		GetComponent<TrailRenderer>().Clear();
		camZoom = camera.orthographicSize;

		ship.ExitSolarSystem();
		target.PrepareEnemies();

		gameObject.SetActive(true);

		this.ship = ship;
		this.target = target;

		ship.gameObject.SetActive(false);
		halfway = (transform.position - target.transform.position).magnitude*0.5f;
	}

	void Update()
	{
		Vector3 direction = (target.transform.position - transform.position);
        float magnitude = direction.magnitude;
		direction.Normalize();
		if(magnitude > halfway)
		{
			transform.Translate(direction * (speed * Time.deltaTime));
			camera.orthographicSize = Mathf.Lerp(zoomOut, camZoom, magnitude / halfway - 1f);
		}
		else if (magnitude < Time.deltaTime*speed)
		{
			target.WarpComplete();
			transform.position = target.transform.position;
			ship.transform.parent = null;
			ship.gameObject.SetActive(true);
			ship.antiClockWiseOrbit = target.antiClockWiseOrbit;
			gameObject.SetActive(false);
			ship.EnterSolarSystem(target.transform.parent.GetComponent<PlanetarySystem>());
		}
		else
		{
			transform.Translate(direction * (speed * Time.deltaTime));
			camera.orthographicSize = Mathf.Lerp(camZoom, zoomOut, magnitude / halfway);
		}
    }
}
