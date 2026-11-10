using UnityEngine;
using System.Collections;

public class CameraController : MonoBehaviour {

	Camera cam;

	public float speed = 50f;
	public float zoom = 150f;
	public float pan = 50f;
	
	void Start () {
		cam = GetComponentInChildren<Camera>();
		cam.transform.tag = "MainCamera";
	}
	
	void Update ()
	{
		float hor = Input.GetAxis("Horizontal")*speed*Time.deltaTime;
		float ver = Input.GetAxis("Vertical")*speed*Time.deltaTime;
		transform.Translate(ver, 0f, -hor, Space.Self);


		float ms = Input.mouseScrollDelta.y*zoom*Time.deltaTime;
		cam.transform.Translate(0f, -ms, 0f, Space.World);
		if (Input.GetMouseButton(2))
		{
			transform.Rotate(0f, Input.GetAxis("Mouse X") * pan * Time.deltaTime, 0f, Space.World);
			transform.Rotate(0f, 0f, Input.GetAxis("Mouse Y") * pan * Time.deltaTime, Space.Self);
		}
	}
}
