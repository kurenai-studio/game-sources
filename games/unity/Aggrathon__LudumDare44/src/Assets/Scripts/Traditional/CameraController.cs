using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static Unity.Mathematics.math;

[RequireComponent(typeof(Camera))]
public class CameraController : MonoBehaviour
{
    Camera camera;

    public float radius = 10f;

    public float speed = 1f;

    public float mouseScroll = 0.1f;


    void Start()
    {
        camera = GetComponent<Camera>();
    }


    void Update()
    {
        float scroll = Input.mouseScrollDelta.y;
        scroll = Mathf.Clamp(camera.orthographicSize - scroll, 1, this.radius);
        camera.orthographicSize = scroll;

        var speed = this.speed * Time.deltaTime;
        var radius = this.radius - scroll;

        var pos = transform.position;

        pos.x += Input.GetAxis("Horizontal") * speed;
        pos.y += Input.GetAxis("Vertical") * speed;

        var mx = Input.mousePosition;
        mx.x = mx.x / Screen.width * 2f - 1f;
        mx.y = mx.y / Screen.height * 2f - 1f;
        mx.x = clamp(abs(mx.x) - 1f + mouseScroll, 0, 1) / mouseScroll * sign(mx.x);
        mx.y = clamp(abs(mx.y) - 1f + mouseScroll, 0, 1) / mouseScroll * sign(mx.y);
        pos += mx * speed;

        pos.x = Mathf.Clamp(pos.x, -radius, radius);
        pos.y = Mathf.Clamp(pos.y, -radius, radius);
        transform.position = pos;
    }

    private void OnDrawGizmos() {
        Gizmos.color = Color.red;
        float size = radius * 2;
        Gizmos.DrawWireCube(Vector3.zero, new Vector3(size, size, size));
    }
}
