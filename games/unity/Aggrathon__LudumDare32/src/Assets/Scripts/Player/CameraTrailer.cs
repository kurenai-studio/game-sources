using UnityEngine;
using System.Collections;

public class CameraTrailer : MonoBehaviour {

    public float followSpeed = 2f;
    public float maxSpeed = 160f;
    public float maxDistance = 2f;
    public float boostShift = 2f;

    Rigidbody body;
    float length;

    void Start()
    {
        body = gameObject.GetComponentInParent<Rigidbody>();
        if(body == null)
            body = transform.parent.GetComponentInParent<Rigidbody>();
        if (body == null)
            body = GameObject.FindGameObjectWithTag("Player").GetComponent<Rigidbody>();
        length = 0f;
    }
	
	void FixedUpdate () {
        float boost = 0f;
        if(Input.GetButton("Boost")) {
            boost = boostShift;
        }

        length = Mathf.Lerp(length, 
            Mathf.Min(Mathf.Max(Vector3.Dot(transform.forward, body.velocity),0f),
            maxSpeed)/maxSpeed *maxDistance + boost, followSpeed * Time.deltaTime);

        transform.localPosition = new Vector3(
            transform.localPosition.x,
            transform.localPosition.y, 
            -length);
	}
}
