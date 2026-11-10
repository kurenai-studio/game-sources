using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Camera))]
public class CameraMove : MonoBehaviour {

	public float moveSpeed;
	public float zoomSpeed = 50f;
	public float scrollSize;
	public float minZoom = 20f;

	new private Camera camera;

	void Start() {
		camera = GetComponent<Camera>();
	}

	void Update () {
		float ver = Input.GetAxis("Vertical")*moveSpeed + transform.position.y;
		float hor = Input.GetAxis("Horizontal")*moveSpeed + transform.position.x;
		float zoom = -Input.GetAxis("Mouse ScrollWheel")*zoomSpeed + camera.orthographicSize;
		
		camera.orthographicSize = Mathf.Max(minZoom, zoom);
		float width = zoom*camera.aspect;

		ver = Mathf.Max(Mathf.Min(ver, scrollSize-zoom), -scrollSize+zoom);
		hor = Mathf.Min(Mathf.Max(hor, -scrollSize+width), scrollSize-width);
		transform.position = new Vector3(hor, ver, -10f);
	}
}
